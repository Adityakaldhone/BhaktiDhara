#!/usr/bin/env python3
"""
Render every Mahapurana PDF into one WebP image per page and upload them to R2,
so the app can open any page instantly instead of streaming a 15–75 MB PDF.

Layout in the bucket:
    puranas/pages/<slug>/0001.webp, 0002.webp, ...
    puranas/pages/<slug>/manifest.json   (written last; marks the book complete)

Multi-part books (Matsya, Brahmanda) are joined into one continuous page sequence.
Re-running is safe: pages already in the bucket are skipped.

Run this on the server (fast network), from the backend directory:
    pip install pypdfium2 pillow boto3 python-dotenv requests
    python scripts/build_purana_pages.py --db data/bhaktidhara.db
    python scripts/build_purana_pages.py --slug vishnu-purana --db data/bhaktidhara.db

Pages already uploaded? Only point the database at them (no rendering):
    python scripts/build_purana_pages.py --db-only --db data/bhaktidhara.db

Needs R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME and
R2_PUBLIC_URL in backend/.env.
"""

import argparse
import io
import json
import os
import sqlite3
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import boto3
import requests
from botocore.config import Config
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND_DIR / ".env")
sys.path.insert(0, str(Path(__file__).resolve().parent))

from upload_puranas_to_r2 import PURANAS_CATALOG  # noqa: E402

PAGES_PREFIX = "puranas/pages"
PAGE_WIDTH = 1100
WEBP_QUALITY = 62
CACHE_CONTROL = "public, max-age=31536000, immutable"


def env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        sys.exit(f"Missing {name} in backend/.env")
    return value


def r2_client():
    return boto3.client(
        "s3",
        endpoint_url=f"https://{env('R2_ACCOUNT_ID')}.r2.cloudflarestorage.com",
        aws_access_key_id=env("R2_ACCESS_KEY_ID"),
        aws_secret_access_key=env("R2_SECRET_ACCESS_KEY"),
        config=Config(signature_version="s3v4", max_pool_connections=32),
        region_name="auto",
    )


def existing_keys(s3, bucket: str, prefix: str) -> set:
    keys = set()
    for page in s3.get_paginator("list_objects_v2").paginate(Bucket=bucket, Prefix=prefix):
        keys.update(obj["Key"] for obj in page.get("Contents", []))
    return keys


def download(url: str, dest: Path) -> None:
    with requests.get(url, stream=True, timeout=60) as res:
        res.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in res.iter_content(chunk_size=1 << 20):
                f.write(chunk)


def source_pdfs(item: dict, public_url: str, workdir: Path) -> list:
    """Local paths of the book's PDF parts, downloading them from R2 if needed."""
    paths = []
    for name in [item["file"], *item.get("extra_files", [])]:
        local = Path(os.path.expanduser("~/Downloads")) / name
        if not local.exists():
            local = workdir / name
            if not local.exists():
                print(f"    downloading {name} ...")
                download(f"{public_url}/puranas/{requests.utils.quote(name)}", local)
        paths.append(local)
    return paths


def render_page(page, width: int, quality: int) -> tuple:
    scale = width / page.get_width()
    image = page.render(scale=scale).to_pil()
    if image.mode != "RGB":
        image = image.convert("RGB")
    buf = io.BytesIO()
    image.save(buf, "WEBP", quality=quality, method=4)
    return buf.getvalue(), image.width, image.height


