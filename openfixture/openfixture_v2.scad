/**
 *  OpenFixture v2 - The goal is to have a turnkey pcb fixturing solution as long as you have access to access to
 *  a laser cutter or laser cutting service.
 *
 *  The input is:
 *   1. (x, y) work area that is >= pcb size
 *   2. (x, y) cooridates of test point centers
 *   3. dxf of pcb outline aligned with (0,0) on the top left.
 *   4. Material parameters: acrylic thickness, kerf, etc
 *
 *  The output is a dxf containing all the parts (minus M3 hardware) to assemble the fixture.
 *
 *  Creative Commons Licensed  (CC BY-SA 4.0)
 *  Tiny Labs
 *  2016
 */
// Smothness function for circles
$fn = 20;

// This should usually be fine but might have to be adjusted
kerf = 0.125;
//kerf = 1;

// Work area of PCB
// Must be >= PCB size
area_x = 44;
area_y = 36;

tps = [
    [0, 0],
    [area_x, 0],
    [0, area_y],
    [area_x, area_y],
];

// Active area offset from edges
// This must account for hardware on the sides but we make it even
// all the way around to simplify
area_offset = 8;

// All measurements in mm
// Material parameters
acr_th = 2.5;

// Screw radius (we want this tight to avoid play)
// This should work for M3 hardware
screw_r = (2.9 - kerf) / 2;
screw_d = (screw_r * 2);

// Change to larger size if you want different hardware for pivoting mechanism
pivot_r = screw_r;

// Nut dimensions (common m3 hardware)
nut_od = 5.5;
nut_th = 2.3;

// Just the threads, not including head
screw_len = 10;

// Pogo pin receptable dimensions
// I use the 2 part pogos with replaceable pins. Its a life save when a pin breaks
pogo_r = (1.8 - kerf) / 2;
pogo_h = 22;

//
// DO NOT EDIT below (unless you feel like it)
//

// To account for kerf
acr_od = acr_th + 2 * kerf;
acr_id = acr_th;

// Pad between hole and edge
pad_h2e = 2 * acr_th;

// Padding for structuring element (ie: tnut)
pad_str = acr_th;

// Chebyshev linkage parameters
T3 = area_y + (2 * area_offset) - (2 * acr_id) - (2 * pad_h2e);

//
// MODULES
//

module tnut_female ()
{
    // Screw hole
    translate ([0, -screw_r, 0])
    cube ([screw_len - acr_id, screw_d, acr_id]);
    
    // Make space for nut
    translate ([pad_str, - nut_od/2, 0])
    cube ([nut_th, nut_od, acr_id]);
}

module tnut_hole ()
{
    cylinder (r = screw_r, h = acr_th);
}

module tng_n (length, cnt)
{
    tng_y = (length / cnt);
    
    translate ([0, -length / 2 - kerf, 0])
    union () {
        for (i = [0 : 2 : cnt - 1]) {
            translate ([0, i * tng_y, 0])
            cube ([acr_od, tng_y + 2 * kerf, acr_th]);
        }
    }
}

module tng_p (length, cnt)
{
    tng_y = length / cnt;
    
    translate ([0, -length / 2, 0])
    union () {
        for (i = [1 : 2 : cnt - 1]) {
            translate ([0, i * tng_y, 0])
            cube ([acr_od, tng_y, acr_th]);
        }
    }
}

module side ()
{
    y = area_y + (2 * area_offset);
    x = pogo_h;
    
    difference () {
        // base cube
        cube ([x, y, acr_th]);
        
        // Drop holes for chebychev linkage
        translate ([acr_id + pad_h2e, (y - T3) / 2, 0])
        cylinder (r = pivot_r, h = acr_th);
        translate ([acr_id + pad_h2e, y - ((y - T3) / 2), 0])
        cylinder (r = pivot_r, h = acr_th);
        
        // Remove tng (top and bottom)
        translate ([0, y/2, 0])
        tng_n (y, 5);
        translate ([x - acr_od, y/2, 0])
        tng_n (y, 5);
        
        // Remove tng back
        translate ([x/2, y - acr_id, 0])
        rotate ([0, 0, 90])
        tng_p (x, 3);
        
        // Remove tnuts
        translate ([acr_id, y / 2, 0])
        tnut_female ();
        translate ([x - acr_id, y / 2, 0])
        rotate ([0, 0, 180])
        tnut_female ();
    }
}

module back ()
{
    x = area_x + (2 * area_offset);
    y = pogo_h;
    
    difference () {
        // Base cube
        cube ([x, y, acr_th]);
        
        // Remove bottom and top tng
        translate ([x/2, 0, 0])
        rotate ([0, 0, 90])
        tng_n (x, 5);
        translate ([x/2, y - acr_id, 0])
        rotate ([0, 0, 90])
        tng_n (x, 5);
        
        // Remove left/right tng
        translate ([0, y / 2, 0])
        tng_n (y, 3);
        translate ([x - acr_id, y / 2, 0])
        tng_n (y, 3);

        // Remove tnuts
        translate ([x/2, acr_id, 0])
        rotate ([0, 0, 90])
        tnut_female ();
        translate ([x/2, y - acr_id, 0])
        rotate ([0, 0, -90])
        tnut_female ();
    }
}

module tp_base (test_points, tp_cnt)
{
    x = area_x + (2 * area_offset);
    y = area_y + (2 * area_offset);
    
    difference () {
        cube ([x, y, acr_th]);
    
        // Calc (x,y) origin = (0, 0)
        origin_x = area_offset;
        origin_y = area_offset + area_y;
    
        // Loop over test points
        for ( i = [0 : tp_cnt - 1] ) {
        
            // Drop pins for test points
            translate ([origin_x + test_points[i][0], origin_y - test_points[i][1], 0])
            cylinder (r = pogo_r, h = acr_th);
        }
        
        // Remove tongue and groove
        translate ([0, y / 2, 0])
        tng_p (y, 5);
        translate ([x - acr_id, y / 2, 0])
        tng_p (y, 5);
        translate ([x/2, y - acr_od, 0])
        rotate ([0, 0, 90])
        tng_p (x, 5);
        
        // Remove tnut holes
        translate ([acr_id / 2, y / 2, 0])
        tnut_hole ();
        translate ([x / 2, y - acr_id/2, 0])
        tnut_hole ();
        translate ([x - acr_id/2, y / 2, 0])
        tnut_hole ();
    }
}

// Laser layout
module lasercut () 
{
    // Left side
    mirror ([1, 0, 0])
    side ();
    // Bases
    tp_base (tps, 4);
    translate ([0, -1, 0])
    mirror ([0, 1, 0])
    tp_base (tps, 4);
    
    // Right side
    translate ([area_x + (2 * area_offset), 0, 0])
    side ();
    // Back
    translate ([0, area_y + (2 * area_offset), 0])
    back ();
}

projection (cut = false)
lasercut ();

// Testing
if (0) {
    //tnut_female_n ();
    //rotate ([0, -90, 0])
    //tp_base (tps, 4);
    //side ();
    back ();
    //tnut_hole ();
    //tng_p (area_x + (2 * area_offset), 5);
    //translate ([0, 0, 3])
    //tng_n (area_x + (2 * area_offset), 5);
    
}
