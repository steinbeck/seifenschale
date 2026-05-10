// seifenschale — wandmontierte 3D-druckbare Seifenschale
// Spec: docs/superpowers/specs/2026-05-10-seifenschale-design.md

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
schale_innen_radius = 2;
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

// --- temporary preview (Task 3) — will be replaced by mode dispatcher ---
wandhalterung();
