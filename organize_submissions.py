#!/usr/bin/env python3
"""Normalize cached Godot Model Bench submissions.

The benchmark stores one cache directory per round and one model directory per
submission. This tool repairs source filenames from saved response files when
possible, removes stale source files from another round, and migrates the old
round-1 ``submissions/`` name to the canonical ``submissions_round1/`` name.

Run without arguments for a report. Use --apply to make the changes.
"""

import argparse
import os
from pathlib import Path

import run_bench

BASE = Path(__file__).resolve().parent
CANONICAL_ROUND1 = BASE / "submissions_round1"
OLD_ROUND1 = BASE / "submissions"


def round_root(round_num: int) -> Path:
    return CANONICAL_ROUND1 if round_num == 1 else BASE / f"submissions_round{round_num}"


def merge_round1_dirs(apply: bool) -> list[str]:
    messages: list[str] = []
    if not OLD_ROUND1.exists():
        return messages
    if not CANONICAL_ROUND1.exists():
        messages.append("migrate submissions -> submissions_round1")
        if apply:
            OLD_ROUND1.rename(CANONICAL_ROUND1)
        return messages

    for child in sorted(OLD_ROUND1.iterdir()):
        target = CANONICAL_ROUND1 / child.name
        messages.append(f"merge {child} -> {target}")
        if not apply:
            continue
        if child.is_dir() and target.is_dir():
            for item in child.iterdir():
                destination = target / item.name
                if destination.exists() and item.is_file() and destination.is_file():
                    # Keep the canonical copy if both trees contain the same
                    # named artifact; never overwrite cached responses.
                    if destination.read_bytes() == item.read_bytes():
                        item.unlink()
                    continue
                if not destination.exists():
                    item.rename(destination)
            child.rmdir()
        elif not target.exists():
            child.rename(target)
    if apply and OLD_ROUND1.exists() and not any(OLD_ROUND1.iterdir()):
        OLD_ROUND1.rmdir()
    return messages


def duplicate_round_roots() -> list[Path]:
    """Find legacy roots that duplicate the canonical round-1 root."""
    return [candidate for candidate in sorted(BASE.glob("submissions*"))
            if candidate.is_dir() and candidate.name == "submissions"]


def response_sources(model_dir: Path, expected: tuple[str, ...]) -> list[str]:
    run_bench.SUBMIT_FILES = expected
    for attempt in (2, 1):
        response_path = model_dir / f"attempt{attempt}_response.txt"
        if not response_path.is_file():
            continue
        try:
            sources, _fallback = run_bench.extract_files(response_path.read_text())
        except OSError:
            continue
        if len(sources) == len(expected) and all(source.strip() for source in sources):
            return sources
    return []


def has_expected_sources(model_dir: Path, expected: tuple[str, ...]) -> bool:
    return all(
        (model_dir / filename).is_file()
        and (model_dir / filename).read_text(errors="replace").strip()
        for filename in expected
    )


def normalize_round(round_num: int, apply: bool) -> dict[str, int]:
    _prompt, _runner, _unused, _live, expected, _tokens = run_bench.ROUNDS[round_num]
    root = round_root(round_num)
    stats = {"models": 0, "ready": 0, "repaired": 0, "removed": 0, "unavailable": 0}
    if not root.is_dir():
        return stats

    for model_dir in sorted(root.iterdir()):
        if not model_dir.is_dir() or model_dir.name == "reference":
            continue
        stats["models"] += 1
        sources = response_sources(model_dir, expected)
        ready = has_expected_sources(model_dir, expected)
        response_matches = ready and bool(sources) and all(
            (model_dir / filename).read_text(errors="replace") == source
            for filename, source in zip(expected, sources)
        )
        if sources and not response_matches:
            stats["repaired"] += 1
            if apply:
                for filename, source in zip(expected, sources):
                    (model_dir / filename).write_text(source)
            ready = True

        for source_path in sorted(model_dir.glob("*.gd")):
            if source_path.name not in expected:
                stats["removed"] += 1
                if apply:
                    source_path.unlink()

        if ready:
            stats["ready"] += 1
        else:
            stats["unavailable"] += 1
    return stats


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="apply migrations and repairs")
    args = parser.parse_args()

    mode = "Applying" if args.apply else "Plan"
    print(f"{mode} submission organization in {BASE}")
    for duplicate in duplicate_round_roots():
        print(f"  duplicate round root: {duplicate}")
    for message in merge_round1_dirs(args.apply):
        print(f"  {message}")

    for round_num in run_bench.ROUNDS:
        stats = normalize_round(round_num, args.apply)
        print(
            "  round %d: %d model dirs, %d ready, %d repaired, %d stale files removed, %d unavailable"
            % (
                round_num,
                stats["models"],
                stats["ready"],
                stats["repaired"],
                stats["removed"],
                stats["unavailable"],
            )
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

__all__ = ["main", "normalize_round", "round_root"]
