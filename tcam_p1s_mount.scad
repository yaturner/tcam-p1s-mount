// tCam-Mini (Rev 4) thermal camera case + tilting mount for a Bambu Lab P1S
// fitted with the MakerWorld "Vented LED Riser" (46 mm).
//
// The camera sits inside the riser near the FRONT-LEFT corner, under the glass
// and above the printer's top edge, so nothing reaches the toolhead's space.
// A bracket tab slides into a vent slot of the riser's FrontLeft piece. A side
// arm carries an M3 pivot screw in the far end of the case. A 1.75 mm filament
// pin locks the tilt at 40..70 deg in 5 deg steps:
//   even stops (40/50/60/70) -> pin in case hole A (outer, R = 18.5)
//   odd  stops (45/55/65)    -> pin in case hole B (inner, R = 15)
//
// World coordinates = the riser FrontLeft piece's own model frame
// (LEDVentedRiser.3mf, object "FrontLeft"): outer corner at +X +Y,
// riser bottom (printer top) at Z = -23, glass ledge at Z = +19.75.
//
// Parts: case_base, case_lid, bracket. Print in PETG/ASA (the chamber gets warm).
// Hardware: 1x M3x10 (pivot, self-taps into the lid block), 4x M2.5x10
// countersunk (case), 5 mm of 1.75 mm filament (angle pin).

part  = "assembly";   // case_base | case_lid | bracket | assembly | case_at | bracket_world
mount = "tab";        // tab  = tab slides into a vent slot (tool-free, removable)
                      // tape = VHB pad on the fin ends + the band under the LED channel,
                      //        with a short lip resting on a slot floor to carry the weight
                      // corner = VHB V-bracket taped to both walls of the corner, with lips in the
                      //        two slots beside the corner post (push it in diagonally)
tape_t = 1.1;         // VHB thickness (3M 5952 = 1.1 mm, 4910 = 1.0 mm)
pitch = 55;           // tilt below horizontal for "assembly" / "case_at"
show_riser = false;   // assembly only: needs riser_stl
riser_stl = "frontleft.stl";

$fn = 48;

// ---------------- placement (riser frame) ----------------
r2 = sqrt(0.5);
A_DIR = [ r2, -r2, 0];          // pivot axis, horizontal, across the corner diagonal
FH    = [-r2, -r2, 0];          // horizontal, pointing from the corner into the printer
UP    = [0, 0, 1];
AXLE  = [25.2, 54.8, -2.65];    // pivot point on the case's far-end face
function d_dir(t) = cos(t) * FH - sin(t) * UP;   // lens direction
function e_dir(t) = sin(t) * FH + cos(t) * UP;   // case "up" in its tilt plane
function frame4(x, y, z, o) =
    [[x[0], y[0], z[0], o[0]], [x[1], y[1], z[1], o[1]], [x[2], y[2], z[2], o[2]], [0, 0, 0, 1]];
module place_case(t) multmatrix(frame4(A_DIR, e_dir(t), d_dir(t), AXLE)) children();

stops      = [40, 45, 50, 55, 60, 65, 70];
pin_r_even = 18.5;              // case hole A
pin_r_odd  = 15.0;              // case hole B
pin_d_case = 1.95;
pin_d_arm  = 1.85;              // snug on 1.75 filament
pin_depth  = 2.0;

// ---------------- case (local frame: X along pivot, Y = "up" E, Z = lens D) ----------------
pcb_w = 38.1; pcb_l = 47; pcb_t = 1.6;
tol = 0.3; wall = 1.6; far_wall = 2.4;
btm_h = 2.5;                    // floor to PCB (ESP32 can pokes into the floor cut-out)
top_h = 6.3;                    // PCB top to lid inside (Lepton sits in a lid recess)
case_len = far_wall + tol + pcb_l + tol + wall;   // 51.6
half_e   = pcb_w / 2 + tol + wall;                // 20.95
round_r  = 2.5;
d_pcb_top  = -(1.6 + (top_h - 1.6) / 2);          // pivot is centred in the block above the PCB
d_pcb_bot  = d_pcb_top - pcb_t;
d_floor_in = d_pcb_bot - btm_h;
d_back     = d_floor_in - wall;
d_front_in = d_pcb_top + top_h;
d_front    = d_front_in + wall;

// board (x 0..38.1 across, y 0..47 with USB at y = 0, z up) -> case local
module board() multmatrix([[0, -1, 0, case_len - wall - tol], [1, 0, 0, -pcb_w / 2], [0, 0, 1, d_pcb_bot], [0, 0, 0, 1]]) children();
holes = [[2.54, 2.54], [35.56, 2.54], [2.54, 44.46], [35.56, 44.46]];

module outer()
    rotate([90, 0, 90]) linear_extrude(case_len)
        offset(r = round_r) offset(delta = -round_r)
            translate([-half_e, d_back]) square([2 * half_e, d_front - d_back]);

