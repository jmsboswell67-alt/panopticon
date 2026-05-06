"""NDJSON output for Panopticon events.

One JSON object per line. Importable on the phone via the Import screen,
which streams the file rather than parsing it as a single document.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from .events import PanopticonEvent


def write_ndjson(path: Path, events: Iterable[PanopticonEvent]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8") as f:
        for event in events:
            f.write(json.dumps(event.to_dict(), ensure_ascii=False))
            f.write("\n")
            count += 1
    return count
