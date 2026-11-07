package org.sonic1persian

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER; setPadding(32,32,32,32) }
        root.addView(TextView(this).apply { text = "سونیک ۱ فارسی"; textSize = 30f; gravity = Gravity.CENTER })
        root.addView(TextView(this).apply { text = "نسخه‌ی آزمایشی؛ موتور بازی هنوز اضافه نشده است."; textSize = 18f; gravity = Gravity.CENTER; setPadding(0,24,0,0) })
        setContentView(root)
    }
}
