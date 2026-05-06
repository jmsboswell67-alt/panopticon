package com.velovault.panopticon.services

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.view.accessibility.AccessibilityEvent
import com.velovault.panopticon.EventBuffer

/**
 * Captures Phase 1 accessibility events:
 *   - window_state_changed
 *   - app_focus_changed (derived from consecutive window_state_changed)
 *   - screen_on / screen_off (via a registered BroadcastReceiver)
 *
 * Captures only metadata. Text content of other apps is NOT captured.
 */
class PanopticonAccessibilityService : AccessibilityService() {

    private var lastForegroundPackage: String? = null
    private var lastForegroundEnteredAt: Long = 0L

    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON ->
                    EventBuffer.push(source = "accessibility", eventType = "screen_on")
                Intent.ACTION_SCREEN_OFF ->
                    EventBuffer.push(source = "accessibility", eventType = "screen_off")
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenStateReceiver, filter)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val pkg = event.packageName?.toString() ?: return
        val cls = event.className?.toString()
        val now = System.currentTimeMillis()

        EventBuffer.push(
            source = "accessibility",
            eventType = "window_state_changed",
            packageName = pkg,
            payload = mapOf(
                "package_name" to pkg,
                "class_name" to cls,
            ),
            timestampUtcMillis = now,
        )

        // Suppress repeats from the same package; many windows within an app
        // generate window_state_changed without a true app switch.
        if (pkg != lastForegroundPackage) {
            val previous = lastForegroundPackage
            val dwell = if (previous != null && lastForegroundEnteredAt > 0) {
                now - lastForegroundEnteredAt
            } else null

            EventBuffer.push(
                source = "accessibility",
                eventType = "app_focus_changed",
                packageName = pkg,
                payload = mapOf(
                    "previous_package" to previous,
                    "current_package" to pkg,
                    "dwell_ms_in_previous" to dwell,
                ),
                timestampUtcMillis = now,
            )
            lastForegroundPackage = pkg
            lastForegroundEnteredAt = now
        }
    }

    override fun onInterrupt() {
        // No interruptible work — we only observe.
    }

    override fun onUnbind(intent: Intent?): Boolean {
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (_: IllegalArgumentException) {
            // Already unregistered.
        }
        return super.onUnbind(intent)
    }
}
