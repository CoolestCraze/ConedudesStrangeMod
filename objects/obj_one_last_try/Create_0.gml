global.one_last_try = true;
global.olt_unlocked = false;
if (!variable_global_exists("olt_harder_bosses")) {
    global.olt_harder_bosses = true;
}
if (!variable_global_exists("olt_elite_enemies")) {
    global.olt_elite_enemies = true;
}

if (!variable_global_exists("heatmeter_threshold")) {
    global.heatmeter_threshold = 0;
    global.heatmeter_count = 0;
    global.heatmeter_threshold_max = 3;
    global.heatmeter_threshold_count = 2;
}