module case_base() {
    difference() {
        union() {
            difference() {
                intersection() {
                    outer();
                    translate([-1, -50, d_back - 1]) cube([100, 100, d_front_in - d_back + 1]);
                }
                translate([far_wall, -(half_e - wall), d_floor_in]) cube([case_len - far_wall - wall, 2 * (half_e - wall), 20]);
            }
            board() for (h = holes)   // stand-offs under the PCB
                translate([h[0] - 2.84, h[1] - 2.84, -btm_h]) cube([5.68, 5.68, btm_h]);
        }
        board() {
            for (h = holes) {
                translate([h[0], h[1], -20]) cylinder(h = 30, d = 2.9);
                translate([h[0], h[1], -btm_h - wall - 0.01]) cylinder(h = 1.45, d1 = 5.4, d2 = 2.5);
            }
            translate([10.6, 15.35, -10]) cube([16.9, 25, 10]);                 // ESP32 can
            translate([6.45, -5, 3.275 - 3.5]) cube([12.5, 5.5, 7]);            // USB-C plug opening
            translate([22.86, 2, 2.6]) rotate([90, 0, 0]) cylinder(h = 10, d = 2);  // LED
            translate([29.21, 2, 3.1]) rotate([90, 0, 0]) cylinder(h = 10, d = 2);  // button
        }
        translate([-1, 0, 0]) rotate([0, 90, 0]) cylinder(h = far_wall + 2, d = 3.3);   // pivot screw
        for (p = [[-pin_r_even, 0], [-pin_r_odd, 0]])                                    // angle-pin holes
            translate([-0.01, p[0], p[1]]) rotate([0, 90, 0]) cylinder(h = pin_depth + 0.01, d = pin_d_case);
    }
}

module case_lid() {
    blk = [far_wall + 0.1, 6.0, 10, d_pcb_top + 1.6];   // x0, length, width, z0
    difference() {
        union() {
            intersection() {
                outer();
                translate([-1, -50, d_front_in]) cube([100, 100, 20]);
            }
            // locating lip just inside the base walls
            difference() {
                translate([far_wall + 0.25, -(half_e - wall - 0.25), d_front_in - 1.5])
                    cube([case_len - far_wall - wall - 0.5, 2 * (half_e - wall - 0.25), 1.51]);
                translate([far_wall + 1.45, -(half_e - wall - 1.45), d_front_in - 2])
                    cube([case_len - far_wall - wall - 2.9, 2 * (half_e - wall - 1.45), 3]);
            }
            board() for (h = holes) translate([h[0], h[1], pcb_t]) cylinder(h = top_h + 0.01, d = 5);
            translate([blk[0], -blk[2] / 2, blk[3]]) cube([blk[1], blk[2], d_front_in - blk[3] + 0.01]);   // pivot block
        }
        board() {
            for (h = holes) translate([h[0], h[1], pcb_t - 0.01]) cylinder(h = top_h - 0.5, d = 2.1);
            translate([19.05, 25.4, 0]) {
                translate([-6.5, -6, pcb_t + top_h - 0.01]) cube([13, 12, 0.86]);              // Lepton recess
                translate([0, 0, pcb_t + top_h]) cylinder(h = wall + 0.02, d1 = 5, d2 = 7);    // lens window
            }
        }
        translate([far_wall - 0.5, 0, 0]) rotate([0, 90, 0]) cylinder(h = 5.7, d = 2.5);   // M3 self-tap pilot
    }
}

// ---------------- bracket (riser frame) ----------------
slot_x  = [31.75, 40.75];       // vent slot nearest the pivot on the front wall
slot_z  = [-20.0, 3.0];
wall_y  = 73.46;                // inner face of the riser's lower wall
arm_w   = [0.3, 3.3];           // arm thickness band, measured outward from the case end
boss_r  = 6;
z_bot   = -19.75;           // = tab bottom (slot floor -20 + 0.25)
z_top   = 2.8;

function pin_uv(t) = let(r = (t % 10 == 0) ? pin_r_even : pin_r_odd) [-r * sin(t), -r * cos(t)];

// arm in its own plane: u along FH, v up, w along -A_DIR (away from the case)
module arm_frame() multmatrix(frame4(FH, UP, -A_DIR, AXLE)) children();

module arm() {
    vb = z_bot - AXLE[2]; vt = z_top - AXLE[2];
    arm_frame() difference() {
        translate([0, 0, arm_w[0]]) linear_extrude(arm_w[1] - arm_w[0]) hull() {
            circle(r = boss_r);
            for (t = stops) translate(pin_uv(t)) circle(r = 2.6);
            translate([-30, vb]) square([22, vt - vb]);
        }
        translate([0, 0, -1]) cylinder(h = 10, d = 3.3);
        for (t = stops) translate(concat(pin_uv(t), -1)) cylinder(h = 10, d = pin_d_arm);
    }
}

