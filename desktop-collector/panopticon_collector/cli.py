"""Command-line interface for the Panopticon desktop collector.

Typical usage:

    panopticon-collector import path/to/google-takeout-folder \\
        --output ~/panopticon-exports/youtube-2026-05.ndjson

    panopticon-collector import path/to/Spotify-Account-Data \\
        --output ~/panopticon-exports/spotify-2026-05.ndjson

    panopticon-collector list-importers

The output NDJSON file is what you transfer to your phone (e.g. via
Syncthing, USB, AirDrop) and feed to the in-app Import screen.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import __version__
from .importers import all_importers
from .writer import write_ndjson


def cmd_list_importers(_: argparse.Namespace) -> int:
    print("Available importers:")
    for importer_cls in all_importers():
        print(f"  - {importer_cls.importer_id:<20} {importer_cls.display_name}")
    return 0


def cmd_import(args: argparse.Namespace) -> int:
    src = Path(args.path).expanduser().resolve()
    if not src.exists():
        print(f"error: path not found: {src}", file=sys.stderr)
        return 2

    if args.importer:
        candidates = [c for c in all_importers() if c.importer_id == args.importer]
        if not candidates:
            print(f"error: no importer named '{args.importer}'", file=sys.stderr)
            print("  run `panopticon-collector list-importers` to see available ids.", file=sys.stderr)
            return 2
    else:
        candidates = [c for c in all_importers() if c.detect(src)]
        if not candidates:
            print(f"error: no importer detected for {src}", file=sys.stderr)
            print("  run `panopticon-collector list-importers` to see what's supported,", file=sys.stderr)
            print("  or pass --importer <id> to force a specific one.", file=sys.stderr)
            return 2

    output_path = Path(args.output).expanduser().resolve()
    if output_path.is_dir():
        print(f"error: --output must be a file, not a directory: {output_path}", file=sys.stderr)
        return 2

    total_events = 0
    all_summaries = []
    for importer_cls in candidates:
        importer = importer_cls()
        summary = importer.run(src)
        all_summaries.append((importer_cls, summary))
        total_events += summary.count

    if total_events == 0:
        print("No events were produced. Notes:")
        for cls, s in all_summaries:
            print(f"  [{cls.importer_id}]")
            for note in s.notes or ["(no files matched)"]:
                print(f"    - {note}")
        return 1

    written = write_ndjson(
        output_path,
        (e for _, s in all_summaries for e in s.events),
    )

    print(f"Wrote {written} event(s) to {output_path}")
    for cls, s in all_summaries:
        print(f"  [{cls.importer_id}] {s.count} event(s), {s.skipped} skipped")
        for et, c in sorted(s.event_type_counts().items()):
            print(f"    - {et}: {c}")
        for note in s.notes:
            print(f"    note: {note}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="panopticon-collector",
        description="Convert platform data exports into Panopticon NDJSON.",
    )
    parser.add_argument("--version", action="version", version=__version__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    list_p = sub.add_parser("list-importers", help="List supported export formats.")
    list_p.set_defaults(func=cmd_list_importers)

    imp_p = sub.add_parser("import", help="Run an importer over a downloaded export.")
    imp_p.add_argument("path", help="Path to the unzipped export folder or a single JSON file.")
    imp_p.add_argument(
        "--output", "-o", required=True,
        help="Where to write the NDJSON. Will be created if missing.",
    )
    imp_p.add_argument(
        "--importer", "-i", default=None,
        help="Force a specific importer id (skips auto-detection). "
             "Run `panopticon-collector list-importers` to see options.",
    )
    imp_p.set_defaults(func=cmd_import)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
