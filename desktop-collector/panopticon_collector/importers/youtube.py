"""YouTube Google Takeout importer.

Google Takeout exports YouTube history as JSON files under a
``Takeout/YouTube and YouTube Music/`` directory. The two files we care
about in v1:

  - ``history/watch-history.json`` — every video the user has watched,
    with timestamps. Maps to ``media.video_view`` events.
  - ``history/search-history.json`` — every YouTube search query, with
    timestamps. Maps to ``browse.search_query`` events.

Both files are arrays of objects. Each object has ``time`` (ISO-8601),
``title`` (the display title — for searches it's "Searched for X"), and
sometimes ``titleUrl`` (canonical URL), ``subtitles`` (channel info for
videos).

The exporter uses Google's "MyActivity" envelope, so item ``header``
distinguishes 'YouTube' / 'YouTube Music' / 'Google'. We filter by header.
"""

from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path
from typing import Any

from ..events import (
    ImportSummary,
    PanopticonEvent,
    make_browse_search_query,
    make_media_video_view,
)
from .base import Importer

YOUTUBE_VIDEO_ID_RE = re.compile(r"[?&]v=([A-Za-z0-9_-]{11})")


class YouTubeTakeoutImporter(Importer):
    importer_id = "youtube_takeout"
    display_name = "YouTube (Google Takeout)"

    @classmethod
    def detect(cls, path: Path) -> bool:
        if path.is_dir():
            takeout = path / "Takeout"
            if takeout.is_dir() and (takeout / "YouTube and YouTube Music").is_dir():
                return True
            yt_dir = path / "YouTube and YouTube Music"
            if yt_dir.is_dir():
                return True
        if path.is_file() and path.suffix == ".json":
            return path.name in {"watch-history.json", "search-history.json"}
        return False

    def run(self, path: Path) -> ImportSummary:
        summary = ImportSummary(
            importer_id=self.importer_id,
            source_doc="google_takeout",
        )
        for source_path, parser in self._discover(path):
            try:
                with source_path.open(encoding="utf-8") as f:
                    items = json.load(f)
            except (OSError, json.JSONDecodeError) as e:
                summary.notes.append(f"Skipped {source_path.name}: {e}")
                continue
            for item in items:
                event = parser(item)
                if event is None:
                    summary.skipped += 1
                    continue
                summary.events.append(event)
            summary.notes.append(
                f"Read {len(items)} item(s) from {source_path.name}"
            )
        return summary

    # ------------------------------------------------------------------ helpers

    def _discover(self, path: Path):
        """Yield (file_path, parser) pairs for the YouTube history JSONs."""
        if path.is_file() and path.suffix == ".json":
            if path.name == "watch-history.json":
                yield path, self._parse_watch_item
            elif path.name == "search-history.json":
                yield path, self._parse_search_item
            return

        candidates = [
            path / "Takeout" / "YouTube and YouTube Music" / "history",
            path / "YouTube and YouTube Music" / "history",
            path / "history",
        ]
        for hist in candidates:
            if not hist.is_dir():
                continue
            watch = hist / "watch-history.json"
            search = hist / "search-history.json"
            if watch.is_file():
                yield watch, self._parse_watch_item
            if search.is_file():
                yield search, self._parse_search_item

    def _parse_watch_item(self, item: dict[str, Any]) -> PanopticonEvent | None:
        if item.get("header") not in {"YouTube", "YouTube Music"}:
            return None
        title = item.get("title", "")
        # Skip the auto-removed "Watched a video that has been removed" rows.
        if not title or title.startswith("Watched a video that has been removed"):
            return None

        clean_title = title.removeprefix("Watched ").strip()
        url = item.get("titleUrl")
        timestamp = _parse_time(item.get("time"))
        video_id = _extract_video_id(url) if url else None

        channel = None
        subtitles = item.get("subtitles") or []
        if subtitles and isinstance(subtitles, list):
            channel = subtitles[0].get("name")

        platform = "youtube_music" if item["header"] == "YouTube Music" else "youtube"

        return make_media_video_view(
            clean_title,
            platform=platform,
            timestamp=timestamp,
            video_id=video_id,
            channel=channel,
            url=url,
            source_doc="google_takeout/youtube/watch-history",
        )

    def _parse_search_item(self, item: dict[str, Any]) -> PanopticonEvent | None:
        if item.get("header") not in {"YouTube", "YouTube Music"}:
            return None
        title = item.get("title", "")
        if not title.startswith("Searched for "):
            return None
        query = title.removeprefix("Searched for ").strip()
        if not query:
            return None
        timestamp = _parse_time(item.get("time"))
        return make_browse_search_query(
            query,
            engine="youtube",
            timestamp=timestamp,
            source_doc="google_takeout/youtube/search-history",
        )


def _extract_video_id(url: str) -> str | None:
    m = YOUTUBE_VIDEO_ID_RE.search(url)
    return m.group(1) if m else None


def _parse_time(raw: str | None) -> datetime | None:
    if not raw:
        return None
    try:
        # Google Takeout uses RFC 3339 / ISO 8601 with trailing 'Z'.
        if raw.endswith("Z"):
            raw = raw[:-1] + "+00:00"
        return datetime.fromisoformat(raw)
    except ValueError:
        return None
