from __future__ import annotations

import argparse
import csv
import json
import random
import time
from pathlib import Path
from typing import Any

import requests


ISIC_IMAGE_API = "https://api.isic-archive.com/api/v2/images/{isic_id}"
DEFAULT_DATASET_DIR = Path("ml/dataset/pad_ufes_20")
DEFAULT_METADATA_PATH = DEFAULT_DATASET_DIR / "metadata.csv"
DEFAULT_SIZE_CACHE_PATH = DEFAULT_DATASET_DIR / "image_file_sizes.csv"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Prepare a small PAD-UFES-20 image download plan without downloading "
            "the image files."
        )
    )
    parser.add_argument("--metadata", type=Path, default=DEFAULT_METADATA_PATH)
    parser.add_argument("--size-cache", type=Path, default=DEFAULT_SIZE_CACHE_PATH)
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_DATASET_DIR / "download_plan_balanced.csv",
    )
    parser.add_argument(
        "--negative-per-class",
        type=int,
        default=52,
        help=(
            "Number of non-melanoma examples to include from each available "
            "PAD diagnosis class."
        ),
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for deterministic sampling.",
    )
    parser.add_argument(
        "--refresh-size-cache",
        action="store_true",
        help="Re-query ISIC file sizes even if a local cache already exists.",
    )
    parser.add_argument(
        "--estimate-selected-only",
        action="store_true",
        help=(
            "Fetch file sizes only for the planned balanced sample instead of "
            "the full PAD-UFES-20 collection."
        ),
    )
    return parser.parse_args()


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def load_size_cache(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}

    return {row["isic_id"]: row for row in load_csv(path)}


