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
        header = f.read(80)
        if header.startswith(b"solid"):
            sys.exit(f"ERROR: {path} appears to be ASCII STL; re-export with --export-format binstl")
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
    if len(sys.argv) < 5:
        sys.exit("Usage: check_bbox.py PATH X Y Z [TOL]")
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
