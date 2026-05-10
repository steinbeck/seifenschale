# Seifenschale — Design-Spec

**Status:** Approved
**Datum:** 2026-05-10
**Autor:** Christoph Steinbeck (mit Claude)

## Zweck

Eine wandmontierte Seifenschale aus drei FDM-druckbaren PLA-Teilen, die mit einem Tesa-Powerstrip Large an Badezimmerfliesen geklebt wird. Schale und Abtropfgitter sind herausnehmbar zum Reinigen.

## Komponenten

Drei separat gedruckte Teile:

1. **Wandhalterung** — Wandplatte für Powerstrip + Steg + offener Rahmen.
2. **Schale** — flache Wanne mit Krempenrand, liegt von oben auf dem Rahmen auf.
3. **Abtropfgitter** — Längsstabgitter mit vier Füßchen, liegt mit Luftspalt im Schalenboden.

## Zielparameter

| Parameter | Wert |
|---|---|
| Drucker | FDM, 0,4 mm Nozzle |
| Filament | PLA |
| Layer-Höhe | 0,2 mm |
| Spielmaß Schale ↔ Rahmen | 0,3 mm pro Seite |
| Spielmaß Gitter ↔ Schale | ~0,9 mm pro Seite (lockerer Sitz) |
| Standard-Wandstärke | 1,6–4 mm (siehe Geometrie) |
| Powerstrip | Tesa Powerstrip Large, Klebefläche 20 × 50 mm, Tragkraft bis 2 kg |

## Geometrie

Alle Maße sind im Code als benannte Variablen am Dateianfang definiert.

### Wandhalterung

In Einbau-Pose (= Druck-Pose, identisch):

- **Wandplatte:** 30 mm breit (X) × 60 mm hoch (Z) × 3 mm dick (Y). Klebeseite ist die −Y-Fläche (zur Wand).
- **Steg:** 12 mm breit (X) × 12 mm hoch (Z) × 20 mm tief (Y). Schließt an die Vorderseite (+Y) der Wandplatte an, in Z von 0 bis 12 (am unteren Ende der Wandplatte).
- **Rahmen:** 110 mm breit (X) × 75 mm tief (Y) × 12 mm hoch (Z). Wandstärke 4 mm → Innenmaß 102 × 67 mm. Oben (+Z) und unten (−Z) offen — also ein vierwandiger Schornstein. Schließt mit seiner Hinterkante (−Y) an den Steg an.

**Gemeinsame Unterkante bei z = 0** — Wandplatte, Steg und Rahmen sitzen alle mit ihrer schmalen Unterseite auf dem Druckbett bzw. später entlang der Schwerkraft-Senkrechten an der Wand. Dadurch ist die Druck-Pose identisch zur Einbau-Pose, und nichts ragt im Druck als Overhang in die Luft.

Powerstrip (20 × 50 mm) wird auf die Wandplatten-Rückseite mittig im oberen Bereich geklebt.

### Schale

In Einbau-Pose:

- **Krempenrand:** 108 mm breit × 73 mm tief × 2 mm dick, oben umlaufend. Liegt von oben auf dem Rahmen auf (überhängt 3 mm pro Seite gegenüber Rahmen-Innenmaß 102 × 67 mm).
- **Schalenkörper:** 101,4 mm × 66,4 mm außen × 10 mm tief. Wandstärke 1,6 mm. Boden 1,6 mm. Spiel zum Rahmen 0,3 mm pro Seite.
- **Innenecken:** scharf (kein Radius) — damit das eckige Gitter sauber einsitzt.
- **Boden:** flach, waagerecht (kein Gefälle, keine Ablauflöcher).

### Abtropfgitter

In Einbau-Pose:

- **Außenmaß:** 97,6 mm × 62,6 mm × 6 mm hoch (4 mm Stabhöhe + 2 mm Füßchen). Außenmaß ergibt sich aus Schalen-Innenmaß 98,2 × 63,2 mm minus 0,3 mm Spiel pro Seite.
- **Längsstäbe:** parallel zur 97,6-mm-Achse, je 4 mm breit × 4 mm hoch, gleichmäßig verteilt mit Lücken ~4 mm (Anzahl wird im Code aus dem Außenmaß und Stab-Breite/Lücken-Verhältnis abgeleitet, ergibt etwa 7 Stäbe). Offener Anteil ungefähr 50 %.
- **Querverbinder:** 2 dünne Stege (1,6 mm hoch × 4 mm breit) an den Enden der Längsstäbe (oben), halten das Gitter als Einheit zusammen.
- **Füßchen:** 4 Stück 4 × 4 × 2 mm in den Ecken, unten. Halten das Gitter mit 2 mm Luftspalt über dem Schalenboden.

## Code-Architektur

**Eine einzige Quelldatei:** `seifenschale.scad`

### Top-Level Customizer-Variablen

```openscad
mode = "assembled";   // [assembled, explosion, print]
part = "all";         // [all, wandhalterung, schale, gitter]
$fn = 64;

// Powerstrip
powerstrip_kleb_x = 50;
powerstrip_kleb_y = 20;

// Wandhalterung
wandplatte_x = 30;
wandplatte_z = 60;
wandplatte_y = 3;

steg_x = 12;
steg_y = 20;
steg_z = 12;

rahmen_x = 110;
rahmen_y = 75;
rahmen_z = 12;
rahmen_wand = 4;

// Toleranzen
clearance_schale = 0.3;
clearance_gitter = 0.3;

// Schale
schale_krempe_ueberlapp = 3;
schale_krempe_dick = 2;
schale_tief = 10;
schale_wand = 1.6;
schale_boden = 1.6;

// Gitter
gitter_stab_breit = 4;
gitter_stab_hoch = 4;
gitter_fuss_hoch = 2;
gitter_quer_hoch = 1.6;
```

