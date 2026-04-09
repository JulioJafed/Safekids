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
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        info.notificationTimeout = 100
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Ignorar el lanzador y la propia app
        if (packageName == "com.safekids.safekids") return
        if (packageName.contains("launcher")) return
        if (packageName == "com.android.systemui") return

        // Si el dispositivo está completamente bloqueado
        if (isDeviceLocked) {
            goToHome()
            return
        }

        // Si la app está bloqueada
        if (blockedApps.contains(packageName)) {
            goToHome()
        }
    }

    private fun goToHome() {
        handler.post {
            val intent = Intent(Intent.ACTION_MAIN)
            intent.addCategory(Intent.CATEGORY_HOME)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        instance = null
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
}