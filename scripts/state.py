"""Tiny helper to get/set keys in the pipeline's flat JSON state file.
Usage:
    python state.py set <state_file> <dotted.key> <value>
    python state.py get <state_file> <dotted.key>     # exit 0 if == "done", else exit 1
"""
import json
import sys
from pathlib import Path


def load(path: Path) -> dict:
    if path.exists() and path.stat().st_size > 0:
        return json.loads(path.read_text())
    return {}


def main():
    action, state_file, key = sys.argv[1], Path(sys.argv[2]), sys.argv[3]
    data = load(state_file)
    if action == "set":
        value = sys.argv[4]
        data[key] = value
        state_file.parent.mkdir(parents=True, exist_ok=True)
        state_file.write_text(json.dumps(data, indent=2, sort_keys=True))
    elif action == "get":
        sys.exit(0 if data.get(key) == "done" else 1)
    else:
        raise SystemExit(f"unknown action {action}")


if __name__ == "__main__":
    main()
