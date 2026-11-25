"""Mandir decisions. Values such as remaining ghee are resolved on the device."""
import json
from pathlib import Path

MANDIR_GUIDE = json.loads(Path(__file__).with_name("mandir_guide.json").read_text(encoding="utf-8"))
