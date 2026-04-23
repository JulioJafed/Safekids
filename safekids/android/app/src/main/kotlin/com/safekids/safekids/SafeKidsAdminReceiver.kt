package com.safekids.safekids

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class SafeKidsAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        Toast.makeText(context, "SafeKids protección activada", Toast.LENGTH_SHORT).show()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Notificar al padre antes de permitir desactivación
        notifyParentAboutDisableAttempt(context)
        return "Para desactivar SafeKids necesitás autorización del padre/madre"
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Toast.makeText(context, "SafeKids desactivado", Toast.LENGTH_SHORT).show()
    }

    private fun notifyParentAboutDisableAttempt(context: Context) {
        // Guardar intento en SharedPreferences para que Flutter lo envíe a Firebase
        val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("pending_disable_alert", true)
            .putLong("disable_attempt_time", System.currentTimeMillis())
            .apply()
    }
}