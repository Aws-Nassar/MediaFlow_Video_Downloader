package com.mediaflow.android

import android.content.Context
import android.util.Log
import com.chaquo.python.Python
import com.chaquo.python.PyObject
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class PythonBridge private constructor(private val appContext: Context) {

    companion object {
        @Volatile
        private var instance: PythonBridge? = null

        fun getInstance(context: Context): PythonBridge {
            return instance ?: synchronized(this) {
                instance ?: PythonBridge(context.applicationContext).also { instance = it }
            }
        }

        private const val FALLBACK_OPTIONS =
            """{"video_formats":["mp4","mkv","webm"],"audio_formats":["mp3","m4a","aac","opus","flac","wav","ogg"],"video_qualities":["Best Available","1080p (FHD)","720p (HD)","480p","360p","240p","144p","Worst"],"audio_qualities":["Best","320 kbps","256 kbps","192 kbps","128 kbps","96 kbps","64 kbps","Worst"]}"""
    }

    private var backend: PyObject? = null
    private var channel: MethodChannel? = null
    private var progressSink: EventChannel.EventSink? = null

    fun initialize(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mediaflow.android/python")

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mediaflow.android/python/progress")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressSink = events
                }

                override fun onCancel(arguments: Any?) {
                    progressSink = null
                }
            })

        channel?.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getOptions" -> result.success(getOptions())
                    "fetchInfo" -> {
                        val url = call.argument<String>("url") ?: ""
                        val playlist = call.argument<Boolean>("playlist") ?: false
                        val cookieFile = call.argument<String>("cookieFile") ?: ""
                        result.success(fetchInfo(url, playlist, cookieFile))
                    }
                    "download" -> {
                        val url = call.argument<String>("url") ?: ""
                        val outputDir = call.argument<String>("outputDir") ?: ""
                        val ext = call.argument<String>("ext") ?: ""
                        val quality = call.argument<String>("quality") ?: ""
                        val isAudio = call.argument<Boolean>("isAudio") ?: false
                        val optionsJson = call.argument<String>("optionsJson") ?: "{}"
                        result.success(download(url, outputDir, ext, quality, isAudio, optionsJson))
                    }
                    "cancelDownload" -> {
                        cancelDownload()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("PYTHON_ERROR", e.message, null)
            }
        }

        try {
            if (!Python.isStarted()) {
                Python.start(AndroidPlatform(appContext))
            }
            backend = Python.getInstance().getModule("mediaflow_core")
            Log.i("PythonBridge", "Python module loaded")
        } catch (e: Exception) {
            Log.e("PythonBridge", "Failed to init Python: ${e.message}")
        }
    }

    fun destroy() {
        channel?.setMethodCallHandler(null)
        progressSink = null
    }

    private fun getOptions(): String {
        return try {
            backend?.callAttr("get_options")?.toString() ?: FALLBACK_OPTIONS
        } catch (e: Exception) {
            Log.e("PythonBridge", "getOptions error: ${e.message}")
            FALLBACK_OPTIONS
        }
    }

    private fun fetchInfo(url: String, playlist: Boolean, cookieFile: String): String {
        return try {
            backend?.callAttr("fetch_info", url, playlist, cookieFile)?.toString()
                ?: """{"ok":false,"error":"Backend not available"}"""
        } catch (e: Exception) {
            Log.e("PythonBridge", "fetchInfo error: ${e.message}")
            jsonError(e)
        }
    }

    private fun download(url: String, outputDir: String, ext: String, quality: String, isAudio: Boolean, optionsJson: String): String {
        return try {
            val bridge = progressBridge()
            val raw = backend?.callAttr("download", url, outputDir, ext, quality, isAudio, optionsJson, bridge)?.toString()
            raw ?: """{"ok":false,"error":"Backend not available"}"""
        } catch (e: Exception) {
            Log.e("PythonBridge", "download error: ${e.message}")
            jsonError(e)
        }
    }

    private fun cancelDownload() {
        try {
            backend?.callAttr("cancel_current")
        } catch (_: Exception) {}
    }

    private fun progressBridge(): Any {
        return object {
            @Suppress("unused")
            fun onProgress(raw: String) {
                progressSink?.success(raw)
            }
        }
    }

    private fun jsonError(e: Exception): String {
        val msg = e.message?.replace("\"", "'") ?: "Unknown error"
        return """{"ok":false,"error":"$msg"}"""
    }
}