def build_book(s3, bucket: str, public_url: str, item: dict, workdir: Path,
               width: int, quality: int, force: bool) -> dict:
    import pypdfium2 as pdfium

    slug = item["slug"]
    prefix = f"{PAGES_PREFIX}/{slug}"
    done = set() if force else existing_keys(s3, bucket, prefix + "/")

    pdfs = source_pdfs(item, public_url, workdir)
    total = sum(len(pdfium.PdfDocument(str(p))) for p in pdfs)
    print(f"  {slug}: {total} pages from {len(pdfs)} file(s), {len(done)} already uploaded")

    sizes = []
    uploaded_bytes = 0
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=16) as pool:
        futures = []
        number = 0
        for path in pdfs:
            doc = pdfium.PdfDocument(str(path))
            for i in range(len(doc)):
                number += 1
                key = f"{prefix}/{number:04d}.webp"
                page = doc[i]
                if key in done:
                    sizes.append([width, round(width * page.get_height() / page.get_width())])
                    continue
                data, w, h = render_page(page, width, quality)
                sizes.append([w, h])
                uploaded_bytes += len(data)
                futures.append(pool.submit(
                    s3.put_object, Bucket=bucket, Key=key, Body=data,
                    ContentType="image/webp", CacheControl=CACHE_CONTROL,
                ))
                if number % 100 == 0:
                    print(f"    {number}/{total} pages ({time.time() - t0:.0f}s)")
            doc.close()
        for f in futures:
            f.result()

    manifest = {
        "slug": slug,
        "pageCount": total,
        "width": width,
        "pageSizes": sizes,
        "generatedAt": int(time.time()),
    }
    s3.put_object(
        Bucket=bucket, Key=f"{prefix}/manifest.json",
        Body=json.dumps(manifest).encode(), ContentType="application/json",
        CacheControl="public, max-age=300",
    )
    print(f"  {slug}: done in {time.time() - t0:.0f}s, "
          f"{uploaded_bytes / 1048576:.1f} MB uploaded")
    return {"slug": slug, "page_count": total, "pages_base_url": f"{public_url}/{prefix}"}


def update_db(db_path: Path, results: list) -> None:
    con = sqlite3.connect(db_path)
    cols = {row[1] for row in con.execute("PRAGMA table_info(granth_books)")}
    if "page_count" not in cols:
        con.execute("ALTER TABLE granth_books ADD COLUMN page_count INTEGER DEFAULT 0")
    if "pages_base_url" not in cols:
        con.execute("ALTER TABLE granth_books ADD COLUMN pages_base_url TEXT")
    for r in results:
        con.execute(
            "UPDATE granth_books SET page_count = ?, pages_base_url = ? WHERE slug = ?",
            (r["page_count"], r["pages_base_url"], r["slug"]),
        )
    con.commit()
    con.close()
    print(f"Updated {len(results)} book(s) in {db_path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--slug", action="append", help="Only these books (repeatable)")
    parser.add_argument("--db", type=Path, help="SQLite DB to update with page_count / pages_base_url")
    parser.add_argument("--width", type=int, default=PAGE_WIDTH)
    parser.add_argument("--quality", type=int, default=WEBP_QUALITY)
    parser.add_argument("--force", action="store_true", help="Re-render pages that already exist")
    parser.add_argument("--db-only", action="store_true",
                        help="Skip rendering; fill --db from the manifests already in the bucket")
    args = parser.parse_args()

    items = [p for p in PURANAS_CATALOG if not args.slug or p["slug"] in args.slug]
    if not items:
        sys.exit("No matching books")

    public_url = env("R2_PUBLIC_URL").rstrip("/")
    if args.db_only:
        if not args.db:
            sys.exit("--db-only needs --db")
        results = []
        for item in items:
            base = f"{public_url}/{PAGES_PREFIX}/{item['slug']}"
            res = requests.get(f"{base}/manifest.json", timeout=30)
            if res.status_code != 200:
                print(f"  {item['slug']}: no manifest yet, skipped")
                continue
            results.append({
                "slug": item["slug"],
                "page_count": res.json()["pageCount"],
                "pages_base_url": base,
            })
        update_db(args.db, results)
        return

    bucket = env("R2_BUCKET_NAME")
    s3 = r2_client()

    results = []
    with tempfile.TemporaryDirectory(prefix="purana_pdfs_") as tmp:
        for item in items:
            print(f"\n📖 {item['title_en']}")
            results.append(build_book(
                s3, bucket, public_url, item, Path(tmp),
                args.width, args.quality, args.force,
            ))

    if args.db:
        update_db(args.db, results)
    else:
        print("\nNo --db given; set page_count / pages_base_url in granth_books yourself:")
        for r in results:
            print(f"  {r['slug']}: {r['page_count']} pages -> {r['pages_base_url']}")


if __name__ == "__main__":
    main()
