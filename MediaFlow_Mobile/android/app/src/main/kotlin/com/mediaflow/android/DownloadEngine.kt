package com.mediaflow.android

import android.content.Context
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.net.URLDecoder
import java.net.CookieManager
import java.net.CookiePolicy
import java.net.HttpCookie
import java.security.MessageDigest
import java.util.concurrent.CancellationException
import java.util.concurrent.atomic.AtomicBoolean

class DownloadEngine(private val context: Context) {
    private class HttpStatusFailure(val code: Int) : IOException("HTTP $code")
    private val cancelled = AtomicBoolean(false)
    @Volatile private var connection: HttpURLConnection? = null
    @Volatile private var processId: String? = null
    private val cookies = CookieManager(null, CookiePolicy.ACCEPT_ORIGINAL_SERVER).apply {
        if (DownloadStore.cookieFile.isFile) DownloadStore.cookieFile.forEachLine { line ->
            val fields = line.removePrefix("#HttpOnly_").split('\t')
            if (!line.startsWith("#") || line.startsWith("#HttpOnly_")) {
                if (fields.size >= 7) runCatching {
                    val expires = fields[4].toLongOrNull() ?: 0L
                    if (expires == 0L || expires > System.currentTimeMillis() / 1000) {
                        val domain = fields[0].trimStart('.')
                        val secure = fields[3].equals("TRUE", true)
                        cookieStore.add(URI("${if (secure) "https" else "http"}://$domain"), HttpCookie(fields[5], fields[6]).apply {
                            this.domain = fields[0]; path = fields[2]; this.secure = secure; version = 0
                        })
                    }
                }
            }
        }
    }

    fun cancel() {
        cancelled.set(true)
        connection?.disconnect()
        processId?.let { YoutubeDL.getInstance().destroyProcessById(it) }
    }

    private fun checkCancelled() {
        if (cancelled.get() || Thread.currentThread().isInterrupted) throw CancellationException()
    }

    private fun initialize() {
        YoutubeDL.getInstance().init(context.applicationContext)
        FFmpeg.getInstance().init(context.applicationContext)
    }

    fun update(): String {
        initialize()
        YoutubeDL.getInstance().updateYoutubeDL(context, YoutubeDL.UpdateChannel.STABLE)
        return YoutubeDL.getInstance().versionName(context) ?: "Current stable engine"
    }

    private fun request(url: String, playlist: Boolean): YoutubeDLRequest {
        initialize()
        return YoutubeDLRequest(DownloadErrors.validateUrl(url)).apply {
            addOption(if (playlist) "--yes-playlist" else "--no-playlist")
            addOption("--socket-timeout", 25)
            addOption("--retries", 3)
            addOption("--fragment-retries", 3)
            addOption("--no-colors")
            // The APK ships QuickJS; EJS scripts are fetched from the official yt-dlp release if absent.
            addOption("--remote-components", "ejs:github")
            if (DownloadStore.cookieFile.isFile) addOption("--cookies", DownloadStore.cookieFile.absolutePath)
        }
    }

    fun analyse(rawUrl: String, mode: String, playlist: Boolean): JSONObject {
        val url = DownloadErrors.validateUrl(rawUrl)
        if (DriveFolders.matches(url)) {
            val folder = DriveFolders.list(url, ::fetchPage)
            return JSONObject().put("title", folder.title).put("extractor", "Drive folder")
                .put("entries", org.json.JSONArray(folder.entries.map { JSONObject().put("title", it.name) }))
        }
        if (isFile(url, mode)) {
            var conn = open(url, "HEAD")
            try {
                if (conn.responseCode in listOf(405, 501)) {
                    conn.disconnect()
                    conn = open(url)
                }
                if (conn.responseCode !in 200..299) throw IOException("HTTP ${conn.responseCode}")
                ensureFile(conn)
                return JSONObject().put("title", filename(conn, url)).put("extractor", "Direct file")
                    .put("filesize", conn.getHeaderFieldLong("Content-Length", -1))
            } finally { conn.disconnect() }
        }
        val req = request(url, playlist).addOption("--dump-single-json").addOption("--skip-download")
        if (playlist) req.addOption("--flat-playlist")
        return JSONObject(YoutubeDL.getInstance().execute(req).out)
    }

