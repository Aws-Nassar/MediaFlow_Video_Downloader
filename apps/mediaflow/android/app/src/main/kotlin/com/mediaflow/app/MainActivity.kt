package com.mediaflow.app

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.mediaflow.app/platform"
    private var engineBridge: AndroidEngineBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engineBridge?.dispose()
        engineBridge = AndroidEngineBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDownloadDirectory" -> {
                        try {
                            result.success(downloadDirectory())
                        } catch (error: Exception) {
                            result.error("directory_failed", error.message, null)
                        }
                    }
                    "getAvailableBytes" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("invalid_path", "A path is required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(availableBytes(path))
                        } catch (error: Exception) {
                            result.error("stat_failed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        engineBridge?.dispose()
        engineBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun downloadDirectory(): String {
        val external = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
        val base = external ?: filesDir
        val directory = File(base, "MediaFlow")
        directory.mkdirs()
        return directory.absolutePath
    }

    private fun availableBytes(path: String): Long {
        var directory = File(path).absoluteFile
        while (!directory.exists()) {
            val parent = directory.parentFile ?: break
            directory = parent
        }
        return StatFs(directory.absolutePath).availableBytes
    }
}
