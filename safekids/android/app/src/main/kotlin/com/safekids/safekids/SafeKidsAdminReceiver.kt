package com.safekids.safekids

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.Timestamp

class SafeKidsAdminReceiver : DeviceAdminReceiver() {

    private fun getChildUid(context: Context): String? {
        val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        return prefs.getString("child_uid", null)
    }

    // ¿El hijo ya tiene una autorización vigente del padre para esta desactivación?
    private fun hasValidAuthorization(context: Context): Boolean {
        val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        val authorizedUntil = prefs.getLong("uninstall_authorized_until", 0L)
        return System.currentTimeMillis() < authorizedUntil
    }

    private fun clearAuthorization(context: Context) {
        val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        prefs.edit().putLong("uninstall_authorized_until", 0L).apply()
    }

    override fun onEnabled(context: Context, intent: Intent) {
        Toast.makeText(context, "SafeKids protección activada", Toast.LENGTH_SHORT).show()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Guardar intento local (respaldo offline, ya existía)
        val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("pending_disable_alert", true)
            .putLong("disable_attempt_time", System.currentTimeMillis())
            .apply()

        // Si NO hay autorización vigente del padre, avisar en tiempo real vía Firestore
        // (fire-and-forget: si no hay internet, Firestore lo encola y lo envía apenas
        //  vuelva la conexión; mientras tanto el intento local ya quedó registrado)
        if (!hasValidAuthorization(context)) {
            val uid = getChildUid(context)
            if (uid != null) {
                try {
                    FirebaseFirestore.getInstance()
                        .collection("uninstallRequests")
                        .document(uid)
                        .set(
                            mapOf(
                                "status" to "pending",
                                "requestedAt" to Timestamp.now(),
                                "authCode" to "",
                                "authorizedAt" to null
                            )
                        )
                } catch (e: Exception) {
                    android.util.Log.e("SafeKids", "Error notificando intento: ${e.message}")
                }
            }
        }

        return "Para desactivar SafeKids necesitás el código de autorización de tu padre/madre"
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Toast.makeText(context, "SafeKids desactivado", Toast.LENGTH_SHORT).show()

        val uid = getChildUid(context)
        val wasAuthorized = hasValidAuthorization(context)

        if (!wasAuthorized) {
            // Se desactivó SIN autorización del padre → volver a bloquear el
            // dispositivo de inmediato usando el mismo mecanismo que ya existe
            // (AppBlockerService + LockScreenActivity), que NO depende de
            // Device Admin para funcionar.
            AppBlockerService.isDeviceLocked = true

            if (uid != null) {
                try {
                    FirebaseFirestore.getInstance()
                        .collection("childProfiles")
                        .document(uid)
                        .update(
                            mapOf(
                                "isDeviceLocked" to true,
                                "lockedReason" to "uninstall_unauthorized"
                            )
                        )
                    FirebaseFirestore.getInstance()
                        .collection("uninstallRequests")
                        .document(uid)
                        .update(mapOf("status" to "unauthorized_disable"))
                } catch (e: Exception) {
                    android.util.Log.e("SafeKids", "Error re-bloqueando: ${e.message}")
                }
            }

            // Lanzar la pantalla de bloqueo ya mismo, sin esperar el listener
            try {
                val lockIntent = Intent(context, LockScreenActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TASK or
                            Intent.FLAG_ACTIVITY_NO_ANIMATION
                }
                context.startActivity(lockIntent)
            } catch (e: Exception) {
                android.util.Log.e("SafeKids", "Error lanzando LockScreen: ${e.message}")
            }
        } else {
            // Fue autorizado correctamente → consumir la autorización (uso único)
            clearAuthorization(context)
            if (uid != null) {
                try {
                    FirebaseFirestore.getInstance()
                        .collection("uninstallRequests")
                        .document(uid)
                        .update(mapOf("status" to "completed"))
                } catch (e: Exception) {
                    android.util.Log.e("SafeKids", "Error: ${e.message}")
                }
            }
        }
    }
}