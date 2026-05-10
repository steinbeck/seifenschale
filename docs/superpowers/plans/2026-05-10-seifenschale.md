# Seifenschale Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single-source OpenSCAD model (`seifenschale.scad`) for a wall-mounted three-part soap dish, with a Makefile that produces three render PNGs (assembled, explosion, print) and four STLs (three individual parts plus a combined print layout), packaged in a public MIT-licensed GitHub repo.

**Architecture:** One `.scad` file with three modules (`wandhalterung`, `schale`, `gitter`) plus one print-pose wrapper (`gitter_print`). Two top-level Customizer variables (`mode` ∈ {assembled, explosion, print}, `part` ∈ {all, wandhalterung, schale, gitter}) drive what gets rendered. A Makefile invokes `openscad` once per output, passing the right variable values via `-D`. STL bounding boxes are verified by a self-contained Python script (no third-party libraries).

**Tech Stack:** OpenSCAD 2025.11.10 (already installed at `/opt/homebrew/bin/openscad`), GNU Make, Python 3 (stdlib only — `struct` for STL parsing), `gh` CLI for GitHub.

**Spec reference:** `docs/superpowers/specs/2026-05-10-seifenschale-design.md`

---

## File Structure

| File | Responsibility |
|---|---|
| `seifenschale.scad` | Single source — all geometry, all modules, mode/part dispatch |
| `Makefile` | Build all PNGs and STLs reproducibly |
| `tests/check_bbox.py` | Verify exported STL bounding-box matches expected dimensions |
| `tests/run_checks.sh` | Run all bbox checks for the three parts |
| `README.md` | Project description, embedded renders, print instructions |
| `LICENSE` | MIT |
| `.gitignore` | Already exists; ignores `build/` and editor lock files |

---

## Task 1: Repo skeleton (LICENSE, README stub, empty .scad, test scaffold)

**Files:**
- Create: `LICENSE`
- Create: `README.md`
- Create: `seifenschale.scad`
- Create: `tests/check_bbox.py`
- Create: `tests/run_checks.sh`

- [ ] **Step 1: Create MIT LICENSE**

Write to `LICENSE`:

```
MIT License

Copyright (c) 2026 Christoph Steinbeck

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Create README stub**

Write to `README.md`:

```markdown
# Seifenschale

Wandmontierte 3D-druckbare Seifenschale mit Tesa-Powerstrip-Halterung. Drei Teile: Wandhalterung, Schale, Abtropfgitter. PLA, FDM, 0,2 mm Layer.

Build: `make`. Mehr Details folgen.
```

- [ ] **Step 3: Create empty seifenschale.scad with header comment**

Write to `seifenschale.scad`:

```openscad
// seifenschale — wandmontierte 3D-druckbare Seifenschale
// Spec: docs/superpowers/specs/2026-05-10-seifenschale-design.md

// --- Customizer ---
mode = "assembled";  // [assembled, explosion, print]
part = "all";        // [all, wandhalterung, schale, gitter]
$fn = 64;
```

- [ ] **Step 4: Create tests/check_bbox.py**

Write to `tests/check_bbox.py`:

```python
#!/usr/bin/env python3
"""Verify STL bounding-box dimensions against expected size.

Usage:
    check_bbox.py PATH X Y Z [TOL]

Reads a binary STL, computes its axis-aligned bounding box, and
compares the size (max-min on each axis) to expected X/Y/Z within TOL
(default 0.1 mm). Exits 0 on PASS, 1 on FAIL.
"""
import struct
import sys


def stl_bbox(path):
    with open(path, "rb") as f:
        f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        mins = [float("inf")] * 3
        maxs = [float("-inf")] * 3
        for _ in range(n):
            f.read(12)
            for _ in range(3):
                v = struct.unpack("<3f", f.read(12))
                for i in range(3):
                    if v[i] < mins[i]:
                        mins[i] = v[i]
                    if v[i] > maxs[i]:
                        maxs[i] = v[i]
            f.read(2)
    return mins, maxs


