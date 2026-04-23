package com.safekids.safekids

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.content.Context
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.ListenerRegistration

class FirestoreListenerService : Service() {

    private var appsListener: ListenerRegistration? = null
    private var lockListener: ListenerRegistration? = null
    private var isListening = false

    override fun onCreate() {
        super.onCreate()
        startListening()
    }

    private fun getChildUid(): String? {
        val prefs = getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        return prefs.getString("child_uid", null)
    }

    private fun startListening() {
        val uid = getChildUid()

        if (uid == null || uid.isEmpty()) {
            // Reintentar cada 5 segundos hasta tener el UID
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                startListening()
            }, 5000)
            return
        }

        if (isListening) return
        isListening = true

        val firestore = FirebaseFirestore.getInstance()

        android.util.Log.d("SafeKids", "Iniciando listeners para UID: $uid")

        // Escuchar apps bloqueadas en tiempo real
        appsListener = firestore
            .collection("appRules")
            .document(uid)
            .addSnapshotListener { snap: DocumentSnapshot?, error: FirebaseFirestoreException? ->
                if (error != null) {
                    android.util.Log.e("SafeKids", "Error listener apps: ${error.message}")
                    return@addSnapshotListener
                }
                if (snap == null || !snap.exists()) return@addSnapshotListener

                @Suppress("UNCHECKED_CAST")
                val blocked = (snap.get("blockedApps") as? List<String>) ?: emptyList()
                AppBlockerService.blockedApps = blocked.toSet()
                android.util.Log.d("SafeKids", "✅ Apps bloqueadas: $blocked")
            }

        // Escuchar bloqueo total del dispositivo
        lockListener = firestore
            .collection("childProfiles")
            .document(uid)
            .addSnapshotListener { snap: DocumentSnapshot?, error: FirebaseFirestoreException? ->
                if (error != null) return@addSnapshotListener
                if (snap == null || !snap.exists()) return@addSnapshotListener

                val isLocked = snap.getBoolean("isDeviceLocked") ?: false
                AppBlockerService.isDeviceLocked = isLocked
                android.util.Log.d("SafeKids", "✅ Dispositivo bloqueado: $isLocked")

                // Si se activó el bloqueo → lanzar pantalla inmediatamente
                if (isLocked) {
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        try {
                            val lockIntent = Intent(applicationContext, LockScreenActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                        Intent.FLAG_ACTIVITY_CLEAR_TASK or
                                        Intent.FLAG_ACTIVITY_NO_ANIMATION
                            }
                            applicationContext.startActivity(lockIntent)
                        } catch (e: Exception) {
                            android.util.Log.e("SafeKids", "Error lanzando LockScreen: ${e.message}")
                        }
                    }
                }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isListening) startListening()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        appsListener?.remove()
        lockListener?.remove()
        isListening = false
        // Auto-reiniciarse
        val intent = Intent(this, FirestoreListenerService::class.java)
        startService(intent)
    }
}