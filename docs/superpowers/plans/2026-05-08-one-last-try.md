# One Last Try Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the "One Last Try" difficulty mode — elite enemy scaling via the existing heat meter, harder boss attacks, and extra phases with cutscenes for all 5 main story bosses.

**Architecture:** A persistent `obj_one_last_try` object owns the `global.one_last_try` flag and initializes heat meter globals (so the mode works with or without `obj_hardmode`). Enemy elite behaviour reuses the existing `elite` flag already in `obj_baddie`. Boss extra phases use a per-boss `olt_phase_triggered` local variable and hook into existing boss state machines. All cutscenes use the existing `dialog_create` / `do_dialog` system.

**Tech Stack:** GameMaker Studio 2, GML

---

## File Map

**New objects (create in GMS2 IDE, then edit .gml files):**
- `objects/obj_one_last_try/` — mode controller, persistent
- `objects/obj_olt_laser_bar/` — Pizzahead Phase 5 laser charge UI
- `objects/obj_olt_hat_boomerang/` — Vigilante extra phase hat projectile
- `objects/obj_olt_shockwave/` — Pizzahead "GET OUT" low shockwave (player must crouch)

**Modified files:**
- `objects/obj_debugcontroller/Create_0.gml` — add `one_last_try` debug command
- `objects/obj_baddie/Create_0.gml` — elite flag based on heat level
- `objects/obj_baddie/Destroy_0.gml` — increment heat count when OLT active (without hardmode)
- `objects/obj_electricpotato/Destroy_0.gml` — same heat count fix
- `scripts/scr_hurtplayer/scr_hurtplayer.gml` — reset heat on hit when OLT active
- `scripts/scr_savesystem/scr_savesystem.gml` — persist `olt_unlocked` flag
- `objects/obj_pepperman/Create_0.gml` + `Step_0.gml` — harder attacks + extra phase
- `objects/obj_vigilante/Create_0.gml` + `Step_0.gml` — harder attacks + extra phase
- `objects/obj_noise/Create_0.gml` + `Step_0.gml` — harder attacks + extra phase (verify actual boss object name)
- `objects/obj_fakepeppino/Create_0.gml` + `Step_0.gml` — harder attacks + extra phase
- `objects/obj_pizzaface/Step_0.gml` — faster Phase 1 enemy spawns
- `objects/obj_pizzahead/Create_0.gml` + `Step_0.gml` — harder phases + Phase 5

> **Object name note:** Boss object names above are best guesses. Before starting boss tasks, search `objects/` for folders containing "pepperman", "vigilante", "noise", "fakepeppino", "pizzahead" to confirm exact names.

---

### Task 1: Create obj_one_last_try

**Files:**
- Create: `objects/obj_one_last_try/Create_0.gml`
- Create: `objects/obj_one_last_try/Step_0.gml`
- Create: `objects/obj_one_last_try/Other_4.gml`
- Create: `objects/obj_one_last_try/Draw_64.gml`

- [ ] **Step 1: Create the object in GMS2 IDE**

Right-click `objects/` → Create Object → name `obj_one_last_try`. Enable **Persistent** in object properties. Add events: Create, Step, Draw GUI, Other → Room Start.

- [ ] **Step 2: Write Create_0.gml**

```gml
global.one_last_try = false;
global.olt_unlocked = false;

// Initialize heat meter globals only if obj_hardmode hasn't done so already
if (!variable_global_exists("heatmeter_threshold")) {
    global.heatmeter_threshold = 0;
    global.heatmeter_count = 0;
    global.heatmeter_threshold_max = 3;
    global.heatmeter_threshold_count = 2;
}
```

- [ ] **Step 3: Write Step_0.gml**

```gml
if (!global.one_last_try) exit;

// Calculate heat threshold (idempotent if obj_hardmode also runs this)
global.heatmeter_threshold = floor(global.heatmeter_count / global.heatmeter_threshold_count);
global.heatmeter_threshold = clamp(global.heatmeter_threshold, 0, global.heatmeter_threshold_max);
```

- [ ] **Step 4: Write Other_4.gml (Room Start event)**

```gml
if (global.one_last_try) {
    global.heatmeter_count = 0;
}
```

- [ ] **Step 5: Write Draw_64.gml (heat meter display for OLT-only sessions)**

This mirrors `obj_hardmode/Draw_64.gml` so the heat meter appears when OLT is on but hardmode is off.

```gml
if (!global.one_last_try) exit;
if (instance_exists(obj_hardmode)) exit; // hardmode draws it already

// Don't show in boss rooms, end screens, rank room, etc.
var _hide = (room == Titlescreen || room == Realtitlescreen || room == characterselect
          || instance_exists(obj_endscreen) || room == rank_room);
if (_hide) exit;

draw_sprite(asset_get_index("spr_heatmeter" + string(global.heatmeter_threshold + 1)), 0, 480, 96);
```

- [ ] **Step 6: Place obj_one_last_try in the title screen room**

In GMS2 IDE: open `Realtitlescreen` room → place one instance of `obj_one_last_try`.

- [ ] **Step 7: Fix heat count increment for OLT-only sessions**

Open `objects/obj_baddie/Destroy_0.gml`. Find:
```gml
if (instance_exists(obj_hardmode)) {
    global.heatmeter_count++;
}
```
Change to:
```gml
if (instance_exists(obj_hardmode) || (variable_global_exists("one_last_try") && global.one_last_try)) {
    global.heatmeter_count++;
}
```

Open `objects/obj_electricpotato/Destroy_0.gml` and apply the same change.

- [ ] **Step 8: Fix heat reset on player hit for OLT-only sessions**

