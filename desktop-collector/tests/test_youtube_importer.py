"""Verify the YouTube Takeout importer produces correct events."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from panopticon_collector.importers.youtube import YouTubeTakeoutImporter


@pytest.fixture
def takeout_dir(tmp_path: Path) -> Path:
    """Build a minimal Takeout folder with one watch + one search history file."""
    history = tmp_path / "Takeout" / "YouTube and YouTube Music" / "history"
    history.mkdir(parents=True)

    (history / "watch-history.json").write_text(
        json.dumps([
            {
                "header": "YouTube",
                "title": "Watched The fastest tortoise in the world",
                "titleUrl": "https://www.youtube.com/watch?v=AbCdEfGhIjK",
                "subtitles": [{"name": "TortoiseFacts"}],
                "time": "2026-04-01T15:23:14Z",
                "products": ["YouTube"],
            },
            {
                "header": "YouTube",
                "title": "Watched a video that has been removed",
                "time": "2026-04-01T16:00:00Z",
            },
            {
                "header": "Google",
                "title": "Visited Some Other Page",
                "time": "2026-04-01T17:00:00Z",
            },
            {
                "header": "YouTube Music",
                "title": "Watched Sufjan Stevens — Mystery of Love",
                "titleUrl": "https://music.youtube.com/watch?v=ZYXwvuTSrqp",
                "subtitles": [{"name": "Sufjan Stevens - Topic"}],
                "time": "2026-04-02T09:00:00Z",
            },
        ]),
        encoding="utf-8",
    )

    (history / "search-history.json").write_text(
        json.dumps([
            {
                "header": "YouTube",
                "title": "Searched for tortoise care",
                "time": "2026-04-01T15:21:00Z",
            },
            {
                "header": "YouTube",
                "title": "Watched Something",  # Not a search; should be skipped.
                "time": "2026-04-01T15:22:00Z",
            },
        ]),
        encoding="utf-8",
    )

    return tmp_path


def test_detect_recognises_takeout_root(takeout_dir):
    assert YouTubeTakeoutImporter.detect(takeout_dir) is True


def test_detect_recognises_inner_history_file(takeout_dir):
    file = takeout_dir / "Takeout" / "YouTube and YouTube Music" / "history" / "watch-history.json"
    assert YouTubeTakeoutImporter.detect(file) is True


def test_run_emits_video_view_events(takeout_dir):
    importer = YouTubeTakeoutImporter()
    summary = importer.run(takeout_dir)

    video_events = [e for e in summary.events if e.event_type == "video_view"]
    assert len(video_events) == 2  # tortoise + sufjan; removed video skipped

    tortoise = video_events[0]
    assert tortoise.source == "media"
    assert tortoise.payload["title"] == "The fastest tortoise in the world"
    assert tortoise.payload["video_id"] == "AbCdEfGhIjK"
    assert tortoise.payload["channel"] == "TortoiseFacts"
    assert tortoise.payload["platform"] == "youtube"
    assert tortoise.payload["source_doc"].startswith("google_takeout/youtube/watch-history")

    music = video_events[1]
    assert music.payload["platform"] == "youtube_music"


def test_run_emits_search_query_events(takeout_dir):
    importer = YouTubeTakeoutImporter()
    summary = importer.run(takeout_dir)

    search_events = [e for e in summary.events if e.event_type == "search_query"]
    assert len(search_events) == 1
    s = search_events[0]
    assert s.source == "browse"
    assert s.payload["query"] == "tortoise care"
    assert s.payload["engine"] == "youtube"


def test_event_to_dict_shape(takeout_dir):
    importer = YouTubeTakeoutImporter()
    summary = importer.run(takeout_dir)
    sample = summary.events[0].to_dict()

    for required in ("timestamp_utc", "timezone_offset", "source", "event_type", "schema_version"):
        assert required in sample
    assert isinstance(sample["timestamp_utc"], int)
    assert isinstance(sample["payload_json"], dict)


def test_event_type_counts(takeout_dir):
    importer = YouTubeTakeoutImporter()
    summary = importer.run(takeout_dir)
    counts = summary.event_type_counts()
    assert counts == {
        "media.video_view": 2,
        "browse.search_query": 1,
    }