def fetch_image_info(
    session: requests.Session,
    isic_id: str,
    retries: int = 3,
) -> dict[str, Any]:
    url = ISIC_IMAGE_API.format(isic_id=isic_id)
    for attempt in range(1, retries + 1):
        try:
            response = session.get(url, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.RequestException:
            if attempt == retries:
                raise
            time.sleep(1.5 * attempt)

    raise RuntimeError(f"Unable to fetch ISIC image info for {isic_id}")


def build_or_update_size_cache(
    metadata_rows: list[dict[str, str]],
    cache_path: Path,
    refresh: bool,
) -> dict[str, dict[str, str]]:
    cached = {} if refresh else load_size_cache(cache_path)
    missing_ids = [
        row["isic_id"]
        for row in metadata_rows
        if row["isic_id"] and row["isic_id"] not in cached
    ]

    if missing_ids:
        print(f"Fetching file sizes for {len(missing_ids)} image record(s)...", flush=True)
        session = requests.Session()
        for index, isic_id in enumerate(missing_ids, start=1):
            info = fetch_image_info(session, isic_id)
            full = info.get("files", {}).get("full", {})
            cached[isic_id] = {
                "isic_id": isic_id,
                "full_url": str(full.get("url", "")),
                "full_size_bytes": str(int(full.get("size") or 0)),
            }
            if index % 100 == 0 or index == len(missing_ids):
                print(f"  {index}/{len(missing_ids)} size records fetched", flush=True)

        write_csv(
            cache_path,
            sorted(cached.values(), key=lambda row: row["isic_id"]),
            ["isic_id", "full_url", "full_size_bytes"],
        )
    else:
        print("Using cached ISIC image file sizes.", flush=True)

    return cached


def diagnosis_key(row: dict[str, str]) -> str:
    return row.get("diagnosis_3", "").strip() or "Unknown"


def binary_label(row: dict[str, str]) -> str:
    return "melanoma" if "melanoma" in diagnosis_key(row).lower() else "non_melanoma"


def select_balanced_rows(
    rows: list[dict[str, str]],
    negative_per_class: int,
    seed: int,
) -> list[dict[str, str]]:
    randomizer = random.Random(seed)
    melanoma_rows = [row for row in rows if binary_label(row) == "melanoma"]
    selected = list(melanoma_rows)

    negative_groups: dict[str, list[dict[str, str]]] = {}
    for row in rows:
        if binary_label(row) == "melanoma":
            continue
        negative_groups.setdefault(diagnosis_key(row), []).append(row)

    for diagnosis, group_rows in sorted(negative_groups.items()):
        shuffled = list(group_rows)
        randomizer.shuffle(shuffled)
        selected.extend(shuffled[:negative_per_class])
        print(
            f"Selected {min(len(shuffled), negative_per_class)} "
            f"non-melanoma image(s) from {diagnosis}.",
            flush=True,
        )

    return sorted(selected, key=lambda row: (binary_label(row), diagnosis_key(row), row["isic_id"]))


def enrich_plan_rows(
    rows: list[dict[str, str]],
    size_cache: dict[str, dict[str, str]],
) -> list[dict[str, Any]]:
    planned: list[dict[str, Any]] = []
    for row in rows:
        cached = size_cache.get(row["isic_id"], {})
        planned.append(
            {
                "isic_id": row["isic_id"],
                "binary_label": binary_label(row),
                "diagnosis_1": row.get("diagnosis_1", ""),
                "diagnosis_2": row.get("diagnosis_2", ""),
                "diagnosis_3": row.get("diagnosis_3", ""),
                "diagnosis_confirm_type": row.get("diagnosis_confirm_type", ""),
                "anatom_site_1": row.get("anatom_site_1", ""),
                "patient_id": row.get("patient_id", ""),
                "lesion_id": row.get("lesion_id", ""),
                "pixels_x": row.get("pixels_x", ""),
                "pixels_y": row.get("pixels_y", ""),
                "full_size_bytes": int(cached.get("full_size_bytes") or 0),
                "full_url": cached.get("full_url", ""),
            }
        )
    return planned


def bytes_to_mb(size_bytes: int) -> float:
    return size_bytes / 1024 / 1024


def main() -> None:
    args = parse_args()
    metadata_rows = load_csv(args.metadata)
    selected_rows = select_balanced_rows(
        rows=metadata_rows,
        negative_per_class=args.negative_per_class,
        seed=args.seed,
    )
    rows_for_size_lookup = selected_rows if args.estimate_selected_only else metadata_rows
    size_cache = build_or_update_size_cache(
        metadata_rows=rows_for_size_lookup,
        cache_path=args.size_cache,
        refresh=args.refresh_size_cache,
    )
    plan_rows = enrich_plan_rows(selected_rows, size_cache)
    write_csv(
        args.output,
        plan_rows,
        [
            "isic_id",
            "binary_label",
            "diagnosis_1",
            "diagnosis_2",
            "diagnosis_3",
            "diagnosis_confirm_type",
            "anatom_site_1",
            "patient_id",
            "lesion_id",
            "pixels_x",
            "pixels_y",
            "full_size_bytes",
            "full_url",
        ],
    )

    selected_size = sum(int(row["full_size_bytes"]) for row in plan_rows)
    class_counts: dict[str, int] = {}
    for row in plan_rows:
        label = f"{row['binary_label']} / {row['diagnosis_3']}"
        class_counts[label] = class_counts.get(label, 0) + 1

    summary = {
        "metadata_records": len(metadata_rows),
        "full_collection_estimated_images": (
            None if args.estimate_selected_only else len(metadata_rows)
        ),
        "full_collection_estimated_mb": (
            None
            if args.estimate_selected_only
            else round(
                bytes_to_mb(
                    sum(
                        int(size_cache.get(row["isic_id"], {}).get("full_size_bytes") or 0)
                        for row in metadata_rows
                    )
                ),
                2,
            )
        ),
        "planned_images": len(plan_rows),
        "planned_download_mb": round(bytes_to_mb(selected_size), 2),
        "plan_path": str(args.output),
        "size_cache_path": str(args.size_cache),
        "class_counts": class_counts,
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
