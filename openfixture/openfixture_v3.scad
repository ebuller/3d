/**
 *  OpenFixture v2 - The goal is to have a turnkey pcb fixturing solution as long as you have access to
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
 
//
// PCB input
//

 // Test points
test_points = [
    [4.85, 19.95],
    [2.85, 21.25],
    [4.85, 22.45],
    [2.85, 23.7],
    [4.85, 24.95],
    [2.85, 26.2],
    [4.85, 27.45],
    [22.1, 18.8],
    [23.4, 30.95],
];
tp_min_y = 18.8;
tp_cnt = 9;

// DXF outline of pcb
pcb_outline = "/home/elliot/projects/3d/openfixture/keysy_outline.dxf";
pcb_x = 27.14;
pcb_y = 45;
pcb_support_scale = 0.90; // 10% around border

// Thickness of pcb
pcb_th = 0.8;
//pcb_th = 1.6;

//
// End PCB input
//

// Smothness function for circles
$fn = 10;

// All measurements in mm
// Material parameters
acr_th = 2.5;

// This should usually be fine but might have to be adjusted
//kerf = 0.125;
kerf = 0.11;
// Space between laser parts
laser_pad = 2;

// Work area of PCB
// Must be >= PCB size
active_area_x = 28;
active_area_y = 46;
//active_area_x = 45;
//active_area_y = 32;

// Screw radius (we want this tight to avoid play)
// This should work for M3 hardware
// Just the threads, not including head
screw_thr_len = 10;
screw_d = 2.9;
screw_r = screw_d / 2;

// Change to larger size if you want different hardware for pivoting mechanism

// Uncomment to use normal M3 screw for pivot
//pivot_d = screw_d;
// Uncomment to use bushing
pivot_d = 5.12;
pivot_r = pivot_d / 2;

// Metric M3 hex nut dimensions
// f2f = flat to flat
nut_od_f2f = 5.45;
nut_od_c2c = 6;
nut_th = 2.25;

// Pogo pin receptable dimensions
// I use the 2 part pogos with replaceable pins. Its a lifer save when a pin breaks
pogo_r = 1.7 / 2;

// Uncompressed length from receptacle
pogo_max_compression = 8;
pogo_compression = 1;

// Locking tab parameters
tab_width = 3 * acr_th;
tab_length = 4 * acr_th;

// Stop tab
stop_tab_y = 2 * acr_th;

//
// DO NOT EDIT below (unless you feel like it)
//
// Calculate min distance to hinge with a constraint on
// the angle of the pogo pin when it meets compression with the board.
// a = compression
// c = active_y_offset + pivot_d
// cos (min_angle) = a^2 / (2ca)
//min_angle = 89.2;
min_angle = 89.5;

// Calculate active_y_back_offset
active_y_back_offset = (pow (pogo_compression, 2) / (cos (min_angle) * 2 * pogo_compression)) - pivot_d - tp_min_y;

// Active area parameters
active_x_offset = 2 * acr_th + nut_od_f2f + 2;
active_y_offset = 2 * acr_th + nut_od_f2f + 2;

// Head dimensions
head_x = active_area_x + 2 * active_x_offset;
head_y = active_area_y + active_y_offset + active_y_back_offset;
head_z = screw_thr_len + (acr_th - nut_th);

// Base dimensions
base_x = head_x + 2 * acr_th;
base_y = head_y + 2 * pivot_d;
base_z = 7 * acr_th; // 4 x thickness for support + 2 carriers
base_pivot_offset = pivot_d + (pogo_max_compression - pogo_compression) - (acr_th - pcb_th);

//
// MODULES
//

module tnut_female ()
{
    // Pad for screw
    pad = 0.4;
    
    // Screw hole
    translate ([0, -screw_r - pad/2, 0])
    cube ([screw_thr_len - acr_th, screw_d + pad, acr_th]);
    
    // Make space for nut
    translate ([acr_th, -nut_od_f2f/2, 0])
    cube ([nut_th, nut_od_f2f, acr_th]);
}

module tnut_hole ()
{
    cylinder (r = screw_r, h = acr_th, $fn = 20);
}

module tng_n (length, cnt)
{
    tng_y = (length / cnt);
    
    translate ([0, -length / 2 - kerf, 0])
    union () {
        for (i = [0 : 2 : cnt - 1]) {
            translate ([0, i * tng_y, 0])
            cube ([acr_th, tng_y + 2 * kerf, acr_th]);
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
            cube ([acr_th, tng_y, acr_th]);
        }
    }
}


module spacer ()
{
    difference () {
        cylinder (r = screw_d, h = acr_th);
        cylinder (r = screw_r, h = acr_th);
    }
}

module nut_hole ()
{
    difference () {
        cylinder (r = nut_od_c2c/2, h = acr_th, $fn = 6);
        //cylinder (r = screw_r, h = acr_th, $fn = 20);
    }
}

module head_side ()
{
    x = head_z;
    y = head_y;
    r = pivot_d;
    
    difference () {
        hull () {
            cube ([x, y, acr_th]);
            
            // Add pivot point
            translate ([r, y + r, 0])
            cylinder (r = r, h = acr_th, $fn = 20);
        }
        
        // Remove pivot
        translate ([r, y + r, 0])
        cylinder (r = r/2, h = acr_th, $fn = 20);
        
        // Remove slots
        translate ([0, y / 2, 0])
        tng_n (y, 3);
        translate ([x - acr_th, y / 2, 0])
        tng_n (y, 3);
    }
}

module head_back ()
{
    x = head_x - 4 * acr_th;
    y = head_z;
    
    difference () {
        translate ([2 * acr_th, 0, 0])
        cube ([x, y, acr_th]);
        
        // Remove grooves
        translate ([head_x / 2, 0, 0])
        rotate ([0, 0, 90])
        tng_n (head_x, 3);
        translate ([head_x / 2, y - acr_th, 0])
        rotate ([0, 0, 90])
        tng_n (head_x, 3);
    }
}

module lock_tab ()
{
    translate ([-tab_length/2, 0, 0])
    cube ([tab_length, tab_width, acr_th]);
    translate ([-tab_length/2, tab_width/2, 0])
    cylinder (r = tab_width / 2, h = acr_th, $fn = 20);
}

module head_base ()
{
    nut_offset = 2 * acr_th + screw_r;
    
    difference () {
        
        union () {
            // Common base
            head_base_common ();

            // Add stop tabs
            translate ([head_x, head_y - 2 * acr_th, 0])
            cube ([acr_th, stop_tab_y, acr_th]);
            translate ([-acr_th, head_y - 2 * acr_th, 0])
            cube ([acr_th, stop_tab_y, acr_th]);

            // Add lock tabs
            lock_tab ();
            translate ([head_x, 0, 0])
            mirror ([1, 0, 0])
            lock_tab ();

        }

        // Remove holes for hex nuts
        translate ([nut_offset, nut_offset, 0])
        nut_hole ();
        translate ([nut_offset, head_y - nut_offset, 0])
        nut_hole ();
        translate ([head_x - nut_offset, head_y - nut_offset, 0])
        nut_hole ();
        translate ([head_x - nut_offset, nut_offset, 0])
        nut_hole ();
        
        // Take 1/4 mouse bit out of front of tabs
        translate ([-acr_th, 0, 0])
        cube ([acr_th, tab_width / 4, acr_th]);
        translate ([head_x, 0, 0])
        cube ([acr_th, tab_width / 4, acr_th]);
    }
}

module head_top ()
{
    hole_offset = 2 * acr_th + screw_r;
    pad = 0.1;
    
    difference () {
        
        // Common base
        head_base_common ();
        
        // Remove holes for hex nuts
        translate ([hole_offset, hole_offset, 0])
        cylinder (r = screw_r + pad, h = acr_th);
        translate ([hole_offset, head_y - hole_offset, 0])
        cylinder (r = screw_r + pad, h = acr_th);
        translate ([head_x - hole_offset, head_y - hole_offset, 0])
        cylinder (r = screw_r + pad, h = acr_th);
        translate ([head_x - hole_offset, hole_offset, 0])
        cylinder (r = screw_r + pad, h = acr_th);
    }
}

module head_base_common ()
{
    difference () {
        
        // Base cube
        cube ([head_x, head_y, acr_th]);
                
        // Remove slots
        translate ([acr_th, head_y / 2, 0])
        tng_p (head_y, 3);
        translate ([head_x - 2 * acr_th, head_y / 2, 0])
        tng_p (head_y, 3);
        translate ([head_x / 2, head_y - 2 * acr_th, 0])
        rotate ([0, 0, 90])
        tng_p (head_x, 3);
        
        // Calc (x,y) origin = (0, 0)
        origin_x = active_x_offset;
        origin_y = active_x_offset + active_area_y;
    
        // Loop over test points
        for ( i = [0 : tp_cnt - 1] ) {
        
            // Drop pins for test points
            translate ([origin_x + test_points[i][0], origin_y - test_points[i][1], 0])
            cylinder (r = pogo_r, h = acr_th);
        }
    }
}

module latch ()
{
    pad = tab_width / 6;
    
    y = base_z / 2 + base_pivot_offset - pivot_d;
    difference () {
        
        hull () {
            cylinder (r = tab_width / 2, h = acr_th, $fn = 20);
            translate ([0, y + screw_d, 0])
            cylinder (r = tab_width / 2, h = acr_th, $fn = 20);
        }
        
        cylinder (r = screw_r, h = acr_th, $fn = 20);
        translate ([-screw_r, y - (pad/2), 0])
        cube ([(3 * tab_width) / 4, acr_th + pad, acr_th]);
    }
}
module base_side ()
{
    x = base_z;
    y = base_y;
    
    difference () {
        union () {
            cube ([x, y, acr_th]);
            
            // Add pivot structure
            hull () {
                translate ([x + base_pivot_offset, y - pivot_d, 0])
                cylinder (r = pivot_d, h = acr_th, $fn = 20);
                translate ([0, y - 2 * pivot_d, 0])
                cube ([1, 2 * pivot_d, acr_th]);
            }
        }
        
        // Remove pivot hole
        translate ([x + base_pivot_offset, y - pivot_d, 0])
        cylinder (r = pivot_r, h = acr_th, $fn = 20);

        // Remove carrier slots
        translate ([x - acr_th, head_y / 2, 0])
        tng_p (head_y, 3);
        translate ([x - 2 * acr_th, head_y / 2, 0])
        tng_p (head_y, 3);
        
        // Remove tnut slot
        translate ([x - (2 * acr_th), head_y / 2, 0])
        rotate ([0, 0, 180])
        tnut_female ();
        
        // Cross bar support
        translate ([acr_th, head_y / 6 + acr_th, 0])
        tng_n (head_y / 3, 3);
        translate ([acr_th + acr_th / 2, head_y / 6 + acr_th, 0])
        tnut_hole ();
        
        // Second cross bar support
        translate ([acr_th, head_y - (head_y / 6 + acr_th), 0])
        tng_n (head_y / 3, 3);
        translate ([acr_th + acr_th / 2, head_y - (head_y / 6 + acr_th), 0])
        tnut_hole ();
        
        // Back support
        translate ([x/2 + acr_th, y - acr_th - pivot_r, 0])
        rotate ([0, 0, 90])
        tng_n (x, 3);
        translate ([x/2 + acr_th, y - acr_th - pivot_r + (acr_th / 2), 0])        
        tnut_hole ();
        
        // Remove locking pivot hole
        translate ([x/2, tab_width / 2, 0])
        cylinder (r = screw_r, h = acr_th, $fn = 20);
    }
}

module base_support (length)
{
    x = base_x;
    y = length;
    
    difference () {
        // Base cube
        cube ([x, y, acr_th]);
        
        // Remove slots
        translate ([0, y / 2, 0])
        tng_p (y, 3);
        translate ([x - acr_th, y / 2, 0])
        tng_p (y, 3);
        
        // Remove female tnuts
        translate ([acr_th, y / 2, 0])
        tnut_female ();
        translate ([x - acr_th, y / 2, 0])
        rotate ([0, 0, 180])
        tnut_female ();
    }
}

module spacer ()
{
    difference () {
        cylinder (r = pivot_d, h = acr_th, $fn = 40);
        cylinder (r = pivot_r, h = acr_th, $fn = 20);
    }
}

module carrier (dxf_filename, pcb_x, pcb_y, s)
{
    x = base_x;
    y = head_y;
    
    difference () {
        cube ([x, y, acr_th]);
        
        // Get scale_offset
        sx_offset = (pcb_x - (pcb_x * s)) / 2;
        sy_offset = (pcb_y - (pcb_y * s)) / 2;
        
        if (s == 1) {
            translate ([acr_th + active_x_offset, active_area_y + active_y_offset, 0])
            hull () {
                linear_extrude (height = acr_th)
                import (dxf_filename);
            }        
        }
        else {
            translate ([acr_th + active_x_offset, active_area_y + active_y_offset, 0])
            translate ([sx_offset, -sy_offset, 0])
            hull () {
                linear_extrude (height = acr_th)
                scale ([s, s, 1])
                import (dxf_filename);
            }
        }
        
        // Remove slots
        translate ([0, y/2, 0])
        tng_n (y, 3);
        translate ([x - acr_th, y/2, 0])
        tng_n (y, 3);
        
        // Remove holes
        translate ([acr_th / 2, y / 2, 0])
        tnut_hole ();
        translate ([x - acr_th / 2, y / 2, 0])
        tnut_hole ();
    }
}


//
// 3D renderings of assembly
//
module 3d_head ()
{
    head_top_offset = head_z - acr_th;
    
    head_base ();
    translate ([2 * acr_th, 0, 0])
    rotate ([0, -90, 0])
    head_side ();
    translate ([head_x - acr_th, 0, 0])
    rotate ([0, -90, 0])
    head_side ();
    translate ([0, 0, head_top_offset])
    head_top ();
    translate ([0, head_y - acr_th, 0])
    rotate ([90, 0, 0])
    head_back ();
}

module 3d_base () {
    // Base sides
    rotate ([0, -90, 0])
    base_side ();
    translate ([head_x + acr_th, 0, 0])
    rotate ([0, -90, 0])
    base_side ();
    
    // Supports
    translate ([-acr_th, acr_th, acr_th])
    base_support (head_y / 3);
    translate ([-acr_th, head_y - (head_y / 3) - acr_th, acr_th])
    base_support (head_y / 3);
    translate ([-acr_th, base_y - pivot_r, acr_th])
    rotate ([90, 0, 0])
    base_support (base_z);
    
    // Add spacers
    translate ([0, base_y - pivot_d, base_z + base_pivot_offset])
    rotate ([0, 90, 0])
    spacer ();
    translate ([base_x - 3 * acr_th, base_y - pivot_d, base_z + base_pivot_offset])
    rotate ([0, 90, 0])
    spacer ();
    
    // Add latch
    translate ([-acr_th * 2, tab_width / 2, base_z / 2])
    rotate ([90, 0, 0])
    rotate ([0, 90, 0])
    latch ();
}

module 3d_model () {
    translate ([0, 0, base_z + base_pivot_offset - pivot_d])
    3d_head ();
    3d_base ();
    
    // Add carrier blank and carrier
    translate ([-acr_th, 0, base_z - (2 * acr_th)])
    carrier (pcb_outline, pcb_x, pcb_y, pcb_support_scale);
    translate ([-acr_th, 0, base_z - acr_th])
    carrier (pcb_outline, pcb_x, pcb_y, 1);
}

module lasercut ()
{
    // Base components
    base_side ();
    translate ([2 * base_z + base_pivot_offset + pivot_d + laser_pad, base_y, 0])
    rotate ([0, 0, 180])
    base_side ();
    
    // Add latch
    yoffset = 2 * pivot_d + screw_d + laser_pad;
    xoffset = base_z + tab_width + laser_pad;
    //translate ([base_z + tab_width + laser_pad, 2 * pivot_d + screw_d + laser_pad, 0])
    translate ([xoffset, yoffset, 0])
    latch ();
    
    // Add spacers
    yoffset1 = yoffset + base_z / 2 + pivot_d + (3 * acr_th / 2) + screw_d + pivot_d + laser_pad;
    translate ([xoffset, yoffset1, 0])
    spacer ();
    yoffset2 = yoffset1 + 2 * pivot_d + laser_pad;
    translate ([xoffset, yoffset2, 0])
    spacer ();
    
    // Add base supports
    xoffset1 = 2 * base_z + base_pivot_offset + pivot_d + 2 * laser_pad;
    translate ([xoffset1, 0, 0])
    base_support (head_y / 3);
    yoffset3 = head_y / 3 + laser_pad;
    translate ([xoffset1, yoffset3, 0])
    base_support (head_y / 3);
    yoffset4 = yoffset3 + head_y / 3 + laser_pad;
    translate ([xoffset1, yoffset4, 0])
    base_support (base_z);

    // Add heads
    xoffset2 = xoffset1 + base_x + tab_length + laser_pad;
    translate ([xoffset2, 0, 0])
    head_base ();
    xoffset3 = xoffset2 + base_x + tab_length + laser_pad;
    translate ([xoffset3, 0, 0])
    head_top ();
    
    // Add carriers
    yoffset5 = -head_y - laser_pad;
    translate ([0, yoffset5, 0])
    carrier (pcb_outline, pcb_x, pcb_y, pcb_support_scale);
    xoffset4 = base_x + laser_pad;
    translate ([xoffset4, yoffset5, 0])
    carrier (pcb_outline, pcb_x, pcb_y, 1);
    
    // Add sides
    xoffset5 = xoffset4 + base_x + laser_pad;
    yoffset6 = yoffset5 - 2 * pivot_d;
    translate ([xoffset5, yoffset6, 0])
    head_side ();
    xoffset6 = xoffset5 + head_z + laser_pad;
    translate ([xoffset6, yoffset6, 0])
    head_side ();
    xoffset7 = xoffset6 + head_z + laser_pad;
    translate ([xoffset7, -head_z - laser_pad, 0])
    head_back ();
}

module test (s)
{
    x = pcb_x;
    sx = x * s;
    y = pcb_y;
    sy = y * s;
    dxf_filename = pcb_outline;
    
    // Get scale_offset
    sx_offset = (x - sx) / 2; ;
    sy_offset = (y - sy) / 2;
    
    // Remove pcb
    if (s == 1) {
        translate ([acr_th + active_x_offset, active_area_y + active_y_offset, 0])
        hull () {
            linear_extrude (height = acr_th)
            import (dxf_filename);
        }        
    }
    else {
        translate ([acr_th + active_x_offset, active_area_y + active_y_offset, 0])
        translate ([sx_offset, -sy_offset, 0])
        hull () {
            linear_extrude (height = acr_th)
            scale ([s, s, 1])
            import (dxf_filename);
        }
    }
}

3d_model ();
//3d_head ();
//3d_base ();

//projection (cut = false)
//lasercut ();

// Testing
if (1) {
    //head_base ();
    //head_side ();
    //head_back ();
    //base_side ();
    //tnut_female ();
    //base_support (head_y / 3);
    //carrier (pcb_outline, pcb_x, pcb_y, pcb_support_scale);
    //translate ([0, 0, 3])
    //carrier (pcb_outline, pcb_x, pcb_y, 1);
    //carrier (pcb_outline, pcb_x, pcb_y, 0.90);
    //latch ();
    //translate ([0, 0, 4])
    //#test (0.9);
    //test (1);
}