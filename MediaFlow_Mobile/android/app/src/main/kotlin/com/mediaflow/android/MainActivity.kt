package com.mediaflow.android

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.widget.*
import androidx.core.content.FileProvider
import java.io.File
import java.util.concurrent.Executors
import java.util.Locale

class MainActivity : Activity() {
    private val worker = Executors.newSingleThreadExecutor()
    private lateinit var urlInput: EditText
    private lateinit var mode: Spinner
    private lateinit var quality: Spinner
    private lateinit var playlist: CheckBox
    private lateinit var info: TextView
    private lateinit var analyse: Button
    private lateinit var activeJobs: LinearLayout
    private lateinit var history: LinearLayout
    private lateinit var cookieStatus: TextView
    private lateinit var pages: FrameLayout
    private lateinit var tabs: List<Button>
    private var selectedTab = 0
    private val observer: () -> Unit = { renderJobs() }
    private val light get() = DownloadStore.prefs.getBoolean("light", false)
    private val bg get() = Color.parseColor(if (light) "#F3F5FA" else "#10131A")
    private val surface get() = Color.parseColor(if (light) "#FFFFFF" else "#1A1F2B")
    private val text get() = Color.parseColor(if (light) "#162034" else "#F0F3FF")
    private val muted get() = Color.parseColor(if (light) "#596579" else "#A7B1C6")
    private val accent get() = Color.parseColor(if (light) "#435BCE" else "#A3B0FF")

