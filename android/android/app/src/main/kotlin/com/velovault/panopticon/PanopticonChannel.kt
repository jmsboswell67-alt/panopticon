package com.velovault.panopticon

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.velovault.panopticon.collectors.UsageStatsCollector
import com.velovault.panopticon.services.PanopticonAccessibilityService
import com.velovault.panopticon.services.PanopticonNotificationListener
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Glue between Dart and the native collectors.
 *
 * Two channels:
 *   - `app.panopticon/control` (MethodChannel) — Dart asks the native side
 *     about permission status and asks it to open settings pages or
 *     start/stop the foreground service.
 *   - `app.panopticon/events` (EventChannel) — native side streams batches of
 *     buffered events into Dart for persistence.
 */
class PanopticonChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CONTROL_CHANNEL)
            .setMethodCallHandler(this)

        EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    EventBuffer.setListener { batch ->
                        events?.success(batch)
                    }
                    // Drain anything already queued.
                    EventBuffer.flush()
                }

                override fun onCancel(arguments: Any?) {
                    EventBuffer.setListener(null)
                }
            })
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
            "isNotificationListenerEnabled" -> result.success(isNotificationListenerEnabled())
            "isUsageStatsEnabled" -> result.success(isUsageStatsEnabled())
            "isPostNotificationsGranted" -> result.success(isPostNotificationsGranted())
            "isBatteryOptimizationDisabled" -> result.success(isBatteryOptimizationDisabled())

            "openAccessibilitySettings" -> {
                openSettings(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                result.success(null)
            }
            "openNotificationListenerSettings" -> {
                openSettings(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                result.success(null)
            }
            "openUsageStatsSettings" -> {
                openSettings(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                result.success(null)
            }
            "requestPostNotifications" -> {
                openAppNotificationSettings()
                result.success(null)
            }
            "openBatteryOptimizationSettings" -> {
                openBatteryOptimizationSettings()
                result.success(null)
            }
            "startForegroundService" -> {
                val svc = Intent(context, PanopticonForegroundService::class.java)
                ContextCompat.startForegroundService(context, svc)
                result.success(null)
            }
            "stopForegroundService" -> {
                context.stopService(Intent(context, PanopticonForegroundService::class.java))
                result.success(null)
            }
            "requestUsageStatsRollup" -> {
                UsageStatsCollector.collectDailySummary(context)
                result.success(null)
            }
            "updateTextCaptureAllowlist" -> {
                @Suppress("UNCHECKED_CAST")
                val packages = (call.argument<List<String>>("packages")) ?: emptyList()
                TextCaptureAllowlistStore.update(context, packages)
                result.success(null)
            }
            "getInstalledLaunchableApps" -> {
                result.success(getInstalledLaunchableApps())
            }
            else -> result.notImplemented()
        }
    }

    private fun getInstalledLaunchableApps(): List<Map<String, String>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            PackageManager.ResolveInfoFlags.of(0L)
        } else null
        val resolved = if (flags != null) {
            pm.queryIntentActivities(intent, flags)
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }
        val seen = mutableMapOf<String, String>()
        for (ri in resolved) {
            val ai = ri.activityInfo ?: continue
            val pkg = ai.packageName ?: continue
            if (pkg == context.packageName) continue
            val label = ai.loadLabel(pm).toString()
            seen.putIfAbsent(pkg, label)
        }
        return seen.entries.map { (pkg, label) ->
            mapOf("package_name" to pkg, "display_name" to label)
        }.sortedBy { it["display_name"]?.lowercase() ?: "" }
    }

    // ---- Permission queries -------------------------------------------------

    private fun isAccessibilityEnabled(): Boolean {
        val expected = ComponentName(context, PanopticonAccessibilityService::class.java)
            .flattenToString()
        val raw = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        return raw.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val pkg = context.packageName
        val packages = NotificationManagerCompat.getEnabledListenerPackages(context)
        if (!packages.contains(pkg)) return false
        // Confirm it's our component, not just our package.
        val expected = ComponentName(context, PanopticonNotificationListener::class.java)
            .flattenToString()
        val raw = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return raw.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    private fun isUsageStatsEnabled(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isPostNotificationsGranted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
            ?: return false
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    // ---- Settings deep links ------------------------------------------------

    private fun openSettings(action: String) {
        val intent = Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            // Some OEMs hide certain settings panels — fall through silently.
        }
    }

    private fun openAppNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
        }
    }

    private fun openBatteryOptimizationSettings() {
        // ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS triggers a system prompt
        // directly — preferred when the permission dialog is what we want.
        val direct = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(Uri.parse("package:${context.packageName}"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(direct)
            return
        } catch (_: Exception) {
        }
        // Fallback: send the user to the global ignore-list page.
        try {
            context.startActivity(
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (_: Exception) {
        }
    }

    companion object {
        private const val CONTROL_CHANNEL = "app.panopticon/control"
        private const val EVENT_CHANNEL = "app.panopticon/events"
    }
}