    fun download(job: DownloadJob, outputDir: File = DownloadStore.downloadDir, progress: (Int, String) -> Unit): List<String> {
        checkCancelled()
        val url = DownloadErrors.validateUrl(job.url)
        if (DriveFolders.matches(url)) return downloadFolder(job, progress)
        if (isFile(url, job.mode)) return downloadFile(url, progress)
        val req = request(url, job.playlist)
        val audio = job.mode.startsWith("Audio")
        val ext = when {
            "MKV" in job.mode -> "mkv"
            "M4A" in job.mode -> "m4a"
            audio -> "mp3"
            else -> "mp4"
        }
        val height = job.quality.removeSuffix("p").toIntOrNull()
        val video = if (height != null) "bv*[height<=$height]+ba/b[height<=$height]" else "bv*+ba/b"
        req.addOption("-f", if (audio) "ba/b" else video)
        if (audio) {
            req.addOption("--extract-audio").addOption("--audio-format", ext)
            req.addOption("--audio-quality", "0")
        } else {
            req.addOption("--merge-output-format", ext).addOption("--remux-video", ext)
        }
        val template = if (job.playlist) "%(playlist_title).80B/%(playlist_index)03d - " else ""
        req.addOption("-o", File(outputDir,
            template + "%(title).120B [%(id)s] [${job.quality}].%(ext)s").absolutePath)
        req.addOption("--windows-filenames").addOption("--trim-filenames", 180)
        req.addOption("--continue").addOption("--no-overwrites").addOption("--newline")
        req.addOption("--no-simulate").addOption("--progress")
        req.addOption("--print", "after_move:MEDIAFLOW_FILE:%(filepath)j")
        processId = job.id
        checkCancelled()
        val response = YoutubeDL.getInstance().execute(req, job.id) { percent, _, line ->
            if (cancelled.get()) YoutubeDL.getInstance().destroyProcessById(job.id)
            progress(if (percent < 0) -1 else percent.toInt().coerceIn(0, 99), DownloadErrors.redact(line))
        }
        processId = null
        checkCancelled()
        val files = response.out.lineSequence().filter { it.startsWith("MEDIAFLOW_FILE:") }.map {
            // Parse the JSON string rather than guessing an extension before postprocessing.
            org.json.JSONArray("[${it.removePrefix("MEDIAFLOW_FILE:")}]").getString(0)
        }.filter { File(it).isFile }.distinct().toList()
        check(files.isNotEmpty()) { "The source returned no completed files. Partial files remain available for retry." }
        return files
    }

    private fun isFile(url: String, mode: String): Boolean {
        if (mode == "Original file") return true
        val uri = URI(url)
        return uri.host.equals("raw.githubusercontent.com", true) ||
            (uri.host.equals("github.com", true) && "/releases/download/" in uri.path) ||
            Regex("(?i)\\.(zip|7z|rar|pdf|docx?|xlsx?|pptx?|apk|exe|dmg|iso|tar|gz|txt|csv|json|png|jpg|jpeg|webp)$").containsMatchIn(uri.path ?: "")
    }

    private fun directUrl(raw: String): String {
        val uri = URI(raw)
        if (uri.host in listOf("drive.google.com", "docs.google.com")) {
            val id = Regex("/file/d/([\\w-]+)").find(uri.path)?.groupValues?.get(1)
            if (id != null) return "https://drive.usercontent.google.com/download?id=$id&export=download&confirm=t"
        }
        if (uri.host.equals("github.com", true) && "/blob/" in uri.path) {
            return "https://raw.githubusercontent.com" + uri.path.replaceFirst("/blob/", "/")
        }
        if (uri.host?.lowercase() in listOf("dropbox.com", "www.dropbox.com")) {
            val query = uri.rawQuery.orEmpty().split('&').filter { it.isNotEmpty() && !it.startsWith("dl=") && !it.startsWith("raw=") }
            return URI(uri.scheme, uri.authority, uri.path, null, null).toString() + "?" + (query + "dl=1").joinToString("&")
        }
        return raw
    }

