#!/usr/bin/env bash
set -euo pipefail
# Official upstream binaries only; same-version templates and SHA512 verification.
version=4.6.3
release="${version}-stable"
root="${1:?Provide a writable installation directory}"
mkdir -p "$root"
cd "$root"
url="https://github.com/godotengine/godot-builds/releases/download/$release"
binary="Godot_v${release}_linux.x86_64.zip"
templates="Godot_v${release}_export_templates.tpz"
for file in SHA512-SUMS.txt "$binary" "$templates"; do
  curl --fail --location --retry 3 --output "$file" "$url/$file"
done
python3 - "$binary" "$templates" <<'PY'
import hashlib, pathlib, sys
checks = {line.split()[-1].lstrip('*'): line.split()[0] for line in pathlib.Path('SHA512-SUMS.txt').read_text().splitlines() if line.strip()}
for name in sys.argv[1:]:
    digest = hashlib.sha512()
    with open(name, 'rb') as source:
        for block in iter(lambda: source.read(8 * 1024 * 1024), b''):
            digest.update(block)
    if digest.hexdigest() != checks[name]:
        raise SystemExit('SHA512 mismatch: ' + name)
PY
unzip -o "$binary"
mv "Godot_v${release}_linux.x86_64" godot
chmod +x godot
template_dir="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${version}.stable"
mkdir -p "$template_dir"
python3 - "$templates" "$template_dir" <<'PY'
import pathlib, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in ['web_nothreads_debug.zip', 'web_nothreads_release.zip']:
        pathlib.Path(sys.argv[2], name).write_bytes(archive.read('templates/' + name))
PY
./godot --version