// slot cross-section is a rounded rectangle (corner R ~2.3); tab = inset all round,
// top corners R 2.6, bottom corners 1.5 mm chamfers (prints flat on the bed)
module tab_profile(inset) {
    r = 2.6; c = 1.5;
    x0 = slot_x[0] + inset; x1 = slot_x[1] - inset; z0 = slot_z[0] + inset; z1 = slot_z[1] - inset;
    hull() {
        polygon([[x0 + c, z0], [x1 - c, z0], [x1, z0 + c], [x1, z0 + c + 1], [x0, z0 + c + 1], [x0, z0 + c]]);
        translate([x0 + r, z1 - r]) circle(r = r);
        translate([x1 - r, z1 - r]) circle(r = r);
    }
}
module tab() {
    translate([0, wall_y - 0.3, 0]) rotate([-90, 0, 0]) mirror([0, 1, 0]) hull() {
        linear_extrude(13.7) tab_profile(0.25);
        linear_extrude(14.5) tab_profile(1.05);
    }
}

module trim_to_arm_plane() intersection() {   // keeps a part on the far side of the arm so the case clears it
    children();
    multmatrix(frame4(FH, UP, -A_DIR, AXLE)) translate([-100, -100, arm_w[0]]) cube([200, 200, 100]);
}

module bracket_tab() {
    union() {
        tab();
        intersection() {   // plate + arm stop 0.16 mm short of the riser's inner face
            union() {
                trim_to_arm_plane() translate([27, wall_y - 3.5, z_bot]) cube([14.5, 3.5, z_top - z_bot]);
                arm();
            }
            translate([-200, -200, z_bot]) cube([400, wall_y - 0.16 + 200, z_top + 1.2 - z_bot]);
        }
    }
}

// ---- VHB version ----
// The riser's inner face above the vents: 73.46 at z 3.5, sloping in to 72.46 at z 5.7 (the LED
// channel's bottom lip, which holds the strip's edge). The pad stops at z 5.4, clear of the strip.
pad_x = [4.0, 41.5];            // covers fins 4.75-7.75, 16.75-19.75, 28.75-31.75 (+ part of 40.75-43.75)
pad_t = 3.5;
pad_top = 5.4;
lip_h = 3.0;                    // lip into slot_x, resting on the slot floor
lip_depth = 4.0;                // how far the lip reaches past the wall face
module pad() band(pad_x[0], pad_x[1]);
module band(x0, x1) {   // taped plate on the front wall, from the bottom up to pad_top
    yb = wall_y - tape_t; yf = yb - pad_t;
    slope = (73.46 - 72.46) / (5.7 - 3.5);
    translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0)
        polygon([[yb, z_bot], [yb, 3.5], [yb - slope * (pad_top - 3.5), pad_top], [yf, pad_top], [yf, z_bot]]);
}
module lip() {
    c = 1.5; x0 = slot_x[0] + 0.25; x1 = slot_x[1] - 0.25; z0 = z_bot;
    translate([0, wall_y - tape_t - 0.5, 0]) rotate([-90, 0, 0]) mirror([0, 1, 0])
        linear_extrude(tape_t + 0.5 + lip_depth)
            polygon([[x0 + c, z0], [x1 - c, z0], [x1, z0 + c], [x1, z0 + lip_h], [x0, z0 + lip_h], [x0, z0 + c]]);
}
module bracket_tape() {
    union() {
        lip();
        intersection() {
            union() { trim_to_arm_plane() pad(); arm(); }
            translate([-200, -200, z_bot]) cube([400, wall_y - tape_t + 200, pad_top + 1 - z_bot]);
        }
    }
}

// ---- corner V version ----
// Corner of the FrontLeft piece: front fins at y 73.46, left fins at x 80.75, and the corner post
// (x >= 76.75, y >= 72.46) standing 1 mm proud of the front fins. Above z ~0.5 the post's edges
// flare and the LED band curves round the corner (R ~7), so the corner part stays below z = 0
// and the legs only rise to pad_top where the walls are straight.
post_x = 76.75; post_y = 72.46; left_x = 80.75;
lslot_y = [63.46, 72.46];       // left-wall slot beside the post
corner_top = 0;
front_leg = [50, 73.5];         // full-height part of the front leg
left_leg  = [46, 65.5];         // full-height part of the left leg (y)
rail_top  = -15.5;              // low rail from the arm's pad to the front leg (case swings above it)
brace_at  = 22;                 // diagonal brace meets each leg this far from the corner
L_SWAP = [[0, 1, 0, left_x - wall_y], [1, 0, 0, wall_y - left_x], [0, 0, 1, 0], [0, 0, 0, 1]];  // front wall -> left wall

