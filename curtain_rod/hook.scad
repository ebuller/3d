/*
 * Curtain rod hook
 *
 *  Elliot Buller
 *  2016
 */

// Circle smoothness
$fn = 40;

// Wall thickness
wall = 1;

// Connector inside diameter
cnt_id = 18;
cnt_od = (cnt_id + 2*wall);
cnt_h = 20;

// Screw slot
cnt_slot_w = 8;
cnt_slot_h = cnt_h + 1;// - 5;

// Screw tab
cnt_tab_w = 10;
cnt_tab_h = 10;

// Screw diameter
screw_d = 4.5;

// Pole dimensions
pole_d = 25;
//hook_w = 10;

module screw_tab ()
{
	translate ([0, -wall/2, 0])
	difference () {

		// Add screw tabs
		hull () {
			cube ([cnt_tab_w/2, wall, cnt_tab_h]);
			translate ([cnt_tab_w/2, wall, cnt_tab_w/2])
			rotate ([90, 0, 0])
			cylinder (r=cnt_tab_w/2, h=wall);
		}

		// Add screw hole
		translate ([cnt_tab_w/2, wall + 0.05, cnt_tab_h/2])
		rotate ([90, 0, 0])
		cylinder (r = screw_d/2, h=wall+0.1);
	}
}

module connector()
{
	difference () {

		// Outside
		cylinder (r = cnt_od / 2, h = cnt_h);

		// collar
		translate ([0, 0, wall])
		cylinder (r = cnt_id / 2, h = cnt_h);

		// hollow center
		cylinder (r = (cnt_id / 2)-wall/2, h = cnt_h);

		// Remove slot
		translate ([0, -cnt_slot_w / 2, 0])
		cube ([cnt_od / 2, cnt_slot_w, cnt_slot_h]);
	}

	// Add screw tabs
	translate ([cnt_id/2, cnt_slot_w / 2 + wall/2, 0])
	screw_tab ();
	translate ([cnt_id/2, -cnt_slot_w / 2 - wall/2, 0])
	screw_tab ();
}


module hook ()
{

	difference () {

		cylinder (r=(pole_d/2)+wall, h=cnt_od);
		cylinder (r=pole_d/2, h=cnt_od);

		// Remove pole entry
		cube ([(pole_d/2)+wall, (pole_d/2)+wall, cnt_od]);
	}
}

module assm () {
		translate ([cnt_od/2, 0, pole_d/2 + cnt_h])
		rotate([0, -90, 0])
		rotate([0, 0, 45])
		hook ();
		connector ();
}

//translate ([0, 0, cnt_od/2])
//rotate ([0, -90, 0])
//assm ();

module test () {


	difference () {
		hull () {
			// connector hull
			union () {
				cylinder (r = cnt_od / 2, h = cnt_h);
				translate ([-cnt_od/4, 0, cnt_h/2])
				cube ([cnt_od/2, cnt_od/2, cnt_h], center=true);
			}

			// hook hull
			//translate ([cnt_od/2, 0, pole_d/2 + cnt_h])
			translate ([0, 0, pole_d/2 + cnt_h])
			rotate([0, -90, 0])
			rotate([0, 0, 45])
			cylinder (r=(pole_d/2)+2*wall, h=cnt_od/2);
		}

		// Hole for pole
		translate ([cnt_od/2+0.1, 0, pole_d/2 + cnt_h])
		rotate([0, -90, 0])
		rotate([0, 0, 45])
		cylinder (r=pole_d/2, h=cnt_od+0.2);

		// Pole entry
		translate ([cnt_od/2+0.1, 0, pole_d/2 + cnt_h])
		rotate([0, -90, 0])
		rotate([0, 0, 45])
		cube ([(pole_d/2)+2*wall, (pole_d/2)+6*wall, cnt_od+wall]);

		// collar
		translate ([0, 0, 2 * wall])
		cylinder (r = cnt_id / 2, h = cnt_h);

		// hollow center
		cylinder (r = (cnt_id / 2)-2, h = cnt_h);

		// Remove slot
		translate ([0.1, -cnt_slot_w / 2, 0])
		cube ([cnt_od / 2, cnt_slot_w+0.1, cnt_slot_h]);

	}
if (0) {
	// Add screw tabs
	translate ([cnt_id/2-0.5, cnt_slot_w / 2 + wall/2, 0])
	screw_tab ();
	translate ([cnt_id/2-0.5, -cnt_slot_w / 2 - wall/2, 0])
	screw_tab ();
}
}

translate ([0, 0, cnt_od/2])
rotate ([0, -90, 0])
test();

//screw_tab ();