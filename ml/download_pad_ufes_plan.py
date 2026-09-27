from __future__ import annotations

import argparse
import csv
from pathlib import Path

import requests


DEFAULT_DATASET_DIR = Path("ml/dataset/pad_ufes_20")
DEFAULT_PLAN_PATH = DEFAULT_DATASET_DIR / "download_plan_balanced.csv"
DEFAULT_OUT_DIR = DEFAULT_DATASET_DIR / "selected_images"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download only the PAD-UFES-20 images listed in a plan CSV."
    )
    parser.add_argument("--plan", type=Path, default=DEFAULT_PLAN_PATH)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    parser.add_argument(
        "--max-mb",
        type=float,
        default=1000.0,
        help="Hard safety limit for planned image download size.",
    )
    return parser.parse_args()


def load_plan(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))


def bytes_to_mb(size_bytes: int) -> float:
    return size_bytes / 1024 / 1024


def image_extension(url: str) -> str:
    suffix = Path(url.split("?", 1)[0]).suffix
    return suffix if suffix else ".jpg"


def download_file(session: requests.Session, url: str, output_path: Path) -> int:
    with session.get(url, stream=True, timeout=60) as response:
        response.raise_for_status()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        bytes_written = 0
        with output_path.open("wb") as file:
            for chunk in response.iter_content(chunk_size=1024 * 256):
                if not chunk:
                    continue
                file.write(chunk)
                bytes_written += len(chunk)
        return bytes_written


def main() -> None:
    args = parse_args()
    rows = load_plan(args.plan)
    planned_bytes = sum(int(row.get("full_size_bytes") or 0) for row in rows)
    planned_mb = bytes_to_mb(planned_bytes)

    if planned_mb > args.max_mb:
        raise SystemExit(
            f"Refusing to download {planned_mb:.2f} MB because it exceeds "
            f"the configured {args.max_mb:.2f} MB limit."
        )

    print(
        f"Downloading {len(rows)} planned image(s), estimated {planned_mb:.2f} MB.",
        flush=True,
    )

    session = requests.Session()
    downloaded_count = 0
    skipped_count = 0
    downloaded_bytes = 0

    for index, row in enumerate(rows, start=1):
        isic_id = row["isic_id"]
        url = row["full_url"]
        diagnosis = row["diagnosis_3"].replace("/", "-").replace("\\", "-")
        label = row["binary_label"]
        output_path = (
            args.out_dir
            / label
            / diagnosis
            / f"{isic_id}{image_extension(url)}"
        )

        if output_path.exists() and output_path.stat().st_size > 0:
            skipped_count += 1
        else:
            downloaded_bytes += download_file(session, url, output_path)
            downloaded_count += 1

        if index % 25 == 0 or index == len(rows):
            print(f"  {index}/{len(rows)} processed", flush=True)

    print(
        "Completed PAD-UFES-20 selected image download: "
        f"{downloaded_count} downloaded, {skipped_count} skipped, "
        f"{bytes_to_mb(downloaded_bytes):.2f} MB newly downloaded.",
        flush=True,
    )


if __name__ == "__main__":
    main()
