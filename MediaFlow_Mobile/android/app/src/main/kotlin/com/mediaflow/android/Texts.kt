package com.mediaflow.android

import android.content.Context

/** Native resources retain Arabic and RTL support during the Flutter migration. */
object Texts {
    private val keys = mapOf(
        "Save what matters." to R.string.tagline,
        "Downloads" to R.string.downloads, "History" to R.string.history, "Settings" to R.string.settings,
        "New download" to R.string.new_download,
        "Paste a link, or add several links on separate lines." to R.string.paste_links,
        "Paste from clipboard" to R.string.clipboard,
        "Save as" to R.string.save_as, "Maximum video quality" to R.string.max_quality,
        "Download the whole playlist" to R.string.whole_playlist,
        "Preview link" to R.string.preview, "Add to downloads" to R.string.enqueue,
        "Download queue" to R.string.queue,
        "Ready when you are. Add your first link above." to R.string.empty_queue,
        "Your downloads" to R.string.your_downloads,
        "Open, share, export, or retry saved downloads." to R.string.history_help,
        "Clear finished history" to R.string.clear_finished,
        "Clear download history?" to R.string.clear_question,
        "Downloaded files will stay on your device." to R.string.keep_files,
        "Completed and interrupted downloads will appear here." to R.string.empty_history,
        "Appearance" to R.string.appearance, "Light mode" to R.string.light_mode,
        "Language" to R.string.language, "Account access" to R.string.account,
        "Cookies imported" to R.string.cookies_ready, "No cookies imported" to R.string.no_cookies,
        "Import cookies.txt" to R.string.import_cookies, "Remove login cookies" to R.string.remove_cookies,
        "Download engine" to R.string.engine, "Update download engine" to R.string.update_engine,
        "Saved files" to R.string.saved_files,
        "Video (MP4)" to R.string.video_mp4, "Video (MKV)" to R.string.video_mkv,
        "Audio (MP3)" to R.string.audio_mp3, "Audio (M4A)" to R.string.audio_m4a,
        "Original file" to R.string.original_file, "Best" to R.string.best,
        "Cancel" to R.string.cancel, "Clear" to R.string.clear, "Keep" to R.string.keep,
        "Retry" to R.string.retry, "Open" to R.string.open, "Share" to R.string.share,
        "Export to folder..." to R.string.export_file, "Remove from queue" to R.string.remove_queue,
        "Error details" to R.string.error_details, "Close" to R.string.close,
        "Copy" to R.string.copy, "Details" to R.string.details,
        "Choose a file" to R.string.choose_file, "Share download" to R.string.share_download,
        "queued" to R.string.queued, "downloading" to R.string.downloading,
        "completed" to R.string.completed, "failed" to R.string.failed,
        "cancelled" to R.string.cancelled, "interrupted" to R.string.interrupted,
        "processing" to R.string.processing, "cancelling" to R.string.cancelling,
        "Checking the link..." to R.string.checking, "Updating..." to R.string.updating,
        "Preview failed" to R.string.preview_failed,
        "Check the link or settings" to R.string.invalid_input,
        "Storage is full" to R.string.disk_full, "Connection interrupted" to R.string.network_error,
        "This link needs your account" to R.string.login_required,
        "The source denied access" to R.string.access_denied,
        "The link is unavailable" to R.string.unavailable,
        "The download failed" to R.string.failed_title
    )

    fun get(context: Context, value: String): String = keys[value]?.let { context.getString(it) } ?: value
}
