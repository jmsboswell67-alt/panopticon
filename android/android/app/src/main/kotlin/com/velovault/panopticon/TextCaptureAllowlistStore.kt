package com.velovault.panopticon

import android.content.Context

/**
 * Mirror of the Flutter-managed text-capture allowlist into Android
 * SharedPreferences. The accessibility service consults this on every
 * relevant event without crossing the platform channel — Dart updates
 * the prefs via [PanopticonChannel.updateTextCaptureAllowlist].
 *
 * Empty by default. Sensitive package names (banking, messaging) are
 * never auto-added — the user explicitly opts each one in.
 */
object TextCaptureAllowlistStore {

    private const val PREFS_NAME = "panopticon_text_capture"
    private const val KEY_PACKAGES = "allowed_packages"

    @Volatile
    private var cache: Set<String>? = null

    fun update(context: Context, packages: List<String>) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_PACKAGES, packages.toSet()).apply()
        cache = packages.toSet()
    }

    fun isAllowed(context: Context, packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        val current = cache ?: load(context).also { cache = it }
        return current.contains(packageName)
    }

    fun isEmpty(context: Context): Boolean {
        val current = cache ?: load(context).also { cache = it }
        return current.isEmpty()
    }

    private fun load(context: Context): Set<String> {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()
    }
}
