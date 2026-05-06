package com.velovault.panopticon.services

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.velovault.panopticon.EventBuffer

/**
 * Captures notifications that the OS routes to this listener:
 *   - notification_posted
 *   - notification_removed
 *
 * Captures package, title, text, category, priority. Does NOT capture replies
 * the user has not sent.
 */
class PanopticonNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val n = sbn.notification ?: return
        val extras = n.extras

        val title = extras?.getCharSequence("android.title")?.toString()
        val text = extras?.getCharSequence("android.text")?.toString()

        EventBuffer.push(
            source = "notification",
            eventType = "notification_posted",
            packageName = sbn.packageName,
            payload = mapOf(
                "package_name" to sbn.packageName,
                "title" to title,
                "text" to text,
                "category" to n.category,
                "priority" to n.priority,
                "post_time_utc" to sbn.postTime,
            ),
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?, rankingMap: RankingMap?, reason: Int) {
        if (sbn == null) return
        EventBuffer.push(
            source = "notification",
            eventType = "notification_removed",
            packageName = sbn.packageName,
            payload = mapOf(
                "package_name" to sbn.packageName,
                "removed_reason" to reason.toRemovalReasonString(),
            ),
        )
    }

    private fun Int.toRemovalReasonString(): String = when (this) {
        REASON_CLICK -> "click"
        REASON_CANCEL -> "cancel"
        REASON_CANCEL_ALL -> "cancel_all"
        REASON_LISTENER_CANCEL -> "listener_cancel"
        REASON_LISTENER_CANCEL_ALL -> "listener_cancel_all"
        REASON_USER_STOPPED -> "user_stopped"
        REASON_PROFILE_TURNED_OFF -> "profile_turned_off"
        REASON_PACKAGE_BANNED -> "package_banned"
        REASON_PACKAGE_CHANGED -> "package_changed"
        REASON_PACKAGE_SUSPENDED -> "package_suspended"
        REASON_TIMEOUT -> "timeout"
        REASON_CHANNEL_BANNED -> "channel_banned"
        REASON_SNOOZED -> "snoozed"
        REASON_LOCKDOWN -> "lockdown"
        REASON_APP_CANCEL -> "app_cancel"
        REASON_APP_CANCEL_ALL -> "app_cancel_all"
        else -> "other_$this"
    }
}