Open `scripts/scr_hurtplayer/scr_hurtplayer.gml`. Find:
```gml
if (instance_exists(obj_hardmode)) {
    global.heatmeter_count = (global.heatmeter_threshold - 1) * global.heatmeter_threshold_count;
}
```
Change to:
```gml
if (instance_exists(obj_hardmode) || (variable_global_exists("one_last_try") && global.one_last_try)) {
    global.heatmeter_count = (global.heatmeter_threshold - 1) * global.heatmeter_threshold_count;
}
```

- [ ] **Step 9: Commit**

```
git add objects/obj_one_last_try/ objects/obj_baddie/Destroy_0.gml objects/obj_electricpotato/Destroy_0.gml scripts/scr_hurtplayer/scr_hurtplayer.gml
git commit -m "feat: add obj_one_last_try mode controller and heat meter wiring"
```

---

### Task 2: Add debug toggle and game-completion unlock

**Files:**
- Modify: `objects/obj_debugcontroller/Create_0.gml`
- Modify: `scripts/scr_savesystem/scr_savesystem.gml`

- [ ] **Step 1: Add debug command**

Open `objects/obj_debugcontroller/Create_0.gml`. Find the `case "hardmode":` block (~line 353). Add immediately after it:

```gml
case "one_last_try":
    global.one_last_try = (argument == "true" || argument == "1");
    break;
```

- [ ] **Step 2: Find the game-beaten flag**

Search `scripts/` for `global.gamecomplete` or `global.beaten` or `global.ending`. Find where it is set to `true` (the ending cutscene script). Add:

```gml
global.olt_unlocked = true;
```

- [ ] **Step 3: Persist olt_unlocked in save data**

In `scr_savesystem.gml`, alongside existing flag saves/loads:

```gml
// In save section:
ini_write_real("flags", "olt_unlocked", global.olt_unlocked);

// In load section:
global.olt_unlocked = ini_read_real("flags", "olt_unlocked", 0);
```

- [ ] **Step 4: Playtest**

Run game (F5), open debug console, type `one_last_try true`. Verify no crash and `global.one_last_try` is true. Type `one_last_try false`, verify it toggles back.

- [ ] **Step 5: Commit**

```
git add objects/obj_debugcontroller/Create_0.gml scripts/scr_savesystem/scr_savesystem.gml
git commit -m "feat: OLT debug toggle and game-completion unlock"
```

---

### Task 3: Enemy elite flag system

**Files:**
- Modify: `objects/obj_baddie/Create_0.gml`

- [ ] **Step 1: Find where scr_initenemy() is called**

Open `objects/obj_baddie/Create_0.gml`. Locate the `scr_initenemy()` call. The OLT code must come AFTER this call so it overrides the `elite = false` default.

- [ ] **Step 2: Add OLT elite scaling**

Directly after `scr_initenemy()` (or after wherever `elite = false` is set):

```gml
// OLT: scale enemy elite chance with global heat level
if (variable_global_exists("one_last_try") && global.one_last_try) {
    switch (global.heatmeter_threshold) {
        case 1: elite = (irandom(2) == 0); break;  // ~33%
        case 2: elite = (irandom(2) != 0); break;  // ~66%
        case 3: elite = true; break;               // 100%
    }
}
```

- [ ] **Step 3: Playtest**

Enable OLT (`one_last_try true`). Kill 4 enemies to reach heat level 2. Observe ~2/3 of new enemy spawns using their rage animation/dash. At heat 3, all enemies rage.

- [ ] **Step 4: Commit**

```
git add objects/obj_baddie/Create_0.gml
git commit -m "feat: OLT elite enemy scaling by heat level"
```

---

### Task 4: Pepperman — harder attacks

**Files:**
- Modify: `objects/obj_pepperman/Create_0.gml`
- Modify: `objects/obj_pepperman/Step_0.gml`

- [ ] **Step 1: Find Pepperman's key variables**

In `Create_0.gml`, search for: movement/dash speed variable, stun duration after wall hit, bounce count for the ground pound bounce attack, pepper drawing spawn timer, marble block hit counter for Phase 2.

Note each variable name before continuing.

- [ ] **Step 2: Add OLT speed and timing modifiers in Create_0.gml**

After existing variable declarations:

```gml
if (variable_global_exists("one_last_try") && global.one_last_try) {
    spd           *= 1.35;             // faster shoulder bash (replace spd with actual name)
    stun_time      = max(1, stun_time - 8); // shorter wall stun window
    bounce_count  += 2;                // more ground pound bounces
    drawing_rate  *= 0.65;             // pepper drawings spawn faster (lower = faster interval)
}
```

- [ ] **Step 3: Set marble hit count to 8 in OLT**

Find where marble block hit count is set for Phase 2 (value 6). Wrap:

```gml
var _marble_hits = (variable_global_exists("one_last_try") && global.one_last_try) ? 8 : 6;
// assign to actual marble variable here
```

- [ ] **Step 4: Make Phase 2 statues spawn in pairs**

In `Step_0.gml`, find where the sliding statue (`obj_peppermanstatue` or equivalent) is created. Wrap:

```gml
if (variable_global_exists("one_last_try") && global.one_last_try) {
    instance_create_layer(statue_x_left,  statue_y, layer, obj_peppermanstatue);
    instance_create_layer(statue_x_right, statue_y, layer, obj_peppermanstatue);
} else {
    instance_create_layer(statue_x, statue_y, layer, obj_peppermanstatue);
}
```

Replace `statue_x_left`, `statue_x_right`, `statue_x`, `statue_y`, `layer`, `obj_peppermanstatue` with actuals.

