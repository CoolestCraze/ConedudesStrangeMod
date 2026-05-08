global.one_last_try = false;
global.olt_unlocked = false;

if (!variable_global_exists("heatmeter_threshold")) {
    global.heatmeter_threshold = 0;
    global.heatmeter_count = 0;
    global.heatmeter_threshold_max = 3;
    global.heatmeter_threshold_count = 2;
}
