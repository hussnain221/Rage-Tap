# Rage Tap — Marketing & Discovery Notes (Phase 6 / Prompt 6.4)

## 1. Ten Short-Form Video Clip Ideas (TikTok, YouTube Shorts, Instagram Reels)

All clips should be recorded vertically (9:16) at 60 FPS using Android's built-in screen recorder or adb. The **first second** must hook the viewer immediately before they can scroll past.

| # | Concept / Angle | First Second Hook (0.0s – 1.0s) | Clip Narrative / Action (1.0s – 15.0s) | Audio / Sound Emphasis |
|---|---|---|---|---|
| **1** | **The Hairline Escape** | Zap micro-skimming 2 pixels over a double spike with yellow "CLOSE! +5" popup bursting | Player chains three consecutive near-misses over high barriers; hype building until a split-second mistake crashes into a barrier. | High-pitch near-miss "ding" chime echoing prominently. |
| **2** | **"It's Always My Fault"** | Extreme close-up of a failure right before a jump: Zap crashing directly into the front face of a block | Instant instant-replay retry within 0.1s; player immediately attempts the same pattern again with intense focus, clearing it cleanly. | Loud arcade "hit" crunch followed immediately by rapid jump blips. |
| **3** | **First Run vs. 20th Run** | Split screen or rapid transition: "Attempt 1" dying on first spike vs. "Attempt 20" dancing through Tier 4 obstacles at 280 px/s | Shows the rapid mastery curve; viewer sees how satisfying muscle memory feels once the jump arc is internalized. | Rhythmic cadence of takeoff and landing audio blips. |
| **4** | **The Charging Block Panic** | Glowing orange "!" warning icon flashing on screen right as speed surges | A high-speed charging block zips in from the right edge; Zap executes a frame-perfect leap over it and lands right in front of a barrier. | Telegraph hum and high-velocity whoosh sound. |
| **5** | **Funny Death Message Roast** | Death screen pops up with a savage randomized one-liner: *"The hazard didn't even move."* | Quick zoom on the message, then instant single-tap retry to get revenge on the game. | Abrupt music/sfx cut on crash, retro click on retry. |
| **6** | **Speedrun / Tier 5 Chaos** | Speed gauge in debug overlay showing 300+ px/s as background pipes and gears blur by | Intense 10 seconds of late-game survival where obstacles spawn in rapid rhythm; hands sweating, ending in a near-miss. | Continuous rapid-fire jump & landing sound sequence. |
| **7** | **New Record Heartbreak** | Player is 1 point away from beating their all-time BEST score (HUD shows 99 vs BEST 100) | Zap jumps... and clips the back heel on the final spike at 99 points. Results screen: *"So close, yet so far."* | Tragic retro hit thud, followed by dramatic pause. |
| **8** | **New Record Celebration** | Player clears obstacle at 101 points; "★ NEW BEST! ★" badge erupts with confetti explosion | Confetti falls across the results card with a celebratory chime. Shows satisfaction of breaking a plateau. | Triumphant "new best" ascending arpeggio blip. |
| **9** | **The Buffer Jump Trick** | Text overlay: *"Did you know you can tap before you land?"* | Demonstration showing early tap during descent automatically buffering and launching a perfect continuous bounce over back-to-back hazards. | Clean double-jump audio rhythm. |
| **10** | **Satisfying Neon ASMR** | Silent background with crisp game SFX turned to 100%: Jump, land, close call, click | Pure gameplay flow with zero voiceover; just the hypnotic visual neon aesthetics and crisp synthesizer blips. | Pure, uncompressed game audio soundscape. |

---

## 2. Short Video Caption & Post Template

```text
One tap. One mistake. One more try. ⚡🎮
Think your reflexes are fast enough for Tier 5?

Drop your high score below 👇

#RageTap #IndieGame #Gaming #MobileGaming #ReflexGame #Arcade #GamingTok #HardcoreGaming #OfflineGames #GameDev
```

---

## 3. Five Screenshot Plan (Google Play Store — Spec Appendix C)

All screenshots must be captured in portrait (9:16, e.g. 1080×1920 or 1080×2400) from actual device gameplay.

| # | Title / Concept | Exact Gameplay Moment to Capture | Key Visual Elements | Caption Text (Optional Overlay) |
|---|---|---|---|---|
| **1** | **The Core Loop** | Mid-run during Tier 2; Zap running toward approaching triple spikes | Neon workshop background, glowing ground, score HUD, Zap with running expression | **ONE TAP TO JUMP**<br>Pure arcade reflex challenge |
| **2** | **The Near-Miss Bonus** | Mid-air apex right as Zap barely clears the top edge of a tall barrier | Bright yellow `"CLOSE! +5"` floating popup, Zap with scared wide-eyed expression | **RISK IT ALL**<br>Skim hazards for bonus points |
| **3** | **Telegraph & Hazard Variety** | Pulsing orange warning icon ("!") visible as a charging block rushes in | Charging block with speed lines and chevrons, telegraph icon, dynamic contrast | **DODGE SPEED HAZARDS**<br>Watch for incoming chargers |
| **4** | **Instant Retry & New Record** | Results overlay with active confetti falling and glowing NEW BEST badge | "GAME OVER" in magenta, "★ NEW BEST! ★" badge, score rollup, RETRY button | **INSTANT RETRY**<br>Beat your best with zero wait |
| **5** | **Neon Aesthetics & Personality** | Home screen with glowing title, animated Zap hero, and clean arcade menu | Stylized RAGE TAP cyan/magenta logo, glowing Play pill button, high score | **NEON ARCADE SURVIVAL**<br>100% Offline • Zero Delay |

---

## 4. Google Play Store Listing Checklist

### Metadata Requirements
- [ ] **App Title:** `Rage Tap: One Tap Challenge` (30 characters max).
- [ ] **Short Description:** `One tap to jump. One mistake to fail. Beat your best in neon arcade chaos.` (74 / 80 chars).
- [ ] **Full Description:** Full text from Spec Appendix C (bullet points highlighting one-tap controls, near-misses, fairness, instant retry, and 100% offline).
- [ ] **App Category:** Games / Arcade.
- [ ] **Content Rating:** Target age 13+ (no realistic violence, no ads, no user communication, no gambling).

### Graphic Assets
- [ ] **App Icon:** `512 × 512` 32-bit PNG (Zap's face with cyan brows on dark purple background, no alpha).
- [ ] **Feature Graphic:** `1024 × 500` PNG (Rage Tap neon logo + Zap leaping over hazards on neon workshop strip).
- [ ] **Screenshots:** Minimum 4 (we have 5 planned above), 16:9 or 9:16 aspect ratio, minimum 1080px on shortest side.

### Privacy & Data Safety
- [ ] **Data Safety Form:** Select **"No user data collected or shared"** (verified: fully offline, no tracking SDKs, no ads).
- [ ] **Privacy Policy:** Hosted publicly on GitHub Pages / public URL using text from Spec Appendix D.

### Binary & Signing
- [ ] Android App Bundle built via `flutter build appbundle --release`.
- [ ] Upload keystore generated and safely backed up (`key.properties` added to `.gitignore`).
- [ ] Verified on real hardware in release mode.