- [ ] **Step 5: Playtest**

Enable OLT, fight Pepperman. Verify: faster bashes, shorter stun window, more bounces, faster drawings, statues spawn in pairs, marble blocks need 8 hits.

- [ ] **Step 6: Commit**

```
git add objects/obj_pepperman/
git commit -m "feat: OLT Pepperman harder attacks"
```

---

### Task 5: Pepperman — extra phase and cutscene

**Files:**
- Modify: `objects/obj_pepperman/Create_0.gml`
- Modify: `objects/obj_pepperman/Step_0.gml`

- [ ] **Step 1: Add OLT phase variables to Create_0.gml**

```gml
olt_phase_triggered = false;
olt_shell_active    = false;
olt_marble_1_done   = false;
olt_marble_2_done   = false;
```

- [ ] **Step 2: Find the tiny-phase defeat condition**

In `Step_0.gml`, search for the tiny phase: where catching Tiny Pepperman and landing one hit normally ends the fight. This will be something like `if (tiny_hit)` or `if (hp <= 0 && state == states.tiny)`.

- [ ] **Step 3: Intercept defeat to trigger OLT phase**

Wrap the fight-end logic:

```gml
if (!olt_phase_triggered && variable_global_exists("one_last_try") && global.one_last_try) {
    olt_phase_triggered = true;
    olt_shell_active    = true;
    hp = 1;
    
    do_dialog([
        dialog_create("You dare lay hands on a MASTERPIECE?!"),
        dialog_create("I''ll show you real art.")
    ]);
    
    // Grow back to full size
    image_xscale = sign(image_xscale);
    image_yscale = 1;
    
    // Spawn two marble blocks
    var _m1 = instance_create_layer(128,              room_height - 96, layer, obj_peppermanmarble);
    var _m2 = instance_create_layer(room_width - 128, room_height - 96, layer, obj_peppermanmarble);
    _m1.olt_boss     = id;
    _m1.olt_block_id = 1;
    _m2.olt_boss     = id;
    _m2.olt_block_id = 2;
    
    state = states.olt_magnum_opus;
    exit;
}
```

Replace `obj_peppermanmarble` with the actual marble/block object name.

- [ ] **Step 4: Add olt_boss and olt_block_id signal-back to the marble object**

Open the marble/chisel object's script (where it becomes a statue after enough hits). When fully chiseled, add:

```gml
if (variable_instance_exists(id, "olt_boss") && instance_exists(olt_boss)) {
    if (olt_block_id == 1) olt_boss.olt_marble_1_done = true;
    if (olt_block_id == 2) olt_boss.olt_marble_2_done = true;
}
```

- [ ] **Step 5: Implement states.olt_magnum_opus in Step_0.gml**

In the boss state machine, add a new case:

```gml
case states.olt_magnum_opus:
    invulnerable = olt_shell_active;
    
    // Spawn pepper drawings rapidly
    if (drawing_timer <= 0) {
        instance_create_layer(irandom(room_width), 0, layer, obj_peppermanpainting);
        drawing_timer = 18;
    }
    drawing_timer--;
    
    // When both blocks are chiseled, remove shell
    if (olt_marble_1_done && olt_marble_2_done && olt_shell_active) {
        olt_shell_active = false;
        invulnerable     = false;
        // Pepperman walks toward nearest statue to admire — reuse existing admire logic
        state = states.admire; // existing admire/vulnerable state
    }
    break;
```

Replace `obj_peppermanpainting` with the actual pepper drawing object name.

- [ ] **Step 6: Playtest full Pepperman fight with OLT**

Complete the fight through tiny phase. Verify: cutscene fires, shell forms, drawings swarm, chiseling both blocks removes the shell, one final hit ends the fight.

- [ ] **Step 7: Commit**

```
git add objects/obj_pepperman/
git commit -m "feat: OLT Pepperman extra phase - My Magnum Opus"
```

---

### Task 6: Create obj_olt_hat_boomerang

**Files:**
- Create: `objects/obj_olt_hat_boomerang/Create_0.gml`
- Create: `objects/obj_olt_hat_boomerang/Step_0.gml`

- [ ] **Step 1: Create object in GMS2 IDE**

Right-click `objects/` → Create Object → name `obj_olt_hat_boomerang`. Assign the Vigilante's hat sprite (search `sprites/` for `hat`). Set collision mask to match. Add Create and Step events.

- [ ] **Step 2: Write Create_0.gml**

```gml
hsp          = image_xscale * 9;
bounce_count = 0;
bounce_max   = 5;
lifetime     = 300;
```

- [ ] **Step 3: Write Step_0.gml**

```gml
x        += hsp;
lifetime--;

// Bounce off walls
if (x < 16 || x > room_width - 16) {
    hsp           = -hsp;
    image_xscale  = sign(hsp);
    bounce_count++;
}

// Hurt player on contact
if (place_meeting(x, y, obj_player)) {
    with (obj_player) scr_hurtplayer();
}

if (bounce_count >= bounce_max || lifetime <= 0) instance_destroy();
```

- [ ] **Step 4: Playtest boomerang in a test room**

Temporarily place one instance. Verify it travels, bounces 5 times, hurts the player, then disappears.

- [ ] **Step 5: Commit**

```
git add objects/obj_olt_hat_boomerang/
git commit -m "feat: add obj_olt_hat_boomerang projectile"
```

---

### Task 7: The Vigilante — harder attacks + extra phase and cutscene

**Files:**
- Modify: `objects/obj_vigilante/Create_0.gml`
- Modify: `objects/obj_vigilante/Step_0.gml`

