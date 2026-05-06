"""Verify NDJSON writer produces one valid event per line."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from panopticon_collector.events import make_browse_search_query, make_media_video_view
from panopticon_collector.writer import write_ndjson


def test_writes_ndjson_one_event_per_line(tmp_path: Path):
    events = [
        make_browse_search_query(
            "tortoise care",
            engine="youtube",
            timestamp=datetime(2026, 4, 1, 15, 21, 0, tzinfo=timezone.utc),
            source_doc="test",
        ),
        make_media_video_view(
            "Tortoise care 101",
            platform="youtube",
            timestamp=datetime(2026, 4, 1, 15, 23, 14, tzinfo=timezone.utc),
            video_id="AbCdEfGhIjK",
            channel="TortoiseFacts",
            source_doc="test",
        ),
    ]
    out = tmp_path / "events.ndjson"
    n = write_ndjson(out, events)

    assert n == 2
    lines = out.read_text(encoding="utf-8").strip().split("\n")
    assert len(lines) == 2

    first = json.loads(lines[0])
    second = json.loads(lines[1])
    assert first["source"] == "browse"
    assert second["source"] == "media"
    assert first["payload_json"]["query"] == "tortoise care"
    assert second["payload_json"]["video_id"] == "AbCdEfGhIjK"
