package com.odmlbook.digitalinktest

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.*
import android.os.Bundle
import android.util.AttributeSet
import android.view.*
import androidx.core.content.res.ResourcesCompat
import com.google.mlkit.vision.digitalink.Ink
import com.odmlbook.digitalinktest.R

class CustomDrawingSurface @JvmOverloads constructor(context: Context?, attributeSet: AttributeSet?=null): View(context, attributeSet) {
    // Holds the path you are currently drawing.
    private var path = Path()
    private val drawColor = Color.BLACK
    private val backgroundColor = Color.MAGENTA
    private lateinit var extraCanvas: Canvas
    private lateinit var extraBitmap: Bitmap
    private lateinit var frame: Rect
    private var inkBuilder = Ink.Builder()
    private lateinit var strokeBuilder: Ink.Stroke.Builder




    // Set up the paint with which to draw.
    private val paint = Paint().apply {
        color = drawColor
        // Smooths out edges of what is drawn without affecting shape.
        isAntiAlias = true
        // Dithering affects how colors with higher-precision than the device are down-sampled.
        isDither = true
        style = Paint.Style.STROKE // default: FILL
        strokeJoin = Paint.Join.ROUND // default: MITER
        strokeCap = Paint.Cap.ROUND // default: BUTT
        strokeWidth = 4f // default: Hairline-width (really thin)
    }

    /**
     * Don't draw every single pixel.
     * If the finger has has moved less than this distance, don't draw. scaledTouchSlop, returns
     * the distance in pixels a touch can wander before we think the user is scrolling.
     */
    private val touchTolerance = ViewConfiguration.get(context).scaledTouchSlop

    private var currentX = 0f
    private var currentY = 0f

    private var motionTouchEventX = 0f
    private var motionTouchEventY = 0f
    private var motionTouchEventT = 0L
    /**
     * Called whenever the view changes size.
     * Since the view starts out with no size, this is also called after
     * the view has been inflated and has a valid size.
     */
    override fun onSizeChanged(width: Int, height: Int, oldWidth: Int, oldHeight: Int) {
        super.onSizeChanged(width, height, oldWidth, oldHeight)

        if (::extraBitmap.isInitialized) extraBitmap.recycle()
        extraBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        extraCanvas = Canvas(extraBitmap)
        extraCanvas.drawColor(backgroundColor)
    }

    override fun onDraw(canvas: Canvas) {
        // Draw the bitmap that has the saved path.
        canvas.drawBitmap(extraBitmap, 0f, 0f, null)
    }

    /**
     * No need to call and implement MyCanvasView#performClick, because MyCanvasView custom view
     * does not handle click actions.
     */
    override fun onTouchEvent(event: MotionEvent): Boolean {
        motionTouchEventX = event.x
        motionTouchEventY = event.y
        motionTouchEventT = System.currentTimeMillis()

        when (event.action) {
            MotionEvent.ACTION_DOWN -> touchStart()
            MotionEvent.ACTION_MOVE -> touchMove()
            MotionEvent.ACTION_UP -> touchUp()
        }
        return true
    }

    /**
     * The following methods factor out what happens for different touch events,
     * as determined by the onTouchEvent() when statement.
     * This keeps the when conditional block
     * concise and makes it easier to change what happens for each event.
     * No need to call invalidate because we are not drawing anything.
     */
    private fun touchStart() {
        // For drawing on the screen
        path.reset()
        path.moveTo(motionTouchEventX, motionTouchEventY)
        // For initializing the stroke that will be used to capture the ink for ML Kit
        currentX = motionTouchEventX
        currentY = motionTouchEventY
        strokeBuilder = Ink.Stroke.builder()
        strokeBuilder.addPoint(Ink.Point.create(motionTouchEventX, motionTouchEventY, motionTouchEventT))
    }

    private fun touchMove() {
        val dx = Math.abs(motionTouchEventX - currentX)
        val dy = Math.abs(motionTouchEventY - currentY)
        if (dx >= touchTolerance || dy >= touchTolerance) {
            // QuadTo() adds a quadratic bezier from the last point,
            // approaching control point (x1,y1), and ending at (x2,y2).
            path.quadTo(currentX, currentY, (motionTouchEventX + currentX) / 2, (motionTouchEventY + currentY) / 2)
            currentX = motionTouchEventX
            currentY = motionTouchEventY
            strokeBuilder.addPoint(Ink.Point.create(motionTouchEventX, motionTouchEventY, motionTouchEventT))
            // Draw the path in the extra bitmap to save it.
            extraCanvas.drawPath(path, paint)
        }
        // Invalidate() is inside the touchMove() under ACTION_MOVE because there are many other
        // types of motion events passed into this listener, and we don't want to invalidate the
        // view for those.
        invalidate()
    }

    private fun touchUp() {
        // Reset the path so it doesn't get drawn again.
        strokeBuilder.addPoint(Ink.Point.create(motionTouchEventX, motionTouchEventY, motionTouchEventT))
        inkBuilder.addStroke(strokeBuilder.build())
        path.reset()
    }

    fun getInk(): Ink{
        val ink = inkBuilder.build()
        return ink
    }

    fun clear(){
        path.reset()
        inkBuilder = Ink.builder()
        extraCanvas.drawColor(backgroundColor)
        invalidate()
    }
}
