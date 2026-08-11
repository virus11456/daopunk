from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).parents[1]
DATA = ROOT / "data" / "balance" / "v4"


def main() -> None:
    manifest = json.loads((DATA / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["version"] == "4.0"
    assert len(manifest["sheets"]) == 11
    assert len({sheet["id"] for sheet in manifest["sheets"]}) == 11
    for sheet in manifest["sheets"]:
        path = DATA / sheet["file"]
        assert path.is_file(), f"missing sheet: {path}"
        if path.suffix == ".json":
            assert json.loads(path.read_text(encoding="utf-8")), f"empty JSON: {path}"
        else:
            with path.open(encoding="utf-8", newline="") as handle:
                rows = list(csv.reader(handle))
            assert len(rows) > 1, f"empty CSV: {path}"
            width = len(rows[0])
            assert all(len(row) == width for row in rows), f"ragged CSV: {path}"
    print("validated 11 Kiro balance sheets")


if __name__ == "__main__":
    main()
