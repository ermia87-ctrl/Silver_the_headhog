package org.sonic1persian

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Base64
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import java.io.ByteArrayOutputStream
import java.util.zip.ZipInputStream

class MainActivity : Activity() {
    private lateinit var web: WebView
    private val pickRomRequest = 41

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility = 5894 or 1024 or 512
        web = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = true
            settings.mediaPlaybackRequiresUserGesture = false
            webChromeClient = WebChromeClient()
            webViewClient = WebViewClient()
            addJavascriptInterface(AndroidBridge(), "AndroidBridge")
        }
        setContentView(web)
        web.loadUrl("file:///android_asset/index.html")
    }

    private inner class AndroidBridge {
        @JavascriptInterface fun openRomPicker() {
            runOnUiThread {
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                }
                startActivityForResult(intent, pickRomRequest)
            }
        }
    }

    @Deprecated("Legacy document picker callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == pickRomRequest && resultCode == RESULT_OK) {
            data?.data?.let { loadSelectedRom(it) }
        }
    }

    private fun loadSelectedRom(uri: Uri) {
        try {
            val raw = (contentResolver.openInputStream(uri) ?: error("فایل باز نشد")).use { it.readBytes() }
            val rom: ByteArray
            if (raw.size >= 4 && raw[0] == 'P'.code.toByte() && raw[1] == 'K'.code.toByte()) {
                var found: ByteArray? = null
                ZipInputStream(raw.inputStream()).use { zip ->
                    while (true) {
                        val entry = zip.nextEntry ?: break
                        if (!entry.isDirectory && entry.name.substringAfterLast('/').substringAfterLast('.').lowercase() in listOf("md", "bin", "gen")) {
                            val out = ByteArrayOutputStream()
                            zip.copyTo(out)
                            found = out.toByteArray()
                            break
                        }
                    }
                }
                rom = found ?: error("داخل ZIP فایل MD یا BIN پیدا نشد")
            } else rom = raw
            require(rom.isNotEmpty() && rom.size <= 32 * 1024 * 1024) { "حجم فایل بازی معتبر نیست" }
            val encoded = Base64.encodeToString(rom, Base64.NO_WRAP)
            web.evaluateJavascript("window.loadSonicRom('Sonic 1','$encoded')", null)
            Toast.makeText(this, "فایل بازی بارگذاری شد", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            Toast.makeText(this, e.message ?: "خطا در خواندن فایل", Toast.LENGTH_LONG).show()
        }
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (::web.isInitialized && web.canGoBack()) web.goBack() else super.onBackPressed()
    }
}
