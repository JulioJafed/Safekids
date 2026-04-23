package com.safekids.safekids

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.safekids/apps"
    private var timeHandler: Handler? = null
    private var timeRunnable: Runnable? = null
    private var flutterChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        )

        flutterChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {

                "startFirestoreService" -> {
                    val intent = Intent(this, FirestoreListenerService::class.java)
                    startService(intent)
                    result.success(true)
                }

                "saveChildUid" -> {
                    val uid = call.argument<String>("uid") ?: ""
                    val prefs = getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("child_uid", uid).apply()
                    // Iniciar el servicio inmediatamente
                    val intent = Intent(this, FirestoreListenerService::class.java)
                    startService(intent)
                    result.success(true)
                }

                "activateDeviceAdmin" -> {
                    activateDeviceAdmin()
                    result.success(true)
                }

                "isDeviceAdminActive" -> {
                    result.success(isDeviceAdminActive())
                }

                "checkPendingAlerts" -> {
                    val prefs = getSharedPreferences("safekids_prefs", Context.MODE_PRIVATE)
                    val hasAlert = prefs.getBoolean("pending_disable_alert", false)
                    if (hasAlert) {
                        prefs.edit().putBoolean("pending_disable_alert", false).apply()
                    }
                    result.success(hasAlert)
                }

                "getInstalledApps" -> {
                    try {
                        result.success(getInstalledApps())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "getAppUsageStats" -> {
                    if (!hasUsageStatsPermission()) {
                        result.error("NO_PERMISSION", "Sin permiso", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(getAppUsageStats())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "hasUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }

                "openUsageSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "updateBlockedApps" -> {
                    val apps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    AppBlockerService.blockedApps = apps.toSet()
                    result.success(true)
                }

                "setDeviceLocked" -> {
                    val locked = call.argument<Boolean>("locked") ?: false
                    AppBlockerService.isDeviceLocked = locked
                    result.success(true)
                }

                "hasAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }

                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }

                "startTimeTracking" -> {
                    startTimeTracking()
                    result.success(true)
                }

                "stopTimeTracking" -> {
                    stopTimeTracking()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

        private fun activateDeviceAdmin() {
            val component = android.content.ComponentName(this, SafeKidsAdminReceiver::class.java)
            val intent = Intent(android.app.admin.DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(android.app.admin.DevicePolicyManager.EXTRA_DEVICE_ADMIN, component)
            intent.putExtra(
                android.app.admin.DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "SafeKids necesita permisos de administrador para proteger el dispositivo"
            )
            startActivity(intent)
        }

        private fun isDeviceAdminActive(): Boolean {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
            val component = android.content.ComponentName(this, SafeKidsAdminReceiver::class.java)
            return dpm.isAdminActive(component)
        }


    private fun startTimeTracking() {
        if (timeHandler != null) return
        timeHandler = Handler(Looper.getMainLooper())
        val runnable = object : Runnable {
            override fun run() {
                flutterChannel?.invokeMethod("onMinutePassed", null)
                timeHandler?.postDelayed(this, 60000L)
            }
        }
        timeRunnable = runnable
        timeHandler?.postDelayed(runnable, 60000L)
    }

    private fun stopTimeTracking() {
        timeRunnable?.let { timeHandler?.removeCallbacks(it) }
        timeHandler = null
        timeRunnable = null
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val result = mutableListOf<Map<String, Any>>()

        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }

        for (app in packages) {
            if ((app.flags and ApplicationInfo.FLAG_SYSTEM) != 0) continue
            if ((app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0) continue
            if (app.packageName == packageName) continue

            try {
                val name = pm.getApplicationLabel(app).toString()
                if (name.isBlank()) continue
                result.add(mapOf(
                    "name" to name,
                    "packageName" to app.packageName,
                    "category" to getCategoryName(app),
                ))
            } catch (e: Exception) {
                continue
            }
        }

        return result.sortedBy { it["name"] as String }
    }

    private fun getAppUsageStats(): List<Map<String, Any>> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager
        val end = System.currentTimeMillis()
        val start = end - 24 * 60 * 60 * 1000L

        val stats: List<UsageStats> = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, start, end
        ) ?: emptyList()

        val result = mutableListOf<Map<String, Any>>()

        for (stat in stats) {
            if (stat.totalTimeInForeground <= 0) continue
            if (stat.packageName == packageName) continue

            try {
                val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getApplicationInfo(
                        stat.packageName,
                        PackageManager.ApplicationInfoFlags.of(0L)
                    )
                } else {
                    @Suppress("DEPRECATION")
                    pm.getApplicationInfo(stat.packageName, 0)
                }

                if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) continue

                val name = pm.getApplicationLabel(appInfo).toString()
                val minutes = stat.totalTimeInForeground / 60000L

                result.add(mapOf(
                    "packageName" to stat.packageName,
                    "name" to name,
                    "minutesUsed" to minutes,
                ))
            } catch (e: PackageManager.NameNotFoundException) {
                continue
            }
        }

        return result.sortedByDescending { it["minutesUsed"] as Long }
    }

    private fun getCategoryName(appInfo: ApplicationInfo): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return when (appInfo.category) {
                ApplicationInfo.CATEGORY_GAME -> "Juegos"
                ApplicationInfo.CATEGORY_SOCIAL -> "Redes sociales"
                ApplicationInfo.CATEGORY_VIDEO -> "Entretenimiento"
                ApplicationInfo.CATEGORY_AUDIO -> "Música"
                ApplicationInfo.CATEGORY_PRODUCTIVITY -> "Productividad"
                ApplicationInfo.CATEGORY_NEWS -> "Noticias"
                else -> "Otros"
            }
        }
        return "Otros"
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "${packageName}/${AppBlockerService::class.java.canonicalName}"
        val enabledServices = android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(service)
    }
}