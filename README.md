# Rage Tap

A high-speed, precision 2D one-tap arcade survival game built with Flutter and Flame.

> *"One tap to jump. One mistake to fail. One more try to beat your record."*

---

## Overview

**Rage Tap** is an auto-running arcade jumper designed around hyper-responsive input, fair procedurally assembled hazard patterns, and instant retry. Players navigate Zap—a lively neon runner with reactive expressions—through hazardous industrial obstacle courses featuring spikes, barriers, and high-speed charging blocks.

### Key Pillars
- **Sub-frame Responsive Controls:** Instant tap-to-jump physics with a 0.10s landing buffer and multi-touch isolation.
- **Fairness Guarantee:** Every hazard pattern is mathematically verified against the player's parabolic jump trajectory; impossible patterns and blind hazards are strictly eliminated.
- **Near-Miss Risk/Reward:** Clearing obstacles with minimal clearance awards the `"CLOSE! +5"` near-miss bonus and distinctive audio chime.
- **Zero-Wait Failure Loop:** Die and restart in under 400 milliseconds.

---

## Exact Installed Versions

- **Flutter SDK:** `3.32.8` (channel stable)
- **Dart SDK:** `3.8.1`
- **Flame:** `1.35.1`
- **Flame Audio:** `2.11.14`
- **shared_preferences:** `2.5.3`
- **url_launcher:** `6.3.2`
- **cupertino_icons:** `1.0.8`

---

## How to Run

### Prerequisites
- Flutter SDK `^3.32.8` installed and added to your `PATH`.
- Android device or emulator connected (`flutter devices`).

### Debug Mode
Runs with hot-reload, live metrics overlay (FPS, speed, run time, tier, pattern ID, seed, state), and 1-second corner hitbox toggle:
```bash
flutter run
```

### Fixed Seed (Reproducible Runs)
To reproduce an exact sequence of obstacles or test a specific seed:
```bash
flutter run --dart-define=SEED=12345
```
*(The seed is logged to the console at the start of every run).*

### Profile Mode (Performance Measurement)
Runs with AOT compilation and lightweight profiling:
```bash
flutter run --profile
```

#### Measuring Performance in DevTools:
1. Run `flutter run --profile`.
2. Open the DevTools URL printed in the terminal or press `v` in the console.
3. Navigate to the **Performance** tab to monitor frame rendering times, raster threads, and UI thread latency.
4. Target: **≥ 55 FPS** on mid-range devices (60 FPS typical).

### Release Mode
Full optimized production binary (all debug overlays, FpsComponent, and hitbox visualizers are tree-shaken and completely removed):
```bash
flutter run --release
```

To build a standalone Android APK:
```bash
flutter build apk --release
```

---

## Project Structure

```
lib/
├── audio/
│   └── audio_service.dart          # Low-latency Soundpool pools & HapticsService
├── core/
│   ├── constants.dart              # Game physics, timings, and layout constants
│   ├── palette.dart                # Neon color tokens and custom HSL shades
│   └── theme.dart                  # Typography and TextStyles
├── data/
│   └── save_service.dart           # SharedPreferences persistence for best score & settings
├── game/
│   ├── components/
│   │   ├── background.dart         # Multi-layer parallax (sky, gears, pipes)
│   │   ├── ground.dart             # Glowing neon ground & scrolling grid lines
│   │   ├── obstacle.dart           # Spikes, barriers, and charging hazard components
│   │   ├── particles.dart          # Pooled particle system (death bursts, landing dust)
│   │   ├── player.dart             # Zap player component (physics, squash/stretch, expressions)
│   │   └── popup_text.dart         # Floating "CLOSE! +5" near-miss text popups
│   ├── painting/
│   │   ├── hazard_painters.dart    # Canvas painting routines for obstacles & telegraphs
│   │   └── zap_painter.dart        # Canvas painting routines for Zap expressions & animations
│   ├── systems/
│   │   ├── difficulty.dart         # Speed scaling and tier calculations
│   │   ├── near_miss.dart          # Clearance threshold and cooldown detection
│   │   ├── pattern.dart            # Pattern and PatternItem data models
│   │   ├── pattern_library.dart    # Verified hazard patterns library
│   │   ├── pattern_validator.dart  # Trajectory and timing window fairness validator
│   │   ├── result_messages.dart    # Dynamic death message selector
│   │   ├── scoring.dart            # Distance-to-score and new-best calculations
│   │   └── spawner.dart            # Deterministic/seeded hazard spawning system
│   ├── game_state.dart             # Game state machine (ready, playing, paused, dying, results)
│   └── rage_tap_game.dart          # FlameGame engine coordination & lifecycle
├── ui/
│   ├── screens/
│   │   ├── game_screen.dart        # Game viewport, gesture listeners, HUD & debug overlays
│   │   ├── home_screen.dart        # Main menu, animated hero Zap, play & settings triggers
│   │   ├── settings_screen.dart    # Audio toggles, privacy policy, credits & reset progress
│   │   └── splash_screen.dart      # Loading screen with animated logo and asset preloading
│   └── widgets/
│       ├── hud.dart                # In-game score, best score, and pause button
│       ├── logo.dart               # Stylized neon RAGE TAP logo
│       ├── neon_button.dart        # Glowing tactile action buttons
│       ├── pause_overlay.dart      # Paused menu & 3-2-1 resume countdown
│       ├── ready_hint.dart         # "TAP TO JUMP" hint and first-run tutorial
│       └── results_overlay.dart    # Game over dialog, score rollup, new best confetti, & retry
└── main.dart                       # App entry point, orientation lock & route management

test/                               # 30 test suites covering physics, simulation, & UI
tool/
└── generate_sfx.py                 # Pure Python (stdlib) procedural retro sound generator
```

---

## Sound Effects Generation

All sound effects (`jump`, `land`, `hit`, `near_miss`, `new_best`, `click`) are procedurally synthesized using only the Python standard library. No external audio libraries or pre-recorded clips are required.

To regenerate sound assets:
```bash
python tool/generate_sfx.py
```
Generated WAV files are saved to `assets/audio/`.

---

## Debug Tools

Available exclusively in debug builds (`kDebugMode`):
- **Metrics Overlay:** Displays live FPS, current scroll speed, run time, difficulty tier, last pattern ID, active seed, and game state.
- **Hitbox Visualization:** Long-press the top-left corner of the screen for 1.0 second to toggle red hitbox outlines on Zap and all active hazards.
- **Release Safety:** All debug code paths are guarded by compile-time `kDebugMode` checks, ensuring zero debug overhead or UI leaking into production builds.

---

## Known Limitations

- **Portrait Only:** The game is locked to portrait mode by design per master specification §15.
- **Offline Only:** v1.0 contains no network code, backend servers, analytics SDKs, or cloud saves.
- **Hardware Calibration:** Audio latency is minimized via dedicated Soundpool native pools; extreme budget devices with uncalibrated hardware audio buffers may experience minor platform-level audio latency.
