package com.mediaflow.android

import android.app.Application
import android.content.Context
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.util.AtomicFile
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID
import java.util.concurrent.CopyOnWriteArraySet

class MediaFlowApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        DownloadStore.init(this)
    }
}

data class DownloadJob(
    val id: String = UUID.randomUUID().toString(),
    val url: String,
    val mode: String,
    val quality: String,
    val playlist: Boolean,
    var title: String = url,
    var state: String = "queued",
    var progress: Int = -1,
    var message: String = "Waiting in queue",
    var files: List<String> = emptyList(),
    var errorCode: String = "",
    var details: String = ""
) {
    fun json() = JSONObject().put("id", id).put("url", url).put("mode", mode)
        .put("quality", quality).put("playlist", playlist).put("title", title)
        .put("state", state).put("progress", progress).put("message", message)
        .put("files", JSONArray(files)).put("errorCode", errorCode).put("details", details)

    companion object {
        fun fromJson(j: JSONObject) = DownloadJob(
            j.getString("id"), j.getString("url"), j.optString("mode", "Video"),
            j.optString("quality", "Best"), j.optBoolean("playlist"),
            j.optString("title"), j.optString("state"), j.optInt("progress", -1),
            j.optString("message"), j.optJSONArray("files")?.let { a ->
                (0 until a.length()).map { a.getString(it) }
            } ?: emptyList(), j.optString("errorCode"), j.optString("details")
        )
    }
}

object DownloadStore {
    private lateinit var context: Context
    private val jobs = mutableListOf<DownloadJob>()
    private val listeners = CopyOnWriteArraySet<() -> Unit>()
    private val main = Handler(Looper.getMainLooper())
    private lateinit var storage: AtomicFile
    val prefs get() = context.getSharedPreferences("mediaflow_native", Context.MODE_PRIVATE)
    val downloadDir: File get() = File(
        context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: File(context.filesDir, "downloads"), "MediaFlow"
    )
    val cookieFile: File get() = File(context.noBackupFilesDir, "session.cookies.txt")

    @Synchronized fun init(app: Context) {
        context = app.applicationContext
        storage = AtomicFile(File(context.filesDir, "downloads.json"))
        try {
            val data = JSONArray(storage.openRead().bufferedReader().use { it.readText() })
            for (i in 0 until data.length()) {
                val job = DownloadJob.fromJson(data.getJSONObject(i))
                if (job.state in listOf("queued", "downloading", "processing", "cancelling")) {
                    job.state = "interrupted"
                    job.message = "App stopped. Retry to resume available partial files."
                }
                jobs.add(job)
            }
        } catch (_: java.io.FileNotFoundException) {
            // First launch.
        } catch (e: Exception) {
            // Preserve corrupt state for recovery instead of replacing it silently.
            runCatching { storage.baseFile.copyTo(File(context.filesDir, "downloads.recovery.json"), overwrite = true) }
            android.util.Log.e("MediaFlow", "Cannot read history", e)
        }
        migrateLegacy()
    }

    private fun migrateLegacy() {
        if (prefs.getBoolean("legacyImported", false)) return
        val legacy = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        runCatching {
            val history = JSONArray(legacy.getString("flutter.download_history", "[]") ?: "[]")
            for (i in 0 until history.length()) {
                val entry = history.getJSONObject(i)
                val url = entry.optString("url")
                if (url.isBlank()) continue
                val path = entry.optString("filePath").takeIf { it.isNotBlank() && it != "null" && File(it).isFile }
                jobs.add(DownloadJob(url = url, mode = if (entry.optBoolean("isAudio")) "Audio (MP3)" else "Video (MP4)",
                    quality = entry.optString("quality", "Best"), playlist = false, title = entry.optString("title", url),
                    state = if (path != null) "completed" else "interrupted", files = path?.let { listOf(it) } ?: emptyList(),
                    message = if (path != null) "Imported from previous app" else "Imported history. Retry to save the file again."))
            }
            if (!prefs.contains("light")) prefs.edit().putBoolean("light", legacy.getString("flutter.theme_mode", "dark") == "light").apply()
            if (!prefs.contains("language")) prefs.edit().putString("language", legacy.getString("flutter.language", java.util.Locale.getDefault().language)).apply()
            val oldCookie = legacy.getString("flutter.cookie_file", "").orEmpty()
            if (oldCookie.isNotBlank() && File(oldCookie).isFile && !cookieFile.exists()) File(oldCookie).copyTo(cookieFile)
            if (jobs.isNotEmpty()) save()
            prefs.edit().putBoolean("legacyImported", true).apply()
        }.onFailure { android.util.Log.e("MediaFlow", "Previous app data could not be imported; original preferences retained", it) }
    }

    @Synchronized fun snapshot(): List<DownloadJob> = jobs.map { it.copy(files = it.files.toList()) }
    @Synchronized fun next(): DownloadJob? = jobs.firstOrNull { it.state == "queued" }?.also {
        it.state = "downloading"
        it.message = "Connecting…"
        save()
    }?.copy()

    @Synchronized fun enqueue(urls: List<String>, mode: String, quality: String, playlist: Boolean) {
        urls.forEach { jobs.add(DownloadJob(url = it, mode = mode, quality = quality, playlist = playlist)) }
        save()
    }

    @Synchronized fun update(id: String, persist: Boolean = false, change: (DownloadJob) -> Unit) {
        jobs.firstOrNull { it.id == id }?.let(change)
        if (persist) save() else notifyChanged()
    }

    @Synchronized fun clearFinished() {
        jobs.removeAll { it.state !in listOf("queued", "downloading", "processing", "cancelling") }
        save()
    }

    fun observe(listener: () -> Unit) { listeners.add(listener) }
    fun removeObserver(listener: () -> Unit) { listeners.remove(listener) }
    private fun notifyChanged() { main.post { listeners.forEach { it() } } }

    @Synchronized private fun save() {
        val bytes = JSONArray(jobs.map { it.json() }).toString().toByteArray(Charsets.UTF_8)
        val stream = storage.startWrite()
        try {
            stream.write(bytes)
            storage.finishWrite(stream)
        } catch (e: Exception) {
            storage.failWrite(stream)
            throw e
        }
        notifyChanged()
    }
}
