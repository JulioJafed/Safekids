package com.safekids.safekids

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.safekids/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // Obtener apps instaladas
                    "getInstalledApps" -> {
                        try {
                            val apps = getInstalledApps()
                            result.success(apps)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    // Obtener uso de apps (últimas 24h)
                    "getAppUsageStats" -> {
                        try {
                            if (!hasUsageStatsPermission()) {
                                result.error("NO_PERMISSION", "No tiene permiso de uso", null)
                                return@setMethodCallHandler
                            }
                            val stats = getAppUsageStats()
                            result.success(stats)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    // Verificar permiso de uso
                    "hasUsagePermission" -> {
                        result.success(hasUsageStatsPermission())
                    }

                    // Abrir configuración de permisos
                    "openUsageSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // Obtener lista de apps instaladas (no sistema)
    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()

        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(PackageManager.GET_META_DATA)
        }

        for (appInfo in packages) {
            // Filtrar apps del sistema
            if (appInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0) continue
            // Filtrar nuestra propia app
            if (appInfo.packageName == packageName) continue

            try {
                val appName = pm.getApplicationLabel(appInfo).toString()
                val packageName = appInfo.packageName

                apps.add(mapOf(
                    "name" to appName,
                    "packageName" to packageName,
                    "category" to getAppCategory(appInfo),
                ))
            } catch (e: Exception) {
                // Ignorar apps que no se pueden leer
            }
        }

        return apps.sortedBy { it["name"] as String }
    }

    // Obtener estadísticas de uso últimas 24 horas
    private fun getAppUsageStats(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager

        val endTime = System.currentTimeMillis()
        val startTime = endTime - 24 * 60 * 60 * 1000 // últimas 24h

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        val result = mutableListOf<Map<String, Any>>()

        for (stat in stats) {
            if (stat.totalTimeInForeground <= 0) continue

            try {
                val appInfo = pm.getApplicationInfo(stat.packageName, 0)
                // Solo apps no sistema
                if (appInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0) continue
                if (stat.packageName == packageName) continue

                val appName = pm.getApplicationLabel(appInfo).toString()
                val minutesUsed = stat.totalTimeInForeground / 60000

                result.add(mapOf(
                    "packageName" to stat.packageName,
                    "name" to appName,
                    "minutesUsed" to minutesUsed,
                ))
            } catch (e: PackageManager.NameNotFoundException) {
                // App desinstalada, ignorar
            }
        }

        return result.sortedByDescending { it["minutesUsed"] as Long }
    }

    // Categoría de la app
    private fun getAppCategory(appInfo: ApplicationInfo): String {
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

    // Verificar si tiene permiso de uso
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
}