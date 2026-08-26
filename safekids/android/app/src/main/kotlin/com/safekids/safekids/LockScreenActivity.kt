package com.safekids.safekids

import android.app.Activity
import android.app.ActivityManager
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

    companion object {
        var isShowing: Boolean = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isShowing = true

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
            text = "⏱ Este dispositivo está bloqueado\n\nPara desbloquearlo se requiere autorización de tus padres.\n\nIngresá el código que te indiquen."
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

        tryStartLockTask()
    }

    override fun onResume() {
        super.onResume()
        // Reforzar el fijado cada vez que la actividad vuelve al frente
        // (por si el sistema la despinó por algún motivo externo)
        tryStartLockTask()
    }

    // ── Fijar pantalla (Screen Pinning): impide que gestos, botón de
    // inicio o recientes saquen al hijo de esta pantalla ──
    private fun tryStartLockTask() {
        try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            if (am.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_NONE) {
                startLockTask()
            }
        } catch (e: Exception) {
            android.util.Log.e("SafeKids", "No se pudo fijar pantalla: ${e.message}")
        }
    }

    private fun tryStopLockTask() {
        try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            if (am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE) {
                stopLockTask()
            }
        } catch (e: Exception) {
            android.util.Log.e("SafeKids", "No se pudo liberar pantalla: ${e.message}")
        }
    }

    private fun listenForRemoteUnlock() {
        val uid = FirebaseAuth.getInstance().currentUser?.uid ?: return
        FirebaseFirestore.getInstance()
            .collection("childProfiles")
            .document(uid)
            .addSnapshotListener { snap, _ ->
                if (snap == null || !snap.exists()) return@addSnapshotListener
                val isLocked = snap.getBoolean("isDeviceLocked") ?: true
                if (!isLocked) {
                    AppBlockerService.isDeviceLocked = false
                    tryStopLockTask()
                    finish()
                }
            }
    }

    private fun verifyCode(code: String) {
        val uid = FirebaseAuth.getInstance().currentUser?.uid

        if (uid == null) {
            Toast.makeText(this, "Sin conexión. Verificá tu internet.", Toast.LENGTH_SHORT).show()
            return
        }

        val firestore = FirebaseFirestore.getInstance()

        firestore.collection("childProfiles").document(uid).get()
            .addOnSuccessListener { profileDoc ->
                val lockedReason = profileDoc.getString("lockedReason") ?: ""

                if (lockedReason == "uninstall_denied" || lockedReason == "uninstall_unauthorized") {
                    firestore.collection("uninstallRequests").document(uid).get()
                        .addOnSuccessListener { reqDoc ->
                            val storedCode = reqDoc.getString("authCode") ?: ""
                            val status = reqDoc.getString("status") ?: ""
                            val expiresAt = reqDoc.getTimestamp("codeExpiresAt")

                            val isExpired = expiresAt != null &&
                                    expiresAt.toDate().before(java.util.Date())

                            if (status != "code_issued" || storedCode.isEmpty()) {
                                Toast.makeText(
                                    this,
                                    "Tu padre/madre todavía no autorizó esta acción.",
                                    Toast.LENGTH_LONG
                                ).show()
                                return@addOnSuccessListener
                            }

                            if (isExpired) {
                                Toast.makeText(
                                    this,
                                    "El código expiró. Pedile uno nuevo a tu padre/madre.",
                                    Toast.LENGTH_LONG
                                ).show()
                                return@addOnSuccessListener
                            }

                            if (storedCode != code) {
                                Toast.makeText(this, "❌ Código incorrecto.", Toast.LENGTH_SHORT).show()
                                return@addOnSuccessListener
                            }

                            firestore.collection("childProfiles").document(uid).update(
                                mapOf(
                                    "isDeviceLocked" to false,
                                    "lockedReason" to null,
                                    "unlockedAt" to com.google.firebase.Timestamp.now()
                                )
                            )
                            firestore.collection("uninstallRequests").document(uid).update(
                                mapOf("status" to "authorized", "authCode" to "")
                            )
                            AppBlockerService.isDeviceLocked = false
                            tryStopLockTask()
                            finish()
                        }
                        .addOnFailureListener {
                            Toast.makeText(this, "Sin conexión. No se puede verificar.", Toast.LENGTH_LONG).show()
                        }
                } else {
                    val storedCode = profileDoc.getString("unlockCode") ?: ""
                    if (storedCode == code && storedCode.isNotEmpty()) {
                        firestore.collection("childProfiles").document(uid).update(
                            mapOf(
                                "isDeviceLocked" to false,
                                "unlockCode" to "",
                                "lockedReason" to null,
                                "unlockedAt" to com.google.firebase.Timestamp.now()
                            )
                        ).addOnSuccessListener {
                            AppBlockerService.isDeviceLocked = false
                            tryStopLockTask()
                            finish()
                        }
                    } else {
                        Toast.makeText(this, "❌ Código incorrecto. Intentá de nuevo.", Toast.LENGTH_SHORT).show()
                    }
                }
            }
            .addOnFailureListener {
                Toast.makeText(this, "Sin conexión. No se puede verificar el código.", Toast.LENGTH_LONG).show()
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // No hacer nada
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_HOME,
            KeyEvent.KEYCODE_APP_SWITCH,
            KeyEvent.KEYCODE_MENU,
            KeyEvent.KEYCODE_BACK -> true
            else -> super.onKeyDown(keyCode, event)
        }
    }

    override fun onPause() {
        super.onPause()
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

    override fun onDestroy() {
        super.onDestroy()
        isShowing = false
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