    override fun attachBaseContext(base: Context) {
        val language = base.getSharedPreferences("mediaflow_native", Context.MODE_PRIVATE)
            .getString("language", Locale.getDefault().language) ?: "en"
        val configuration = android.content.res.Configuration(base.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(language))
        super.attachBaseContext(base.createConfigurationContext(configuration))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (light) setTheme(R.style.AppTheme_Light)
        super.onCreate(savedInstanceState)
        window.statusBarColor = bg
        window.navigationBarColor = bg
        window.decorView.systemUiVisibility = if (light) View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR else 0
        val shell = column().apply { setBackgroundColor(bg); setPadding(dp(20), dp(12), dp(20), dp(8)) }
        shell.setOnApplyWindowInsetsListener { view, insets ->
            val top = if (Build.VERSION.SDK_INT >= 30) insets.getInsets(WindowInsets.Type.systemBars()).top else insets.systemWindowInsetTop
            val bottom = if (Build.VERSION.SDK_INT >= 30) insets.getInsets(WindowInsets.Type.systemBars()).bottom else insets.systemWindowInsetBottom
            view.setPadding(dp(20), dp(12) + top, dp(20), dp(8) + bottom)
            insets
        }
        shell.addView(label("MediaFlow", 29, text, true))
        shell.addView(label("Save what matters.", 14, muted).apply { setPadding(0, dp(4), 0, dp(16)) })
        pages = FrameLayout(this)
        shell.addView(pages, LinearLayout.LayoutParams(-1, 0, 1f))
        val nav = LinearLayout(this)
        tabs = listOf("Downloads", "History", "Settings").mapIndexed { index, title ->
            button(title, false) { showTab(index) }.also { nav.addView(it, LinearLayout.LayoutParams(0, dp(50), 1f)) }
        }
        shell.addView(nav)
        setContentView(shell)
        pages.addView(downloadPage())
        pages.addView(historyPage())
        pages.addView(settingsPage())
        urlInput.setText(savedInstanceState?.getString("draft") ?: DownloadStore.prefs.getString("draft", ""))
        mode.setSelection(savedInstanceState?.getInt("mode", 0) ?: 0)
        quality.setSelection(savedInstanceState?.getInt("quality", 0) ?: 0)
        playlist.isChecked = savedInstanceState?.getBoolean("playlist") ?: false
        showTab(savedInstanceState?.getInt("tab", 0) ?: 0)
        receiveShare(intent)
        if (Build.VERSION.SDK_INT >= 33 && !DownloadStore.prefs.getBoolean("notificationsAsked", false)) {
            DownloadStore.prefs.edit().putBoolean("notificationsAsked", true).apply()
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 20)
        }
    }

    private fun downloadPage(): ScrollView {
        val body = column()
        val inputCard = card()
        inputCard.addView(label("New download", 20, text, true))
        inputCard.addView(label("Paste a link, or add several links on separate lines.", 13, muted))
        urlInput = EditText(this).apply {
            hint = "https://..."
            setTextColor(this@MainActivity.text); setHintTextColor(muted)
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_VARIATION_URI
            textDirection = View.TEXT_DIRECTION_LTR
            minLines = 2; maxLines = 5; textSize = 16f
            backgroundTintList = ColorStateList.valueOf(accent)
        }
        inputCard.addView(urlInput, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(14) })
        inputCard.addView(button("Paste from clipboard", false) {
            val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            urlInput.setText(clipboard.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString().orEmpty())
        })
        inputCard.addView(label("Save as", 13, muted))
        mode = spinner(listOf("Video (MP4)", "Video (MKV)", "Audio (MP3)", "Audio (M4A)", "Original file"))
        inputCard.addView(mode)
        inputCard.addView(label("Maximum video quality", 13, muted))
        quality = spinner(listOf("Best", "2160p", "1440p", "1080p", "720p", "480p", "360p"))
        inputCard.addView(quality)
        playlist = CheckBox(this).apply { setText(tr("Download the whole playlist")); setTextColor(this@MainActivity.text); buttonTintList = ColorStateList.valueOf(accent) }
        inputCard.addView(playlist)
        info = label("YouTube / Facebook / Instagram / direct files\nOther media sources depend on the download engine.", 13, muted)
        inputCard.addView(info)
        analyse = button("Preview link", false) { preview() }
        inputCard.addView(analyse)
        inputCard.addView(button("Add to downloads", true) { enqueue() })
        body.addView(inputCard)
        body.addView(label("Download queue", 19, text, true).apply { setPadding(0, dp(24), 0, dp(10)) })
        activeJobs = column()
        body.addView(activeJobs)
        return scroll(body)
    }

    private fun historyPage(): ScrollView {
        val body = column()
        body.addView(label("Your downloads", 23, text, true))
        body.addView(label("Open, share, export, or retry saved downloads.", 14, muted))
        body.addView(button("Clear finished history", false) {
            AlertDialog.Builder(this).setTitle(tr("Clear download history?"))
                .setMessage(tr("Downloaded files will stay on your device."))
                .setPositiveButton(tr("Clear")) { _, _ -> DownloadStore.clearFinished() }.setNegativeButton(tr("Keep"), null).show()
        })
        history = column()
        body.addView(history)
        return scroll(body)
    }

    private fun settingsPage(): ScrollView {
        val body = column()
        val appearance = card()
        appearance.addView(label("Appearance", 20, text, true))
        appearance.addView(Switch(this).apply {
            setText(tr("Light mode")); setTextColor(this@MainActivity.text); isChecked = light
            setOnCheckedChangeListener { _, value -> DownloadStore.prefs.edit().putBoolean("light", value).apply(); recreate() }
        })
        appearance.addView(button("Language", false) {
            AlertDialog.Builder(this).setTitle(tr("Language")).setItems(arrayOf("English", "العربية")) { _, choice ->
                DownloadStore.prefs.edit().putString("language", if (choice == 1) "ar" else "en").apply()
                recreate()
            }.show()
        })
        body.addView(appearance)
        val auth = card()
        auth.addView(label("Account access", 20, text, true))
        auth.addView(label("For links you can access with your account, import a Netscape cookies.txt file. It stays in private app storage and is excluded from backups.", 14, muted))
        cookieStatus = label(if (DownloadStore.cookieFile.isFile) "Cookies imported" else "No cookies imported", 13, accent)
        auth.addView(cookieStatus)
        auth.addView(button("Import cookies.txt", false) {
            startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).setType("*/*").addCategory(Intent.CATEGORY_OPENABLE), 10)
        })
        auth.addView(button("Remove login cookies", false) {
            if (DownloadStore.cookieFile.exists() && !DownloadStore.cookieFile.delete()) toast("Could not remove cookies")
            else cookieStatus.text = "No cookies imported"
        })
        body.addView(auth, spaced())
        val engine = card()
        engine.addView(label("Download engine", 20, text, true))
        engine.addView(label("FFmpeg and JavaScript support are included. Update yt-dlp when a supported site changes its player.", 14, muted))
        val update = button("Update download engine", false) {}
        update.setOnClickListener {
            if (DownloadStore.snapshot().any { it.state in listOf("downloading", "queued", "processing", "cancelling") }) {
                toast("Wait for the current downloads to finish")
            } else {
                update.isEnabled = false; update.text = tr("Updating...")
                worker.execute {
                    try {
                        val version = DownloadEngine(applicationContext).update()
                        runOnUiThread { if (!isDestroyed) toast("Engine updated: $version") }
                    } catch (e: Exception) { runOnUiThread { if (!isDestroyed) showError(e) } }
                    finally { runOnUiThread { update.isEnabled = true; update.text = tr("Update download engine") } }
                }
            }
        }
        engine.addView(update)
        body.addView(engine, spaced())
        val storage = card()
        storage.addView(label("Saved files", 20, text, true))
        storage.addView(label("Downloads stay in this app's storage. Use Open or Share in History, or Export to save a copy to a folder you choose. Uninstalling removes app storage.", 14, muted))
        storage.addView(label(DownloadStore.downloadDir.absolutePath, 12, muted).apply { setTextIsSelectable(true) })
        body.addView(storage, spaced())
        return scroll(body)
    }

    private fun urls(): List<String> {
        val values = urlInput.text.toString().trim().split(Regex("\\s+")).filter { it.isNotBlank() }
        require(values.isNotEmpty()) { "Paste a link first." }
        require(values.size <= 100) { "Add at most 100 links at a time." }
        return values.map { DownloadErrors.validateUrl(it) }.distinct()
    }

    private fun enqueue() {
        try {
            val links = urls()
            DownloadStore.enqueue(links, mode.selectedItem.toString(), quality.selectedItem.toString(), playlist.isChecked)
            startDownloads()
            toast("${links.size} link(s) added")
        } catch (e: Exception) { showError(e) }
    }

    private fun startDownloads() {
        val intent = Intent(this, DownloadService::class.java)
        if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
    }

    private fun preview() {
        try {
            val links = urls()
            require(links.size == 1) { "Preview one link at a time. You can queue multiple links together." }
            val url = links.first()
            val selectedMode = mode.selectedItem.toString()
            val wholePlaylist = playlist.isChecked
            analyse.isEnabled = false; info.text = tr("Checking the link...")
            worker.execute {
                try {
                    val result = DownloadEngine(applicationContext).analyse(url, selectedMode, wholePlaylist)
                    runOnUiThread {
                        if (!isDestroyed) {
                            info.text = listOf(result.optString("title", "Untitled"), result.optString("extractor"),
                                if (result.optBoolean("is_live")) "LIVE ? records while the stream is available" else "",
                                result.optJSONArray("entries")?.let { "${it.length()} items" }.orEmpty()).filter { it.isNotBlank() }.joinToString("\n")
                        }
                    }
                } catch (e: Exception) { runOnUiThread { if (!isDestroyed) { info.text = tr("Preview failed"); showError(e) } } }
                finally { runOnUiThread { analyse.isEnabled = true } }
            }
        } catch (e: Exception) { showError(e) }
    }

    private fun renderJobs() {
        if (!::activeJobs.isInitialized) return
        activeJobs.removeAllViews(); history.removeAllViews()
        val jobs = DownloadStore.snapshot()
        val active = jobs.filter { it.state in listOf("queued", "downloading", "processing", "cancelling") }
        if (active.isEmpty()) activeJobs.addView(label("Ready when you are. Add your first link above.", 14, muted))
        active.forEach { activeJobs.addView(jobCard(it), spaced()) }
        val finished = jobs.filter { it !in active }.asReversed()
        if (finished.isEmpty()) history.addView(label("Completed and interrupted downloads will appear here.", 14, muted))
        finished.forEach { history.addView(jobCard(it), spaced()) }
    }

    private fun jobCard(job: DownloadJob): LinearLayout {
        val card = card()
        card.addView(label(job.title, 16, text, true, false).apply { maxLines = 2; ellipsize = android.text.TextUtils.TruncateAt.END })
        card.addView(label("${tr(job.mode)} / ${tr(job.quality)} / ${tr(job.state)}", 12, accent))
        card.addView(label(job.message, 13, muted).apply { maxLines = 5 })
        if (job.state in listOf("downloading", "processing", "cancelling")) {
            card.addView(ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
                max = 100; isIndeterminate = job.progress < 0; progress = job.progress.coerceAtLeast(0)
                progressTintList = ColorStateList.valueOf(accent)
            }, LinearLayout.LayoutParams(-1, dp(10)))
            card.addView(button("Cancel", false) {
                startService(Intent(this, DownloadService::class.java).setAction("cancel").putExtra("id", job.id))
            })
        } else if (job.state == "queued") {
            card.addView(button("Remove from queue", false) { DownloadStore.update(job.id, true) { it.state = "cancelled"; it.message = "Removed from queue" } })
        } else if (job.state != "completed") {
            card.addView(button("Retry", true) {
                DownloadStore.update(job.id, true) { it.state = "queued"; it.message = "Waiting in queue"; it.progress = -1 }
                try { startDownloads() } catch (e: Exception) { showError(e) }
            })
        }
        if (job.files.isNotEmpty()) {
            card.addView(button("Open", false) { chooseFile(job.files) { file -> openFile(file, false) } })
            card.addView(button("Share", false) { chooseFile(job.files) { file -> openFile(file, true) } })
            card.addView(button("Export to folder...", false) { chooseFile(job.files) { file -> exportFile(file) } })
        }
        if (job.details.isNotBlank()) card.addView(button("Error details", false) {
            AlertDialog.Builder(this).setTitle(job.errorCode).setMessage(job.details)
                .setPositiveButton(tr("Close"), null).setNeutralButton(tr("Copy")) { _, _ ->
                    (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText("MediaFlow error", job.details))
                }.show()
        })
        return card
    }

    private fun chooseFile(files: List<String>, action: (File) -> Unit) {
        val present = files.map { File(it) }.filter { it.isFile }
        if (present.isEmpty()) { toast("These files have been moved or deleted"); return }
        if (present.size == 1) action(present.first())
        else AlertDialog.Builder(this).setTitle(tr("Choose a file")).setItems(present.map { it.name }.toTypedArray()) { _, index -> action(present[index]) }.show()
    }

    private fun mime(file: File) = android.webkit.MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension.lowercase()) ?: "application/octet-stream"
    private fun openFile(file: File, share: Boolean) {
        try {
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = if (share) Intent(Intent.ACTION_SEND).setType(mime(file)).putExtra(Intent.EXTRA_STREAM, uri)
                else Intent(Intent.ACTION_VIEW).setDataAndType(uri, mime(file))
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            intent.clipData = ClipData.newRawUri("MediaFlow download", uri)
            startActivity(if (share) Intent.createChooser(intent, "Share download") else intent)
        } catch (e: Exception) { showError(e) }
    }

    private var pendingExport: String? = null
    private fun exportFile(file: File) {
        pendingExport = file.absolutePath
        DownloadStore.prefs.edit().putString("pendingExport", pendingExport).apply()
        startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
            .setType(mime(file)).putExtra(Intent.EXTRA_TITLE, file.name), 11)
    }

    @Deprecated("Platform activity result API supports API 24 without an additional UI dependency")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode != RESULT_OK) return
        val uri = data?.data ?: return
        worker.execute {
            try {
                when (requestCode) {
                    10 -> {
                        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytesLimited(2 * 1024 * 1024) }
                            ?: error("Cannot read the selected file")
                        require(String(bytes, Charsets.UTF_8).contains("HTTP Cookie File")) { "Choose a Netscape-format cookies.txt export." }
                        DownloadStore.cookieFile.writeBytes(bytes)
                        runOnUiThread { if (!isDestroyed) cookieStatus.text = "Cookies imported" }
                    }
                    11 -> {
                        val path = pendingExport ?: DownloadStore.prefs.getString("pendingExport", null) ?: error("Select a file again")
                        val file = File(path)
                        contentResolver.openOutputStream(uri, "w")?.use { output -> file.inputStream().use { it.copyTo(output) } }
                            ?: error("Cannot save to the selected location")
                        DownloadStore.prefs.edit().remove("pendingExport").apply()
                        runOnUiThread { if (!isDestroyed) toast("File exported") }
                    }
                }
            } catch (e: Exception) { runOnUiThread { if (!isDestroyed) showError(e) } }
        }
    }

    private fun java.io.InputStream.readBytesLimited(limit: Int): ByteArray {
        val output = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(8192)
        while (true) {
            val count = read(buffer)
            if (count < 0) return output.toByteArray()
            require(output.size() + count <= limit) { "Cookie file is too large (maximum 2 MB)." }
            output.write(buffer, 0, count)
        }
    }

    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); setIntent(intent); receiveShare(intent) }
    private fun receiveShare(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND) {
            val shared = intent.getStringExtra(Intent.EXTRA_TEXT).orEmpty()
            val links = Regex("https?://[^\\s]+").findAll(shared).map { it.value }.joinToString("\n")
            if (links.isNotBlank()) { urlInput.setText(links); showTab(0) }
            // Theme/language recreation must restore the current draft, not replay an old share.
            intent.action = Intent.ACTION_MAIN
            intent.removeExtra(Intent.EXTRA_TEXT)
        }
    }
    override fun onResume() { super.onResume(); DownloadStore.observe(observer); renderJobs() }
    override fun onPause() { DownloadStore.removeObserver(observer); DownloadStore.prefs.edit().putString("draft", urlInput.text.toString()).apply(); super.onPause() }
    override fun onSaveInstanceState(out: Bundle) {
        out.putString("draft", urlInput.text.toString()); out.putInt("tab", selectedTab)
        out.putInt("mode", mode.selectedItemPosition); out.putInt("quality", quality.selectedItemPosition); out.putBoolean("playlist", playlist.isChecked)
        super.onSaveInstanceState(out)
    }
    override fun onDestroy() { worker.shutdownNow(); super.onDestroy() }
    private fun showTab(index: Int) {
        selectedTab = index
        for (i in 0 until pages.childCount) pages.getChildAt(i).visibility = if (i == index) View.VISIBLE else View.GONE
        tabs.forEachIndexed { i, tab -> tab.setTextColor(if (i == index) accent else muted) }
    }
    private fun showError(e: Throwable) {
        val failure = DownloadErrors.classify(e)
        AlertDialog.Builder(this).setTitle(tr(failure.title)).setMessage(tr(failure.action))
            .setPositiveButton(tr("Close"), null).setNeutralButton(tr("Details")) { _, _ ->
                AlertDialog.Builder(this).setTitle(failure.code).setMessage(failure.details).setPositiveButton(tr("Close"), null).show()
            }.show()
    }
    private fun tr(value: String) = Texts.get(this, value)
    private fun toast(message: String) = Toast.makeText(this, tr(message), Toast.LENGTH_LONG).show()
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun column() = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    private fun scroll(view: View) = ScrollView(this).apply { isFillViewport = true; addView(view) }
    private fun spaced() = LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(12); bottomMargin = dp(6) }
    private fun label(value: String, size: Int, color: Int, bold: Boolean = false, translate: Boolean = true) = TextView(this).apply {
        setText(if (translate) tr(value) else value); textSize = size.toFloat(); setTextColor(color); setPadding(0, dp(4), 0, dp(4))
        if (bold) setTypeface(typeface, Typeface.BOLD)
    }
    private fun card() = column().apply {
        setPadding(dp(18), dp(16), dp(18), dp(16))
        background = GradientDrawable().apply { setColor(surface); cornerRadius = dp(18).toFloat() }
    }
    private fun button(title: String, primary: Boolean, action: () -> Unit) = Button(this).apply {
        setText(tr(title)); isAllCaps = false; minHeight = dp(48); textSize = 14f
        setTextColor(if (primary) Color.WHITE else accent)
        backgroundTintList = ColorStateList.valueOf(if (primary) Color.parseColor("#4D62D8") else Color.TRANSPARENT)
        setOnClickListener { action() }
    }
    private fun spinner(items: List<String>) = Spinner(this).apply {
        val adapter = object : ArrayAdapter<String>(this@MainActivity, android.R.layout.simple_spinner_dropdown_item, items) {
            override fun getView(position: Int, convertView: View?, parent: android.view.ViewGroup): View =
                super.getView(position, convertView, parent).also { (it as TextView).setTextColor(this@MainActivity.text); it.text = tr(items[position]) }
            override fun getDropDownView(position: Int, convertView: View?, parent: android.view.ViewGroup): View =
                super.getDropDownView(position, convertView, parent).also { it.setBackgroundColor(surface); (it as TextView).setTextColor(this@MainActivity.text); it.text = tr(items[position]) }
        }
        this.adapter = adapter
        layoutParams = LinearLayout.LayoutParams(-1, dp(52))
    }
}
