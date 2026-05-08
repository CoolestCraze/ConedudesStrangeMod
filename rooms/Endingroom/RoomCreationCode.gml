pal_swap_init_system(shd_pal_swapper);
global.gameframe_caption_text = lang_get_value("caption_ending");
ini_open_from_string(obj_savesystem.ini_str);
if (ini_read_string("Game", "finalrank", "none") == "none")
{
	notification_push(notifications.game_beaten, [room]);
}
ini_close();
global.olt_unlocked = true;
ini_open_from_string(obj_savesystem.ini_str_options);
ini_write_real("Game", "olt_unlocked", 1);
ini_write_real("Game", "olt_harder_bosses", global.olt_harder_bosses);
ini_write_real("Game", "olt_elite_enemies", global.olt_elite_enemies);
obj_savesystem.ini_str_options = ini_close();
gamesave_async_save_options();