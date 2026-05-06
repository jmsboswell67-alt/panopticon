"""Spotify export importer.

Spotify offers two relevant exports:

  - **Account data** (delivered ~5 days): contains ``StreamingHistory*.json``
    files with one entry per track played. Limited to the last year.
  - **Extended streaming history** (delivered ~30 days): contains files
    named like ``Streaming_History_Audio_2018-2020_0.json`` with deeper
    fields (ms_played, reason_start/end, shuffle, skipped, country).

We support both. The extended export is preferred; the lightweight
StreamingHistory file is fine when the extended one isn't available.
"""

from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable

from ..events import ImportSummary, PanopticonEvent, make_media_audio_play
from .base import Importer

EXTENDED_PATTERN = re.compile(r"Streaming_History_Audio.*\.json", re.IGNORECASE)
LIGHTWEIGHT_PATTERN = re.compile(r"StreamingHistory.*\.json", re.IGNORECASE)


class SpotifyExportImporter(Importer):
    importer_id = "spotify_export"
    display_name = "Spotify (Account / Extended Streaming History)"

    @classmethod
    def detect(cls, path: Path) -> bool:
        if path.is_file() and path.suffix == ".json":
            return bool(
                EXTENDED_PATTERN.fullmatch(path.name)
                or LIGHTWEIGHT_PATTERN.fullmatch(path.name)
            )
        if path.is_dir():
            for child in path.rglob("*.json"):
                if EXTENDED_PATTERN.fullmatch(child.name) or LIGHTWEIGHT_PATTERN.fullmatch(child.name):
                    return True
        return False

    def run(self, path: Path) -> ImportSummary:
        summary = ImportSummary(
            importer_id=self.importer_id,
            source_doc="spotify_export",
        )
        for file_path in self._discover(path):
            try:
                with file_path.open(encoding="utf-8") as f:
                    items = json.load(f)
            except (OSError, json.JSONDecodeError) as e:
                summary.notes.append(f"Skipped {file_path.name}: {e}")
                continue
            parser = (
                self._parse_extended
                if EXTENDED_PATTERN.fullmatch(file_path.name)
                else self._parse_lightweight
            )
            for item in items:
                event = parser(item, file_path.name)
                if event is None:
                    summary.skipped += 1
                    continue
                summary.events.append(event)
            summary.notes.append(
                f"Read {len(items)} item(s) from {file_path.name}"
            )
        return summary

    # ------------------------------------------------------------------ helpers

    def _discover(self, path: Path) -> Iterable[Path]:
        if path.is_file():
            yield path
            return
        for child in path.rglob("*.json"):
            if EXTENDED_PATTERN.fullmatch(child.name) or LIGHTWEIGHT_PATTERN.fullmatch(child.name):
                yield child

    def _parse_extended(self, item: dict[str, Any], filename: str) -> PanopticonEvent | None:
        track = item.get("master_metadata_track_name")
        if not track:
            return None
        ts = _parse_time(item.get("ts"))
        artist = item.get("master_metadata_album_artist_name")
        album = item.get("master_metadata_album_album_name")
        track_uri = item.get("spotify_track_uri")
        track_id = track_uri.split(":")[-1] if track_uri else None
        return make_media_audio_play(
            track,
            platform="spotify",
            timestamp=ts,
            artist=artist,
            album=album,
            track_id=track_id,
            ms_played=(item.get("ms_played") if isinstance(item.get("ms_played"), int) else None),
            skipped=item.get("skipped"),
            shuffled=item.get("shuffle"),
            context=_extract_context(item),
            source_doc=f"spotify_export/{filename}",
            extra={
                k: v for k, v in {
                    "reason_start": item.get("reason_start"),
                    "reason_end": item.get("reason_end"),
                    "country": item.get("conn_country"),
                    "platform_played_on": item.get("platform"),
                }.items() if v is not None
            } or None,
        )

    def _parse_lightweight(self, item: dict[str, Any], filename: str) -> PanopticonEvent | None:
        track = item.get("trackName")
        if not track:
            return None
        ts = _parse_time(item.get("endTime"))
        return make_media_audio_play(
            track,
            platform="spotify",
            timestamp=ts,
            artist=item.get("artistName"),
            ms_played=(item.get("msPlayed") if isinstance(item.get("msPlayed"), int) else None),
            source_doc=f"spotify_export/{filename}",
        )


def _extract_context(item: dict[str, Any]) -> str | None:
    for key in ("reason_start", "context_uri", "context_id"):
        v = item.get(key)
        if isinstance(v, str) and v:
            return v
    return None


def _parse_time(raw: str | None) -> datetime | None:
    if not raw:
        return None
    try:
        if raw.endswith("Z"):
            raw = raw[:-1] + "+00:00"
        return datetime.fromisoformat(raw)
    except ValueError:
        return None
