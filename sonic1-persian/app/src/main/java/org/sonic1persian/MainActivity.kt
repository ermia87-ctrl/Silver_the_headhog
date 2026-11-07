package org.sonic1persian

import android.app.Activity
import android.os.Bundle
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Color
import android.graphics.RectF
import android.view.MotionEvent
import android.view.View
import kotlin.math.max
import kotlin.math.min

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG immersiveSticky
        setContentView(PrototypeGameView())
    }
}

private class PrototypeGameView : View(null) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var playerX = 150f
    private var playerY = 0f
    private var velocityY = 0f
    private var speed = 0f
    private var score = 0
    private var rings = 0
    private var left = false
    private var right = false
    private var jumping = false
    private var lastTime = 0L
    private var groundY = 0f
    private val ringX = floatArrayOf(520f, 680f, 840f, 1040f, 1210f, 1400f)
    private val ringTaken = BooleanArray(ringX.size)

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        if (w <= 0f || h <= 0f) return
        groundY = h * .78f
        val now = System.nanoTime()
        val dt = if (lastTime == 0L) 0.016f else min(.04f, (now - lastTime) / 1_000_000_000f)
        lastTime = now
        update(dt, w, h)

        canvas.drawColor(Color.rgb(105, 194, 245))
        paint.color = Color.rgb(180, 231, 255)
        canvas.drawCircle(w * .78f, h * .18f, h * .10f, paint)
        paint.color = Color.rgb(65, 177, 115)
        canvas.drawOval(RectF(0f, groundY - 75f, w, groundY + 45f), paint)
        paint.color = Color.rgb(130, 82, 43)
        canvas.drawRect(0f, groundY, w, h, paint)
        paint.color = Color.rgb(55, 170, 80)
        canvas.drawRect(0f, groundY, w, groundY + 12f, paint)

        val worldOffset = max(0f, playerX - w * .30f)
        for (i in ringX.indices) {
            if (!ringTaken[i]) {
                val x = ringX[i] - worldOffset + w * .30f
                if (x > -30f && x < w + 30f) {
                    paint.style = Paint.Style.STROKE
                    paint.strokeWidth = 6f
                    paint.color = Color.rgb(255, 211, 35)
                    canvas.drawCircle(x, groundY - 92f, 17f, paint)
                    paint.style = Paint.Style.FILL
                }
            }
        }

        val px = w * .30f
        val py = groundY - 32f - playerY
        paint.color = Color.rgb(25, 91, 215)
        canvas.drawOval(RectF(px - 25f, py - 32f, px + 25f, py + 32f), paint)
        paint.color = Color.WHITE
        canvas.drawCircle(px + 10f, py - 12f, 7f, paint)
        paint.color = Color.rgb(20, 35, 65)
        canvas.drawCircle(px + 13f, py - 12f, 3f, paint)
        paint.color = Color.rgb(245, 245, 245)
        canvas.drawOval(RectF(px - 19f, py + 20f, px + 25f, py + 32f), paint)

        paint.color = Color.WHITE
        paint.textSize = 25f
        canvas.drawText("امتیاز: $score     حلقه‌ها: $rings", 24f, 38f, paint)
        paint.textSize = 17f
        canvas.drawText("نسخه آزمایشی فارسی — شخصیت و مراحل اصلی هنوز اضافه نشده‌اند", 24f, 66f, paint)

        drawButton(canvas, RectF(24f, h - 88f, 112f, h - 20f), "◀")
        drawButton(canvas, RectF(122f, h - 88f, 210f, h - 20f), "▶")
        drawButton(canvas, RectF(w - 118f, h - 100f, w - 24f, h - 20f), "پرش")
        postInvalidateOnAnimation()
    }

    private fun update(dt: Float, w: Float, h: Float) {
        if (left) speed = max(-260f, speed - 900f * dt)
        if (right) speed = min(520f, speed + 900f * dt)
        if (!left && !right) speed *= .90f
        playerX = max(0f, playerX + speed * dt)
        if (jumping && playerY <= 0f) velocityY = 650f
        jumping = false
        velocityY -= 1500f * dt
        playerY = max(0f, playerY + velocityY * dt)
        if (playerY == 0f) velocityY = 0f
        val worldX = playerX + w * .30f
        for (i in ringX.indices) {
            if (!ringTaken[i] && kotlin.math.abs(ringX[i] - worldX) < 30f && playerY < 150f) {
                ringTaken[i] = true
                rings++
                score += 100
            }
        }
        score += (max(0f, speed) * dt / 12f).toInt()
    }

    private fun drawButton(c: Canvas, r: RectF, label: String) {
        paint.color = 0xAA17345B.toInt()
        c.drawRoundRect(r, 18f, 18f, paint)
        paint.color = Color.WHITE
        paint.textSize = if (label == "پرش") 22f else 34f
        paint.textAlign = Paint.Align.CENTER
        c.drawText(label, r.centerX(), r.centerY() + 11f, paint)
        paint.textAlign = Paint.Align.LEFT
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val w = width.toFloat()
        val h = height.toFloat()
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN,
            MotionEvent.ACTION_MOVE -> {
                left = false
                right = false
                for (i in 0 until event.pointerCount) {
                    val x = event.getX(i)
                    val y = event.getY(i)
                    if (y > h - 120f && x < 115f) left = true
                    if (y > h - 120f && x in 115f..230f) right = true
                    if (y > h - 130f && x > w - 130f) jumping = true
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL, MotionEvent.ACTION_POINTER_UP -> {
                left = false
                right = false
            }
        }
        return true
    }
}
