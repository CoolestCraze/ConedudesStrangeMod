if (state == states.shoulderbash && hsp != 0)
{
	if (other.flash)
	{
		other.flash = false;
	}
	var s = other.state;
	scr_hurtplayer(other);
	if (other.state != s && other.state == states.hurt)
	{
		state = states.stun;
		hsp = -image_xscale * 5;
		vsp = -8;
		stunned = 220;
		sprite_index = spr_pepperman_shoulderhurtstart;
		image_index = 0;
		image_speed = 0.35;
		with (obj_camera)
		{
			shake_mag = 3;
			shake_mag_acc = 5 / room_speed;
		}
		repeat (4)
		{
			create_debris(x, y, spr_slapstar);
		}
	}
}
else if (wastedhits == 9 && phase == 1 && !pizzahead && (other.instakillmove || other.state == states.handstandjump) && state == states.contemplate)
{
	scr_boss_do_hurt_phase2(other);
}
else if (olt_phase_triggered && !olt_shell_active && (other.instakillmove || other.state == states.handstandjump) && state == states.contemplate)
{
	// OLT final hit: shell is broken, Pepperman is vulnerable — trigger defeat
	var lay1 = layer_get_id("Backgrounds_scroll");
	var lay2 = layer_get_id("Backgrounds_2");
	var lay3 = layer_get_id("Backgrounds_1");
	layer_set_visible(lay3, true);
	var bg1 = layer_background_get_id(lay1);
	var bg2 = layer_background_get_id(lay2);
	layer_background_change(bg1, bg_peppermanbosscloud1);
	layer_background_change(bg2, bg_peppermanboss1);
	layer_hspeed(lay1, 1);
	obj_bosscontroller.alarm[1] = 5;
	scr_sleep(25);
	instance_destroy(obj_peppermanartdude);
	instance_destroy(obj_peppermanbowlingball);
	instance_destroy(obj_peppermanbowlingballspawner);
	instance_destroy(obj_peppermanGIANTbowlingball);
	instance_destroy(obj_pepper_marbleblock);
	destroyable = true;
	spr_dead = spr_pepperman_hurtplayer;
	instance_destroy();
}
else if (state == states.mini && ministate != states.transitioncutscene && (other.instakillmove || other.state == states.handstandjump))
{
	with (other)
	{
		scr_pummel();
	}
	with (obj_camera)
	{
		shake_mag = 3;
		shake_mag_acc = 5 / room_speed;
	}
	if (!olt_phase_triggered && variable_global_exists("one_last_try") && global.one_last_try)
	{
		// OLT: intercept defeat — Pepperman grows back and gains a marble shell
		olt_phase_triggered = true;
		olt_shell_active    = true;
		olt_marble_1_done   = false;
		olt_marble_2_done   = false;
		hp = 1;
		elitehit = 1;

		// Restore to full-size walking state
		state          = states.olt_magnum_opus;
		ministate      = states.normal;
		sprite_index   = spr_pepperman_idle;
		image_index    = 0;
		image_speed    = 0.35;

		// Spawn two marble blocks from the marblespots (reuse existing spot logic)
		var _spots = [];
		with (obj_pepper_marblespot)
		{
			array_push(_spots, id);
		}
		if (array_length(_spots) >= 2)
		{
			var _s1 = _spots[0];
			var _s2 = _spots[1];
			instance_destroy(obj_pepper_marbleblock);
			with (instance_create(_s1.x, -85, obj_pepper_marbleblock))
			{
				image_xscale = _s1.image_xscale;
				number       = _s1.number;
				parentID     = _s1;
				olt_boss     = other.id;
				olt_block_id = 1;
			}
			with (instance_create(_s2.x, -85, obj_pepper_marbleblock))
			{
				image_xscale = _s2.image_xscale;
				number       = _s2.number;
				parentID     = _s2;
				olt_boss     = other.id;
				olt_block_id = 2;
			}
		}

		do_dialog([
			dialog_create("You dare lay hands on a MASTERPIECE?!", spr_pepperman_contemplate),
			dialog_create("I''ll show you what REAL art looks like!!", spr_pepperman_contemplate)
		]);
	}
	else
	{
		// Normal defeat path
		var lay1 = layer_get_id("Backgrounds_scroll");
		var lay2 = layer_get_id("Backgrounds_2");
		var lay3 = layer_get_id("Backgrounds_1");
		layer_set_visible(lay3, true);
		var bg1 = layer_background_get_id(lay1);
		var bg2 = layer_background_get_id(lay2);
		layer_background_change(bg1, bg_peppermanbosscloud1);
		layer_background_change(bg2, bg_peppermanboss1);
		layer_hspeed(lay1, 1);
		obj_bosscontroller.alarm[1] = 5;
		scr_sleep(25);
		instance_destroy(obj_peppermanartdude);
		instance_destroy(obj_peppermanbowlingball);
		instance_destroy(obj_peppermanbowlingballspawner);
		instance_destroy(obj_peppermanGIANTbowlingball);
		destroyable = true;
		spr_dead = spr_pepperman_minifall;
		instance_destroy();
	}
}
