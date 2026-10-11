# RAGE TAP — MASTER SPECIFICATION (Design + Architecture + Requirements)

> **This file is the single source of truth.** The companion file `RAGE_TAP_PROMPTS.md` contains the step-by-step prompts. When a prompt says "per SPEC §8.3", read that section of this file and follow it exactly. If the spec and your own idea conflict, the spec wins. If the spec is ambiguous or technically impossible with the installed package versions, STOP and ask the human instead of guessing.

---

## 0. HOW TO USE THIS FILE

### 0.1 Rules for the AI agent (apply to every task)

1. Work on **one prompt at a time**. Never build features that belong to a later prompt.
2. Before editing, **inspect the existing project** and read the relevant spec sections.
3. After every task: run `flutter analyze` (must be clean) and `flutter test` (must pass), then summarize **which files were created/changed and why**.
4. **Never rewrite working code** to fix a small issue. Make the smallest change that fixes it.
5. Use only the packages listed in §3. Do not add packages without asking.
6. **Flame's API changes between versions.** After adding Flame, read the installed version's documentation/source in the pub cache (or its changelog) and use APIs that exist in the installed version. Never assume API names from memory.
7. All art is **drawn in code** (Canvas/Paths). Do not download, generate, or reference image files except where §19 explicitly requires (icon, store graphics). All sounds are **synthesized by a script** (§13).
8. Keep gameplay constants in `lib/core/constants.dart` (Appendix A). **No magic numbers** in game code.
9. Commit to Git after each completed task with message `Prompt X.Y: <short title>`.
10. If something is unclear, ask a question. Do not invent requirements, revenue claims, or store policies.

### 0.2 Decisions the human must make (agent: ask if not answered)

| # | Decision | Needed by |
|---|---|---|
| 1 | Android `applicationId`, e.g. `com.yourname.ragetap` (must be unique on Play, cannot change after publishing) | Prompt 7.1 |
| 2 | Developer/publisher display name for credits | Prompt 3.8 |
| 3 | Is the Play developer account a *personal account created after 13 Nov 2023*? (If yes, closed testing with 12 testers for 14 continuous days is required before production access — verify in Play Console.) | Before Phase 6 |
| 4 | Where to host the privacy policy (free option: GitHub Pages or a Google Sites page) | Prompt 7.3 |
| 5 | Final public name (working title "Rage Tap" — search Play Store/trademarks for conflicts; fallback "Rage Tap: One Tap Challenge") | Prompt 7.1 |

---

## 1. PRODUCT SUMMARY