- [ ] **Step 1: Add OLT harder attack modifiers in Create_0.gml**

After existing variable declarations:

```gml
if (variable_global_exists("one_last_try") && global.one_last_try) {
    bullet_spd        *= 1.4;
    cow_bounce_max    += 3;
    cutout_rate       *= 0.7;
    duel_window        = max(4, duel_window - 6);
}

olt_phase_triggered = false;
olt_parry_count     = 0;
olt_melee_timer     = 0;
olt_melee_state     = 0;
```

- [ ] **Step 2: Add earlier John E. Cheese spawn in Phase 2**

Find the HP threshold check for John E. Cheese spawn (normally 4 HP). Change to:

```gml
var _cheese_hp = (variable_global_exists("one_last_try") && global.one_last_try) ? 6 : 4;
if (hp <= _cheese_hp && !cheese_spawned) {
    cheese_spawned = true;
    instance_create_layer(x, y, layer, obj_johncheese);
}
```

- [ ] **Step 3: Find and intercept the quick draw duel victory**

In `Step_0.gml`, find where winning the duel ends the fight. Wrap:

```gml
if (!olt_phase_triggered && variable_global_exists("one_last_try") && global.one_last_try) {
    olt_phase_triggered = true;
    
    do_dialog([
        dialog_create("...I was set up."),
        dialog_create("Pizzahead used me like a pawn."),
        dialog_create("This ain''t about the law no more.")
    ]);
    
    // Remove player revolver
    with (obj_player) {
        if (variable_instance_exists(id, "has_gun")) has_gun = false;
    }
    
    // Spawn traps
    instance_create_layer(180,              room_height - 64, layer, obj_anchortrap);
    instance_create_layer(room_width - 180, room_height - 64, layer, obj_anchortrap);
    instance_create_layer(room_width / 2,   room_height - 64, layer, obj_knighttrap);
    
    // Spawn King Ghost
    instance_create_layer(room_width / 2, 96, layer, obj_trapghost);
    
    hp    = 3;
    state = states.olt_last_stand;
    exit;
}
```

Replace `has_gun`, `obj_anchortrap`, `obj_knighttrap`, `obj_trapghost` with actual names.

- [ ] **Step 4: Implement states.olt_last_stand**

```gml
case states.olt_last_stand:
    olt_melee_timer--;
    if (olt_melee_timer <= 0) {
        olt_melee_state = (olt_melee_state + 1) mod 3;
        olt_melee_timer = 130;
        
        switch (olt_melee_state) {
            case 0: // Chained dive kicks — reuse existing dive kick state 3 times
                state = states.divekick;
                break;
            case 1: // Hat boomerang
                var _b = instance_create_layer(x, y - 16, layer, obj_olt_hat_boomerang);
                _b.image_xscale = image_xscale;
                _b.hsp          = image_xscale * 9;
                break;
            case 2: // Flamethrower — reuse existing flamethrower state
                state = states.flamethrower;
                break;
        }
    }
    
    // Parry detection: use existing parry flag
    if (variable_instance_exists(id, "parried") && parried) {
        parried = false;
        olt_parry_count++;
        audio_play_sound(snd_parry, 0, false); // replace with actual parry sound name
        if (olt_parry_count >= 3) {
            with (obj_trapghost)  instance_destroy();
            state = states.death;
        }
    }
    break;
```

Replace `states.divekick`, `states.flamethrower`, `states.death`, `snd_parry` with actual names.

- [ ] **Step 5: Playtest full Vigilante fight with OLT**

Verify: faster bullets, earlier cheese spawn, duel victory triggers cutscene, traps and King Ghost spawn, Vigilante goes melee, 3 parries end the fight.

- [ ] **Step 6: Commit**

```
git add objects/obj_vigilante/ objects/obj_olt_hat_boomerang/
git commit -m "feat: OLT Vigilante harder attacks and extra phase - This Ain't Over"
```

---

### Task 8: The Noise — harder attacks + extra phase and cutscene

**Files:**
- Modify: `objects/obj_noise/Create_0.gml` (verify actual boss object — may be `obj_noiseboss`)
- Modify: `objects/obj_noise/Step_0.gml`
- Create: `objects/obj_noise/Alarm_9.gml`

- [ ] **Step 1: Add OLT harder attack modifiers in Create_0.gml**

```gml
if (variable_global_exists("one_last_try") && global.one_last_try) {
    skateboard_kick_delay  = max(5, skateboard_kick_delay - 15);
    pogo_bomb_every_bounce = true;
    noisey_spawn_rate      = floor(noisey_spawn_rate * 0.6);
    jetpack_explode_radius *= 1.5;
    balloon_decoy_always   = true;
}

olt_phase_triggered  = false;
olt_armor_hits       = 0;
olt_damage_hits      = 0;
olt_cycle            = 0;
olt_window_open      = false;
olt_attack_active    = false;
olt_super_started    = false;
olt_super_timer      = 0;
```

- [ ] **Step 2: Apply balloon_decoy_always**

Find the balloon decoy condition. Add to it:

```gml
var _use_decoy = balloon_decoy_triggered
              || (variable_instance_exists(id, "balloon_decoy_always") && balloon_decoy_always);
```

- [ ] **Step 3: Apply pogo_bomb_every_bounce**

Find the pogo attack's bomb drop condition (currently occasional). Wrap:

```gml
var _drop_bomb = pogo_bomb_every_bounce || (irandom(1) == 0); // original occasional logic
if (_drop_bomb) {
    instance_create_layer(x, y, layer, obj_noise_bomb);
}
```

- [ ] **Step 4: Find the Noisette-drags-Noise fight-end event**

