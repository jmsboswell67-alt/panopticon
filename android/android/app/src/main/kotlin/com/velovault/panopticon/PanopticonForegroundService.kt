package com.velovault.panopticon

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.velovault.panopticon.collectors.UsageStatsCollector

/**
 * Long-running foreground service that hosts the in-process collectors.
 *
 * What lives here:
 *   - The persistent notification that keeps us alive.
 *   - The periodic flush timer for [EventBuffer].
 *   - The daily UsageStats rollup timer.
 *
 * What does NOT live here:
 *   - Accessibility events (delivered to PanopticonAccessibilityService).
 *   - Notification events (delivered to PanopticonNotificationListener).
 *   Those services run in their own process scopes; they push to [EventBuffer]
 *   directly and we drain it here.
 */
class PanopticonForegroundService : Service() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val flushRunnable = object : Runnable {
        override fun run() {
            EventBuffer.flush()
            mainHandler.postDelayed(this, FLUSH_INTERVAL_MS)
        }
    }
    private val rollupRunnable = object : Runnable {
        override fun run() {
            UsageStatsCollector.collectDailySummary(applicationContext)
            mainHandler.postDelayed(this, ROLLUP_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        startInForeground()
        mainHandler.postDelayed(flushRunnable, FLUSH_INTERVAL_MS)
        mainHandler.postDelayed(rollupRunnable, INITIAL_ROLLUP_DELAY_MS)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(flushRunnable)
        mainHandler.removeCallbacks(rollupRunnable)
        EventBuffer.flush()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startInForeground() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                PanopticonApp.FOREGROUND_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(PanopticonApp.FOREGROUND_NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        val tapIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = if (tapIntent != null) {
            PendingIntent.getActivity(
                this,
                0,
                tapIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        } else null

        return NotificationCompat.Builder(this, PanopticonApp.FOREGROUND_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentTitle(getString(R.string.foreground_service_notification_title))
            .setContentText(getString(R.string.foreground_service_notification_text))
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pi)
            .build()
    }

    companion object {
        private const val FLUSH_INTERVAL_MS = 10_000L
        private const val INITIAL_ROLLUP_DELAY_MS = 5_000L
        private const val ROLLUP_INTERVAL_MS = 60L * 60L * 1000L // hourly catch-up
    }
}