def main():
    path = sys.argv[1]
    expected = [float(x) for x in sys.argv[2:5]]
    tol = float(sys.argv[5]) if len(sys.argv) > 5 else 0.1
    mins, maxs = stl_bbox(path)
    size = [maxs[i] - mins[i] for i in range(3)]
    print(f"{path}: size = {size[0]:.3f} x {size[1]:.3f} x {size[2]:.3f}")
    fail = False
    for i, (s, e) in enumerate(zip(size, expected)):
        axis = "XYZ"[i]
        if abs(s - e) > tol:
            print(f"  FAIL {axis}: got {s:.3f}, expected {e:.3f} +/- {tol}")
            fail = True
    if fail:
        sys.exit(1)
    print("  PASS")


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: Create tests/run_checks.sh**

Write to `tests/run_checks.sh`:

```bash
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
```

Make it executable:

```bash
chmod +x tests/run_checks.sh
```

- [ ] **Step 6: Verify nothing breaks (no module body yet — tests will fail, that's OK at this point)**

Run:
```bash
openscad -q -o /tmp/empty.stl -D 'mode="print"' -D 'part="wandhalterung"' seifenschale.scad 2>&1 | head -5
```
Expected: a warning like "Current top level object is not a 3D object" (no geometry yet) — but no syntax error. STL may be empty or absent. This confirms the file parses.

- [ ] **Step 7: Commit**

```bash
git add LICENSE README.md seifenschale.scad tests/check_bbox.py tests/run_checks.sh
git commit -m "Add repo skeleton: LICENSE, README stub, empty .scad, bbox check script

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Geometry constants

**Files:**
- Modify: `seifenschale.scad` (append after the Customizer block)

- [ ] **Step 1: Append all geometry constants to seifenschale.scad**

Append to `seifenschale.scad` (after the existing Customizer block):

```openscad
// --- Geometry constants (mm) ---

// Wandhalterung
wandplatte_x = 30;
wandplatte_y = 3;
wandplatte_z = 60;

steg_x = 12;
steg_y = 20;
steg_z = 12;

rahmen_x = 110;
rahmen_y = 75;
rahmen_z = 12;
rahmen_wand = 4;

// Powerstrip (informational — geometry has no recess)
powerstrip_kleb_x = 50;
powerstrip_kleb_y = 20;

// Tolerances
clearance_schale = 0.3;
clearance_gitter = 0.3;

// Schale
rahmen_innen_x = rahmen_x - 2 * rahmen_wand;             // 102
rahmen_innen_y = rahmen_y - 2 * rahmen_wand;             // 67
schale_koerper_x = rahmen_innen_x - 2 * clearance_schale; // 101.4
schale_koerper_y = rahmen_innen_y - 2 * clearance_schale; // 66.4
schale_krempe_ueberlapp = 3;
schale_krempe_x = rahmen_innen_x + 2 * schale_krempe_ueberlapp; // 108
schale_krempe_y = rahmen_innen_y + 2 * schale_krempe_ueberlapp; // 73
schale_krempe_dick = 2;
schale_tief = 10;
schale_wand = 1.6;
schale_boden = 1.6;
schale_innen_radius = 2;

// Gitter
schale_innen_x = schale_koerper_x - 2 * schale_wand;  // 98.2
schale_innen_y = schale_koerper_y - 2 * schale_wand;  // 63.2
gitter_x = schale_innen_x - 2 * clearance_gitter;     // 97.6
gitter_y = schale_innen_y - 2 * clearance_gitter;     // 62.6
gitter_stab_breit = 4;
gitter_stab_hoch = 4;
gitter_fuss_hoch = 2;
gitter_quer_hoch = 1.6;
gitter_total_height = gitter_fuss_hoch + gitter_stab_hoch;  // 6
```

- [ ] **Step 2: Verify file still parses**

Run:
```bash
openscad -q -o /tmp/empty.stl -D 'mode="print"' -D 'part="wandhalterung"' seifenschale.scad 2>&1 | head -5
```
Expected: same "no 3D object" warning, no syntax errors.

- [ ] **Step 3: Commit**

```bash
git add seifenschale.scad
git commit -m "Add geometry constants for all three parts

Constants are derived from each other where appropriate (e.g. schale
körper from rahmen_innen minus clearance) so changing one base
dimension cascades correctly.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Wandhalterung module

**Files:**
- Modify: `seifenschale.scad`
- Test: `tests/run_checks.sh` (already created in Task 1)

The Wandhalterung consists of three pieces fused into one solid: a hollow rectangular frame (open top + bottom — a four-walled chimney), a solid connecting post (Steg) at the back-center bottom of the frame, and the wall plate (Wandplatte) attached to the back face of the Steg. The model origin is the center of the rear edge of the frame, at z=0. The frame extends in +Y forward, the Steg in -Y, the Wandplatte further in -Y. All three pieces have their bottom face at z=0.

Expected final bounding box: **X = 110, Y = 98, Z = 60**.
- X: rahmen spans -55 to +55 (rahmen_x = 110)
- Y: -wandplatte_y - steg_y = -23 to +rahmen_y = +75 → 98
- Z: 0 to wandplatte_z = 60

- [ ] **Step 1: Append wandhalterung module to seifenschale.scad**

Append:

```openscad
// --- Module: Wandhalterung ---
// Origin: center of rear edge of frame, z=0.
// Frame extends +Y, Steg and Wandplatte extend -Y.
module wandhalterung() {
    // Rahmen: hollow vertical chimney, 4 walls
    difference() {
        translate([-rahmen_x / 2, 0, 0])
            cube([rahmen_x, rahmen_y, rahmen_z]);
        translate([
            -rahmen_x / 2 + rahmen_wand,
            rahmen_wand,
            -0.1
        ])
            cube([
                rahmen_x - 2 * rahmen_wand,
                rahmen_y - 2 * rahmen_wand,
                rahmen_z + 0.2
            ]);
    }

    // Steg: solid block from rear edge of frame backward to wall plate
    translate([-steg_x / 2, -steg_y, 0])
        cube([steg_x, steg_y, steg_z]);

    // Wandplatte: thin plate at the back, rises from z=0 to z=wandplatte_z
    translate([-wandplatte_x / 2, -steg_y - wandplatte_y, 0])
        cube([wandplatte_x, wandplatte_y, wandplatte_z]);
}
```

- [ ] **Step 2: Add a temporary preview line so the module renders standalone**

Append at the very end of `seifenschale.scad` (this will be replaced in Task 6 by the mode dispatcher):

```openscad
// --- temporary preview (Task 3) — will be replaced by mode dispatcher ---
wandhalterung();
```

- [ ] **Step 3: Render and check bounding box**

Run:
```bash
mkdir -p build
openscad -q -o build/wandhalterung.stl seifenschale.scad
python3 tests/check_bbox.py build/wandhalterung.stl 110 98 60
```
Expected output:
```
build/wandhalterung.stl: size = 110.000 x 98.000 x 60.000
  PASS
```

- [ ] **Step 4: Visual sanity render**

Run:
```bash
openscad -q -o build/wandhalterung-preview.png \
    --imgsize=800,600 --colorscheme=Tomorrow seifenschale.scad
```
Open `build/wandhalterung-preview.png` and confirm: a vertical wall plate at the back, a small connecting post, and a horizontal frame extending forward — all sitting on z=0.

- [ ] **Step 5: Commit**

```bash
git add seifenschale.scad
git commit -m "Add wandhalterung module (wall plate + steg + frame)

All three pieces share their bottom face at z=0 so the part prints
in its in-use pose without supports.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Schale module

**Files:**
- Modify: `seifenschale.scad`

The Schale is a flat dish with a 2 mm rim (Krempe) at the top. The rim overhangs the dish body by 3.3 mm per side and rests on top of the frame. Inner corners are rounded (r = 2 mm) for cleaning. Origin: center of dish in X/Y, z=0 = outside bottom (= what touches the printer bed in print pose).

Expected bounding box: **X = 108, Y = 73, Z = 12** (Krempe outer dimensions × Schale-Tiefe).

- [ ] **Step 1: Replace the temporary preview line and append schale module**

In `seifenschale.scad`:

Remove the line:
```openscad
wandhalterung();
```

Append:

```openscad
// --- Module: Schale ---
// Origin: center of dish in X/Y, z=0 = outside bottom of dish.
// Krempe (rim) sits at z = schale_tief.
module schale() {
    // Body (outer) minus inner cavity with rounded inner corners
    difference() {
        translate([-schale_koerper_x / 2, -schale_koerper_y / 2, 0])
            cube([schale_koerper_x, schale_koerper_y, schale_tief]);
        schalen_innenraum();
    }
    // Krempe (rim)
    translate([-schale_krempe_x / 2, -schale_krempe_y / 2, schale_tief])
        cube([schale_krempe_x, schale_krempe_y, schale_krempe_dick]);
}

module schalen_innenraum() {
    r = schale_innen_radius;
    inner_x = schale_koerper_x - 2 * schale_wand;
    inner_y = schale_koerper_y - 2 * schale_wand;
    inner_z = schale_tief - schale_boden + 0.1;
    translate([0, 0, schale_boden])
        hull() {
            for (sx = [-1, 1], sy = [-1, 1])
                translate([
                    sx * (inner_x / 2 - r),
                    sy * (inner_y / 2 - r),
                    0
                ])
                    cylinder(h=inner_z, r=r);
        }
}
```

Add a temporary preview at the end:

```openscad
// --- temporary preview (Task 4) ---
schale();
```

- [ ] **Step 2: Render and check bounding box**

Run:
```bash
openscad -q -o build/schale.stl seifenschale.scad
python3 tests/check_bbox.py build/schale.stl 108 73 12
```
Expected:
```
build/schale.stl: size = 108.000 x 73.000 x 12.000
  PASS
```

- [ ] **Step 3: Visual sanity render**

Run:
```bash
openscad -q -o build/schale-preview.png \
    --imgsize=800,600 --colorscheme=Tomorrow seifenschale.scad
```
Open `build/schale-preview.png`. Confirm: a shallow rectangular dish with a thin rim around the top, rounded inner corners visible from above.

- [ ] **Step 4: Commit**

```bash
git add seifenschale.scad
git commit -m "Add schale module (dish body + rim with rounded inner corners)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Gitter module + print-pose wrapper

**Files:**
- Modify: `seifenschale.scad`

The Gitter consists of parallel longitudinal bars (entlang X-Achse), two thin cross-connectors at the X-ends (oben), and four small feet in the corners (unten). In Einbau-Pose, feet point down at z=0 and bars span z=2..6. Origin: center of grate in X/Y, z=0 = bottom of feet.

`gitter_print()` flips the grate 180° around X so the feet point upward → no support needed when printing.

Expected bounding box (in Einbau-Pose): **X = 97.6, Y = 62.6, Z = 6**.

The number of bars is computed so that bars and gaps split the available Y span evenly: 4 mm bar + ~4 mm gap, anchored so the first and last bars sit at y = ±gitter_y/2.

- [ ] **Step 1: Replace the temporary preview and append gitter modules**

In `seifenschale.scad`:

Remove:
```openscad
schale();
```

Append:

```openscad
// --- Module: Gitter ---
// Origin: center of grate in X/Y, z=0 = bottom of feet (Einbau-Pose).
module gitter() {
    // Bar pitch is chosen so the outermost bars sit flush with y = ±gitter_y/2
    // and the gap between bars is approximately 4 mm.
    n_staebe = floor((gitter_y - gitter_stab_breit) / (gitter_stab_breit + 4)) + 1;
    pitch = (gitter_y - gitter_stab_breit) / (n_staebe - 1);

    z_stab_unten = gitter_fuss_hoch;

    // Längsstäbe
    for (i = [0 : n_staebe - 1]) {
        y_center = -gitter_y / 2 + gitter_stab_breit / 2 + i * pitch;
        translate([
            -gitter_x / 2,
            y_center - gitter_stab_breit / 2,
            z_stab_unten
        ])
            cube([gitter_x, gitter_stab_breit, gitter_stab_hoch]);
    }

    // Querverbinder: thin strips at top, at both X-ends, spanning full Y
    z_quer_unten = z_stab_unten + gitter_stab_hoch - gitter_quer_hoch;
    for (sx = [-1, 1]) {
        x = sx * gitter_x / 2 - (sx > 0 ? gitter_stab_breit : 0);
        translate([x, -gitter_y / 2, z_quer_unten])
            cube([gitter_stab_breit, gitter_y, gitter_quer_hoch]);
    }

    // Füßchen: 4 corner cubes
    for (sx = [-1, 1], sy = [-1, 1]) {
        x = sx * gitter_x / 2 - (sx > 0 ? gitter_stab_breit : 0);
        y = sy * gitter_y / 2 - (sy > 0 ? gitter_stab_breit : 0);
        translate([x, y, 0])
            cube([gitter_stab_breit, gitter_stab_breit, gitter_fuss_hoch]);
    }
}

// Print pose: flipped so feet point up — no support needed
module gitter_print() {
    translate([0, 0, gitter_total_height])
        rotate([180, 0, 0])
            gitter();
}
```

Add a temporary preview at the end:

```openscad
// --- temporary preview (Task 5) ---
gitter();
```

- [ ] **Step 2: Render in Einbau-Pose and check bounding box**

Run:
```bash
openscad -q -o build/gitter.stl seifenschale.scad
python3 tests/check_bbox.py build/gitter.stl 97.6 62.6 6
```
Expected:
```
build/gitter.stl: size = 97.600 x 62.600 x 6.000
  PASS
```

- [ ] **Step 3: Render in print pose and verify it has the same XY bbox and same Z height**

Replace the preview line at the end of the file with:
```openscad
gitter_print();
```

Run:
```bash
openscad -q -o build/gitter-print.stl seifenschale.scad
python3 tests/check_bbox.py build/gitter-print.stl 97.6 62.6 6
```
Expected: PASS (same overall size — just flipped).

Then put the preview back to `gitter();` (Einbau-Pose) before continuing.

- [ ] **Step 4: Visual sanity render**

Run:
```bash
openscad -q -o build/gitter-preview.png \
    --imgsize=800,600 --colorscheme=Tomorrow seifenschale.scad
```
Open `build/gitter-preview.png`. Confirm: parallel bars with visible gaps, two end-cap strips, four corner feet underneath.

- [ ] **Step 5: Commit**

```bash
git add seifenschale.scad
git commit -m "Add gitter module + gitter_print wrapper

Bar count is derived from total Y so changing dimensions stays
consistent. gitter_print flips the grate so feet point up — no
support material needed during printing.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Mode dispatcher (assembled / explosion / print)

**Files:**
- Modify: `seifenschale.scad`

Replace the temporary preview at the bottom of the file with the full mode dispatcher. The assembly geometry uses derived offsets:

- `schale_y_offset = rahmen_y / 2` → 37.5 (Schale center on frame center)
- `schale_z_offset = rahmen_z - schale_tief` → 2 (Schale rim sits at z=12, top of frame)
- `gitter_y_offset = rahmen_y / 2` → 37.5
- `gitter_z_offset = schale_z_offset + schale_boden` → 3.6 (Gitter feet rest on inside bottom of dish)

For the `print` mode, `part="all"` lays the three pieces out in a row at X = -130, 0, +130 (≈330 mm total — wider than most beds, but the individual STLs are also exported by the Makefile for slicing one part at a time). When `part` selects a single part, it renders at the origin (no offset).

- [ ] **Step 1: Remove the temporary preview line**

Remove from end of `seifenschale.scad`:
```openscad
// --- temporary preview (Task 5) ---
gitter();
```

- [ ] **Step 2: Append assembly offsets and mode dispatcher**

Append:

```openscad
// --- Assembly offsets (in wandhalterung coordinates) ---
schale_y_offset = rahmen_y / 2;                  // 37.5
schale_z_offset = rahmen_z - schale_tief;        // 2
gitter_y_offset = rahmen_y / 2;                  // 37.5
gitter_z_offset = schale_z_offset + schale_boden; // 3.6

explosion_lift_schale = 30;
explosion_lift_gitter = 60;

print_x_offset = 130;

// --- Mode dispatcher ---
if (mode == "assembled") {
    wandhalterung();
    translate([0, schale_y_offset, schale_z_offset]) schale();
    translate([0, gitter_y_offset, gitter_z_offset]) gitter();
}
else if (mode == "explosion") {
    wandhalterung();
    translate([0, schale_y_offset, schale_z_offset + explosion_lift_schale])
        schale();
    translate([0, gitter_y_offset, gitter_z_offset + explosion_lift_gitter])
        gitter();
}
else if (mode == "print") {
    if (part == "all") {
        translate([-print_x_offset, 0, 0]) wandhalterung();
        translate([0, 0, 0]) schale();
        translate([+print_x_offset, 0, 0]) gitter_print();
    }
    else if (part == "wandhalterung") wandhalterung();
    else if (part == "schale")        schale();
    else if (part == "gitter")        gitter_print();
}
```

- [ ] **Step 3: Verify each individual `print`-mode part still has the right bbox**

Run:
```bash
bash tests/run_checks.sh
```
Expected output (three PASS lines):
```
build/wandhalterung.stl: size = 110.000 x 98.000 x 60.000
  PASS
build/schale.stl: size = 108.000 x 73.000 x 12.000
  PASS
build/gitter.stl: size = 97.600 x 62.600 x 6.000
  PASS
```

- [ ] **Step 4: Render assembled view and inspect**

Run:
```bash
openscad -q -o build/assembled.png \
    -D 'mode="assembled"' \
    --imgsize=1200,900 --colorscheme=Tomorrow \
    --camera=0,30,30,60,0,30,400 seifenschale.scad
```
Open `build/assembled.png`. Confirm: wandhalterung visible with frame extending forward, schale sitting on the frame, gitter visible inside the schale. Nothing floating, nothing intersecting.

- [ ] **Step 5: Render explosion view**

Run:
```bash
openscad -q -o build/explosion.png \
    -D 'mode="explosion"' \
    --imgsize=1200,900 --colorscheme=Tomorrow \
    --camera=0,30,60,60,0,30,500 seifenschale.scad
```
Open `build/explosion.png`. Confirm: three parts visibly separated in Z, with the schale ~30 mm above the frame and the gitter another ~30 mm above that.

- [ ] **Step 6: Render print layout**

Run:
```bash
openscad -q -o build/print.png \
    -D 'mode="print"' \
    --imgsize=1200,900 --colorscheme=Tomorrow \
    --camera=0,40,200,0,0,0,500 seifenschale.scad
```
Open `build/print.png`. Confirm: three parts laid out side-by-side on z=0 (wandhalterung left, schale center, gitter right with feet pointing up).

- [ ] **Step 7: Commit**

```bash
git add seifenschale.scad
git commit -m "Wire up assembled/explosion/print mode dispatcher

assembled and explosion use the natural in-use pose. print mode lays
the three parts side-by-side on z=0; with part != all, the selected
part renders at the origin for clean single-part STL export.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Makefile

**Files:**
- Create: `Makefile`

The Makefile defines explicit targets for each build artifact, all derived from the single `seifenschale.scad` source. Render PNGs use a fixed camera so subsequent re-renders are visually consistent.

- [ ] **Step 1: Create Makefile**

Write to `Makefile`:

```make
SCAD       := seifenschale.scad
OPENSCAD   := openscad
BUILD      := build
IMG_SIZE   := 1200,900
COLORSCHEME := Tomorrow

CAM_ASSEMBLED := 0,30,30,60,0,30,400
CAM_EXPLOSION := 0,30,60,60,0,30,500
CAM_PRINT     := 0,40,200,0,0,0,500

RENDERS := $(BUILD)/assembled.png $(BUILD)/explosion.png $(BUILD)/print.png
STLS    := $(BUILD)/wandhalterung.stl $(BUILD)/schale.stl $(BUILD)/gitter.stl $(BUILD)/print.stl

.PHONY: all renders stls clean check
all: renders stls

renders: $(RENDERS)
stls:    $(STLS)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/assembled.png: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ \
		-D 'mode="assembled"' \
		--imgsize=$(IMG_SIZE) --colorscheme=$(COLORSCHEME) \
		--camera=$(CAM_ASSEMBLED) $<

$(BUILD)/explosion.png: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ \
		-D 'mode="explosion"' \
		--imgsize=$(IMG_SIZE) --colorscheme=$(COLORSCHEME) \
		--camera=$(CAM_EXPLOSION) $<

$(BUILD)/print.png: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ \
		-D 'mode="print"' \
		--imgsize=$(IMG_SIZE) --colorscheme=$(COLORSCHEME) \
		--camera=$(CAM_PRINT) $<

$(BUILD)/wandhalterung.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ -D 'mode="print"' -D 'part="wandhalterung"' $<

$(BUILD)/schale.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ -D 'mode="print"' -D 'part="schale"' $<

$(BUILD)/gitter.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ -D 'mode="print"' -D 'part="gitter"' $<

$(BUILD)/print.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ -D 'mode="print"' -D 'part="all"' $<

check: stls
	bash tests/run_checks.sh

clean:
	rm -rf $(BUILD)
```

- [ ] **Step 2: Run full build**

Run:
```bash
make clean && make
```
Expected: 7 OpenSCAD invocations succeed (3 PNGs + 4 STLs), no errors.

- [ ] **Step 3: Run check target**

Run:
```bash
make check
```
Expected: 3 PASS lines.

- [ ] **Step 4: Sanity-open the PNGs**

Run:
```bash
ls -la build/
```
Verify all 7 artifacts are present and the PNGs are non-trivially sized (>10 KB).

- [ ] **Step 5: Commit**

```bash
git add Makefile
git commit -m "Add Makefile with renders, stls, check, and clean targets

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: README with embedded renders

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace README with full content**

Overwrite `README.md`:

````markdown
# Seifenschale

Wandmontierte 3D-druckbare Seifenschale aus drei Teilen, geklebt mit einem Tesa-Powerstrip Large an Badezimmerfliesen. Schale und Abtropfgitter sind herausnehmbar zum Reinigen.

![Zusammengebaut](build/assembled.png)

## Teile

![Explosionsdarstellung](build/explosion.png)

1. **Wandhalterung** — Wandplatte mit Klebefläche für den Powerstrip, Steg, offener Rahmen.
2. **Schale** — flache Wanne mit Krempenrand. Liegt von oben auf dem Rahmen auf.
3. **Abtropfgitter** — Längsstabgitter mit vier Füßchen, hält die Seife mit 2 mm Luftspalt über dem Schalenboden.

## Druckhinweise

- **Filament:** PLA
- **Layer-Höhe:** 0,2 mm
- **Düse:** 0,4 mm
- **Brim:** für die Wandhalterung empfohlen (schmale Wandplatten-Auflage)
- **Support:** nicht nötig — alle Teile sind so designed, dass sie support-frei drucken
- **Gitter:** wird **kopfüber** gedruckt — die exportierte `gitter.stl` enthält bereits die richtige Pose

![Druck-Layout](build/print.png)

Die kombinierte `print.stl` legt alle drei Teile nebeneinander (~330 mm gesamt). Für Druckbetten kleiner als 350 mm pro Teil eine eigene Datei verwenden (`wandhalterung.stl`, `schale.stl`, `gitter.stl`).

## Bauen

```bash
make            # alle Renderings + alle STLs
make renders    # nur die 3 PNGs
make stls       # nur die 4 STLs
make check      # Bounding-Box-Prüfung
make clean      # build/ löschen
```

## Anpassen

Alle Maße sind als benannte Konstanten am Anfang von `seifenschale.scad` definiert. Tesa-Powerstrip-Größe, Schalenmaß, Wandstärken und Toleranzen können dort einzeln angepasst werden — abgeleitete Maße (z.B. Krempenrand, Schalen-Innenmaß, Gitter-Außenmaß) ziehen sich automatisch nach.

OpenSCAD-Customizer unterstützt zwei Top-Level-Variablen:

- `mode` — `assembled`, `explosion`, oder `print`
- `part` — `all`, `wandhalterung`, `schale`, oder `gitter` (nur im Print-Mode relevant)

## Lizenz

MIT — siehe [LICENSE](LICENSE).
````

- [ ] **Step 2: Verify renders are present (so README images resolve locally)**

Run:
```bash
ls build/assembled.png build/explosion.png build/print.png
```
Expected: all three exist. If not, run `make renders` first.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Flesh out README with embedded renders, print instructions, and build doc

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Create public GitHub repo and push

**Files:** none

- [ ] **Step 1: Verify gh authentication**

Run:
```bash
gh auth status
```
Expected: logged in as `steinbeck`.

- [ ] **Step 2: Create public repo and push**

Run:
```bash
gh repo create steinbeck/seifenschale \
    --public \
    --description "Wall-mounted 3D-printable soap dish in OpenSCAD (three parts: wall mount, dish, drain grate)" \
    --source=. \
    --remote=origin \
    --push
```
Expected: a GitHub URL in the output, e.g. `https://github.com/steinbeck/seifenschale`.

- [ ] **Step 3: Verify the repo exists and is public**

Run:
```bash
gh repo view steinbeck/seifenschale --json url,visibility,description
```
Expected: visibility = `PUBLIC`, URL printed.

- [ ] **Step 4: Verify renders show up correctly on GitHub**

Open the printed URL in a browser. Confirm: README displays, the three embedded PNGs render (they need to be tracked in Git for that — they are, because `.gitignore` only excludes `build/`, but the renders ARE in `build/`).

If renders don't appear (likely — `build/` is gitignored, so `build/*.png` are not on GitHub):

  a. Move the README's PNG references to a tracked location:

  Run:
  ```bash
  mkdir -p docs/img
  cp build/assembled.png build/explosion.png build/print.png docs/img/
  ```

  b. Update README image paths from `build/` to `docs/img/`:

  Edit `README.md` and replace:
  - `build/assembled.png` → `docs/img/assembled.png`
  - `build/explosion.png` → `docs/img/explosion.png`
  - `build/print.png` → `docs/img/print.png`

  c. Commit and push:
  ```bash
  git add docs/img/ README.md
  git commit -m "Move render PNGs into tracked docs/img/ for GitHub display

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
  git push
  ```

  d. Reload the GitHub page and confirm renders display.

- [ ] **Step 5: Final verification**

Run:
```bash
make clean && make && make check
git status
```
Expected:
- `make` succeeds
- `make check` shows 3 PASS lines
- `git status` is clean (no untracked or modified files)

Print final summary URL of the repo.
