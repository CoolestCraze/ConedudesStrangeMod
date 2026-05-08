depth = -600;
if (instance_number(object_index) > 1)
{
	instance_destroy();
	exit;
}
dirty = false;
savegame = false;
saveoptions = false;
fadeoutcreate = false;
showicon = false;
ini_str = "";
state = 0;
icon_index = 0;
ispeppino = true;
icon_max = sprite_get_number(spr_pizzaslice);
ini_open("saveData.ini");
ini_str_options = ini_close();
ini_open_from_string(ini_str_options);
global.olt_unlocked = ini_read_real("Game", "olt_unlocked", 0);
global.olt_harder_bosses = ini_read_real("Game", "olt_harder_bosses", 1);
global.olt_elite_enemies = ini_read_real("Game", "olt_elite_enemies", 1);
ini_close();
