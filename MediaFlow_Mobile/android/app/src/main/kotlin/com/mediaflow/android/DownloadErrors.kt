package com.mediaflow.android

import java.io.IOException
import java.net.URI

data class DownloadFailure(val code: String, val title: String, val action: String, val details: String)

object DownloadErrors {
    fun validateUrl(value: String): String {
        val uri = try { URI(value.trim()) } catch (_: Exception) {
            throw IllegalArgumentException("Invalid URL. Paste a complete http:// or https:// link.")
        }
        require(uri.scheme?.lowercase() in listOf("http", "https") && !uri.host.isNullOrBlank()) {
            "Invalid URL. Paste a complete http:// or https:// link."
        }
        require(uri.userInfo == null) { "URLs containing passwords are not supported." }
        return uri.toASCIIString()
    }

    // Keep session tokens and signed query strings out of visible diagnostics.
    fun redact(raw: String): String = raw
        .replace(Regex("https?://[^\\s<>\"]+")) { match ->
            try {
                val uri = URI(match.value)
                "${uri.scheme}://${uri.host}${uri.path ?: ""}" + if (uri.query != null) "?[redacted]" else ""
            } catch (_: Exception) { "[URL]" }
        }
        .replace(Regex("(?i)(authorization|cookie|token|password)\\s*[:=]\\s*[^\\r\\n]+"), "$1=[redacted]")
        .takeLast(5000)

    fun classify(error: Throwable): DownloadFailure {
        val details = redact(error.message ?: error.javaClass.simpleName)
        val message = details.lowercase()
        val (code, title, action) = when {
            error is IllegalArgumentException -> Triple("INVALID_INPUT", "Check the link or settings", details)
            "no space" in message || "enospc" in message -> Triple("DISK_FULL", "Storage is full", "Free up storage, then retry.")
            "permission denied" in message || "eacces" in message -> Triple("PERMISSION", "Cannot save this file", "Check storage access and available space.")
            "429" in message || "rate limit" in message -> Triple("RATE_LIMIT", "The source is limiting requests", "Wait before retrying. Avoid starting many downloads at once.")
            "private" in message || "sign in" in message || "login" in message || "cookies" in message || "401" in message ->
                Triple("LOGIN_REQUIRED", "This link needs your account", "Import a cookies.txt file in Settings, then retry.")
            "403" in message || "forbidden" in message || "canDownload" in details ->
                Triple("ACCESS_DENIED", "The source denied access", "Check sharing permissions or refresh your login cookies. Download restrictions may apply.")
            "404" in message || "not found" in message || "removed" in message || "expired" in message ->
                Triple("UNAVAILABLE", "The link is unavailable", "Open the link in your browser and check that it has not expired or been removed.")
            "drm" in message -> Triple("DRM", "Protected media", "This app cannot save DRM-protected media.")
            "javascript" in message || "challenge" in message || "nsig" in message ->
                Triple("EXTRACTOR_UPDATE", "The source changed its player", "Update the download engine in Settings and retry.")
            "ffmpeg" in message || "ffprobe" in message -> Triple("PROCESSING", "Media processing failed", "Try another format. Check free space; details are available below.")
            "unsupported url" in message || "web page" in message -> Triple("UNSUPPORTED", "This link is not supported yet", "Try a direct file URL or use Video mode for media pages.")
            "format" in message -> Triple("FORMAT_UNAVAILABLE", "That quality is unavailable", "Choose Best quality or a different output format.")
            error is IOException || "timeout" in message || "timed out" in message || "connection" in message || "resolve" in message ->
                Triple("NETWORK", "Connection interrupted", "Check your connection, then retry to resume when the source supports it.")
            else -> Triple("DOWNLOAD_FAILED", "The download failed", "Retry, check the link in your browser, or update the download engine.")
        }
        return DownloadFailure(code, title, action, details)
    }
}
