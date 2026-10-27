package com.mediaflow.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Method-channel bridge to the bundled youtubedl-android runtime.
 *
 * Dart owns the command arguments and reuses the desktop JSON/progress parsers.
 * Kotlin only initializes the native runtime, runs the request, forwards marked
 * stdout lines, cancels by job id, and returns the terminal result.
 */
class AndroidEngineBridge(
    context: Context,
    messenger: BinaryMessenger,
) {
    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val activeJobs: MutableSet<String> = ConcurrentHashMap.newKeySet()
    private val cancelledJobs: MutableSet<String> = ConcurrentHashMap.newKeySet()
    private val initLock = Any()

    @Volatile
    private var youtubeDlInitialized = false

    @Volatile
    private var ffmpegInitialized = false

    @Volatile
    private var disposed = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "probe" -> handleProbe(call, result)
                "download" -> handleDownload(call, result)
                "cancel" -> handleCancel(call, result)
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        for (jobId in activeJobs) {
            cancelledJobs.add(jobId)
            try {
                YoutubeDL.getInstance().destroyProcessById(jobId)
            } catch (_: Exception) {
                // The runtime may not have been initialized yet.
            }
        }
        executor.shutdownNow()
    }

    private fun handleProbe(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url")?.trim()
        val args = stringList(call.argument<List<*>>("args"))
        if (url.isNullOrEmpty()) {
            result.error("invalid_arguments", "A URL is required.", null)
            return
        }

        try {
            executor.execute { runProbe(url, args, result) }
        } catch (error: Exception) {
            result.error("engine_unavailable", errorMessage(error), null)
        }
    }

    private fun runProbe(
        url: String,
        args: List<String>,
        result: MethodChannel.Result,
    ) {
        try {
            ensureYoutubeDl()
        } catch (error: Exception) {
            postError(result, "engine_init_failed", error)
            return
        }

        try {
            val request = YoutubeDLRequest(url)
            if (args.isNotEmpty()) request.addCommands(args)
            val response = YoutubeDL.getInstance().execute(request)
            postResult(result, response.out)
        } catch (error: Exception) {
            postError(result, "probe_failed", error)
        }
    }

    private fun handleDownload(call: MethodCall, result: MethodChannel.Result) {
        val jobId = call.argument<String>("jobId")?.trim()
        val url = call.argument<String>("url")?.trim()
        val args = stringList(call.argument<List<*>>("args"))
        if (jobId.isNullOrEmpty() || url.isNullOrEmpty()) {
            result.error(
                "invalid_arguments",
                "A job id and URL are required.",
                null,
            )
            return
        }

        if (!activeJobs.add(jobId)) {
            result.error("duplicate_job", "That job is already active.", null)
            return
        }
        cancelledJobs.remove(jobId)

        try {
            executor.execute { runDownload(jobId, url, args, result) }
        } catch (error: Exception) {
            activeJobs.remove(jobId)
            result.error("engine_unavailable", errorMessage(error), null)
        }
    }

    private fun runDownload(
        jobId: String,
        url: String,
        args: List<String>,
        result: MethodChannel.Result,
    ) {
        try {
            if (cancelledJobs.contains(jobId)) {
                postResult(result, cancelledResult())
                return
            }

            try {
                ensureYoutubeDl()
            } catch (error: Exception) {
                postDownloadFailure(result, "engine_init_failed", error)
                return
            }
            if (cancelledJobs.contains(jobId)) {
                postResult(result, cancelledResult())
                return
            }

            try {
                ensureFfmpeg()
            } catch (error: Exception) {
                postDownloadFailure(result, "ffmpeg_init_failed", error)
                return
            }
            if (cancelledJobs.contains(jobId)) {
                postResult(result, cancelledResult())
                return
            }

            val request = YoutubeDLRequest(url)
            if (args.isNotEmpty()) request.addCommands(args)

            var callbackPath: String? = null
            val response =
                try {
                    YoutubeDL.getInstance().execute(
                        request,
                        jobId,
                        callback = { _, _, line ->
                            if (
                                line.contains(PROGRESS_MARKER) ||
                                    line.contains(FILE_MARKER)
                            ) {
                                postLine(jobId, line)
                                if (line.contains(FILE_MARKER)) {
                                    extractPath(line)?.let { callbackPath = it }
                                }
                            }
                        },
                    )
                } catch (_: YoutubeDL.CanceledException) {
                    postResult(result, cancelledResult())
                    return
                } catch (error: InterruptedException) {
                    if (cancelledJobs.contains(jobId)) {
                        postResult(result, cancelledResult())
                    } else {
                        postDownloadFailure(result, null, error)
                    }
                    return
                } catch (error: YoutubeDLException) {
                    if (cancelledJobs.contains(jobId)) {
                        postResult(result, cancelledResult())
                    } else {
                        postDownloadFailure(result, null, error)
                    }
                    return
                } catch (error: Exception) {
                    if (cancelledJobs.contains(jobId)) {
                        postResult(result, cancelledResult())
                    } else {
                        postDownloadFailure(result, null, error)
                    }
                    return
                }

            if (cancelledJobs.contains(jobId)) {
                postResult(result, cancelledResult())
                return
            }

            val finalPath = callbackPath ?: extractPath(response.out)
            if (finalPath.isNullOrBlank()) {
                postDownloadFailure(
                    result,
                    null,
                    "The Android engine finished without reporting the output file.",
                    1,
                )
                return
            }

            val totalBytes =
                try {
                    File(finalPath).takeIf { it.exists() }?.length() ?: 0L
                } catch (_: Exception) {
                    0L
                }
            postResult(
                result,
                mapOf(
                    "status" to "completed",
                    "filePath" to finalPath,
                    "totalBytes" to totalBytes,
                ),
            )
        } finally {
            activeJobs.remove(jobId)
            cancelledJobs.remove(jobId)
        }
    }

    private fun handleCancel(call: MethodCall, result: MethodChannel.Result) {
        val jobId = call.argument<String>("jobId")?.trim()
        if (jobId.isNullOrEmpty()) {
            result.error("invalid_arguments", "A job id is required.", null)
            return
        }

        cancelledJobs.add(jobId)
        val destroyed =
            try {
                YoutubeDL.getInstance().destroyProcessById(jobId)
            } catch (_: Exception) {
                false
            }
        if (!destroyed && !activeJobs.contains(jobId)) {
            cancelledJobs.remove(jobId)
        }
        result.success(destroyed)
    }

    private fun ensureYoutubeDl() {
        if (youtubeDlInitialized) return
        synchronized(initLock) {
            if (youtubeDlInitialized) return
            YoutubeDL.getInstance().init(appContext)
            youtubeDlInitialized = true
        }
    }

    private fun ensureFfmpeg() {
        ensureYoutubeDl()
        if (ffmpegInitialized) return
        synchronized(initLock) {
            if (ffmpegInitialized) return
            FFmpeg.getInstance().init(appContext)
            ffmpegInitialized = true
        }
    }

    private fun postLine(jobId: String, line: String) {
        if (disposed) return
        mainHandler.post {
            if (!disposed) {
                channel.invokeMethod(
                    "line",
                    mapOf("jobId" to jobId, "line" to line),
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {}

                        override fun error(
                            errorCode: String,
                            errorMessage: String?,
                            errorDetails: Any?,
                        ) {}

                        override fun notImplemented() {}
                    },
                )
            }
        }
    }

    private fun postResult(result: MethodChannel.Result, value: Any?) {
        mainHandler.post {
            if (!disposed) result.success(value)
        }
    }

    private fun postError(
        result: MethodChannel.Result,
        code: String,
        error: Throwable,
    ) {
        postError(result, code, errorMessage(error))
    }

    private fun postError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        mainHandler.post {
            if (!disposed) result.error(code, message, null)
        }
    }

    private fun postDownloadFailure(
        result: MethodChannel.Result,
        code: String?,
        error: Throwable,
        exitCode: Int = 1,
    ) {
        postDownloadFailure(result, code, errorMessage(error), exitCode)
    }

    private fun postDownloadFailure(
        result: MethodChannel.Result,
        code: String?,
        details: String,
        exitCode: Int = 1,
    ) {
        val value =
            mutableMapOf<String, Any?>(
                "status" to "failed",
                "details" to truncate(details),
                "exitCode" to exitCode,
            )
        if (!code.isNullOrEmpty()) value["code"] = code
        postResult(result, value)
    }

    private fun cancelledResult(): Map<String, Any> =
        mapOf("status" to "cancelled")

    private fun extractPath(text: String): String? {
        var found: String? = null
        for (line in text.lineSequence()) {
            val index = line.indexOf("$FILE_MARKER ")
            if (index < 0) continue
            val value =
                line
                    .substring(index + FILE_MARKER.length + 1)
                    .trim()
                    .trim('"')
            if (value.isNotEmpty()) found = value
        }
        return found
    }

    private fun stringList(value: List<*>?): List<String> {
        if (value == null) return emptyList()
        return value.mapNotNull { it as? String }
    }

    private fun errorMessage(error: Throwable): String {
        val message = error.message?.trim().orEmpty()
        val text = if (message.isEmpty()) error.toString() else message
        return truncate(text)
    }

    private fun truncate(value: String): String {
        if (value.length <= MAX_ERROR_DETAILS) return value
        return value.substring(0, MAX_ERROR_DETAILS) + "..."
    }

    private companion object {
        const val CHANNEL_NAME = "com.mediaflow.app/engine"
        const val PROGRESS_MARKER = "MF_PROGRESS"
        const val FILE_MARKER = "MF_FILE"
        const val MAX_ERROR_DETAILS = 16 * 1024
    }
}
