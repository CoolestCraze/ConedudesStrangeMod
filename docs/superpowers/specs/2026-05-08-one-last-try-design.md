# One Last Try — Design Spec
**Date:** 2026-05-08
**Project:** ConedudesStrangeMod (Pizza Tower GMS2)

---

## Overview

"One Last Try" is a standalone difficulty mode added to ConedudesStrangeMod. It is separate from the existing hardmode system, though it reuses the heat meter infrastructure. When active, it does three things:

1. **Enemy heat attacks** — enemies become elite (aggressive rage state) based on the global heat level
2. **Harder boss attacks** — existing boss phases are more punishing
3. **Extra boss phases** — all 5 main story bosses (Pepperman, The Vigilante, The Noise, Fake Peppino, Pizzaface/Pizzahead) gain one additional phase after their normal fight ends

The mode is designed to feel like the game's final desperate resistance — every enemy and boss giving everything they have. Narratively it fits before the ending reconciliation: all bosses survive their extra phases, they're just beaten badly enough to stand down.

---

## Mode Architecture

### New Object: `obj_one_last_try`

Persistent object (like `obj_hardmode`), present across all rooms when the mode is active.

**Globals initialized:**
```gml
global.one_last_try = false
global.heatmeter_threshold = 0      // initialized here so OLT works without obj_hardmode
global.heatmeter_count = 0
global.heatmeter_threshold_max = 3
global.heatmeter_threshold_count = 2
```

`obj_one_last_try` initializes the heat meter globals itself so the system works whether or not `obj_hardmode` is also present. If both exist, `obj_hardmode` initializes them first and `obj_one_last_try` simply reads the same globals. Both objects can coexist.

**Debug command:** `one_last_try <bool>` — mirrors the existing `hardmode <bool>` pattern in `obj_debugcontroller`.

### Per-Boss OLT Phase Flag

Each boss object gets a local variable `olt_phase_triggered = false` set in its Create event. The extra phase fires once when the normal fight ends and sets this to true so it never loops.

---

## Enemy Heat Meter Attacks

Enemies already have a fully implemented `elite` flag and rage state (`states.rage`, `spr_*_rage`, `create_heatattack_afterimage()`). The code is active but the flag is never set to true. OLT activates it based on heat level.

**Implementation:** In `obj_baddie`'s Create event (or a shared enemy init script), when `global.one_last_try` is true:

| Heat Level | Elite Probability |
|---|---|
| 0 | 0% (normal) |
| 1 | ~33% of enemies spawn elite |
| 2 | ~66% of enemies spawn elite |
| 3 | 100% of enemies spawn elite |

This uses the existing rage dash, hitbox creation, and afterimage system with zero new enemy code.

---

## Boss Changes

### Pepperman

**Harder existing attacks:**
- Shoulder bash and drift are faster; wall stun window is shorter
- Ground pound bounce ricochets more times
- Art marble blocks require 8 hits to chisel (up from 6 in Phase 2)
- Pepper drawings spawn more frequently and move faster
- Sliding statues in Phase 2 come in pairs instead of singles

**Extra Phase — "My Magnum Opus"**

*Trigger:* Tiny Pepperman is caught and hit. Instead of ending the fight, Pepperman snaps and grows back to full size.

*Mechanic:* Pepperman encases himself in a giant marble statue shell — invulnerable to all normal attacks. Two art marble blocks spawn. The player must chisel both into Pepperman statues (8 hits each). While doing this:
- Animated pepper drawings swarm the arena nonstop
- Sliding statue pairs keep coming

Once both blocks are chiseled, Pepperman stops to admire them (his existing vulnerable "admiring" state). The marble shell shatters — one final hit ends the fight.

*Lore note:* Pepperman was recruited by Pizzahead via a personal art studio offer. His ego is his defining trait; encasing himself in his own likeness is entirely in character.

---

### The Vigilante

**Harder existing attacks:**
- Bullets travel faster in both phases
- Cardboard cutout drops earlier and more frequently
- John E. Cheese spawns from 6 HP in Phase 2 (instead of 4)
- Cow bounces more times and faster
- Dynamite scatter spread is wider
- Quick draw duel window is tighter

**Extra Phase — "This Ain't Over"**

*Trigger:* Quick draw duel ends. Instead of going down, The Vigilante gets back up.

*Setup:* He throws away his revolver. The player's revolver also disappears. The arena stays dark from Phase 2. Three traps spawn in the arena (anchor trap + knight trap combination) — these use the existing `obj_anchortrap` and `obj_knighttrap` objects. **King Ghost** (`obj_trapghost`) materialises and behaves exactly as coded: he floats toward the nearest trap and possesses it, using his existing anchor drop and knight electrocute attacks.

*Vigilante attacks (pure melee):*
- Relentless chained dive kicks (reuses existing dive kick logic)
- Hat boomerang — new attack: throws his hat as a projectile that bounces wall-to-wall several times before returning; requires new projectile object
- Full-arena flamethrower sweep: low pass then high pass — player must jump over low, duck the high (reuses existing flamethrower)

*John E. Cheese* continues spawning throughout.

*Win condition:* Successfully **parry** The Vigilante's attacks — 3 parries stagger him enough to end the fight. King Ghost disappears when Vigi goes down.

*Lore note:* The Vigilante is an honorable Cheeseslime lawman who was manipulated by Pizzahead via a fake wanted poster. His rage in this phase is the fury of someone who was genuinely deceived. King Ghost being a crowned Cheeseslime ancestor fits as fan-lore; both are Cheeseslimes, and the Ghost King rules Pizzascare's ghost castle.

---

### The Noise

