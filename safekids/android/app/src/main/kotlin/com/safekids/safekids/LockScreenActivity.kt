package com.safekids.safekids

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.Gravity
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore

class LockScreenActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Mostrar encima de TODO incluso pantalla de bloqueo del sistema
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        }

        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )

        // Escuchar Firestore por si el padre desbloquea remotamente
        listenForRemoteUnlock()

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#1A2340"))
            setPadding(80, 80, 80, 80)
        }

        val lockIcon = TextView(this).apply {
            text = "🔒"
            textSize = 64f
            gravity = Gravity.CENTER
        }

        val title = TextView(this).apply {
            text = "Dispositivo bloqueado"
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 0)
            typeface = Typeface.DEFAULT_BOLD
        }

        val message = TextView(this).apply {
            text = "⏱ El tiempo de uso ha finalizado\n\nPara desbloquear este dispositivo se requiere autorización de tus padres.\n\nIngresá el código que te indiquen."
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

        val codeInput = EditText(this).apply {
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

        val buttonParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            topMargin = 48
        }

        val verifyButton = Button(this).apply {
            text = "Desbloquear"
            textSize = 16f
            setTextColor(Color.WHITE)
            background = buttonBg
            setPadding(48, 32, 48, 32)
            layoutParams = buttonParams
        }

        val helpText = TextView(this).apply {
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
                Toast.makeText(this, "Ingresá el código", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            verifyCode(code)
        }

        layout.addView(lockIcon)
        layout.addView(title)
        layout.addView(message)
        layout.addView(codeInput)
        layout.addView(verifyButton)
        layout.addView(helpText)

        setContentView(layout)
    }

    // Escuchar si el padre desbloquea remotamente desde su app
    private fun listenForRemoteUnlock() {
        val uid = FirebaseAuth.getInstance().currentUser?.uid ?: return
        FirebaseFirestore.getInstance()
            .collection("childProfiles")
            .document(uid)
            .addSnapshotListener { snap, _ ->
                if (snap == null || !snap.exists()) return@addSnapshotListener
                val isLocked = snap.getBoolean("isDeviceLocked") ?: true
                if (!isLocked) {
                    // El padre desbloqueó remotamente
                    AppBlockerService.isDeviceLocked = false
                    finish()
                }
            }
    }

    private fun verifyCode(code: String) {
        val uid = FirebaseAuth.getInstance().currentUser?.uid

        // Si no hay internet o no hay uid → verificar localmente
        if (uid == null) {
            Toast.makeText(this, "Sin conexión. Verificá tu internet.", Toast.LENGTH_SHORT).show()
            return
        }

        FirebaseFirestore.getInstance()
            .collection("childProfiles")
            .document(uid)
            .get()
            .addOnSuccessListener { doc ->
                val storedCode = doc.getString("unlockCode") ?: ""
                if (storedCode == code && storedCode.isNotEmpty()) {
                    // Código correcto — desbloquear
                    FirebaseFirestore.getInstance()
                        .collection("childProfiles")
                        .document(uid)
                        .update(
                            mapOf(
                                "isDeviceLocked" to false,
                                "unlockCode" to "",
                                "lockedReason" to null,
                                "unlockedAt" to com.google.firebase.Timestamp.now()
                            )
                        ).addOnSuccessListener {
                            AppBlockerService.isDeviceLocked = false
                            finish()
                        }
                } else {
                    Toast.makeText(
                        this,
                        "❌ Código incorrecto. Intentá de nuevo.",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
            .addOnFailureListener {
                Toast.makeText(
                    this,
                    "Sin conexión. No se puede verificar el código.",
                    Toast.LENGTH_LONG
                ).show()
            }
    }

    // Bloquear botón atrás
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // No hacer nada
    }

    // Bloquear todos los botones físicos excepto volumen
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_HOME,
            KeyEvent.KEYCODE_APP_SWITCH,
            KeyEvent.KEYCODE_MENU,
            KeyEvent.KEYCODE_BACK -> true // Bloquear
            else -> super.onKeyDown(keyCode, event)
        }
    }

    // No permitir que se minimice
    override fun onPause() {
        super.onPause()
        // Si la actividad se pausa (el hijo intentó salir)
        // volver a mostrarla
        if (AppBlockerService.isDeviceLocked) {
            val intent = intent
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TASK or
                Intent.FLAG_ACTIVITY_NO_ANIMATION
            )
            startActivity(intent)
        }
    }

    // No permitir que se destruya excepto cuando el código es correcto
    override fun onDestroy() {
        super.onDestroy()
        // Si todavía está bloqueado y se destruyó → relanzar
        if (AppBlockerService.isDeviceLocked) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    val lockIntent = Intent(applicationContext, LockScreenActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TASK or
                                Intent.FLAG_ACTIVITY_NO_ANIMATION
                    }
                    applicationContext.startActivity(lockIntent)
                } catch (e: Exception) {
                    // Error silencioso
                }
            }, 100)
        }
    }
}