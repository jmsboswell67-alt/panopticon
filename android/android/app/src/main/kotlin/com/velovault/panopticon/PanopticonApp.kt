package com.velovault.panopticon

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import io.flutter.app.FlutterApplication

class PanopticonApp : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        registerForegroundChannel()
    }

    private fun registerForegroundChannel() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(FOREGROUND_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            FOREGROUND_CHANNEL_ID,
            getString(R.string.foreground_service_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.foreground_service_channel_description)
            setShowBadge(false)
        }
        nm.createNotificationChannel(channel)
    }

    companion object {
        const val FOREGROUND_CHANNEL_ID = "panopticon.foreground"
        const val FOREGROUND_NOTIFICATION_ID = 1001
    }
}
