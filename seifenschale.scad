// seifenschale — wandmontierte 3D-druckbare Seifenschale
// Spec: docs/superpowers/specs/2026-05-10-seifenschale-design.md
//
// Render-Modi (Variable `mode`):
//   "assembled" — alle drei Teile in Einbau-Pose zusammengesetzt
//   "explosion" — drei Teile vertikal auseinandergezogen für Übersicht
//   "print"     — Druck-Layout, Teile nebeneinander auf z=0
//
// Teil-Auswahl (Variable `part`, nur im "print"-Mode wirksam):
//   "all"           — alle drei Teile nebeneinander
//   "wandhalterung" — nur die Wandhalterung
//   "schale"        — nur die Schale
//   "gitter"        — nur das Abtropfgitter (umgedreht für Druck)
//
// Beide Variablen können im OpenSCAD-Customizer per Dropdown gewählt
// oder per CLI gesetzt werden, z.B.:
//   openscad -D 'mode="explosion"' seifenschale.scad

// --- Customizer ---
mode = "assembled";  // [assembled, explosion, print]
part = "all";        // [all, wandhalterung, schale, gitter]
$fn = 64;

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
schale_innen_x = schale_koerper_x - 2 * schale_wand;  // 98.2
schale_innen_y = schale_koerper_y - 2 * schale_wand;  // 63.2

// Gitter
gitter_x = schale_innen_x - 2 * clearance_gitter;     // 97.6
gitter_y = schale_innen_y - 2 * clearance_gitter;     // 62.6
gitter_stab_breit = 4;
gitter_stab_hoch = 4;
gitter_fuss_hoch = 2;
gitter_quer_hoch = 1.6;          // Höhe der Querverbinder oben
gitter_total_hoch = gitter_fuss_hoch + gitter_stab_hoch;  // 6

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
    // Krempe (rim) — ring around the outside of the body so the dish stays open on top
    difference() {
        translate([-schale_krempe_x / 2, -schale_krempe_y / 2, schale_tief])
            cube([schale_krempe_x, schale_krempe_y, schale_krempe_dick]);
        translate([-schale_koerper_x / 2, -schale_koerper_y / 2, schale_tief - 0.1])
            cube([schale_koerper_x, schale_koerper_y, schale_krempe_dick + 0.2]);
    }
}

module schalen_innenraum() {
    inner_x = schale_koerper_x - 2 * schale_wand;
    inner_y = schale_koerper_y - 2 * schale_wand;
    inner_z = schale_tief - schale_boden + 0.1;
    translate([-inner_x / 2, -inner_y / 2, schale_boden])
        cube([inner_x, inner_y, inner_z]);
}

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
    translate([0, 0, gitter_total_hoch])
        rotate([180, 0, 0])
            gitter();
}

// --- Assembly offsets (in wandhalterung coordinates) ---
schale_y_offset = rahmen_y / 2;                  // 37.5
schale_z_offset = rahmen_z - schale_tief;        // 2
gitter_y_offset = rahmen_y / 2;                  // 37.5
gitter_z_offset = schale_z_offset + schale_boden; // 3.6

explosion_lift_schale = 30;
explosion_lift_gitter = 60;

// Print layout: parts arranged in a single row along Y (front-to-back)
// to fit the typical H2S build plate geometry. Wandhalterung in the back,
// then Schale, then Gitter at the front, separated by print_gap.
print_gap = 5;
print_y_wand   = wandplatte_y + steg_y;                                                          // 23 — Wandhalterung-Origin (Rahmen-Hinterkante)
print_y_schale = wandplatte_y + steg_y + rahmen_y + print_gap + schale_krempe_y / 2;             // 139.5 — Schale-Mitte
print_y_gitter = wandplatte_y + steg_y + rahmen_y + print_gap + schale_krempe_y + print_gap + gitter_y / 2; // 212.3 — Gitter-Mitte

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
        translate([0, print_y_wand,   0]) wandhalterung();
        translate([0, print_y_schale, 0]) schale();
        translate([0, print_y_gitter, 0]) gitter_print();
    }
    else if (part == "wandhalterung") wandhalterung();
    else if (part == "schale")        schale();
    else if (part == "gitter")        gitter_print();
}
