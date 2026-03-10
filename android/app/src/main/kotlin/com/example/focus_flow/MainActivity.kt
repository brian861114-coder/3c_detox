package com.example.focus_flow

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "focus_flow/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "requestUsageStatsPermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "requestOverlayPermission" -> {
                    startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
                    result.success(null)
                }
                "requestBatteryOptimizationPermission" -> {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    result.success(null)
                }
                "getInstalledApps" -> {
                    val pm = packageManager
                    val packages = pm.getInstalledApplications(android.content.pm.PackageManager.GET_META_DATA)
                    val appList = mutableListOf<Map<String, String>>()
                    for (app in packages) {
                        if (pm.getLaunchIntentForPackage(app.packageName) != null) {
                            val map = mapOf(
                                "name" to pm.getApplicationLabel(app).toString(),
                                "packageName" to app.packageName
                            )
                            appList.add(map)
                        }
                    }
                    result.success(appList)
                }
                "startService" -> {
                    val apps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    val serviceIntent = Intent(this, FocusService::class.java).apply {
                        putStringArrayListExtra("blockedApps", ArrayList(apps))
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(null)
                }
                "stopService" -> {
                    val serviceIntent = Intent(this, FocusService::class.java).apply {
                        action = "STOP_SERVICE"
                    }
                    startService(serviceIntent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