    private fun open(raw: String, method: String = "GET"): HttpURLConnection {
        var url = URL(directUrl(raw))
        repeat(10) {
            checkCancelled()
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = method
                connectTimeout = 25000
                readTimeout = 25000
                instanceFollowRedirects = false
                setRequestProperty("User-Agent", "MediaFlow/2.0")
                setRequestProperty("Accept-Encoding", "identity")
                cookies.get(url.toURI(), emptyMap()).forEach { (name, values) -> setRequestProperty(name, values.joinToString("; ")) }
            }
            // Redirects are handled explicitly so headers and schemes stay predictable.
            connection = conn
            cookies.put(url.toURI(), conn.headerFields.filterKeys { it != null })
            if (conn.responseCode in listOf(301, 302, 303, 307, 308)) {
                val location = conn.getHeaderField("Location") ?: throw IOException("Redirect without a destination")
                val next = URL(url, location)
                DownloadErrors.validateUrl(next.toString())
                conn.disconnect()
                url = next
            } else return conn
        }
        throw IOException("Too many redirects")
    }

    private fun ensureFile(conn: HttpURLConnection) {
        val type = conn.contentType.orEmpty().lowercase()
        if (("text/html" in type || "application/xhtml" in type) && conn.getHeaderField("Content-Disposition") == null) {
            if (conn.url.host in listOf("drive.usercontent.google.com", "drive.google.com", "docs.google.com")) throw HttpStatusFailure(403)
            throw IOException("This URL is a web page, not a downloadable file. Check sharing permissions or use Video mode for a media page.")
        }
    }

    private fun filename(conn: HttpURLConnection, url: String): String {
        val disposition = conn.getHeaderField("Content-Disposition").orEmpty()
        val encoded = Regex("(?i)filename\\*=UTF-8''([^;]+)").find(disposition)?.groupValues?.get(1)
        val plain = Regex("(?i)filename=\"?([^\";]+)").find(disposition)?.groupValues?.get(1)
        val raw = encoded?.let { URLDecoder.decode(it, "UTF-8") } ?: plain
            ?: URI(url).path.substringAfterLast('/').ifBlank { "download" }
        val clean = raw.replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_").trim(' ', '.').take(160)
        return clean.ifBlank { "download" }
    }

    private fun downloadFile(url: String, progress: (Int, String) -> Unit, destination: File? = null, suppliedName: String? = null): List<String> {
        // Per-URL directory avoids collisions and keeps retries on the same partial file.
        val hash = MessageDigest.getInstance("SHA-256").digest(url.toByteArray()).take(8).joinToString("") { "%02x".format(it) }
        val folder = (destination ?: File(DownloadStore.downloadDir, "Files/$hash")).also { check(it.isDirectory || it.mkdirs()) }
        var lastError: Exception? = null
        repeat(3) { attempt ->
            checkCancelled()
            var conn: HttpURLConnection? = null
            try {
                conn = open(url)
                if (conn.responseCode !in 200..299) throw HttpStatusFailure(conn.responseCode)
                ensureFile(conn)
                val target = File(folder, suppliedName?.let { DriveFolders.safeName(it) } ?: filename(conn, url))
                val partial = File(folder, target.name + ".part")
                // Restart direct transfers rather than risk concatenating a changed remote file.
                // Media downloads use yt-dlp's validated resume handling instead.
                val total = conn.getHeaderFieldLong("Content-Length", -1)
                var done = 0L
                val start = System.nanoTime()
                var lastUpdate = 0L
                conn.inputStream.use { input ->
                    RandomAccessFile(partial, "rw").use { output ->
                        output.setLength(0)
                        val buffer = ByteArray(128 * 1024)
                        while (true) {
                            checkCancelled()
                            val count = input.read(buffer)
                            if (count < 0) break
                            output.write(buffer, 0, count)
                            done += count
                            val now = System.nanoTime()
                            if (now - lastUpdate > 250_000_000L) {
                                val rate = done / ((now - start) / 1e9).coerceAtLeast(0.01)
                                progress(if (total > 0) ((done.toDouble() / total) * 100).toInt().coerceIn(0, 99) else -1,
                                    "${size(done)} / ${if (total > 0) size(total) else "unknown size"} · ${size(rate.toLong())}/s")
                                lastUpdate = now
                            }
                        }
                        output.fd.sync()
                    }
                }
                checkCancelled()
                if (total >= 0 && done != total) throw IOException("Connection interrupted before the complete file arrived")
                var completed = target
                var number = 1
                while (completed.exists()) {
                    completed = File(folder, "${target.nameWithoutExtension} (${number++})${if (target.extension.isNotEmpty()) ".${target.extension}" else ""}")
                }
                check(partial.renameTo(completed)) { "Cannot finalize the downloaded file" }
                return listOf(completed.absolutePath)
            } catch (e: CancellationException) { throw e
            } catch (e: Exception) {
                lastError = e
                checkCancelled()
                if (e is HttpStatusFailure && e.code in 400..499 && e.code !in listOf(408, 429)) throw e
                if (attempt < 2) {
                    progress(-1, "Connection interrupted. Retrying ${attempt + 1}/2…")
                    repeat((attempt + 1) * 10) { checkCancelled(); Thread.sleep(100) }
                }
            } finally { conn?.disconnect(); connection = null }
        }
        throw lastError ?: IOException("File transfer failed")
    }

    private fun fetchPage(url: String): String {
        checkCancelled()
        val conn = open(url)
        try {
            if (conn.responseCode !in 200..299) throw IOException("HTTP ${conn.responseCode}")
            if (conn.url.host == "accounts.google.com") throw IOException("Login required for this Drive folder")
            val data = java.io.ByteArrayOutputStream()
            conn.inputStream.use { input ->
                val buffer = ByteArray(8192)
                while (true) {
                    checkCancelled()
                    val count = input.read(buffer)
                    if (count < 0) break
                    require(data.size() + count <= 8 * 1024 * 1024) { "Folder listing is too large. Open a smaller subfolder." }
                    data.write(buffer, 0, count)
                }
            }
            return data.toString("UTF-8")
        } finally { conn.disconnect() }
    }

    private fun downloadFolder(job: DownloadJob, progress: (Int, String) -> Unit): List<String> {
        val root = DriveFolders.list(job.url, ::fetchPage)
        val destination = File(DownloadStore.downloadDir, "Drive/${root.title} [${root.id.take(8)}]")
        val files = mutableListOf<String>()
        val visited = mutableSetOf<String>()
        fun visit(folder: DriveFolder, directory: File, depth: Int) {
            checkCancelled()
            require(depth <= 40 && visited.size <= 1000 && files.size <= 10000) { "Folder is too large for one job. Download its subfolders separately." }
            if (!visited.add(folder.id)) return
            check(directory.isDirectory || directory.mkdirs()) { "Cannot create download folder" }
            folder.entries.forEach { entry ->
                checkCancelled()
                if (entry.folder) {
                    visit(DriveFolders.list(entry.url, ::fetchPage), File(directory, "${entry.name} [${entry.id.take(8)}]"), depth + 1)
                } else {
                    val uri = URI(entry.url)
                    val kind = uri.path.trim('/').substringBefore('/')
                    val ext = mapOf("document" to "pdf", "spreadsheets" to "xlsx", "presentation" to "pptx")[kind]
                    val link = if (uri.host == "docs.google.com" && ext != null) "https://docs.google.com/$kind/d/${entry.id}/export?format=$ext"
                        else "https://drive.usercontent.google.com/download?id=${entry.id}&export=download&confirm=t"
                    val name = "${entry.id.take(8)} - ${entry.name}" + if (ext != null) ".$ext" else ""
                    val saved = try {
                        downloadFile(link, { percent, message -> progress(percent, "${files.size} saved · ${entry.name}\n$message") }, directory, name)
                    } catch (error: HttpStatusFailure) {
                        if (error.code != 403 || job.mode == "Original file" || ext != null) throw error
                        checkCancelled()
                        download(job.copy(url = entry.url, playlist = false), directory) { percent, message ->
                            progress(percent, "Saving an available playback copy · ${entry.name}\n$message")
                        }
                    }
                    files += saved
                    DownloadStore.update(job.id, true) { it.files = files.toList() }
                }
            }
        }
        visit(root, destination, 0)
        return files
    }

    private fun size(bytes: Long): String = when {
        bytes >= 1_073_741_824 -> "%.1f GB".format(bytes / 1_073_741_824.0)
        bytes >= 1_048_576 -> "%.1f MB".format(bytes / 1_048_576.0)
        bytes >= 1024 -> "%.1f KB".format(bytes / 1024.0)
        else -> "$bytes B"
    }
}
