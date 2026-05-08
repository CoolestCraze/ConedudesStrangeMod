if (!global.one_last_try) exit;

global.heatmeter_threshold = floor(global.heatmeter_count / global.heatmeter_threshold_count);
global.heatmeter_threshold = clamp(global.heatmeter_threshold, 0, global.heatmeter_threshold_max);
