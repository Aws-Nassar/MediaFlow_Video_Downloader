package com.mediaflow.android

import android.text.Html
import java.io.IOException
import java.net.URI

data class DriveEntry(val id: String, val name: String, val url: String, val folder: Boolean)
data class DriveFolder(val id: String, val title: String, val entries: List<DriveEntry>)

object DriveFolders {
    fun matches(url: String): Boolean {
        val uri = URI(url)
        return uri.host in listOf("drive.google.com", "docs.google.com") &&
            Regex("/drive/(?:u/\\d+/)?folders/[\\w-]+/?").matches(uri.path)
    }

    fun safeName(value: String): String = value.replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
        .trim(' ', '.').take(120).ifBlank { "Untitled" }

    private fun text(value: String) = Html.fromHtml(value, Html.FROM_HTML_MODE_LEGACY).toString().trim()

    fun list(url: String, fetch: (String) -> String): DriveFolder {
        require(matches(url)) { "Invalid Google Drive folder URL" }
        val id = URI(url).path.trimEnd('/').substringAfterLast('/')
        val page = fetch("https://drive.google.com/embeddedfolderview?id=$id")
        val title = Regex("<title[^>]*>(.*?)</title>", setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL))
            .find(page)?.groupValues?.get(1)?.let { text(it) }.orEmpty()
        if (title.isBlank() || "sign in" in title.lowercase() || "request access" in title.lowercase()) {
            throw IOException("Login required or access denied for this Drive folder")
        }
        val entries = Regex("<a\\s[^>]*href=([\"'])(.*?)\\1[^>]*>(.*?)</a>", setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL))
            .findAll(page).mapNotNull { match ->
                val href = text(match.groupValues[2])
                val uri = runCatching { URI(href) }.getOrNull() ?: return@mapNotNull null
                if (uri.host !in listOf("drive.google.com", "docs.google.com")) return@mapNotNull null
                val entryId = Regex("/(?:file/d|folders|document/d|spreadsheets/d|presentation/d)/([\\w-]+)")
                    .find(uri.path)?.groupValues?.get(1) ?: return@mapNotNull null
                DriveEntry(entryId, safeName(text(match.groupValues[3]).ifBlank { entryId }), href, "/folders/" in uri.path)
            }.distinctBy { it.id }.toList()
        if (entries.isEmpty() && "flip-entries" !in page) throw IOException("Drive folder contents are unavailable. Check sharing permissions.")
        return DriveFolder(id, safeName(title), entries)
    }
}
