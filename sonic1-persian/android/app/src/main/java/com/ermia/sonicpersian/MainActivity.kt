package com.ermia.sonicpersian

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import com.swordfish.libretrodroid.GLRetroView
import com.swordfish.libretrodroid.GLRetroViewData
import com.swordfish.libretrodroid.ShaderConfig
import java.io.File

class MainActivity : ComponentActivity() {
    private var retroView: GLRetroView? = null
    private val pickRom = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) startGame(uri)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)
        showPickerScreen()
    }

    private fun showPickerScreen() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(28, 28, 28, 28)
            setBackgroundColor(0xFF071A35.toInt())
        }
        root.addView(TextView(this).apply {
            text = "سونیک فارسی"
            textSize = 30f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
        })
        root.addView(TextView(this).apply {
            text = "فایل ROM قانونی خودت را انتخاب کن"
            textSize = 18f
            setTextColor(0xFFE2E8F0.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 18, 0, 24)
        })
        root.addView(Button(this).apply {
            text = "انتخاب فایل بازی"
            setOnClickListener { pickRom.launch(arrayOf("*/*")) }
        })
        setContentView(root)
    }

    private fun startGame(uri: Uri) {
        try {
            val rom = File(cacheDir, "selected-game.rom")
            contentResolver.openInputStream(uri)?.use { input ->
                rom.outputStream().use { output -> input.copyTo(output) }
            } ?: throw IllegalStateException("فایل انتخاب‌شده خوانده نشد")

            val core = File(filesDir, "picodrive_libretro_android.so")
            assets.open("picodrive_libretro_android.so").use { input ->
                core.outputStream().use { output -> input.copyTo(output) }
            }

            val data = GLRetroViewData(this).apply {
                coreFilePath = core.absolutePath
                gameFilePath = rom.absolutePath
                systemDirectory = File(filesDir, "system").apply { mkdirs() }.absolutePath
                savesDirectory = File(filesDir, "saves").apply { mkdirs() }.absolutePath
                shader = ShaderConfig.Default
            }
            val frame = FrameLayout(this)
            val game = GLRetroView(this, data)
            retroView = game
            frame.addView(game, FrameLayout.LayoutParams(-1, -1))
            frame.addView(makeControls(), FrameLayout.LayoutParams(-1, -1))
            setContentView(frame)
            lifecycle.addObserver(game)
        } catch (e: Exception) {
            showError("اجرای بازی ناموفق بود: ${e.message ?: "خطای ناشناخته"}")
        }
    }

    private fun makeControls(): View {
        val overlay = FrameLayout(this)
        val pad = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            alpha = 0.78f
        }
        val row1 = LinearLayout(this).apply { gravity = Gravity.CENTER }
        val row2 = LinearLayout(this).apply { gravity = Gravity.CENTER }
        row1.addView(control("▲", KeyEvent.KEYCODE_DPAD_UP))
        row2.addView(control("◀", KeyEvent.KEYCODE_DPAD_LEFT))
        row2.addView(control("▼", KeyEvent.KEYCODE_DPAD_DOWN))
        row2.addView(control("▶", KeyEvent.KEYCODE_DPAD_RIGHT))
        pad.addView(row1)
        pad.addView(row2)
        overlay.addView(pad, FrameLayout.LayoutParams(-2, -2, Gravity.BOTTOM or Gravity.START).apply {
            leftMargin = 24; bottomMargin = 18
        })

        val actions = LinearLayout(this).apply { gravity = Gravity.CENTER; alpha = 0.78f }
        actions.addView(control("B", KeyEvent.KEYCODE_BUTTON_B))
        actions.addView(control("A", KeyEvent.KEYCODE_BUTTON_A))
        overlay.addView(actions, FrameLayout.LayoutParams(-2, -2, Gravity.BOTTOM or Gravity.END).apply {
            rightMargin = 30; bottomMargin = 35
        })
        return overlay
    }

    private fun control(label: String, key: Int): Button = Button(this).apply {
        text = label
        textSize = 18f
        minWidth = 54
        minHeight = 48
        setPadding(8, 2, 8, 2)
        setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> retroView?.sendKeyEvent(KeyEvent.ACTION_DOWN, key)
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> retroView?.sendKeyEvent(KeyEvent.ACTION_UP, key)
            }
            true
        }
    }

    private fun showError(message: String) {
        val text = TextView(this).apply {
            this.text = "$message\n\nدوباره فایل ROM را انتخاب کن."
            textSize = 18f
            gravity = Gravity.CENTER
            setTextColor(0xFFFFFFFF.toInt())
            setPadding(28, 28, 28, 28)
            setBackgroundColor(0xFF071A35.toInt())
            setOnClickListener { showPickerScreen() }
        }
        setContentView(text)
    }

    override fun onDestroy() {
        retroView?.let { lifecycle.removeObserver(it) }
        retroView = null
        super.onDestroy()
    }
}