- **Name:** Rage Tap (working title)
- **Genre:** 2D one-tap arcade survival ("auto-runner jumper")
- **Platform:** Android, **portrait only**, phones (tablets must not break but are not optimized)
- **Engine/stack:** Flutter + Dart + Flame
- **Connectivity:** **Fully offline.** No accounts, no backend, no player communication, no cloud save, no analytics SDK in v1.0.
- **Pitch:** *One tap to jump. One mistake to fail. One more try to beat your record.*
- **Audience:** Teens and adults. **Not** designed for or marketed to children under 13.
- **Business model:** v1.0 ships **without ads**. Ads are only considered after the playtest gate shows people replay the game (§20.6).
- **Design pillars (in priority order):**
  1. **Responsive controls** (tap → jump with no perceptible delay)
  2. **Fairness** (every death feels like the player's fault; patterns are validated)
  3. **Instant retry** (failure → new attempt in well under one second)
  4. **Personality** (the near-miss "CLOSE!" moment, funny failure messages, a character with a face)

### 1.1 Core loop
Open app → tap Play → tap once to start → auto-run → tap to jump over hazards → score rises with distance → hit hazard → short death animation → results (score, best, funny message) → tap Retry → next run starts immediately.

### 1.2 The "hook" in v1.0
The **near-miss bonus**: if the player clears a hazard with a very small vertical gap, a yellow **"CLOSE! +5"** popup appears, a bright ding plays, and 5 bonus points are added. This rewards risky timing and creates shareable moments. The full **Rage Meter** is deliberately **not** in v1.0 (see §20.1); it is added only if playtesting shows the near-miss bonus is fun.

---

## 2. SCOPE

### 2.1 In v1.0 (build now)
- Player character "Zap" with jump physics and facial expressions
- 3 hazard types: **Spikes**, **Barrier**, **Charging Block**
- Validated, seeded obstacle patterns with a difficulty curve
- Distance-based score, best score, near-miss bonus
- Screens: Splash, Home, Game (HUD), Pause overlay, Results overlay, Settings (with Privacy and Credits)
- One environment: **Neon Workshop** (parallax background drawn in code)
- Sound effects (synthesized), haptics, mute and vibration toggles
- Local save: best score + settings
- Debug tooling (debug builds only)
- Release preparation: icon, store graphics, privacy policy, signed AAB

### 2.2 NOT in v1.0 (locked until the playtest gate passes — see §20)
Rage meter, coins, skins/shop, daily challenge, achievements, ghost replay, ads, multiple environments, leaderboards, sharing, music.

---

## 3. TECHNOLOGY STACK

| Purpose | Choice |
|---|---|
| Framework | Flutter (latest stable) + Dart |
| Game engine | `flame` (latest version compatible with the installed Flutter) |
| Audio | `flame_audio` |
| Persistence | `shared_preferences` |
| Open privacy-policy link | `url_launcher` |
| State management | Plain Flutter: `ValueNotifier` / `ChangeNotifier` (no extra packages) |
| Lint | `flutter_lints` (default) |
| Later (locked) | `google_mobile_ads`, `package_info_plus` |

**Version policy:** Add packages with `flutter pub add`, then keep the resolved versions in `pubspec.lock`. Record the exact Flame version in the project README. Do not upgrade Flame mid-project unless a bug requires it.

**Why manual collision (decision):** Collision is done with simple axis-aligned rectangle (AABB) checks inside the game's `update()` rather than Flame's collision-detection system. Reasons: deterministic, trivial to unit-test, immune to Flame version differences, and needed anyway for near-miss clearance tracking.

**Why Flutter overlays instead of Flame overlays (decision):** HUD, Pause and Results are normal Flutter widgets placed in a `Stack` **above** the `GameWidget`. Input for jumping is captured by a `Listener(onPointerDown)` wrapped **only around** the `GameWidget`, so taps on UI buttons never trigger jumps. `onPointerDown` fires on touch-down (not release), giving the lowest latency.

---

## 4. ARCHITECTURE

### 4.1 Layers and data flow

```
 ┌───────────────────────────── Flutter UI layer ─────────────────────────────┐
 │ Splash → Home → GameScreen (Stack: GameWidget + HUD + Pause + Results)     │
 │ Settings                                                                    │
 └──────────────▲──────────────────────────────────────────┬──────────────────┘
   reads notifiers (score, state, best, popups)             │ calls methods (start, jump, pause, resume, retry)
 ┌──────────────┴──────────────────────────────────────────▼──────────────────┐
 │ RageTapGame (FlameGame)  — owns GameState, run clock, score, spawner        │
 │   components: Background, Ground, Player, Obstacles, Particles, Popups      │
 │   systems: Difficulty, Spawner (patterns), Scoring, NearMiss, Collision     │
 └──────────────▲──────────────────────────────────────────┬──────────────────┘
                │ reads/writes                              │ plays
        SaveService (shared_preferences)             AudioService (flame_audio) + Haptics
```

**Rules:** UI never contains gameplay logic. The game never imports UI widgets. The game exposes `ValueNotifier`s; the UI listens.

### 4.2 File tree (create exactly this, add files only when the prompt calls for them)

```
rage_tap/
├─ RAGE_TAP_SPEC.md
├─ RAGE_TAP_PROMPTS.md
├─ README.md                     (created in Prompt 5.5)
├─ pubspec.yaml
├─ assets/audio/*.wav            (generated, §13)
├─ tool/
│   ├─ generate_sfx.py
│   └─ generate_store_art.py
├─ lib/
│   ├─ main.dart
│   ├─ app.dart                  (MaterialApp, routes, theme)
│   ├─ core/
│   │   ├─ constants.dart        (Appendix A)
│   │   ├─ palette.dart          (colors, §10.1)
│   │   └─ theme.dart            (text styles, button styles)
│   ├─ data/
│   │   └─ save_service.dart
│   ├─ audio/
│   │   └─ audio_service.dart    (+ haptics wrapper)
│   ├─ game/
│   │   ├─ rage_tap_game.dart
│   │   ├─ game_state.dart       (enum + helpers)
│   │   ├─ painting/
│   │   │   ├─ zap_painter.dart  (shared by game Player and Home screen)
│   │   │   └─ hazard_painters.dart
│   │   ├─ components/
│   │   │   ├─ player.dart
│   │   │   ├─ obstacle.dart
│   │   │   ├─ background.dart
│   │   │   ├─ ground.dart
│   │   │   ├─ particles.dart
│   │   │   └─ popup_text.dart
│   │   └─ systems/
│   │       ├─ difficulty.dart
│   │       ├─ pattern.dart
│   │       ├─ pattern_library.dart
│   │       ├─ pattern_validator.dart
│   │       ├─ spawner.dart
│   │       ├─ scoring.dart
│   │       └─ near_miss.dart
│   └─ ui/
│       ├─ screens/
│       │   ├─ splash_screen.dart
│       │   ├─ home_screen.dart
│       │   ├─ game_screen.dart
│       │   └─ settings_screen.dart
│       └─ widgets/
│           ├─ neon_button.dart
│           ├─ logo.dart
│           ├─ hud.dart
│           ├─ pause_overlay.dart
│           ├─ results_overlay.dart
│           └─ ready_hint.dart
└─ test/
    ├─ pattern_validator_test.dart
    ├─ spawner_simulation_test.dart
    ├─ physics_test.dart
    ├─ scoring_test.dart
    ├─ near_miss_test.dart
    ├─ save_service_test.dart
    └─ game_state_test.dart
```

### 4.3 Class responsibilities

| Class | Responsibility |
|---|---|
| `RageTapGame` | Owns state machine (§6), run clock, speed, score, spawner; exposes notifiers; handles `jump()`, `startRun()`, `pause()`, `resume()`, `retry()`; performs AABB collision each frame |
| `Player` | Position/velocity, gravity, jump, jump buffer, grounded flag, expression state, squash/stretch; draws via `ZapPainter` |
| `Obstacle` | One hazard (type, size, speed multiplier, hitbox, `passed` and `minClearance` tracking); draws via `hazard_painters` |
| `Spawner` | Picks validated patterns (seeded RNG), places obstacles, enforces rest gaps and safe opening |
| `PatternLibrary` | Static list of `Pattern` definitions (§8.4) |
| `PatternValidator` | Pure functions that check fairness invariants (§8.5) — used by unit tests |
| `Difficulty` | Pure functions: speed(t), tier(t), restGapRange(t) |
| `Scoring` | Pure: distance→points, bonus handling, best-score detection |
| `NearMiss` | Pure helper deciding if a pass counts as a near-miss |
| `SaveService` | Load/save/validate persistent values |
| `AudioService` | Preload and play SFX, honoring settings; wraps haptics |

### 4.4 Notifiers exposed by `RageTapGame`

```
ValueNotifier<GameState> state
ValueNotifier<int>       score
ValueNotifier<int>       bestScore
ValueNotifier<bool>      isNewBest
ValueNotifier<int>       resumeCountdown      // 0 = not counting, else 3,2,1
RunResult?               lastResult           // score, best, isNewBest, deathCause, nearMisses, durationSeconds
```

---

## 5. WORLD, COORDINATES AND PHYSICS

### 5.1 Fixed-resolution world
- Logical world size: **360 × 640** units, origin top-left, **+y is down**.
- The camera uses a **fixed resolution** (`CameraComponent.withFixedResolution` or the equivalent in the installed Flame version) so that every phone, short or tall, plays **identically** (same jump distances and gaps). Extra screen space becomes letterbox bars; the Flutter/Game background color must equal `Palette.bgDeep` so bars are invisible.
- All physics use **delta time**. **Clamp `dt` to max 1/30 s** per frame to avoid tunneling after a hitch. Never tie movement to frame count (phones run at 60, 90 or 120 Hz).

### 5.2 Constants table (also in Appendix A)

| Name | Value | Notes |
|---|---|---|
| `worldW`, `worldH` | 360, 640 | |
| `groundTopY` | 500 | Top surface of the ground; hazards and player stand here |
| `playerLeft` | 64 | Player's left edge (x) |
| `playerSize` | 40 | Visual 40×40 |
| Player hitbox (relative) | left 6, top 6, width 28, height 34 | bottom at ground; forgiving |
| `gravity` | 2000 units/s² | |
| `jumpVelocity` | 640 units/s (upward) | air time = 2v/g = **0.64 s**, apex height ≈ **102** |
| `jumpBufferSec` | 0.10 | A tap up to 0.10 s before landing triggers a jump on landing (**not** a double jump) |
| `baseSpeed` | 190 units/s | |
| `maxSpeed` | 300 units/s | |
| `speedRampPerSec` | 3.0 | `speed(t) = clamp(190 + 3.0·t, 190, 300)`, reached at t≈36.7 s |
| `safeOpeningFirstRun` | 3.0 s | Time until the first hazard reaches the player on the first run after Home |
| `safeOpeningRetry` | 2.0 s | On retries |
| `distancePerPoint` | 40 units | `score = floor(distance / 40) + bonuses` |
| `nearMissClearance` | 14 units | Max vertical clearance that counts as near-miss |
| `nearMissBonus` | 5 | |
| `nearMissCooldownSec` | 0.4 | |
| `hitFreezeSec` | 0.10 | |
| `deathAnimSec` | 0.30 | Results appear at 0.40 s after the hit |
| `shakeAmplitude`, `shakeSec` | 6, 0.25 | |
| `chargingExtraSpeed` | +60 units/s | Added to scroll speed |
| `chargingTelegraphSec` | 0.7 | |

### 5.3 Jump physics (implementation)
```
// each frame, with dt clamped:
if (!grounded) { vy += gravity*dt; y += vy*dt; if (y >= groundTopY - height) { land } }
jump(): if grounded → vy = -jumpVelocity, grounded = false
tap while airborne → store jumpBufferTimer = jumpBufferSec; on landing if timer > 0 → jump immediately
No double jump. Fixed jump height (no variable-height hold).
```

### 5.4 Forgiving hitboxes
| Object | Visual | Hitbox (relative to object top-left) |
|---|---|---|
| Player | 40×40 | x 6, y 6, w 28, h 34 |
| Spike unit | 30×28 | x 3, y 6, w 24, h 22 |
| Barrier | 30×56 | x 3, y 3, w 24, h 53 |
| Charging Block | 34×34 | x 4, y 4, w 26, h 30 |

Hitboxes are smaller than visuals so that deaths feel fair ("I touched it" never feels like "I didn't touch it").

---

## 6. GAME STATE MACHINE

Use **one enum**, not many booleans.

```
enum GameState { ready, playing, paused, resuming, dying, results }
```

| From | Event | To | Actions |
|---|---|---|---|
| (screen opens) | GameScreen created | `ready` | Reset world; show Ready hint; no scrolling hazards yet |
| `ready` | first tap | `playing` | Start run clock; first-run safe opening 3.0 s |
| `playing` | collision | `dying` | Guard: only once; stop spawning/score; freeze 0.10 s; flash; particles; shake; sound; haptic |
| `dying` | 0.40 s elapsed | `results` | Compute RunResult; save best if higher; show Results overlay |
| `results` | Retry | `playing` | Full reset of run data; **skip Ready**; safe opening 2.0 s |
| `results` | Home | (leave screen) | Pop to Home |
| `playing` | Pause button / app backgrounded | `paused` | Stop movement, spawning, score, timers; show Pause overlay |
| `paused` | Resume | `resuming` | 3-2-1 countdown (0.4 s per number), game still frozen |
| `resuming` | countdown ends | `playing` | |
| `paused` | Restart | `playing` | Reset run (like Retry) |
| `paused` | Home | (leave) | |

**Rules**
- A run starts only once per Play action; a collision ends a run only once (guard flag).
- Reset clears: score, run time, distance, speed, obstacles, popups, particles, near-miss cooldown, `isNewBest`. Reset **never** clears best score or settings.
- Taps are ignored in `paused`, `resuming`, `dying`, `results`.
- `jump()` in `ready` starts the run **and** performs the first jump.

---

## 7. ENTITIES

### 7.1 Player character — "Zap"
A cheerful-but-furious glowing **cyan cube** with a face. Drawn by `ZapPainter` (a pure function `paintZap(Canvas, Offset origin, double size, ZapExpression, double t, ...)`) so the same drawing is reused in the game and on the Home screen.

**Drawing spec (for size 40; scale proportionally):**
- Glow: rounded rect same as body, color cyan @ 50% alpha, `MaskFilter.blur(BlurStyle.normal, 8)`.
- Body: rounded rect 40×40, corner radius 10, fill `Palette.cyan`. Darker bottom edge strip (4 units) `Palette.cyanDark`. Small highlight rect (10×4 at (6,5)) white @ 25%.
- Eyes: white ovals 9×11 at (9,13) and (22,13). Pupils: `Palette.bgDeep` ovals 4×6 shifted +3 right inside each eye (looking forward).
- Brows: two 3-unit-thick round-cap lines in `Palette.bgDeep`: left (7,11)→(17,14), right (33,11)→(23,14) (angled inward = determined/angry look).
- Mouth: flat line (14,31)→(26,31), 2 units thick.
- Feet (running only): two 10×5 rounded rects at the bottom, alternate x offset ±3 every 0.08 s.

**Expressions (`ZapExpression`):**
| Expression | When | Change |
|---|---|---|
| `run` | grounded, playing | Default look + body bob `sin(t·18)·1.5` and feet animation |
| `air` | airborne | Eyes 10×12 (wider), mouth becomes small open oval 8×6, no feet |
| `scared` | 0.4 s after a near-miss | Eyes wide with tiny pupils, small cyan sweat drop (4×6) at upper-right |
| `dead` | dying/results | Eyes replaced by "X" strokes, body color `cyanDark`, squash scaleY 0.6 anchored at ground |
| `idle` | Home screen / ready | Slow blink every ~3 s, gentle bob |

**Squash & stretch:** takeoff: scaleX 0.85 / scaleY 1.2 for 80 ms; landing: scaleX 1.2 / scaleY 0.8 for 80 ms; scale anchored at the bottom-center, eased back to 1.

### 7.2 Hazards (drawn in `hazard_painters.dart`)

1. **Spikes** — unit 30×28, a row of N adjacent triangles pointing up (`count` 1–3, no gaps between units). Fill `Palette.orange`, 2-unit outline `Palette.magenta`, soft magenta glow on the tips, dark thin base line.
2. **Barrier** — 30×56 rounded rect (radius 6), fill `Palette.magenta`, diagonal hazard stripes (yellow @ 35% alpha, 8-unit stripes at 45°), light top highlight, soft magenta glow.
3. **Charging Block** — 34×34 rounded rect (radius 6), fill `Palette.orange`, three dark chevrons "‹‹‹" on the face, three trailing speed lines to the right (lengths 30, 22, 14; alpha 50%), orange glow. Moves faster than the scroll speed: `speed = scrollSpeed + 60`.
   - **Telegraph:** while the block's left edge is still off-screen right (x > 360), show a pulsing orange warning triangle with "!" (24×24) at (332, groundTopY − 36), flashing at ~6 Hz. The block spawns with its leading edge at `360 + 0.7 s × its own speed` so the warning lasts ≈ 0.7 s.

### 7.3 Hazard behavior
- Hazards move left at the current scroll speed (Charging Block: scroll + 60).
- Remove a hazard when its right edge < −20.
- Each hazard tracks `passed` (trailing edge crossed the player's hitbox left edge) and `minClearance` (for near-miss).

---

## 8. SPAWNER, PATTERNS AND FAIRNESS

### 8.1 Principles
Hazards are **never** spawned completely at random. A seeded RNG chooses from a library of **validated patterns**. The same seed always produces the same sequence (debuggable).

### 8.2 Jump math (used by the validator)
Let `v = jumpVelocity`, `g = gravity`, `T_air = 2v/g = 0.64 s`.
- Time the player's hitbox bottom stays **above height H**: `clearTime(H) = 2·sqrt(v² − 2·g·H) / g`.
  - H=22 (spike): 0.567 s. H=53 (barrier): 0.4445 s. H=30 (charging): 0.538 s.
- Relative speed `s_rel` = scroll speed (or scroll+60 for the charging block).
- Hitbox width of a spike group with n units: `24n + 6(n−1)`; barrier 24; charging 26. Player hitbox width = 28.
- **Timing window (seconds)** for clearing a single-jump group: `window = clearTime(H) − (groupHitboxWidth + 28) / s_rel`.
- **Fairness invariant 1:** `window ≥ 0.12 s` for every single-jump group across the speed range in which its pattern can appear.
- **Fairness invariant 2 (separate jumps):** For consecutive hazards A then B that require separate jumps, `gapTime = B.arrivalTime − (A.arrivalTime + A.width / A.s_rel) ≥ T_air + 0.25 = 0.89 s`, where arrival = time the leading edge reaches the player's hitbox right edge.
- **Dead zone rule:** A pair must be either one jump group (adjacent spike units only) **or** separate-jump compatible. Anything in between is forbidden.

### 8.3 Pattern placement rules
- **Safe opening:** first hazard's leading edge reaches the player after 3.0 s (first run) or 2.0 s (retry).
- **Rest gap** between the last hazard's trailing edge of one pattern and the next pattern's leading edge, in seconds × current speed: random in `[restMin(t), restMax(t)]`, with `restMin(t)`/`restMax(t)` lerping linearly from `[1.30, 1.90]` at t=0 to `[0.95, 1.25]` at t=45 s (then constant). Never below 0.95 s.
- Spawn position for the next pattern: `x = max(360 + 40, rightmostEdge + restGapPx)`.
- **Charging Block pattern (C1):** requires lead gap ≥ 1.8 s × scroll speed from the previous hazard's right edge and spawns at `max(that, 360 + 0.7·(scroll+60))`. It may never directly follow another C1.
- Avoid the same pattern more than twice in a row.
- Obstacles spawned off-screen right; never spawn on-screen.

### 8.4 Pattern library (define in `pattern_library.dart`)

Offsets (`dx`) are **seconds between leading edges**; convert to pixels with the speed at spawn time. `spikes(n)` = one group of n adjacent spike units.

| ID | Items | Min speed | Tier (from t) | Weight |
|---|---|---|---|---|
| S1 | spikes(1)@0 | 190 | 1 (0 s) | 3 |
| S2 | spikes(2)@0 | 190 | 2 (8 s) | 3 |
| B1 | barrier@0 | 190 | 2 (8 s) | 3 |
| S1B1 | spikes(1)@0, barrier@1.25 | 190 | 3 (16 s) | 2 |
| B1S1 | barrier@0, spikes(1)@1.25 | 190 | 3 (16 s) | 2 |
| S2S1 | spikes(2)@0, spikes(1)@1.30 | 190 | 3 (16 s) | 2 |
| B1B1 | barrier@0, barrier@1.30 | 190 | 4 (24 s) | 2 |
| S3 | spikes(3)@0 | **255** | 4 (24 s) | 2 |
| C1 | charging@0 (minLead 1.8 s) | 190 | 4 (24 s) | 2 |
| S1B1S1 | spikes(1)@0, barrier@1.25, spikes(1)@2.50 | 190 | 5 (36 s) | 1 |
| B1S2B1 | barrier@0, spikes(2)@1.30, barrier@2.60 | 190 | 5 (36 s) | 1 |

Tier rule: a pattern becomes available when run time ≥ its tier start **and** current speed ≥ its min speed. Tier 1 uses **only S1** so new players learn the single jump.

### 8.5 Pattern validator (`pattern_validator.dart`)
Pure Dart; no Flame imports. Must provide:
- `clearTime(H)`, `timingWindow(group, sRel)`, `separateGapTime(...)`.
- `validatePattern(Pattern, minSpeed..maxSpeed)` → list of violations (empty = valid).
- Unit tests assert every pattern in the library is valid at speeds 190, 230, 260, 300 (respecting each pattern's min speed).
- A **simulation test** (`spawner_simulation_test.dart`) runs the real `Spawner` headlessly for 120 simulated seconds across seeds 1..200 with the real speed ramp and asserts invariant 2 for every consecutive pair that is not a same-jump group.

### 8.6 Difficulty (`difficulty.dart`)
Pure functions of run time `t` (seconds since the run started, excluding paused time):
- `speed(t) = clamp(190 + 3.0·t, 190, 300)`
- `tier(t)`: 1 for t<8, 2 for t<16, 3 for t<24, 4 for t<36, 5 otherwise.
- `restGapRange(t)` as in §8.3.
Change **one major variable at a time** conceptually: speed ramps continuously; complexity unlocks by tier; rest gaps tighten slowly. Never trade fairness for difficulty.

---

## 9. SCORING AND NEAR-MISS

### 9.1 Score
- `score = floor(distance / 40) + nearMissBonuses`, where `distance += speed · dt` only while `playing`.
- Pause, resume countdown, dying and results never change the score.
- `isNewBest` becomes true when the final score > the best score loaded at run start (and best > 0 or score > 0). Best score is saved **once** at the end of the run.
- Typical expectations: ~5–7 points/second; a 30 s run ≈ 150–200.

### 9.2 Near-miss rules
- Each hazard tracks `minClearance` while its hitbox horizontally overlaps the player's hitbox: `clearance = obstacleHitboxTop − playerHitboxBottom` (positive = player above). Sample every frame.
- When the hazard has fully passed (hazard hitbox right edge < player hitbox left edge) **and** the player did not collide: if `0 ≤ minClearance ≤ 14` and the global cooldown (0.4 s) has expired → **near-miss**.
- At most one near-miss per hazard. Group of spikes counts as one hazard.
- Effects: `+5` score, yellow popup **"CLOSE! +5"** rising 24 units above the player over 0.6 s with a scale-pop (1.0→1.3→1.0) and fade, `scared` expression for 0.4 s, near-miss SFX, light haptic.
- Tunable: `nearMissClearance` may be adjusted in playtesting; keep in constants.

---

## 10. VISUAL DESIGN SYSTEM

### 10.1 Palette (`palette.dart`)
| Name | Hex | Use |
|---|---|---|
| `bgDeep` | `#0B1026` | Background top, letterbox, scaffold |
| `bgPurple` | `#1A1140` | Background gradient bottom |
| `gearFill` | `#141A3D` | Far-layer gears |
| `pipeFill` | `#1B2350` | Mid-layer pipes |
| `groundFill` | `#101532` | Ground body |
| `cyan` | `#22E3FF` | Player, ground line, primary buttons |
| `cyanDark` | `#0FA3B8` | Player shading, dead state |
| `orange` | `#FF8A1F` | Spikes, charging block |
| `magenta` | `#FF2E93` | Barrier, "TAP" logo word, GAME OVER |
| `yellow` | `#FFD23F` | Score highlights, CLOSE!, NEW BEST |
| `green` | `#3DDC97` | Positive toggles |
| `white` | `#F4F7FF` | Primary text |
| `muted` | `#8A93B8` | Secondary text |
| `scrim` | `#B8050816` | Overlay background (≈72% alpha) |

### 10.2 Typography (`theme.dart`) — use the default system font (Roboto) to avoid asset dependencies
| Style | Size / weight | Notes |
|---|---|---|
| `logo` | 64 / w900, letterSpacing 2 | Glow shadow |
| `scoreHud` | 44 / w800 | White, soft shadow |
| `scoreResult` | 72 / w900 | |
| `h1` | 28 / w800 | |
| `button` | 24 / w800, letterSpacing 1.5 | |
| `body` | 16 / w500 | |
| `caption` | 13 / w500 | `muted` |

### 10.3 Spacing and components
- Base spacing unit 8 dp; screen horizontal padding 24 dp.
- Always respect `SafeArea` (notches, gesture bars). Minimum touch target **48×48 dp**.
- **NeonButton:** pill shape (radius 32). *Primary*: filled `cyan`, text `bgDeep`, glow `cyan@55%` blur 18. *Secondary*: transparent fill, 2 dp `cyan` border, text `cyan`. *Danger* (for reset): `magenta` border/text. Press animation: scale 0.96 over 80 ms. Disabled: 40% opacity.
- Icon buttons: 48×48 circle, `bgPurple` fill, 1.5 dp `cyan@40%` border.
- Screen transitions: 180 ms fade.

---

## 11. ART SPEC — "NEON WORKSHOP" (all drawn in code)

Layer order (back to front), each scrolling horizontally at a fraction of the current scroll speed:

1. **Sky gradient** (static): vertical gradient `bgDeep` → `bgPurple`, cached shader.
2. **Far layer (0.10×):** large dark gear silhouettes (`gearFill`), radii 40–90 units, 8 teeth-rich gears placed at seeded positions over a 720-unit tile that repeats seamlessly; each rotates slowly (±6°/s, alternating direction).
3. **Mid layer (0.30×):** vertical pipes (`pipeFill`, width 14, from y=0 to groundTopY) every ~110–160 units, with small cyan joint rings and occasional lamp glows (circle radius 18, cyan @ 20% alpha). Tile width 720, seeded.
4. **Ground (1.0×):** body `groundFill` from y=500 to 640; top edge **3-unit cyan line with soft glow**; vertical grid lines every 40 units scrolling at 1.0× plus one horizontal line at y=540 (cyan @ 15%).
5. **Gameplay:** hazards, player, particles, popups.

**Performance rules for art:** cache `Paint`/`Path`/shader objects; no per-frame allocation of `Paint`; use glow (`MaskFilter`) only on the player, hazards, and the ground line; avoid `saveLayer`; keep draw calls low. Target ≥ 55 FPS on a mid-range phone in profile mode.

### 11.1 Effects (`particles.dart`, `popup_text.dart`)
- **Hit:** freeze 0.10 s with a white flash overlay (alpha 0.35→0 over 0.15 s); screen shake (amplitude 6, 0.25 s, decaying); 14 cyan square particles (4–7 units) with random velocity (80–260 units/s, upward bias) and gravity 900, fading over 0.5 s; Zap switches to `dead`.
- **Land dust:** 3 tiny `muted` particles at feet on landing.
- **Popup text:** the "CLOSE! +5" described in §9.2.
- **New best:** on Results, "NEW BEST!" badge pulses (scale 1.0↔1.08, 0.8 s loop) with a small confetti of 12 coloured squares falling once.
- Do not use flashing faster than 3 Hz over large areas (accessibility); the hit flash is a single flash.

---

## 12. SCREENS AND UI LAYOUTS

All sizes in Flutter logical dp. All screens have background `Palette.bgDeep` (Home may reuse a static version of the neon background).

### 12.1 Splash (≤ 1.2 s)
Centered logo fades in (0.5 s) on `bgDeep`; meanwhile `SaveService.init()` and audio preload run; then fade to Home. Never block longer than needed.

### 12.2 Home
```
┌──────────────────────────────┐
│                         (⚙) │  settings icon button (top-right, in SafeArea)
│                              │
│          R A G E             │  logo word 1 (cyan), 64 sp
│           T A P              │  logo word 2 (magenta), 64 sp, slightly overlapping
│  One tap. One mistake.       │  tagline caption (muted)
│                              │
│            [Zap]             │  Zap idle/run animation 96×96 on a short neon ground strip
│  ────────────────────        │
│                              │
│        ( ▶  PLAY )           │  primary NeonButton 240×68
│                              │
│        BEST  123             │  yellow label + number
│                              │
│  v1.0.0                      │  caption bottom-center
└──────────────────────────────┘
```
- Zap runs in place on the ground strip, occasionally hopping every 2 s.
- Play → fade transition → GameScreen (`ready` state).
- Settings icon → Settings screen.
- Android back on Home exits app (default).

### 12.3 Game screen (HUD)
```
┌──────────────────────────────┐
│  BEST 123    [ 87 ]    (II) │  best (left, caption), score (center, 44 sp), pause (right 48×48)
│                              │  HUD sits inside SafeArea, top padding 8
│                              │
│                              │
│   [Zap]  →  hazards          │  gameplay (Flame world)
│▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔│  ground
└──────────────────────────────┘
```
- Score text scales 1.0→1.15→1.0 (120 ms) when a near-miss bonus is added.
- Pause button hidden during `results`/`dying`.
- Back button during play = pause.
- **Ready hint** (state `ready`): pulsing text "TAP TO JUMP" (h1, white) above the player with a small animated tap-icon (circle ripple). Shown only until the first tap. For the very first launch ever (`firstRunDone == false`), also show a one-line caption "Jump over the hazards. Don't touch them." below; set `firstRunDone = true` after the first run.

### 12.4 Pause overlay
Scrim full-screen. Center card width 300, radius 24, fill `bgPurple`, border 2 dp `cyan@50%`:
```
        PAUSED                  (h1)
   [   RESUME   ]  primary 260×56
   [  RESTART   ]  secondary 260×48
   [    HOME    ]  secondary 260×48
   (🔊)    (📳)                 sound & vibration icon toggles
```
Resume → countdown "3 … 2 … 1" (large centered number, 96 sp, scale-pop each second) → play continues.

### 12.5 Results overlay
Appears ≈0.40 s after the hit with 150 ms fade-in. Scrim over the frozen game.
```
┌──────────────────────────────┐
│                              │
│          GAME OVER           │  h1, magenta
│             87               │  scoreResult (72 sp, white)
│       BEST 123               │  caption/yellow  OR  ★ NEW BEST! ★ (pulsing yellow badge)
│   "Gravity wins again."      │  funny message, italic 16 sp muted, max 2 lines
│                              │
│   [      RETRY       ]       │  primary 280×64, lower third (thumb zone)
│   [      HOME        ]       │  secondary 280×48
└──────────────────────────────┘
```
- Retry is the dominant action and works from the very first visible frame.
- Score counts up from 0 to final over 300 ms (skippable by design: do not delay Retry).
- Message selection: see Appendix B.

### 12.6 Settings
List on `bgDeep`, app bar title "Settings", back arrow:
1. **Sound effects** — switch
2. **Vibration** — switch
3. **Privacy policy** — opens URL via `url_launcher` (external browser). If the URL is not yet set (placeholder), show a dialog with the policy text from Appendix D.
4. **Credits** — dialog: "Rage Tap — made by <publisher name>. Sound effects generated procedurally. Built with Flutter and Flame."
5. **Reset progress** — danger button → confirmation dialog ("This resets your best score. This cannot be undone.") → resets best score only.
6. Footer: version text.

---

## 13. AUDIO AND HAPTICS

### 13.1 Sound effects (synthesized by `tool/generate_sfx.py`, Python standard library only: `wave`, `math`, `random`, `struct`)
Format: mono, 16-bit PCM, 44100 Hz, output to `assets/audio/`. Apply a short fade-in (2 ms) and fade-out to avoid clicks. Normalize peaks to ~0.8.

| File | Description |
|---|---|
| `jump.wav` | Sine sweep 400→800 Hz over 0.12 s, exponential decay |
| `land.wav` | 120 Hz sine thump, 0.05 s, fast decay (volume low) |
| `hit.wav` | White-noise burst + 90 Hz sine, 0.35 s, decaying |
| `near_miss.wav` | Two sine tones 880 Hz then 1320 Hz, 0.07 s each, bright |
| `new_best.wav` | Arpeggio C5, E5, G5, C6 (523, 659, 784, 1047 Hz), 0.09 s each |
| `click.wav` | 1000 Hz sine 0.03 s |

### 13.2 Audio service
- Preload all files at startup (`FlameAudio.audioCache.loadAll`).
- Respect the sound setting at play time. If jump latency is noticeable on a real device, use an audio pool for `jump.wav` and `near_miss.wav`.
- Stop/pause appropriately when the app is backgrounded; never play sounds while `paused`.
- No music in v1.0.

### 13.3 Haptics (via `HapticFeedback`)
| Event | Haptic |
|---|---|
| Hit | `mediumImpact` |
| Near-miss | `lightImpact` |
| Button press | `selectionClick` |
| Jump | none (avoid fatigue) |
All respect the vibration setting.

---

## 14. PERSISTENCE

`SaveService` (singleton, async `init()` before `runApp` or in Splash). Keys in `shared_preferences`:

| Key | Type | Default | Validation |
|---|---|---|---|
| `schema_version` | int | 1 | |
| `best_score` | int | 0 | clamp 0…9,999,999 |
| `sound_enabled` | bool | true | |
| `haptics_enabled` | bool | true | |
| `first_run_done` | bool | false | |
| `total_runs` | int | 0 | clamp ≥ 0 |

Rules: write only on meaningful events (end of run, settings change, reset), never per frame; wrap reads in safe defaults when null/invalid; keep all persistence in this one service; `resetProgress()` resets `best_score` and `total_runs` only. Tests must cover missing keys, invalid values, and reset.

---

## 15. PLATFORM CONFIGURATION, LIFECYCLE, PERFORMANCE

- **Portrait lock:** `SystemChrome.setPreferredOrientations([portraitUp])` **and** `android:screenOrientation="portrait"` in `AndroidManifest.xml`.
- **System UI:** edge-to-edge (`SystemUiMode.edgeToEdge`), transparent status/navigation bars, light icons.
- **Lifecycle:** `GameScreen` uses `WidgetsBindingObserver`; on `paused`/`inactive`/`hidden` while `playing` → `game.pause()`; never auto-resume. Verify in the installed Flame version how backgrounding affects the engine, audio and timers, and make sure nothing double-counts time. Stop audio on background.
- **Input:** `Listener(onPointerDown)` only around `GameWidget`; ignore multi-touch beyond the first pointer for jump purposes (one jump per pointer-down is fine; jump buffer prevents spam exploits).
- **Performance targets:** 60 FPS minimum on a mid-range device in `flutter run --profile`; no per-frame garbage in hot paths; remove off-screen components; app size well under 50 MB.
- **Screen sizes:** test 360×640, 360×800, 412×915, a tablet-ish 800×1280, and small 320×568. The fixed-resolution camera guarantees identical gameplay; UI must not overflow.
- **Error handling:** wrap the app in `runZonedGuarded`/`FlutterError.onError` that logs in debug; do not show raw errors to users.

---

## 16. DEBUG TOOLS (debug builds only, guarded by `kDebugMode`)

- Overlay showing: FPS, speed, run time, current tier, last pattern ID, run seed, state.
- Toggle hitbox drawing (long-press the top-left corner for 1 s).
- Fixed seed via `--dart-define=SEED=12345`; otherwise seed from time. The seed is printed in the log at the start of each run so any unfair sequence can be reproduced.
- Never ship debug UI in release builds.

---

## 17. TESTING REQUIREMENTS

### 17.1 Automated (must pass before each commit)
- `physics_test`: jump apex ≈ 102 ±2, air time ≈ 0.64 s ±0.02, no double jump, jump buffer works only on landing.
- `scoring_test`: distance→score, pause doesn't change score, `isNewBest` logic.
- `near_miss_test`: clearance thresholds, cooldown, once-per-hazard.
- `pattern_validator_test` + `spawner_simulation_test`: §8.5.
- `save_service_test`: defaults, clamping, reset.
- `game_state_test`: legal transitions, single game-over, reset preserves best.

### 17.2 Manual checklist (physical device)
- First tap starts the run and jumps once.
- Tap during a jump does not create a second jump; a tap just before landing jumps on landing.
- Collision ends the run exactly once; Retry resets everything but best score.
- Pause/resume/countdown correct; backgrounding pauses; returning does not resume automatically.
- Failed audio load never crashes; sound toggle works; vibration toggle works.
- Airplane mode: game fully works (no network use at all in v1.0).
- Force close mid-run and relaunch: best score intact.
- Rotate device: stays portrait.
- Small, tall and tablet screens: no overflow, no gameplay differences.
- 10 minutes of continuous play: no slowdown, no memory growth (profile).

### 17.3 Release blockers
Crash on launch; lost/incorrect best score; unplayable controls; unfair/impossible pattern; Retry not working; audio/vibration ignoring settings.

---

## 18. PLAYTEST GATE AND DISCOVERY PLAN

### 18.1 Gate protocol (human, after Phase 3)
Give a release/profile build to **5 people** who haven't seen the game. Do **not** explain anything. Watch silently for 5 minutes each. Record:
1. Did they understand tap-to-jump within 3 attempts?
2. Did they say deaths were "my fault" (fair) in most runs?
3. How many times did they press Retry without being asked?
4. Can they describe the game in one sentence afterwards?
5. Top 3 confusions/complaints.

**Pass criteria (written in advance):** at least 4 of 5 understand the controls within 3 attempts; at least 4 of 5 retry 3+ times unprompted; at least 4 of 5 describe deaths as mostly fair; at least 3 of 5 can describe the game in one sentence. **If it fails, fix the core feel (jump timing, spacing, speed, hitboxes, restart speed) before adding anything else.**

### 18.2 Discovery assets (start as soon as the game is playable)
- Record 15-second screen clips: a near-miss "CLOSE!" moment; a funny death message; first run vs 20th run; a long-run speed-up.
- Icon, 5 real gameplay screenshots, feature graphic, clear honest description (§19).
- Short-video platforms (TikTok/Shorts/Reels) are the main free channel; the mechanic must be visible in the first second.

---

## 19. GOOGLE PLAY RELEASE

> Policies change. Verify every item below in Play Console and the official help pages at release time.

### 19.1 Account and testing
- If the developer account is a personal account created after 13 Nov 2023: run a **closed test** with **≥12 testers opted in continuously for 14 days**, then apply for production access (official page: support.google.com/googleplay/android-developer/answer/14151465). Plan for roughly three or more weeks from first closed-test upload to public availability. Organization accounts are exempt.
- Start the closed test as soon as a stable build exists (testers' 14 days run in calendar time while development continues); upload updated builds during the test.

### 19.2 App identity
- `applicationId` fixed once (§0.2). App label "Rage Tap". `versionName 1.0.0`, `versionCode 1`.
- Target audience in Play Console: **13+** (not child-directed; avoid Families Policy). Set the target SDK to what Play currently requires.

### 19.3 Store listing (draft — see Appendix C for full text)
- Title ≤ 30 characters; short description ≤ 80 characters; full description ≤ 4000 characters.
- **Icon** 512×512 PNG. **Feature graphic** 1024×500 PNG. **Phone screenshots**: 5 images, 9:16 (e.g., 1080×1920), real gameplay, with short captions in the image optional.
- Content rating questionnaire: answer honestly (abstract cartoon obstacles; no realistic violence, no gambling, no user-generated content, no communication).

### 19.4 Privacy and Data safety
- v1.0 has no ads, no analytics, no network use, no accounts → expected Data safety answer: **no data collected or shared**. Verify by checking all dependencies; if any SDK collects data, declare it.
- A privacy policy URL is required by Play for most apps; host the Appendix D text on a public page (§0.2 #4).

### 19.5 Signing and build
- Create an **upload keystore** with `keytool`; store `key.properties` and the `.jks` **outside Git** (add to `.gitignore`) and **back them up** (losing the upload key is painful). Use Play App Signing.
- Build: `flutter build appbundle --release`. Test the release build on a real device (from the AAB via `bundletool` or a release APK) — not just debug.

### 19.6 Rights
Use only original or properly licensed content. All art/audio in v1.0 is generated in code/script, so no third-party licences are needed; keep Flutter/Flame licences (MIT) acknowledged in Credits ("Built with Flutter and Flame").

---

## 20. LOCKED POST-GATE FEATURES (do **not** build until the gate in §18.1 passes and the human says so)

### 20.1 Rage Meter
Near-misses add 25% each to a 0–100 meter; the meter drains 8%/s when no near-miss in the last 3 s. Full meter → **Rage Mode** for 5 s: scroll speed ×1.15 for the player's progression (hazard gaps must still satisfy invariants at the boosted speed), score ×2, Zap's brows glow red and body shows a flame outline, HUD meter bar (top, under score, 160×8 dp, yellow→magenta gradient), screen edges tinted magenta @ 15%. Hazards remain fully readable. Meter resets after Rage Mode. Validate by re-running the simulation tests with boosted speed. If it doesn't improve fun in testing, remove or simplify it.

### 20.2 Coins
At run end: `coins = floor(score / 10) + 2 × nearMisses` (non-negative int, saved). Results shows "+N coins". No in-run pickups initially.

### 20.3 Skins and Shop (cosmetic only)
Six skins (data-driven, drawn by `ZapPainter` with a `ZapSkin` palette): **Zap** (cyan, free), **Blaze** (orange, 100), **Pixel** (green with square pixel eyes, 150), **Ghost** (white translucent, 250), **Bolt** (yellow with lightning mark, 400), **Royal** (purple with small crown, 600). Shop screen: 2-column grid, preview animation, price/owned/equipped state. Purchase logic in one function: verify not owned → verify balance → subtract once → mark owned → save → block double taps. Only owned skins equip.

### 20.4 Daily Challenge
Seed = integer from device date `yyyyMMdd`; goal types: reach score X, collect N near-misses, survive T seconds; reward coins. The device clock can be changed by the user; treat as a fun extra, not competitive. No server.

### 20.5 Ghost of best run (optional)
Record jump timestamps of the best run; replay as a translucent Zap. Memory-tiny. Optional.

### 20.6 Ads (only with evidence people return)
- Package `google_mobile_ads`. During development use **only Google's test IDs** (verify in AdMob docs): Android test App ID `ca-app-pub-3940256099942544~3347511713`; rewarded test unit `ca-app-pub-3940256099942544/5224354917`; interstitial test unit `ca-app-pub-3940256099942544/1033173712`.
- Add AdMob App ID to `AndroidManifest.xml` (the app crashes on launch without it). Implement consent via UMP (supported by the package) where required. Update Data safety and the privacy policy.
- **Rewarded:** optional "Watch ad: double coins" on Results (clearly explained; reward granted once, only after the SDK confirms). **Interstitial:** only after ≥ 4 completed runs since the last one and ≥ 3 minutes since the last one, only on Results after tapping Retry/Home, never mid-run, never at launch. If an ad fails or the device is offline, Retry and Home still work instantly.
- Revenue is unpredictable; do not assume any amount.

---

## 21. KNOWN PITFALLS FOR AI-GENERATED FLAME CODE (read before coding)

1. Flame APIs differ between versions (camera/world, component lifecycle, input). Verify against the installed version.
2. Don't use `onTap`-style callbacks for jumping (they fire on release). Use `Listener.onPointerDown`.
3. Don't tie motion to frames; always use clamped `dt`.
4. Don't allocate `Paint`, `Path`, `TextPainter` objects every frame.
5. Always guard game-over with a flag to prevent double triggers.
6. Don't forget `ValueNotifier.dispose()` and listener removal.
7. Don't put gameplay logic in widgets.
8. Don't assume audio assets exist; handle load failures without crashing.
9. Don't run performance tests in debug mode.
10. Don't edit generated platform files beyond what is specified.

---

## APPENDIX A — `lib/core/constants.dart` (create exactly)

```dart
// All values in world units (360x640 logical world) and seconds.
class C {
  // World
  static const double worldW = 360;
  static const double worldH = 640;
  static const double groundTopY = 500;

  // Player
  static const double playerLeft = 64;
  static const double playerSize = 40;
  static const double playerHitX = 6, playerHitY = 6, playerHitW = 28, playerHitH = 34;

  // Physics
  static const double gravity = 2000;
  static const double jumpVelocity = 640;
  static const double jumpBufferSec = 0.10;
  static const double maxDt = 1 / 30;

  // Speed
  static const double baseSpeed = 190;
  static const double maxSpeed = 300;
  static const double speedRampPerSec = 3.0;
  static const double chargingExtraSpeed = 60;

  // Opening
  static const double safeOpeningFirstRun = 3.0;
  static const double safeOpeningRetry = 2.0;

  // Scoring
  static const double distancePerPoint = 40;
  static const double nearMissClearance = 14;
  static const int nearMissBonus = 5;
  static const double nearMissCooldownSec = 0.4;

  // Hazards (visual w,h) and hitbox (x,y,w,h)
  static const double spikeW = 30, spikeH = 28;
  static const double spikeHitX = 3, spikeHitY = 6, spikeHitW = 24, spikeHitH = 22;
  static const double barrierW = 30, barrierH = 56;
  static const double barrierHitX = 3, barrierHitY = 3, barrierHitW = 24, barrierHitH = 53;
  static const double chargeW = 34, chargeH = 34;
  static const double chargeHitX = 4, chargeHitY = 4, chargeHitW = 26, chargeHitH = 30;

  // Spawning
  static const double separateJumpReactionSec = 0.25; // + air time = 0.89 s
  static const double minTimingWindowSec = 0.12;
  static const double chargingTelegraphSec = 0.7;
  static const double chargingMinLeadSec = 1.8;
  static const double restMinStart = 1.30, restMaxStart = 1.90;
  static const double restMinEnd = 0.95, restMaxEnd = 1.25;
  static const double restRampSeconds = 45;
  static const List<double> tierStarts = [0, 8, 16, 24, 36];

  // FX
  static const double hitFreezeSec = 0.10;
  static const double deathAnimSec = 0.30;
  static const double shakeAmplitude = 6;
  static const double shakeSec = 0.25;
  static const int resumeCountStart = 3;
  static const double resumeCountStepSec = 0.4;

  // Persistence
  static const int maxScore = 9999999;
}
```

---

## APPENDIX B — Result messages (original text; choose with a seeded or plain `Random`)

**General (default pool):**
- "That spike has been waiting for you."
- "Gravity wins again."
- "So close you could taste the neon."
- "Your cube has filed a complaint."
- "Jump earlier. Or later. Or not."
- "The barrier did not move. You did."
- "That was a warm-up. Probably."
- "One more try. You know you want to."
- "Nice try. Great crash."
- "Tap. Tap. Oops."
- "Your reflexes are buffering..."
- "Almost! Almost is a word."
- "Even the cube felt that."

**Cause-specific (use when the death hazard matches):**
- Spikes: "Spikes: 1. You: 0.", "Pointy things are pointy."
- Barrier: "The barrier did not move. You did.", "Wall. Meet face."
- Charging block: "The block was fast. You were almost fast.", "It charged. You didn't dodge."

**Score-based:**
- Score < 10: "Warm-up run. Now do it for real."
- Score ≥ 80% of best (but not new best): "So close to your best. Again?"
- New best: "NEW BEST! Show-off." / "Personal record! Cube is proud."

**Selection order:** new best → near-best → cause-specific (50% chance) → general pool. Never show the same message twice in a row.

---

## APPENDIX C — Store listing draft

- **Title:** Rage Tap: One Tap Challenge (≤30 chars; verify availability)
- **Short description (≤80):** One tap to jump. One mistake to fail. Beat your best in neon arcade chaos.
- **Full description:**
```
RAGE TAP is a fast, fair, one-tap arcade challenge.

Your cube runs automatically. Tap to jump over spikes, barriers and charging blocks. Hit one and it's over — but retrying takes a single tap.

★ ONE-TAP CONTROLS — learn in seconds, master in hours
★ CLOSE CALLS — clear hazards by a hair for bonus points and a loud "CLOSE!"
★ FAIR BY DESIGN — every hazard pattern is tested so deaths are your fault, not the game's
★ INSTANT RETRY — no waiting, no menus, just one more try
★ NEON WORKSHOP — a glowing, fast, stylish world
★ 100% OFFLINE — play anywhere, no account, no sign-in

How far can you go before the cube crashes?
```
- **Keywords to naturally include in the text:** one tap, arcade, jump, endless, reflex, offline game.
- **Screenshots (5):** (1) mid-run with hazard approaching, (2) "CLOSE! +5" moment, (3) charging block warning, (4) results with NEW BEST, (5) home screen.
- **Icon concept:** Zap's face (cyan cube, angry brows) centered on a navy→purple gradient with a soft cyan glow, minimal margin.

---

## APPENDIX D — Privacy policy template (host publicly; edit publisher name/contact)

```
Privacy Policy for Rage Tap
Last updated: <date>

Rage Tap ("the app") is an offline game published by <publisher name>.

Information we collect: The app does not collect, store on our servers, or share any personal information. It does not require an account and does not use the internet during gameplay.

Data stored on your device: The app saves your best score and your settings (sound and vibration) locally on your device. This data never leaves your device and is removed when you uninstall the app.

Third parties: This version of the app contains no advertising, analytics, or other third-party data-collecting services.

Children: The app is not directed to children under 13.

Changes: If a future version adds advertising or other features that process data, this policy will be updated before release and the app's Data safety information will be updated accordingly.

Contact: <email address>
```

---

## APPENDIX E — Definition of Done for v1.0

- [ ] All v1.0 features in §2.1 implemented per this spec
- [ ] `flutter analyze` clean; all tests pass
- [ ] Manual checklist §17.2 passed on a real device in profile/release mode
- [ ] Playtest gate §18.1 passed
- [ ] Icon, screenshots, feature graphic, listing text, privacy policy URL ready
- [ ] Signed AAB built; keystore backed up and kept out of Git
- [ ] Closed test running (if required) with ≥12 testers opted in continuously for 14 days
- [ ] Play Console forms (content rating, Data safety, target audience) completed accurately