Wrap the defeat:

```gml
if (!olt_phase_triggered && variable_global_exists("one_last_try") && global.one_last_try) {
    olt_phase_triggered = true;
    alarm[9] = 90; // delay before crash-back-in
    exit;
}
```

- [ ] **Step 5: Write Alarm_9.gml**

```gml
// Noise crashes back in with armor
do_dialog([
    dialog_create("LADIES AND GENTLEMEN—"),
    dialog_create("YOU THOUGHT THE SHOW WAS OVER?!"),
    dialog_create("THIS. IS. MY. FINALE.")
]);

olt_cycle        = 0;
olt_attack_active = false;
state            = states.olt_armor_phase;
```

- [ ] **Step 6: Implement states.olt_armor_phase, olt_taunt_window, olt_super_attempt**

```gml
case states.olt_armor_phase:
    invulnerable = true;

    switch (olt_cycle) {
        case 0: // Rocket Noise: bounce wall-to-wall
            if (!olt_attack_active) {
                olt_attack_active = true;
                hsp = image_xscale * 11;
            }
            x += hsp;
            if (x < 32 || x > room_width - 32) {
                hsp          = -hsp;
                image_xscale = sign(hsp);
            }
            break;

        case 1: // Knight Noise: ground pound and shockwave
            if (!olt_attack_active) {
                olt_attack_active = true;
                // Reuse existing ground pound state, return to olt_armor_phase after
                state = states.groundpound;
            }
            break;

        case 2: // Ghost Noise: dash through player repeatedly
            invulnerable = true;
            if (!olt_attack_active) {
                olt_attack_active = true;
                olt_dash_count    = 4;
                olt_dash_timer    = 40;
            }
            olt_dash_timer--;
            if (olt_dash_timer <= 0 && olt_dash_count > 0) {
                olt_dash_count--;
                olt_dash_timer = 40;
                // Dash toward player x
                hsp = (obj_player.x > x) ? 14 : -14;
            }
            x += hsp;
            if (x < 16 || x > room_width - 16) {
                hsp = 0;
                if (olt_dash_count <= 0) olt_attack_active = false;
            }
            if (!olt_attack_active) {
                hsp = 0;
                // Check for Noisey hit (see Step 7)
            }
            break;
    }

    // Noisey-hit detection handled in Step 7
    break;

case states.olt_taunt_window:
    // Reuse existing taunt animation — player can land one hit
    if (hit_this_frame) {
        hit_this_frame  = false;
        olt_damage_hits++;
        olt_window_open = false;

        if (olt_damage_hits >= 3) {
            state = states.olt_super_attempt;
        } else {
            olt_cycle         = (olt_cycle + 1) mod 3;
            olt_attack_active = false;
            olt_armor_hits    = 0;
            state             = states.olt_armor_phase;
        }
    }
    break;

case states.olt_super_attempt:
    if (!olt_super_started) {
        olt_super_started = true;
        olt_super_timer   = 120;
        invulnerable      = false;
        // Play Super Noise sprite
    }
    olt_super_timer--;

    if (hit_this_frame) {
        state = states.death;
    } else if (olt_super_timer <= 0) {
        // Bomb detonates — hurt player, reset to cycle 2
        with (obj_player) scr_hurtplayer();
        with (obj_player) scr_hurtplayer(); // 2 damage
        olt_super_started = false;
        olt_cycle         = 2;
        olt_damage_hits   = 2;
        olt_attack_active = false;
        state             = states.olt_armor_phase;
    }
    break;
```

Replace `states.groundpound`, `states.death`, `hit_this_frame`, `hit_taken` with actual names.

- [ ] **Step 7: Wire Noisey throws to crack armor**

Find where the player throws a Noisey and it deals damage. When it hits the Noise boss and he's in `olt_armor_phase`, intercept:

```gml
// In Noisey collision / throw-hit logic on obj_noise:
if (state == states.olt_armor_phase) {
    olt_armor_hits++;
    if (olt_armor_hits >= 3) {
        olt_armor_hits    = 0;
        olt_attack_active = false;
        invulnerable      = false;
        state             = states.olt_taunt_window;
    }
    exit; // don't apply normal damage
}
```

- [ ] **Step 8: Playtest full Noise fight with OLT**

Verify: harder Phase 1 & 2 attacks, cutscene fires, Noise crashes back in, armor cycles through Rocket/Knight/Ghost, 3 Noisey throws crack armor, taunt window opens, Super Noise attempt at end.

- [ ] **Step 9: Commit**

```
git add objects/obj_noise/
git commit -m "feat: OLT Noise harder attacks and extra phase - One Final Trick"
```

---

### Task 9: Fake Peppino — harder attacks + extra phase and cutscene

**Files:**
- Modify: `objects/obj_fakepeppino/Create_0.gml`
- Modify: `objects/obj_fakepeppino/Step_0.gml`
- Create: `objects/obj_fakepeppino/Alarm_8.gml`

- [ ] **Step 1: Add OLT harder attack modifiers in Create_0.gml**

```gml
if (variable_global_exists("one_last_try") && global.one_last_try) {
    grabs_required     = 3;              // up from 2
    head_throw_spd    *= 1.3;
    body_linger_time  += 30;
    taunt_spread      *= 1.4;
    chase_spd         *= 1.2;
}

olt_phase_triggered  = false;
olt_giant_hp         = 3;
olt_giant_stun       = false;
olt_giant_stun_timer = 0;
olt_grabs_on_giant   = 0;
olt_attack_timer     = 80;
olt_current_attack   = 0;
```

- [ ] **Step 2: Make clone safe-gap shift faster**