module lip_xz(x0, x1) {   // lip cross-section (x across the slot, z), chamfered bottom corners
    c = 1.5; z0 = z_bot;
    polygon([[x0 + c, z0], [x1 - c, z0], [x1, z0 + c], [x1, z0 + lip_h], [x0, z0 + lip_h], [x0, z0 + c]]);
}
module bracket_corner() {
    yb = wall_y - tape_t; ypb = post_y - tape_t; xb = left_x - tape_t;
    t = pad_t; w = 4; L = 3.5;
    union() {
        // front lip, in the front-wall slot beside the post, ending 0.25 mm from the post side
        translate([0, yb - 0.5, 0]) rotate([-90, 0, 0]) mirror([0, 1, 0])
            linear_extrude(0.5 + tape_t + L) lip_xz(post_x - 0.25 - w, post_x - 0.25);
        // left lip
        translate([xb - 0.5, 0, 0]) rotate([90, 0, 90]) linear_extrude(0.5 + tape_t + L)
            lip_xz(lslot_y[1] - 0.25 - w, lslot_y[1] - 0.25);
        difference() {
        intersection() {
            union() {
                trim_to_arm_plane() band(27, 41.5);                                       // pad at the arm
                translate([41.5, yb - t, z_bot]) cube([front_leg[0] - 41.5 + 0.01, t, rail_top - z_bot]);   // rail
                band(front_leg[0], front_leg[1]);                                         // front leg
                translate([front_leg[1] - 0.01, yb - t, z_bot]) cube([post_x - 0.6 - front_leg[1] + 0.02, t, corner_top - z_bot]);
                hull() {   // on the post; back-bottom edge chamfered for the fillet at the post's foot
                    translate([post_x - 0.6, ypb - t, z_bot + 1.5]) cube([xb - post_x + 0.6, t, corner_top - z_bot - 1.5]);
                    translate([post_x - 0.6, ypb - t, z_bot]) cube([xb - post_x + 0.6, t - 1.4, 1]);
                }
                multmatrix(L_SWAP) band(left_leg[0] + left_x - wall_y, left_leg[1] + left_x - wall_y);       // left leg
                translate([xb - t, left_leg[1] - 0.01, z_bot]) cube([t, ypb - left_leg[1] + 0.01, corner_top - z_bot]);
                // diagonal brace + floor web make the V a closed triangle
                p1 = [xb - brace_at, yb - t]; p2 = [xb - t, ypb - brace_at];
                n = [p2[1] - p1[1], p1[0] - p2[0]] / norm(p2 - p1);   // unit normal toward the corner
                translate([0, 0, z_bot]) linear_extrude(corner_top - z_bot)
                    polygon([p1 - 1.5 * n, p2 - 1.5 * n, p2 + 1.0 * n, p1 + 1.0 * n]);
                translate([0, 0, z_bot]) linear_extrude(2)
                    polygon([p1 - 1.5 * n, p2 - 1.5 * n, [xb, p2[1]], [xb, ypb], [post_x - 0.6, ypb], [post_x - 0.6, yb], [p1[0], yb]]);
                arm();
            }
            translate([-200, -200, z_bot]) cube([xb + 200, yb + 200, pad_top + 1 - z_bot]);
        }
        // the post's foot has a ~1 mm fillet in its bottom 1.5 mm: chamfer everything along the post face
        hull() {
            translate([post_x - 1, ypb - 2.33, z_bot - 1]) cube([xb - post_x + 2, 10, 0.01]);
            translate([post_x - 1, ypb, z_bot + 1.5]) cube([xb - post_x + 2, 10, 0.01]);
        }
        }
    }
}

module bracket_world() {
    if (mount == "tape") bracket_tape();
    else if (mount == "corner") bracket_corner();
    else bracket_tab();
}

// print orientation = installed orientation (flat bottom at z_bot)
module bracket() translate([-27, -(wall_y - 3.5), -z_bot]) bracket_world();   // flat bottom on the bed

// ---------------- render ----------------
use <../tCam/tCam-Mini/enclosure/tcam_mini_basic/openscad_libraries/tcam_mini.scad>

if (part == "case_base") rotate([0, 0, 0]) translate([0, 0, -d_back]) case_base();
if (part == "case_lid")  rotate([180, 0, 0]) translate([0, 0, -d_front]) case_lid();
if (part == "bracket")   bracket();
if (part == "bracket_world") bracket_world();
if (part == "case_at")   place_case(pitch) { case_base(); case_lid(); }
if (part == "assembly") {
    color("orange") bracket_world();
    place_case(pitch) {
        color("dimgray") case_base();
        color("gray", 0.6) case_lid();
        color("green") board() tCamMini();
    }
    if (show_riser) color("lightblue", 0.35) import(riser_stl);
}
