#!/usr/bin/env python3
"""
Convert Shri Dasbodh PDF into high-definition WebP images for Pothi Reader.
Source PDF: /Users/adityakaldhone/Downloads/Shri.Dasbodh.of.Shri.Samartha.Ramdas.Marathi.pdf
Output Dir: backend/data/pothi/dasbodh/
"""

import os
import sys
import time
from pathlib import Path
import pypdfium2 as pdfium

SOURCE_PDF = Path("/Users/adityakaldhone/Downloads/Shri.Dasbodh.of.Shri.Samartha.Ramdas.Marathi.pdf")
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "pothi" / "dasbodh"

def main():
    if not SOURCE_PDF.exists():
        print(f"Error: Source PDF not found at {SOURCE_PDF}")
        sys.exit(1)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Opening PDF: {SOURCE_PDF}")
    doc = pdfium.PdfDocument(str(SOURCE_PDF))
    total_pages = len(doc)
    print(f"Total pages: {total_pages}")
    print(f"Rendering to {OUTPUT_DIR} ...")

    t0 = time.time()
    for i in range(total_pages):
        page = doc[i]
        # scale=3.2 renders at ~764x1038, crystal clear for mobile pothi view
        image = page.render(scale=3.2).to_pil()
        target_path = OUTPUT_DIR / f"page_{i+1:04d}.webp"
        image.save(str(target_path), "WEBP", quality=78, method=4)
        if (i + 1) % 50 == 0 or (i + 1) == total_pages:
            elapsed = time.time() - t0
            print(f"Rendered {i+1}/{total_pages} pages ({elapsed:.1f}s)...")

    t1 = time.time()
    total_size = sum(f.stat().st_size for f in OUTPUT_DIR.glob("*.webp"))
    print(f"Conversion complete in {t1-t0:.1f}s!")
    print(f"Total files: {len(list(OUTPUT_DIR.glob('*.webp')))}")
    print(f"Total directory size: {total_size / (1024*1024):.1f} MB")

if __name__ == "__main__":
    main()
