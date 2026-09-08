package com.safekids.safekids

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.os.Handler
import android.os.Looper
import com.google.firebase.firestore.FirebaseFirestore
import android.os.Build


class AppBlockerService : AccessibilityService() {

    companion object {
        var blockedApps: Set<String> = emptySet()
        var instance: AppBlockerService? = null
        private var appContext: Context? = null

        // Al cambiar isDeviceLocked, automáticamente muestra/oculta el
        // overlay — así CUALQUIER archivo que haga
        // "AppBlockerService.isDeviceLocked = true/false" controla el
        // bloqueo real sin tener que tocar ese archivo para agregar la
        // lógica del overlay.
        var isDeviceLocked: Boolean = false
            set(value) {
                field = value
                appContext?.let { ctx ->
                    if (value) LockOverlayManager.show(ctx) else LockOverlayManager.hide(ctx)
                }
            }

        val systemPackagesForBlockedAppsFeature = setOf(
            "com.android.systemui",
            "com.android.launcher",
            "com.android.launcher2",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.miui.home",
            "com.huawei.android.launcher",
            "com.hihonor.android.launcher",
            "com.samsung.android.app.launcher",
            "com.oppo.launcher",
            "com.vivo.launcher",
            "com.safekids.safekids",
            "android",
        )

        // Overlays del propio sistema (barra de estado, volumen, avisos
        // como "Pantalla fija") que son pasajeros. Ya no se usan para
        // relanzar nada (eso lo maneja el overlay ahora), se dejan solo
        // por si se necesitan más adelante.
        val transientSystemOverlays = setOf("com.android.systemui")

        fun persistLockState(context: Context, locked: Boolean) {
            val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("is_device_locked_persisted", locked).apply()
        }

        fun readPersistedLockState(context: Context): Boolean {
            val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
            return prefs.getBoolean("is_device_locked_persisted", false)
        }
    }

    private var lastBlockedPackage = ""
    private var lastBlockTime = 0L
    private var currentForegroundPackage = ""
    private var lastActivityReportTime = 0L

    private fun isKeyboardPackage(packageName: String): Boolean {
        val ime = try {
            android.provider.Settings.Secure.getString(
                contentResolver,
                android.provider.Settings.Secure.DEFAULT_INPUT_METHOD
            )?.substringBefore("/")
        } catch (e: Exception) {
            null
        }
        if (ime != null && packageName == ime) return true
        if (packageName.contains("inputmethod") || packageName.contains("keyboard")) return true
        return false
    }

    private fun reportActivity() {
        val now = System.currentTimeMillis()
        if (now - lastActivityReportTime < 60_000L) return
        lastActivityReportTime = now

        val prefs = getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        val uid = prefs.getString("child_uid", null) ?: return

        try {
            val docRef = FirebaseFirestore.getInstance()
                .collection("childProfiles")
                .document(uid)

            docRef.update("lastActivityAt", com.google.firebase.Timestamp.now())

            docRef.get().addOnSuccessListener { snap ->
                val pin = snap.getString("emergencyPin")
                if (!pin.isNullOrEmpty()) {
                    prefs.edit().putString("cached_emergency_pin", pin).apply()
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("SafeKids", "Error reportando actividad: ${e.message}")
        }
    }

    private val lockChecker = object : Runnable {
        override fun run() {
            handler.postDelayed(this, 500)
        }
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        appContext = applicationContext

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

        val wasLocked = readPersistedLockState(applicationContext)
        if (wasLocked) {
            android.util.Log.d("SafeKids", "⚠️ Bloqueo persistido detectado al reiniciar")
            isDeviceLocked = true
        }

        try {
            val intent = Intent(this, FirestoreListenerService::class.java)
            startService(intent)
        } catch (e: Exception) {
            android.util.Log.e("SafeKids", "Error iniciando servicio: ${e.message}")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (isKeyboardPackage(packageName)) return

        currentForegroundPackage = packageName

        if (!isDeviceLocked) {
            reportActivity()
        }

        // El bloqueo del dispositivo ahora lo maneja el overlay
        // directamente (ver LockOverlayManager) — ya no depende de
        // detectar "escapes" ni relanzar nada aquí.
        if (isDeviceLocked) return

        if (systemPackagesForBlockedAppsFeature.any { packageName.contains(it) }) return

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