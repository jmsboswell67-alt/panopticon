"""Per-platform importers for data exports."""

from .base import Importer
from .youtube import YouTubeTakeoutImporter
from .spotify import SpotifyExportImporter

__all__ = ["Importer", "YouTubeTakeoutImporter", "SpotifyExportImporter"]


def all_importers() -> list[type[Importer]]:
    return [YouTubeTakeoutImporter, SpotifyExportImporter]