### Module

Jedes Modul kennt nur seine eigene Geometrie, keine Cross-References.

- `wandhalterung()` — Wandplatte + Steg + Rahmen, Ursprung am Schnittpunkt Rahmen-Hinterkante (Y=0) / Rahmen-Mitte-X / z=0.
- `schale()` — Krempenrand + Schalenkörper, Ursprung an Schalen-Mitte / z=0 = Krempen-Oberkante (oder z=0 = Boden außen — wird im Code festgelegt und konsistent angewendet).
- `gitter()` — Längsstäbe + Querverbinder + Füßchen, Ursprung an Gitter-Mitte / z=0 = Füßchen-Unterkante (Einbau-Pose).

### Print-Pose-Wrapper

Nur das Gitter braucht eine Drucklage, die von der Einbau-Pose abweicht (Füßchen nach oben, damit kein Support nötig):

```openscad
module gitter_print() {
    translate([0, 0, gitter_total_height])
        rotate([180, 0, 0])
            gitter();
}
```

Wandhalterung und Schale werden im `print`-Mode direkt in Einbau-Pose verwendet.

### Render-Mode-Logik (Datei-Ende)

```openscad
if (mode == "assembled") {
    wandhalterung();
    translate([0, schale_y_offset, schale_z_offset]) schale();
    translate([0, gitter_y_offset, gitter_z_offset]) gitter();
}
else if (mode == "explosion") {
    wandhalterung();
    translate([0, schale_y_offset, schale_z_offset + 30]) schale();
    translate([0, gitter_y_offset, gitter_z_offset + 60]) gitter();
}
else if (mode == "print") {
    if (part == "all" || part == "wandhalterung")
        translate([-130, 0, 0]) wandhalterung();
    if (part == "all" || part == "schale")
        translate([   0, 0, 0]) schale();
    if (part == "all" || part == "gitter")
        translate([+130, 0, 0]) gitter_print();
}
```

## Build-System

**Makefile** mit folgenden Targets:

| Target | Bedeutung |
|---|---|
| `make` / `make all` | renders + stls |
| `make renders` | `build/assembled.png`, `build/explosion.png`, `build/print.png` |
| `make stls` | `build/wandhalterung.stl`, `build/schale.stl`, `build/gitter.stl`, `build/print.stl` |
| `make clean` | `rm -rf build/` |

Aufrufmuster pro Target:
```
openscad -o build/<name>.<ext> -D 'mode="<m>"' -D 'part="<p>"' \
    --imgsize=1200,900 --colorscheme=Tomorrow seifenschale.scad
```

Camera-Position wird per `--camera=…` für die Renderings fixiert, damit die drei PNGs konsistent aussehen.

## Repo-Struktur

```
seifenschale/
├── seifenschale.scad
├── Makefile
├── README.md
├── LICENSE                    (MIT)
├── .gitignore                 (build/, *.bak, .~lock.*)
├── docs/superpowers/specs/
│   └── 2026-05-10-seifenschale-design.md
└── build/                     (generiert, nicht in Git)
    ├── assembled.png
    ├── explosion.png
    ├── print.png
    ├── wandhalterung.stl
    ├── schale.stl
    ├── gitter.stl
    └── print.stl
```

## README-Inhalt

- Kurzbeschreibung
- Eingebettete `assembled.png` und `explosion.png`
- Druckhinweise:
  - PLA, 0,2 mm Layer
  - **Brim** für die Wandhalterung (schmale Wandplatten-Auflage)
  - **Kein Support** nötig
  - Gitter wird **kopfüber** gedruckt — das `print.stl` enthält bereits die richtige Pose
- Build-Anleitung (`make`)
- Lizenz: MIT

## GitHub-Workflow

- Initialer Commit: Skelett (`README.md`, `LICENSE`, `.gitignore`, leeres `seifenschale.scad`)
- Inkrementelle Commits pro Bauteil und Build-System
- Spec-Commit nach Brainstorming
- Am Ende: `gh repo create steinbeck/seifenschale --public --source=. --remote=origin --push`

## Verifikation

Vor "fertig":

- `make` läuft fehlerfrei durch.
- Alle 3 PNGs zeigen plausible Geometrie (Schale liegt im Rahmen, Gitter in der Schale, Explosion zeigt 3 getrennte Teile).
- Alle STLs öffnen sich ohne Manifold-Warnung in einem Slicer.
- Bounding-Box-Stichproben pro Bauteil entsprechen den Spec-Maßen ±0,1 mm.

## Out of Scope

- Schraubmontage (nur Powerstrip)
- Wasserablauf-Mechanismen (Schale ist waagerecht ohne Löcher)
- Mehrteilige Wandhalterung (alles ein Druckteil)
- Weitere Powerstrip-Größen (Variablen sind aber so definiert, dass eine spätere Anpassung trivial ist)
- GitHub Actions für automatischen Build (kann später ergänzt werden)
