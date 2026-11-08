# Rage Tap — Release Notes v1.1.0 (Version Code 5)

## Play Console Release Notes (What's New in this Release)
*Under 500 characters, ready to paste directly into Google Play Console:*

```text
What's new in Rage Tap v1.1.0:
• Stability & Controls: Resolved back button navigation lag and fixed app close freezing.
• Rage Meter: Chain near-misses to unleash high-speed Rage Mode!
• Coins & Shop: Earn coins and unlock 6 custom character skins.
• Daily Challenge: New seeded course and rewards every day.
• Audio & Ads: Instant sound toggling, smoother playback, and balanced ad pacing.
• General performance optimizations for all Android devices.
```

---

## Detailed Version 1.1.0 Changelog

### 1. New Gameplay Features
- **Rage Meter (§20.1):**
  - Narrowly clearing hazards now charges a dynamic neon rage meter.
  - Reaching 100% unleashes 5 seconds of Rage Mode (boosted speed, 2x score multiplier, burning visual aura).
- **In-Game Currency & Economy (§20.2):**
  - Earn coins dynamically based on run distance and near-miss frequency.
  - Saved persistently with automatic backward-compatible schema migration.
- **Skins & Cosmetic Shop (§20.3):**
  - New dedicated neon Shop accessible directly from the Home screen.
  - 6 data-driven Zap skins: *Zap (Default)*, *Blaze*, *Pixel*, *Ghost*, *Bolt*, and *Royal*.
  - Character preview animations with strict single-purchase protections.
- **Daily Challenge (§20.4):**
  - Deterministic daily seed based on device date (`yyyyMMdd`).
  - Dynamic daily goals (Target score, near-miss count, survival time).
  - One-claim-per-day 50-coin bonus.

### 2. Monetization & Ad Integration (§20.6)
- **Google Mobile Ads (AdMob) Integration:**
  - Standardized integration using official Google test IDs during development.
  - AndroidManifest configured with AdMob application metadata.
  - User Messaging Platform (UMP) consent flow implemented for GDPR/privacy compliance.
- **Optional Rewarded Ads:**
  - Non-intrusive "Watch an ad: double your coins" button on Results overlay.
  - Double coins rewarded strictly once upon SDK callback confirmation.
- **Paced Results Interstitials:**
  - Strictly capped frequency: shown only after $\ge 4$ completed runs AND $\ge 3$ minutes between impressions.
  - Never shown mid-run and never on app launch.
  - Fail-safe architecture: network failures or load timeouts never block or delay game navigation.
  - Master feature switch (`C.interstitialsEnabled`) default-safe.

### 3. Policy & Data Safety Updates
- Privacy Policy updated in Markdown (`docs/privacy_policy.md`) and HTML (`docs/privacy_policy.html`).
- Play Console Data Safety guide created (`docs/play_data_safety_ads_update.md`).
- Play Console Ads declaration instructions added to `docs/play_console_checklist.md`.
