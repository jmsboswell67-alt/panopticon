package com.velovault.panopticon.collectors

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import com.velovault.panopticon.EventBuffer
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Periodic UsageStatsManager rollup.
 *
 * Emits one usagestats.daily_summary event per (date, package_name) tuple
 * each invocation. The repository upserts on (date, package_name) so re-runs
 * within the same day update the foreground_ms / launch_count fields rather
 * than duplicating rows.
 */
object UsageStatsCollector {

    fun collectDailySummary(context: Context) {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return

        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfDay = cal.timeInMillis
        val endOfDay = startOfDay + DAY_MILLIS

        val events = try {
            usm.queryEvents(startOfDay, endOfDay)
        } catch (_: SecurityException) {
            // Permission revoked — silently skip.
            return
        }

        val foregroundMs = mutableMapOf<String, Long>()
        val launchCount = mutableMapOf<String, Int>()
        val resumeAt = mutableMapOf<String, Long>()

        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    resumeAt[pkg] = event.timeStamp
                    launchCount[pkg] = (launchCount[pkg] ?: 0) + 1
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val started = resumeAt.remove(pkg) ?: continue
                    val delta = event.timeStamp - started
                    if (delta > 0) {
                        foregroundMs[pkg] = (foregroundMs[pkg] ?: 0) + delta
                    }
                }
            }
        }
        // Close any still-foreground intervals at "now".
        val now = System.currentTimeMillis()
        for ((pkg, started) in resumeAt) {
            val delta = now - started
            if (delta > 0) {
                foregroundMs[pkg] = (foregroundMs[pkg] ?: 0) + delta
            }
        }

        val date = isoDate(startOfDay)
        for (pkg in (foregroundMs.keys + launchCount.keys).distinct()) {
            EventBuffer.push(
                source = "usagestats",
                eventType = "daily_summary",
                packageName = pkg,
                payload = mapOf(
                    "date" to date,
                    "package_name" to pkg,
                    "foreground_ms" to (foregroundMs[pkg] ?: 0L),
                    "launch_count" to (launchCount[pkg] ?: 0),
                ),
                timestampUtcMillis = now,
            )
        }
        EventBuffer.flush()
    }

    private fun isoDate(epochMillis: Long): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }
        return fmt.format(epochMillis)
    }

    private const val DAY_MILLIS = 24L * 60L * 60L * 1000L
}
