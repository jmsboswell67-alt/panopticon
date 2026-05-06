package com.velovault.panopticon

import java.util.Calendar
import java.util.Collections
import java.util.TimeZone

/**
 * In-memory ring buffer of events captured by the native collectors.
 *
 * App focus changes can fire dozens of times a minute on heavy multitasking;
 * hammering SQLite per event burns battery and gains nothing. We buffer in
 * memory and flush every ~10 seconds or every 50 events, whichever first.
 *
 * Thread-safe — multiple collector services push concurrently.
 */
object EventBuffer {

    private const val FLUSH_THRESHOLD = 50

    private val buffer = Collections.synchronizedList(mutableListOf<Map<String, Any?>>())

    @Volatile
    private var listener: ((List<Map<String, Any?>>) -> Unit)? = null

    fun setListener(l: ((List<Map<String, Any?>>) -> Unit)?) {
        listener = l
    }

    /**
     * Build an event matching schema/events.schema.json (minus the autoincrement id).
     * `payload` is a JSON-serializable map; the Dart side encodes it with jsonEncode.
     */
    fun push(
        source: String,
        eventType: String,
        packageName: String? = null,
        payload: Map<String, Any?>? = null,
        timestampUtcMillis: Long = System.currentTimeMillis(),
        schemaVersion: Int = 1,
    ) {
        val tz = TimeZone.getDefault()
        val offsetMin = tz.getOffset(timestampUtcMillis) / 60_000

        val event = mapOf(
            "timestamp_utc" to timestampUtcMillis,
            "timezone_offset" to offsetMin,
            "source" to source,
            "event_type" to eventType,
            "package_name" to packageName,
            "payload" to (payload ?: emptyMap<String, Any?>()),
            "schema_version" to schemaVersion,
        )

        buffer.add(event)
        if (buffer.size >= FLUSH_THRESHOLD) {
            flush()
        }
    }

    fun flush() {
        val snapshot: List<Map<String, Any?>>
        synchronized(buffer) {
            if (buffer.isEmpty()) return
            snapshot = buffer.toList()
            buffer.clear()
        }
        listener?.invoke(snapshot)
    }

    fun pendingCount(): Int = buffer.size

    /**
     * Helper for collectors emitting "for date X" events: returns the millis
     * for midnight local-time of [calendar].
     */
    fun midnightLocalMillis(calendar: Calendar): Long {
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}
