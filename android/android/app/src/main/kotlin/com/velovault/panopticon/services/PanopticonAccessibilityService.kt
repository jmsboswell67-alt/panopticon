package com.velovault.panopticon.services

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.velovault.panopticon.EventBuffer
import com.velovault.panopticon.TextCaptureAllowlistStore

/**
 * Accessibility events:
 *   - window_state_changed
 *   - app_focus_changed (derived from consecutive window_state_changed)
 *   - screen_on / screen_off (via a registered BroadcastReceiver)
 *   - text_capture (Phase 3+, gated per-package by the in-app allowlist)
 *
 * Text capture is OFF by default. It only fires when the foreground
 * package has been explicitly added to [TextCaptureAllowlistStore] from
 * the Flutter UI. Capture is throttled and de-duplicated by a hash of
 * the rendered text — repeated scrolls inside the same view tree don't
 * spam the buffer.
 *
 * Sensitive view types (password fields, input fields marked sensitive)
 * are excluded from capture.
 */
class PanopticonAccessibilityService : AccessibilityService() {

    private var lastForegroundPackage: String? = null
    private var lastForegroundEnteredAt: Long = 0L

    private var lastCaptureAt: Long = 0L
    private var lastCaptureHash: Int = 0

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

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> handleWindowStateChange(event)
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> maybeCaptureText(event)
            else -> Unit
        }
    }

    private fun handleWindowStateChange(event: AccessibilityEvent) {
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

        // A new screen invalidates the dedup hash so the first capture on
        // the new screen always fires.
        lastCaptureHash = 0
    }

    private fun maybeCaptureText(event: AccessibilityEvent) {
        val pkg = event.packageName?.toString() ?: return
        if (!TextCaptureAllowlistStore.isAllowed(applicationContext, pkg)) return

        val now = System.currentTimeMillis()
        if (now - lastCaptureAt < CAPTURE_INTERVAL_MS) return

        val root = rootInActiveWindow ?: return
        val blocks = mutableListOf<Map<String, Any?>>()
        try {
            collectText(root, blocks, depth = 0)
        } finally {
            // The root is owned by the system, but the docs strongly suggest
            // recycling node copies we made. We didn't copy here — only walked
            // the live tree — so no recycle calls.
        }
        if (blocks.isEmpty()) return

        val signature = blocks
            .joinToString("|") { "${it["text"]}#${it["view_id"] ?: ""}" }
            .hashCode()
        if (signature == lastCaptureHash) return
        lastCaptureHash = signature
        lastCaptureAt = now

        EventBuffer.push(
            source = "accessibility",
            eventType = "text_capture",
            packageName = pkg,
            payload = mapOf(
                "package_name" to pkg,
                "window_class" to event.className?.toString(),
                "screen_signature" to signature.toString(),
                "blocks" to blocks,
            ),
            timestampUtcMillis = now,
        )
    }

    private fun collectText(
        node: AccessibilityNodeInfo,
        out: MutableList<Map<String, Any?>>,
        depth: Int,
    ) {
        if (depth > MAX_DEPTH) return
        if (out.size >= MAX_BLOCKS) return

        if (node.isPassword) return // never capture password fields
        if (node.className?.toString()?.contains("EditText") == true) {
            // Don't capture user input fields; we want the rendered feed,
            // not what the user is typing.
        } else {
            val text = node.text?.toString()?.trim()
            val desc = node.contentDescription?.toString()?.trim()
            val captured = text?.takeIf { it.isNotEmpty() }
                ?: desc?.takeIf { it.isNotEmpty() }
            if (captured != null && captured.length <= MAX_TEXT_LEN) {
                out.add(
                    mapOf(
                        "text" to captured,
                        "view_id" to node.viewIdResourceName,
                        "role" to inferRole(captured, node.viewIdResourceName),
                    )
                )
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            collectText(child, out, depth + 1)
        }
    }

    private fun inferRole(text: String, viewId: String?): String {
        val lid = viewId?.lowercase().orEmpty()
        return when {
            text.startsWith("@") -> "creator"
            text.startsWith("#") -> "hashtag"
            lid.contains("desc") || lid.contains("caption") -> "caption"
            lid.contains("user") || lid.contains("author") -> "creator"
            text.matches(Regex("^[\\d.,KMB]+$")) -> "count"
            else -> "unknown"
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

    companion object {
        private const val CAPTURE_INTERVAL_MS = 2000L
        private const val MAX_DEPTH = 30
        private const val MAX_BLOCKS = 64
        private const val MAX_TEXT_LEN = 500
    }
}
