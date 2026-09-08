package com.safekids.safekids

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.text.InputType
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * Pantalla de bloqueo como ventana superpuesta (overlay), en vez de una
 * Activity. Esto evita por completo las restricciones de Android 10+ que
 * bloquean silenciosamente el lanzamiento de Activities desde segundo
 * plano — el overlay simplemente se dibuja encima de lo que sea que esté
 * en pantalla (launcher, otra app, lo que sea), sin necesitar "ganar" el
 * primer plano.
 */
object LockOverlayManager {

    private var overlayView: LinearLayout? = null

    fun show(context: Context) {
        if (overlayView != null) return // ya se está mostrando

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.canDrawOverlays(context)) {
            android.util.Log.e("SafeKids", "Falta permiso de superposición — no se puede mostrar el bloqueo")
            return
        }

        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            android.graphics.PixelFormat.TRANSLUCENT
        )

        val layout = buildUi(context)

        try {
            windowManager.addView(layout, params)
            overlayView = layout
        } catch (e: Exception) {
            android.util.Log.e("SafeKids", "Error mostrando overlay: ${e.message}")
        }
    }

    fun hide(context: Context) {
        val view = overlayView ?: return
        try {
            val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            windowManager.removeView(view)
        } catch (e: Exception) {
            android.util.Log.e("SafeKids", "Error ocultando overlay: ${e.message}")
        } finally {
            overlayView = null
        }
    }

    fun isShowing(): Boolean = overlayView != null

    private fun buildUi(context: Context): LinearLayout {
        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#1A2340"))
            setPadding(80, 80, 80, 80)
        }

        val lockIcon = TextView(context).apply {
            text = "🔒"
            textSize = 64f
            gravity = Gravity.CENTER
        }

        val title = TextView(context).apply {
            text = "Dispositivo bloqueado"
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 0)
            typeface = Typeface.DEFAULT_BOLD
        }

        val message = TextView(context).apply {
            text = "Para desbloquearlo se requiere autorización de tus padres.\n\nIngresá el código que te indiquen."
            textSize = 15f
            setTextColor(Color.parseColor("#AAAACC"))
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 48)
            setLineSpacing(0f, 1.4f)
        }

        val inputBorder = GradientDrawable().apply {
            setStroke(2, Color.parseColor("#7B9FFF"))
            setColor(Color.TRANSPARENT)
            cornerRadius = 8f
        }

        val codeInput = EditText(context).apply {
            hint = "Ingresá el código"
            setHintTextColor(Color.parseColor("#666688"))
            setTextColor(Color.WHITE)
            textSize = 28f
            gravity = Gravity.CENTER
            letterSpacing = 0.3f
            inputType = InputType.TYPE_CLASS_NUMBER
            maxLines = 1
            background = inputBorder
            setPadding(24, 20, 24, 20)
        }

        val buttonBg = GradientDrawable().apply {
            setColor(Color.parseColor("#7B9FFF"))
            cornerRadius = 28f
        }

        val verifyButton = Button(context).apply {
            text = "Desbloquear"
            textSize = 16f
            setTextColor(Color.WHITE)
            background = buttonBg
            setPadding(48, 32, 48, 32)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = 48 }
        }

        val helpText = TextView(context).apply {
            text = "Pedile a tu padre/madre que abra SafeKids\ny te dé el código de desbloqueo"
            textSize = 12f
            setTextColor(Color.parseColor("#666688"))
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 0)
            setLineSpacing(0f, 1.4f)
        }

        verifyButton.setOnClickListener {
            val code = codeInput.text.toString().trim()
            if (code.isEmpty()) {
                Toast.makeText(context, "Ingresá el código", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            LockVerifier.verifyCode(context, code) { result ->
                when (result) {
                    is LockVerifier.Result.Success -> {
                        Toast.makeText(context, "✓ Desbloqueado", Toast.LENGTH_SHORT).show()
                        // AppBlockerService.isDeviceLocked ya se puso en
                        // false dentro de LockVerifier, lo cual dispara
                        // hide() automáticamente (ver AppBlockerService).
                    }
                    is LockVerifier.Result.Error -> {
                        Toast.makeText(context, result.message, Toast.LENGTH_LONG).show()
                    }
                }
            }
        }

        layout.addView(lockIcon)
        layout.addView(title)
        layout.addView(message)
        layout.addView(codeInput)
        layout.addView(verifyButton)
        layout.addView(helpText)

        return layout
    }
}
