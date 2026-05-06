"""Panopticon desktop collector.

Reads platform-issued data exports (YouTube via Google Takeout, Spotify,
TikTok, Instagram, etc.) and converts them into Panopticon events suitable
for import into the phone app.

This package is stdlib-only by design — no third-party dependencies, so it
runs anywhere Python 3.10+ is available without a virtualenv setup ritual.
"""

__version__ = "0.1.0"
