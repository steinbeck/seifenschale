#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build

render_part() {
    local name="$1"
    openscad -q -o "build/${name}.stl" \
        -D "mode=\"print\"" \
        -D "part=\"${name}\"" \
        seifenschale.scad
}

# Expected sizes (X Y Z) per part:
render_part wandhalterung
python3 tests/check_bbox.py build/wandhalterung.stl 110 98 60

render_part schale
python3 tests/check_bbox.py build/schale.stl 108 73 12

render_part gitter
python3 tests/check_bbox.py build/gitter.stl 97.6 62.6 6