Find the gap-shift timer in the clone line attack. Replace the value:

```gml
var _gap_time = (variable_global_exists("one_last_try") && global.one_last_try) ? 42 : 70;
// use _gap_time instead of hardcoded value
```

- [ ] **Step 3: Find the chase exit trigger**

Find where the chase sequence ends when Peppino reaches the exit (room transition trigger or exit-zone object). Intercept:

```gml
if (!olt_phase_triggered && variable_global_exists("one_last_try") && global.one_last_try) {
    olt_phase_triggered = true;

    do_dialog([dialog_create("you cant leave")]);

    scr_screenshake(30, 4); // use actual screenshake function name
    alarm[8] = 75;
    exit; // cancel room transition
}
```

- [ ] **Step 4: Write Alarm_8.gml (giant enters arena)**

```gml
image_xscale = 3 * sign(image_xscale);
image_yscale = 3;
x            = room_width / 2;
y            = room_height - 80;
state        = states.olt_giant;
```

- [ ] **Step 5: Implement olt_giant, olt_giant_swipe, olt_giant_slam, olt_giant_split, olt_giant_sink states**

```gml
case states.olt_giant:
    olt_attack_timer--;
    if (olt_attack_timer <= 0) {
        olt_attack_timer   = 110;
        olt_current_attack = irandom(2);
        switch (olt_current_attack) {
            case 0: state = states.olt_giant_swipe; break;
            case 1: state = states.olt_giant_slam;  break;
            case 2: state = states.olt_giant_split; break;
        }
    }

    if (olt_giant_stun) {
        olt_giant_stun_timer--;
        if (olt_giant_stun_timer <= 0) olt_giant_stun = false;

        // Player grab input while stunned
        if (place_meeting(x, y, obj_player)) {
            with (obj_player) {
                if (grab_held) { // replace grab_held with actual grab input variable
                    other.olt_grabs_on_giant++;
                    other.olt_giant_stun       = false;
                    other.olt_giant_stun_timer = 0;
                    if (other.olt_grabs_on_giant >= 3) {
                        other.state = states.olt_giant_sink;
                    } else {
                        other.state = states.olt_giant;
                    }
                }
            }
        }
    }
    break;

case states.olt_giant_swipe:
    // Slow horizontal arm sweep at ground level — player must jump
    // Use a large hitbox moving across the room, then stun on completion
    x += 2 * image_xscale;
    if (x < 32 || x > room_width - 32) {
        image_xscale      = -image_xscale;
        olt_giant_stun    = true;
        olt_giant_stun_timer = 90;
        state = states.olt_giant;
    }
    if (place_meeting(x, y + 16, obj_player)) {
        with (obj_player) scr_hurtplayer();
    }
    break;

case states.olt_giant_slam:
    // Slam face down, two shockwaves outward
    if (!variable_instance_exists(id, "slam_done") || !slam_done) {
        slam_done = true;
        instance_create_layer(x - 32, y, layer, obj_olt_shockwave);
        var _s2 = instance_create_layer(x + 32, y, layer, obj_olt_shockwave);
        _s2.hsp = -_s2.hsp; // travel left
        olt_giant_stun       = true;
        olt_giant_stun_timer = 80;
    }
    slam_done = false;
    state     = states.olt_giant;
    break;

case states.olt_giant_split:
    // Release wave of invulnerable small clones
    repeat(6) {
        var _cx = x + irandom_range(-200, 200);
        var _cy = room_height - 48;
        var _c  = instance_create_layer(_cx, _cy, layer, obj_fakepeppino_clone);
        _c.image_xscale = choose(-1, 1);
    }
    state = states.olt_giant;
    break;

case states.olt_giant_sink:
    y           += 3;
    image_alpha -= 0.015;
    if (image_alpha <= 0) instance_destroy();
    break;
```

Replace `obj_olt_shockwave` (created in Task 11), `obj_fakepeppino_clone`, `grab_held`, state names with actuals.

- [ ] **Step 6: Playtest full Fake Peppino fight with OLT**

Verify: 3 grabs needed, gap shifts faster, "you cant leave" text fires at exit, giant enters, swipe/slam/split work, 3 grabs sink the giant.

- [ ] **Step 7: Commit**

```
git add objects/obj_fakepeppino/
git commit -m "feat: OLT Fake Peppino harder attacks and extra phase - You Can't Leave"
```

---

### Task 10: Create obj_olt_shockwave

**Files:**
- Create: `objects/obj_olt_shockwave/Create_0.gml`
- Create: `objects/obj_olt_shockwave/Step_0.gml`

*(This object is used by both the Fake Peppino giant slam and the Pizzahead "GET OUT" scream.)*

- [ ] **Step 1: Create the object in GMS2 IDE**

Right-click `objects/` → Create Object → name `obj_olt_shockwave`. Assign a low wide collision mask. Add Create and Step events.

- [ ] **Step 2: Write Create_0.gml**

```gml
hsp      = 6;    // travels right by default; spawner flips hsp for leftward copy
lifetime = 100;
low      = true; // if true: player must CROUCH to dodge; if false: player must JUMP
```

- [ ] **Step 3: Write Step_0.gml**

```gml
x        += hsp;
lifetime--;

if (place_meeting(x, y, obj_player)) {
    with (obj_player) {
        var _safe = (other.low) ? crouching : (y < other.y); // crouching or above
        if (!_safe) scr_hurtplayer();
    }
}

if (x < -32 || x > room_width + 32 || lifetime <= 0) instance_destroy();
```

Replace `crouching` with the actual player crouch variable name.

- [ ] **Step 4: Playtest shockwave**

