"""Common importer interface."""

from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path

from ..events import ImportSummary


class Importer(ABC):
    """Single-platform importer.

    Each subclass turns one bundle of platform-issued export files into a
    list of Panopticon events. Importers are stateless — given the same
    input they produce the same output, so re-imports are deterministic
    and idempotent (the phone-side dedup key is `(source, event_type, timestamp_utc, hash(payload))`).
    """

    importer_id: str = ""
    display_name: str = ""

    @classmethod
    @abstractmethod
    def detect(cls, path: Path) -> bool:
        """Return True if the given path looks like an export this importer handles."""

    @abstractmethod
    def run(self, path: Path) -> ImportSummary:
        """Read the export and produce events. Path may be a file or a directory."""
