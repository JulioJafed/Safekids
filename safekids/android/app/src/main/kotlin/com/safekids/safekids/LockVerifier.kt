package com.safekids.safekids

import android.content.Context
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore

/**
 * Lógica de verificación de código compartida entre LockScreenActivity
 * (Activity) y LockOverlayManager (overlay). Evita duplicar la lógica en
 * dos lugares — que es justo lo que nos causó varios bugs hoy.
 */
object LockVerifier {

    sealed class Result {
        object Success : Result()
        data class Error(val message: String) : Result()
    }

    fun hasRealNetworkConnection(context: Context): Boolean {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val capabilities = cm.getNetworkCapabilities(network) ?: return false
            capabilities.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                    capabilities.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        } catch (e: Exception) {
            false
        }
    }

    fun verifyCode(context: Context, code: String, onResult: (Result) -> Unit) {
        if (!hasRealNetworkConnection(context)) {
            tryOfflineUnlock(context, code, onResult)
            return
        }

        val uid = FirebaseAuth.getInstance().currentUser?.uid
        if (uid == null) {
            tryOfflineUnlock(context, code, onResult)
            return
        }

        val firestore = FirebaseFirestore.getInstance()

        firestore.collection("childProfiles").document(uid).get()
            .addOnSuccessListener { profileDoc -> handleProfileDoc(context, profileDoc, uid, code, firestore, onResult) }
            .addOnFailureListener { tryOfflineUnlock(context, code, onResult) }
    }

    private fun handleProfileDoc(
        context: Context,
        profileDoc: DocumentSnapshot,
        uid: String,
        code: String,
        firestore: FirebaseFirestore,
        onResult: (Result) -> Unit
    ) {
        val lockedReason = profileDoc.getString("lockedReason") ?: ""

        if (lockedReason == "uninstall_denied" || lockedReason == "uninstall_unauthorized") {
            firestore.collection("uninstallRequests").document(uid).get()
                .addOnSuccessListener { reqDoc -> handleUninstallRequest(context, reqDoc, uid, code, firestore, onResult) }
                .addOnFailureListener { tryOfflineUnlock(context, code, onResult) }
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
                    AppBlockerService.persistLockState(context, false)
                    onResult(Result.Success)
                }
            } else {
                onResult(Result.Error("❌ Código incorrecto. Intentá de nuevo."))
            }
        }
    }

    private fun handleUninstallRequest(
        context: Context,
        reqDoc: DocumentSnapshot,
        uid: String,
        code: String,
        firestore: FirebaseFirestore,
        onResult: (Result) -> Unit
    ) {
        val storedCode = reqDoc.getString("authCode") ?: ""
        val status = reqDoc.getString("status") ?: ""
        val expiresAt = reqDoc.getTimestamp("codeExpiresAt")
        val isExpired = expiresAt != null && expiresAt.toDate().before(java.util.Date())

        if (status != "code_issued" || storedCode.isEmpty()) {
            onResult(Result.Error("Tu padre/madre todavía no autorizó esta acción."))
            return
        }
        if (isExpired) {
            onResult(Result.Error("El código expiró. Pedile uno nuevo a tu padre/madre."))
            return
        }
        if (storedCode != code) {
            onResult(Result.Error("❌ Código incorrecto."))
            return
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
        AppBlockerService.persistLockState(context, false)
        onResult(Result.Success)
    }

    private fun tryOfflineUnlock(context: Context, code: String, onResult: (Result) -> Unit) {
        val prefs = context.getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
        val cachedPin = prefs.getString("cached_emergency_pin", null)

        if (cachedPin.isNullOrEmpty()) {
            onResult(Result.Error("Sin conexión y no hay PIN de emergencia configurado. Reconectá a internet."))
            return
        }
        if (code != cachedPin) {
            onResult(Result.Error("❌ PIN incorrecto."))
            return
        }

        prefs.edit().putBoolean("pending_unlock_sync", true).apply()
        AppBlockerService.isDeviceLocked = false
        AppBlockerService.persistLockState(context, false)
        onResult(Result.Success)
    }
}