Place one in a test room. Verify it travels, hurts upright player, does not hurt crouching player, then disappears.

- [ ] **Step 5: Commit**

```
git add objects/obj_olt_shockwave/
git commit -m "feat: add obj_olt_shockwave (crouch-to-dodge hazard)"
```

---

### Task 11: Create obj_olt_laser_bar

**Files:**
- Create: `objects/obj_olt_laser_bar/Create_0.gml`
- Create: `objects/obj_olt_laser_bar/Step_0.gml`
- Create: `objects/obj_olt_laser_bar/Draw_64.gml`

- [ ] **Step 1: Create the object in GMS2 IDE**

Right-click `objects/` → Create Object → name `obj_olt_laser_bar`. No sprite. Add Create, Step, Draw GUI events.

- [ ] **Step 2: Write Create_0.gml**

```gml
charge      = 0;
charge_rate = 0.09; // fills to 100 in ~70 seconds at 60fps — tune during playtest
bar_x       = 16;
bar_y       = 16;
bar_w       = 180;
bar_h       = 18;
```

- [ ] **Step 3: Write Step_0.gml**

```gml
charge += charge_rate;

if (charge >= 100) {
    // Peppino's Pizza is destroyed — kill the player
    with (obj_player) {
        hp = 0;
        scr_hurtplayer(); // or scr_killplayer() — use whichever causes instant death
    }
    instance_destroy();
}
```

- [ ] **Step 4: Write Draw_64.gml**

```gml
// Background
draw_set_color(c_dkgray);
draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, false);

// Fill (pulses red when > 80%)
var _fill = (charge / 100) * bar_w;
var _col  = (charge > 80)
          ? make_color_rgb(255, irandom_range(0, 40), 0)
          : c_red;
draw_set_color(_col);
draw_rectangle(bar_x, bar_y, bar_x + _fill, bar_y + bar_h, false);

// Label
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_font(font0);
draw_text(bar_x, bar_y - 18, "PEPPINO'S PIZZA");
draw_reset_font();
```

- [ ] **Step 5: Playtest laser bar in isolation**

Temporarily place in a test room. Verify bar fills in ~70 seconds, pulses red above 80%, kills the player at 100%.

- [ ] **Step 6: Commit**

```
git add objects/obj_olt_laser_bar/
git commit -m "feat: add obj_olt_laser_bar UI"
```

---

### Task 12: Pizzaface / Pizzahead — harder attacks + Phase 5 "GET OUT"

**Files:**
- Modify: `objects/obj_pizzaface/Step_0.gml`
- Modify: `objects/obj_pizzahead/Create_0.gml`
- Modify: `objects/obj_pizzahead/Step_0.gml`

- [ ] **Step 1: Pizzaface Phase 1 — faster enemy spawns**

In `obj_pizzaface/Step_0.gml`, find the enemy spawn timer. Wrap:

```gml
var _rate = (variable_global_exists("one_last_try") && global.one_last_try)
          ? floor(spawn_timer * 0.7) : spawn_timer;
```

- [ ] **Step 2: Pizzahead Phase 2 — OLT modifiers in Create_0.gml**

```gml
olt_phase_triggered = false;

if (variable_global_exists("one_last_try") && global.one_last_try) {
    move_spd      *= 1.25;
    rat_bounce_max += 3;
    cog_drop_rate  = floor(cog_drop_rate * 0.55); // Broken Pizzaface drops cogs faster
}
```

- [ ] **Step 3: Phase 4 — start at 2 attacks immediately**

Find where Phase 4 combo count is initialized (starts at 1):

```gml
var _start_combo = (variable_global_exists("one_last_try") && global.one_last_try) ? 2 : 1;
attack_combo_count = _start_combo;
```

- [ ] **Step 4: Hook Phase 5 after Phase 4's final hit**

Find Phase 4's defeat condition. Wrap:

```gml
if (!olt_phase_triggered && variable_global_exists("one_last_try") && global.one_last_try) {
    olt_phase_triggered = true;
    hp = 4;

    do_dialog([
        dialog_create("Heh..."),
        dialog_create("You really thought you won?"),
        dialog_create("GET. OUT.")
    ]);

    // Reboot Broken Pizzaface with laser mode
    if (instance_exists(obj_pizzaface_broken)) {
        with (obj_pizzaface_broken) olt_laser_mode = true;
    } else {
        var _pf = instance_create_layer(room_width / 2, 48, layer, obj_pizzaface_broken);
        _pf.olt_laser_mode = true;
    }

    // Spawn laser charge bar
    instance_create_layer(0, 0, layer, obj_olt_laser_bar);

    state = states.olt_get_out;
    exit;
}
```

Replace `obj_pizzaface_broken` with the actual broken Pizzaface object name.

- [ ] **Step 5: Implement states.olt_get_out and sub-states**

