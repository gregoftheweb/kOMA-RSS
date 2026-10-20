"""Build the KDE Store widget archive without development files."""

import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parent.parent
plugin = json.loads((root / "metadata.json").read_text())["KPlugin"]
output = root / "dist" / f"{plugin['Id']}-{plugin['Version']}.plasmoid"
output.parent.mkdir(exist_ok=True)
files = [root / "metadata.json", root / "LICENSE"]
files.extend(
    p
    for p in (root / "contents").rglob("*")
    if p.is_file() and "__pycache__" not in p.parts and p.suffix != ".pyc"
)
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for path in sorted(files):
        archive.write(path, path.relative_to(root))
print(output)
