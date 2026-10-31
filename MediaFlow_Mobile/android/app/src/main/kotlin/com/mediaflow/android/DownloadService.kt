package com.mediaflow.android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import java.util.concurrent.CancellationException
import java.util.concurrent.Executors

class DownloadService : Service() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    @Volatile private var engine: DownloadEngine? = null
    @Volatile private var activeId: String? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= 26) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel("downloads", "Downloads", NotificationManager.IMPORTANCE_LOW)
            )
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "cancel") {
            val id = intent.getStringExtra("id") ?: activeId
            if (id == activeId) {
                DownloadStore.update(id ?: "", true) { it.state = "cancelling"; it.message = "Stopping…" }
                engine?.cancel()
            } else if (id != null) {
                DownloadStore.update(id, true) { it.state = "cancelled"; it.message = "Removed from queue" }
            }
            return START_NOT_STICKY
        }
        startForeground(1, notification("Preparing downloads", -1))
        worker.execute {
            try {
                drain()
            } catch (e: Exception) {
                activeId?.let { id ->
                    val failure = DownloadErrors.classify(e)
                    runCatching { DownloadStore.update(id, true) {
                        it.state = "failed"; it.message = failure.title + "\n" + failure.action
                        it.errorCode = failure.code; it.details = failure.details
                    } }
                }
            } finally {
                main.post {
                    if (DownloadStore.snapshot().none { it.state in listOf("queued", "downloading", "processing", "cancelling") }) {
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        stopSelf()
                    }
                }
            }
        }
        return START_NOT_STICKY
    }

    private fun drain() {
        val lock = (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, "MediaFlow:download"
        )
        wakeLock = lock
        lock.acquire(6 * 60 * 60 * 1000L)
        try {
            while (!Thread.currentThread().isInterrupted) {
                val job = DownloadStore.next() ?: break
                activeId = job.id
                try {
                    val current = DownloadEngine(applicationContext)
                    engine = current
                    if (DownloadStore.snapshot().firstOrNull { it.id == job.id }?.state == "cancelling") current.cancel()
                    val paths = current.download(job) { percent, message ->
                        DownloadStore.update(job.id) { it.progress = percent; it.message = message }
                        main.post {
                            if (activeId == job.id) getSystemService(NotificationManager::class.java)
                                .notify(1, notification(message.take(150), percent))
                        }
                    }
                    DownloadStore.update(job.id, true) {
                        it.state = "completed"; it.progress = 100; it.files = paths
                        it.title = paths.firstOrNull()?.let { path -> java.io.File(path).name } ?: "Empty Drive folder"
                        it.message = "${paths.size} file(s) saved"; it.errorCode = ""; it.details = ""
                    }
                } catch (e: Exception) {
                    val stopping = e is CancellationException || e is com.yausername.youtubedl_android.YoutubeDL.CanceledException ||
                        DownloadStore.snapshot().firstOrNull { it.id == job.id }?.state == "cancelling"
                    val failure = DownloadErrors.classify(e)
                    DownloadStore.update(job.id, true) {
                        it.state = if (stopping) "cancelled" else "failed"
                        it.message = if (stopping) "Stopped. Media partial files can be resumed by Retry." else failure.title + "\n" + failure.action
                        it.errorCode = if (stopping) "CANCELLED" else failure.code
                        it.details = if (stopping) "" else failure.details
                    }
                } finally { activeId = null; engine = null }
            }
        } finally {
            if (lock.isHeld) lock.release()
            wakeLock = null
        }
    }

    private fun notification(message: String, percent: Int): Notification {
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val cancel = PendingIntent.getService(this, 1, Intent(this, DownloadService::class.java).setAction("cancel"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, "downloads") else Notification.Builder(this)
        return builder.setSmallIcon(android.R.drawable.stat_sys_download).setContentTitle("MediaFlow")
            .setContentText(message).setContentIntent(open).setOngoing(true).setOnlyAlertOnce(true)
            .setProgress(100, percent.coerceIn(0, 100), percent < 0)
            .addAction(Notification.Action.Builder(null, "Cancel", cancel).build()).build()
    }

    override fun onTimeout(startId: Int, fgsType: Int) {
        DownloadStore.snapshot().filter { it.state == "queued" }.forEach { job ->
            DownloadStore.update(job.id, true) { it.state = "interrupted"; it.message = "Android background time limit reached. Retry to continue." }
        }
        activeId?.let { DownloadStore.update(it, true) { job -> job.state = "cancelling" } }
        engine?.cancel()
        stopSelf()
    }

    override fun onDestroy() {
        engine?.cancel()
        worker.shutdownNow()
        super.onDestroy()
    }
}