```gml
case states.olt_get_out:
    attack_timer--;
    if (attack_timer <= 0) {
        attack_timer    = 105;
        current_attack  = irandom(5);

        switch (current_attack) {
            case 0: state = states.olt_spin_punch;  break;
            case 1: state = states.olt_spin_kick;   break;
            case 2: state = states.olt_face_slam;   break;
            case 3: state = states.olt_scream;      break;
            case 4: state = states.olt_gustavo;     break;
            case 5: state = states.olt_rat_heal;    break;
        }
    }
    break;

case states.olt_spin_punch:
    // Charge across arena fists-first
    hsp = image_xscale * 10;
    x  += hsp;
    if (place_meeting(x, y, obj_player)) {
        with (obj_player) scr_hurtplayer();
    }
    if (x < 0 || x > room_width) {
        hsp   = 0;
        state = states.olt_get_out;
    }
    break;

case states.olt_spin_kick:
    // Wide kick sweep — player must jump
    if (!variable_instance_exists(id, "kick_done") || !kick_done) {
        kick_done = true;
        // Create a wide low hitbox sweeping across the room
        var _k = instance_create_layer(x, y + 8, layer, obj_olt_shockwave);
        _k.hsp = image_xscale * 8;
        _k.low = false; // player must jump, not crouch
    }
    kick_done = false;
    state     = states.olt_get_out;
    break;

case states.olt_face_slam:
    // Slam face into ground, then charge full room length
    if (!variable_instance_exists(id, "slam_phase") || slam_phase == 0) {
        slam_phase = 1;
        vsp = 8;
    }
    if (slam_phase == 1) {
        y += vsp;
        if (place_meeting(x, y + 1, obj_solid)) {
            slam_phase = 2;
            hsp        = image_xscale * 12;
            scr_screenshake(20, 3);
        }
    }
    if (slam_phase == 2) {
        x += hsp;
        if (place_meeting(x, y, obj_player)) {
            with (obj_player) scr_hurtplayer();
        }
        if (x < 16 || x > room_width - 16) {
            slam_phase = 0;
            hsp        = 0;
            state      = states.olt_get_out;
        }
    }
    break;

case states.olt_scream:
    // "GET OUT" scream — low shockwave, player must CROUCH
    if (!variable_instance_exists(id, "scream_fired") || !scream_fired) {
        scream_fired  = true;
        var _sw_r     = instance_create_layer(x + 16, y + 8, layer, obj_olt_shockwave);
        var _sw_l     = instance_create_layer(x - 16, y + 8, layer, obj_olt_shockwave);
        _sw_r.hsp     =  7;
        _sw_l.hsp     = -7;
        _sw_r.low     = true;
        _sw_l.low     = true;
        // Play scream sound + show "GET OUT" text
        audio_play_sound(snd_peppino_scream, 0, false); // use any available scream sound
    }
    scream_fired = false;
    alarm[0]     = 60;
    state        = states.olt_scream_wait;
    break;

case states.olt_scream_wait:
    // Wait for shockwaves to clear
    break; // Alarm_0 will return to olt_get_out — add: state = states.olt_get_out; in Alarm_0

case states.olt_gustavo:
    // Grab Gustavo offscreen, throw him as a projectile
    var _g = instance_create_layer(room_width + 32, room_height / 2, layer, obj_gustavo);
    _g.hsp           = -9;
    _g.is_projectile = true; // set a flag so Gustavo object hurts player when is_projectile is true
    state            = states.olt_get_out;
    break;

case states.olt_rat_heal:
    // Stuff Stupid Rat in mouth — player must interrupt within 80 frames
    if (!variable_instance_exists(id, "rat_heal_timer")) rat_heal_timer = 0;
    if (rat_heal_timer <= 0) {
        rat_heal_timer = 80;
        // Play eating animation
    }
    rat_heal_timer--;
    if (rat_heal_timer <= 0) {
        hp = min(hp + 1, 4);
        state = states.olt_get_out;
    }
    // If player lands a hit during this state, interrupt heal
    // (handled by normal hit detection — on hit, set state = states.olt_get_out)
    break;
```

- [ ] **Step 6: Wire Broken Pizzaface cog drop rate to olt_laser_mode**

Find `obj_pizzaface_broken`'s Step. Wrap cog drop timer:

```gml
var _cog_rate = (variable_instance_exists(id, "olt_laser_mode") && olt_laser_mode)
              ? floor(cog_drop_timer * 0.5)
              : cog_drop_timer;
```

- [ ] **Step 7: Tune laser bar charge_rate during playtest**

The bar should give the player enough time to land 4 hits under pressure, but not so much that the pressure is meaningless. Start with `charge_rate = 0.09` (~70 seconds). Adjust in `obj_olt_laser_bar/Create_0.gml` based on feel.

- [ ] **Step 8: Playtest full Pizzahead fight with OLT**

Complete all 4 phases. Verify: Phase 1 spawns faster, Phase 2 Pizzahead moves faster + Rat bounces more, Phase 4 starts at 2 attacks, cutscene fires after Phase 4's last hit, Broken Pizzaface reboots, laser bar appears, scrapped moveset activates, Rat heal is interruptible, laser kills on full charge, 4 hits win.

- [ ] **Step 9: Commit**

```
git add objects/obj_pizzaface/ objects/obj_pizzahead/ objects/obj_olt_shockwave/ objects/obj_olt_laser_bar/
git commit -m "feat: OLT Pizzahead harder attacks and extra phase - GET OUT"
```

---

### Task 13: Final integration and push

- [ ] **Step 1: Full playthrough — OLT enabled, no hardmode**

Enable `one_last_try true`, disable hardmode. Play through all 5 bosses. Verify: heat meter appears in regular stages, elite enemies scale by heat level, all 5 harder attack sets are active, all 5 extra phases trigger with correct cutscenes.

- [ ] **Step 2: Full playthrough — OLT disabled**

Disable `one_last_try false`. Play through all 5 bosses. Verify the base game is completely unaffected — no speed changes, no extra phases, no crashes.

- [ ] **Step 3: Full playthrough — OLT and hardmode both enabled**

Enable both. Verify no conflicts: ghost spawner from hardmode + elite scaling from OLT both run, heat meter displays once (not doubled), boss phases trigger correctly.

- [ ] **Step 4: Final commit and push**

```
git add .
git commit -m "feat: One Last Try mode — complete implementation"
git push origin master
```
