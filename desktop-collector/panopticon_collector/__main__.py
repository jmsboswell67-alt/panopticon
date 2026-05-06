"""Entry point so `python -m panopticon_collector ...` works without
requiring the `panopticon-collector` script to be on PATH.

This is the same dispatch as the installed CLI script — handy on
Windows where script-dir PATH setup is fiddly."""

from .cli import main

if __name__ == "__main__":
    raise SystemExit(main())
