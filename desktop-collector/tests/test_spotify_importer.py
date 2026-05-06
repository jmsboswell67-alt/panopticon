"""Verify the Spotify export importer handles both export formats."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from panopticon_collector.importers.spotify import SpotifyExportImporter


@pytest.fixture
def lightweight_export(tmp_path: Path) -> Path:
    """The smaller 'Account data' export — just StreamingHistoryN.json files."""
    target = tmp_path / "MyData"
    target.mkdir()
    (target / "StreamingHistory0.json").write_text(
        json.dumps([
            {
                "endTime": "2026-04-12 14:30",
                "artistName": "Phoebe Bridgers",
                "trackName": "Motion Sickness",
                "msPlayed": 215000,
            },
            {
                "endTime": "2026-04-12 14:34",
                "artistName": "Big Thief",
                "trackName": "Not",
                "msPlayed": 308000,
            },
        ]),
        encoding="utf-8",
    )
    return target


@pytest.fixture
def extended_export(tmp_path: Path) -> Path:
    """The Extended Streaming History export — deeper per-event fields."""
    target = tmp_path / "Extended"
    target.mkdir()
    (target / "Streaming_History_Audio_2024-2026_0.json").write_text(
        json.dumps([
            {
                "ts": "2026-04-12T14:30:00Z",
                "platform": "android",
                "ms_played": 215000,
                "conn_country": "US",
                "master_metadata_track_name": "Motion Sickness",
                "master_metadata_album_artist_name": "Phoebe Bridgers",
                "master_metadata_album_album_name": "Stranger in the Alps",
                "spotify_track_uri": "spotify:track:5MtxhMoGS9MM5RHmwOcGPq",
                "reason_start": "trackdone",
                "reason_end": "trackdone",
                "shuffle": False,
                "skipped": False,
            },
            {
                "ts": "2026-04-12T14:31:30Z",
                "platform": "android",
                "ms_played": 4200,
                "conn_country": "US",
                "master_metadata_track_name": "Skipped Song",
                "master_metadata_album_artist_name": "Some Artist",
                "spotify_track_uri": "spotify:track:abcabcabcabc",
                "reason_start": "clickrow",
                "reason_end": "fwdbtn",
                "shuffle": True,
                "skipped": True,
            },
        ]),
        encoding="utf-8",
    )
    return target


def test_detect_lightweight(lightweight_export):
    assert SpotifyExportImporter.detect(lightweight_export) is True


def test_detect_extended(extended_export):
    assert SpotifyExportImporter.detect(extended_export) is True


def test_lightweight_emits_audio_play(lightweight_export):
    importer = SpotifyExportImporter()
    summary = importer.run(lightweight_export)
    assert summary.count == 2
    first = summary.events[0]
    assert first.source == "media"
    assert first.event_type == "audio_play"
    assert first.payload["track_name"] == "Motion Sickness"
    assert first.payload["artist"] == "Phoebe Bridgers"
    assert first.payload["ms_played"] == 215000
    # Lightweight format doesn't have track URIs / shuffle data.
    assert "track_id" not in first.payload
    assert "shuffled" not in first.payload


def test_extended_carries_richer_fields(extended_export):
    importer = SpotifyExportImporter()
    summary = importer.run(extended_export)
    assert summary.count == 2
    skipped = summary.events[1]
    assert skipped.payload["track_name"] == "Skipped Song"
    assert skipped.payload["track_id"] == "abcabcabcabc"
    assert skipped.payload["skipped"] is True
    assert skipped.payload["shuffled"] is True
    assert skipped.payload["ms_played"] == 4200


def test_event_type_counts(extended_export):
    importer = SpotifyExportImporter()
    summary = importer.run(extended_export)
    assert summary.event_type_counts() == {"media.audio_play": 2}
