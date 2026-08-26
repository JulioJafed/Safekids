package com.safekids.safekids

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.os.Handler
import android.os.Looper

class AppBlockerService : AccessibilityService() {

    companion object {
        var blockedApps: Set<String> = emptySet()
        var isDeviceLocked: Boolean = false
        var instance: AppBlockerService? = null

        val systemPackages = setOf(
            "com.android.systemui",
            "com.android.launcher",
            "com.android.launcher2",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.miui.home",
            "com.huawei.android.launcher",
            "com.samsung.android.app.launcher",
            "com.oppo.launcher",
            "com.vivo.launcher",
            "com.safekids.safekids",
            "android",
        )
    }

    private var lastBlockedPackage = ""
    private var lastBlockTime = 0L
    private var currentForegroundPackage = ""

    // Obtiene el paquete del teclado activo para no confundirlo con
    // "otra app" cuando el hijo escribe el código (esto sí arregla el parpadeo)
    private fun getCurrentInputMethodPackage(): String? {
        return try {
            val ime = android.provider.Settings.Secure.getString(
                contentResolver,
                android.provider.Settings.Secure.DEFAULT_INPUT_METHOD
            )
            ime?.substringBefore("/")
        } catch (e: Exception) {
            null
        }
    }

    private fun isIgnorablePackage(packageName: String): Boolean {
        if (systemPackages.any { packageName.contains(it) }) return true
        val ime = getCurrentInputMethodPackage()
        if (ime != null && packageName == ime) return true
        if (packageName.contains("inputmethod") || packageName.contains("keyboard")) return true
        return false
    }

    // Red de seguridad: revisa cada 500ms sin depender de eventos de
    // accesibilidad, por si el hijo logró salir por algún medio (gestos,
    // recientes, etc.) que no dispare un evento capturable.
    private val lockChecker = object : Runnable {
        override fun run() {
            if (isDeviceLocked) {
                if (currentForegroundPackage.isNotEmpty() &&
                    !isIgnorablePackage(currentForegroundPackage)) {
                    try {
                        val lockIntent = Intent(applicationContext, LockScreenActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_CLEAR_TASK or
                                    Intent.FLAG_ACTIVITY_NO_ANIMATION
                        }
                        applicationContext.startActivity(lockIntent)
                    } catch (e: Exception) {
                        goToLauncher()
                    }
                }
            }
            handler.postDelayed(this, 500)
        }
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 50
        }
        serviceInfo = info
        handler.postDelayed(lockChecker, 500)

        try {
            val intent = Intent(this, FirestoreListenerService::class.java)
            startService(intent)
            android.util.Log.d("SafeKids", "FirestoreListenerService iniciado desde AccessibilityService")
        } catch (e: Exception) {
            android.util.Log.e("SafeKids", "Error iniciando servicio: ${e.message}")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Ignorar el teclado: no lo tratamos como "cambio de app"
        if (isIgnorablePackage(packageName)) return

        currentForegroundPackage = packageName

        if (isDeviceLocked) {
            if (packageName != "com.safekids.safekids") {
                try {
                    val lockIntent = Intent(applicationContext, LockScreenActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TASK or
                                Intent.FLAG_ACTIVITY_NO_ANIMATION
                    }
                    applicationContext.startActivity(lockIntent)
                } catch (e: Exception) {
                    goToLauncher()
                }
            }
            return
        }

        if (blockedApps.contains(packageName)) {
            val now = System.currentTimeMillis()
            if (packageName == lastBlockedPackage && now - lastBlockTime < 1000) return
            lastBlockedPackage = packageName
            lastBlockTime = now
            goToHome()
        }
    }

    private fun goToHome() {
        handler.post {
            try {
                val intent = Intent(this, LockScreenActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                startActivity(intent)
            } catch (e: Exception) {
                goToLauncher()
            }
        }
    }

    private fun goToLauncher() {
        handler.post {
            try {
                val intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            } catch (e: Exception) {
                android.util.Log.e("SafeKids", "Error: ${e.message}")
            }
        }
    }

    override fun onInterrupt() {
        instance = null
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(lockChecker)
        instance = null
    }
}