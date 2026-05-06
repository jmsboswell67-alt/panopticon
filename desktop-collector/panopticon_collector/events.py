"""Event construction helpers.

Every event written by the collector conforms to ``schema/events.schema.json``.
This module is the single place that enforces that contract — importers
build domain objects, hand them here, and get back JSON-serialisable dicts
ready for the NDJSON writer.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

SCHEMA_VERSION = 1


def _epoch_millis(dt: datetime | None) -> int:
    if dt is None:
        return int(time.time() * 1000)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return int(dt.timestamp() * 1000)


def _utc_offset_minutes(dt: datetime | None) -> int:
    target = dt if (dt and dt.tzinfo) else datetime.now().astimezone()
    offset = target.utcoffset()
    if offset is None:
        return 0
    return int(offset.total_seconds() // 60)


@dataclass
class PanopticonEvent:
    """One row destined for the events table on the phone."""

    source: str
    event_type: str
    payload: dict[str, Any]
    timestamp: datetime | None = None
    package_name: str | None = None
    schema_version: int = SCHEMA_VERSION

    def to_dict(self) -> dict[str, Any]:
        return {
            "timestamp_utc": _epoch_millis(self.timestamp),
            "timezone_offset": _utc_offset_minutes(self.timestamp),
            "source": self.source,
            "event_type": self.event_type,
            "package_name": self.package_name,
            "payload_json": self.payload,
            "schema_version": self.schema_version,
        }


@dataclass
class ImportSummary:
    """What an importer produced, useful for the user-facing report."""

    importer_id: str
    source_doc: str
    events: list[PanopticonEvent] = field(default_factory=list)
    skipped: int = 0
    notes: list[str] = field(default_factory=list)

    @property
    def count(self) -> int:
        return len(self.events)

    def event_type_counts(self) -> dict[str, int]:
        counts: dict[str, int] = {}
        for e in self.events:
            key = f"{e.source}.{e.event_type}"
            counts[key] = counts.get(key, 0) + 1
        return counts


def make_browse_search_query(
    query: str,
    engine: str,
    *,
    timestamp: datetime | None = None,
    source_doc: str = "",
    extra: dict[str, Any] | None = None,
) -> PanopticonEvent:
    payload: dict[str, Any] = {"query": query, "engine": engine}
    if source_doc:
        payload["source_doc"] = source_doc
    if extra:
        payload.update(extra)
    return PanopticonEvent(
        source="browse",
        event_type="search_query",
        timestamp=timestamp,
        payload=payload,
    )


def make_media_video_view(
    title: str,
    *,
    platform: str,
    timestamp: datetime | None = None,
    video_id: str | None = None,
    channel: str | None = None,
    url: str | None = None,
    duration_seconds: int | None = None,
    watched_seconds: int | None = None,
    source_doc: str = "",
    extra: dict[str, Any] | None = None,
) -> PanopticonEvent:
    payload: dict[str, Any] = {"title": title, "platform": platform}
    if video_id is not None:
        payload["video_id"] = video_id
    if channel is not None:
        payload["channel"] = channel
    if url is not None:
        payload["url"] = url
    if duration_seconds is not None:
        payload["duration_seconds"] = duration_seconds
    if watched_seconds is not None:
        payload["watched_seconds"] = watched_seconds
    if source_doc:
        payload["source_doc"] = source_doc
    if extra:
        payload.update(extra)
    return PanopticonEvent(
        source="media",
        event_type="video_view",
        timestamp=timestamp,
        payload=payload,
    )


def make_media_audio_play(
    track_name: str,
    *,
    platform: str,
    timestamp: datetime | None = None,
    artist: str | None = None,
    album: str | None = None,
    track_id: str | None = None,
    ms_played: int | None = None,
    skipped: bool | None = None,
    shuffled: bool | None = None,
    context: str | None = None,
    source_doc: str = "",
    extra: dict[str, Any] | None = None,
) -> PanopticonEvent:
    payload: dict[str, Any] = {"track_name": track_name, "platform": platform}
    if artist is not None:
        payload["artist"] = artist
    if album is not None:
        payload["album"] = album
    if track_id is not None:
        payload["track_id"] = track_id
    if ms_played is not None:
        payload["ms_played"] = ms_played
    if skipped is not None:
        payload["skipped"] = skipped
    if shuffled is not None:
        payload["shuffled"] = shuffled
    if context is not None:
        payload["context"] = context
    if source_doc:
        payload["source_doc"] = source_doc
    if extra:
        payload.update(extra)
    return PanopticonEvent(
        source="media",
        event_type="audio_play",
        timestamp=timestamp,
        payload=payload,
    )
