package com.velovault.panopticon

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/** Restarts the foreground service after device boot or app upgrade. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED) {
            return
        }
        val svc = Intent(context, PanopticonForegroundService::class.java)
        ContextCompat.startForegroundService(context, svc)
    }
}