**Harder existing attacks:**
- Skateboard kick projectile triggers earlier (less warning)
- Pogo stick drops a bomb on every bounce instead of occasionally
- Phase 2 balloon decoy fake-out is active from the very first use
- Jetpack explosion radius is larger
- Noiseys spawn faster in Phase 2

**Extra Phase — "One Final Trick"**

*Trigger:* Noisette drags The Noise offscreen. He breaks free and crashes back into the arena.

*Setup:* The Noise re-enters wearing a cobbled suit of armor made from all his gadgets combined. No taunt windows between attacks. The only way to stagger him is to grab a Noisey and throw it — 3 Noisey hits crack the armor. Once cracked, a normal taunt window opens for one damage hit. Repeat 3 times.

*Each of the 3 armor-break cycles uses a different transformation:*

- **Cycle 1 — Rocket Noise:** He eats a rocket and launches himself wall-to-wall across the arena bouncing chaotically (his playable rocket form behavior)
- **Cycle 2 — Knight Noise:** Dons knight armor, double-jumps and ground-pounds with his sword, sending floor shockwaves
- **Cycle 3 — Ghost Noise:** Goes fully invincible and dashes through the player repeatedly; Noiseys still stagger him but direct hits do nothing

*Final attempt:* After 3 damage hits, he tries to go **Super Noise** — pulls out the giant Noise Bomb. Player has a brief window to land the finishing hit. Miss it and the bomb detonates (large damage) and the cycle resets to Cycle 3.

*Lore note:* The Noise is Peppino's pre-existing archrival and an NTV TV star. His extra phase is pure showmanship — he's putting on one final performance. The transformation sequence is literally him cycling through his greatest hits.

---

### Fake Peppino

**Harder existing attacks:**
- Damage combo requires 3 grabs + 1 hit (up from 2+1)
- Clone safe-gap shifts faster in Phase 2
- Head throw moves faster, headless body lingers longer
- Super taunt projectile spread is wider
- Chase sequence is faster with tighter obstacle windows

**Extra Phase — "You Can't Leave"**

*Trigger:* Player reaches the exit at the end of the chase hallway. Ground breaks again. The giant Fake Peppino crashes into a proper open arena.

*Stats:* 3 HP.

*Attacks:*
- **Giant swipe** — slow horizontal arm sweep along the ground; must jump over it
- **Face slam** — slams his face down creating two outward floor shockwaves
- **Face split** — tears face open releasing a wave of small invulnerable clone Fake Peppinos that scatter across the arena (same clone logic from Phase 2)

*Win condition:* Parry his swipe to stun him, then land a grab. 3 grabs end the fight. He never truly dies — on the third grab he sinks silently into the floor and is gone.

*Lore note:* Fake Peppino's origins are deliberately unexplained — he is Bruno Pizza's mysterious doppelganger. He never dies in the base game either (Peppino just escapes). Keeping that pattern in the extra phase preserves the character's unsettling nature.

---

### Pizzaface / Pizzahead

**Harder existing attacks:**
- Phase 1: Pizzaface spawns harder enemies sooner, wave escalation is accelerated
- Phase 2: Pizzahead moves faster from the start; Stupid Rat bounces more; Broken Pizzaface drops cogs faster
- Phase 4: Attack combinations begin from the first exchange (2 attacks immediately)

**Extra Phase — "GET OUT"**

*Trigger:* Phase 4's final hit lands. Pizzahead stumbles — then smiles.

*Cutscene:*
Broken Pizzaface reboots, eyes glowing red. Pizzahead points toward Peppino's Pizza on the horizon. Pizzaface begins charging a massive laser directly at it. Pizzahead turns back to Peppino, cracks his knuckles. The phase begins.

This is a direct narrative callback to the game's opening scene — Pizzaface threatening to destroy Peppino's Pizza with a laser is exactly why Peppino climbed the tower. In One Last Try, that threat becomes real.

*Phase 5 — "GET OUT":*

A **laser charge bar** fills on screen. When it hits 100%, Peppino's Pizza is destroyed — instant death. Broken Pizzaface rains cogs continuously and aggressively throughout the entire phase.

Pizzahead drops all props and uses the scrapped moveset:
- **Spinning punch** — spins across the arena fists-first
- **Spin-kick** — wide sweeping kick, must jump
- **Face-slam dash** — slams face into ground then charges the full arena length
- **"GET OUT" scream** — horizontal shockwave, player must **crouch** to avoid it
- **Gustavo throw** — reaches offscreen, grabs Gustavo, hurls him as a projectile (Gustavo is Peppino's ally — Pizzahead weaponizing him is a deliberate cruelty)
- **Stupid Rat health steal** — stuffs the Stupid Rat into his own mouth to regain 1 HP; player must interrupt by landing a hit first

The Stupid Rat heal means passive play loses — the player must stay aggressive or Pizzahead heals faster than they damage him.

*Win condition:* Land 4 hits on Pizzahead before the laser bar fills.

*Victory cutscene:* Fourth hit lands. Pizzahead collapses. Pizzaface's laser fizzles and dies. Peppino's Pizza is saved — again.

*Lore note:* Pizzahead is Peppino's old business rival who built the tower purely to ruin him. Phase 5 strips away everything cartoonish about him and shows the raw obsessive hatred underneath. The `spr_pizzahead_bigkickstart` sprite already exists in the game files as a remnant of this scrapped content.

---

## What's Out of Scope

- New enemy types
- New music (reuse existing tracks)
- Changes to level layouts
- New UI elements beyond the laser charge bar and existing heat meter

---

## Open Questions

- Should the laser charge bar share screen space with the existing heat meter, or have its own position?
- Should OLT be unlockable (e.g. beat the game first) or always available via debug toggle?
