# Rage Tap — Release Verification Checklist

## 1. Automated Verification
- [x] `flutter analyze --no-pub`: Clean (0 issues)
- [x] `flutter test --no-pub`: All 247 tests passing
- [x] Spawner simulations over 180s across 300+ seeds pass cleanly
- [x] Near-miss detection and Rage meter logic validated
- [x] Coin economy and migration logic validated
- [x] Cosmetics purchase and equip guards validated
- [x] Daily challenge deterministic seeding and single claim validated
- [x] Rewarded ads & Interstitial pacing tests validated

---

## 2. Manual Device Checklist (Spec §17.2)
*To verify on a physical Android test device before production rollout:*

- [ ] **First Launch:**
  - [ ] App launches into Splash screen and transitions cleanly to Home.
  - [ ] No ANR, crash, or black frame on start.
  - [ ] Teaching hint shows on first run.
- [ ] **Gameplay & Physics:**
  - [ ] Tap-to-jump is instantaneous and responsive.
  - [ ] Short tap produces short hop; hold produces full jump arc.
  - [ ] Jump buffer registers tap just before landing.
  - [ ] Near-miss bonus triggers with sound, haptics, and "CLOSE! +5".
- [ ] **Rage Mode:**
  - [ ] 4 near-misses charge rage meter to 100%.
  - [ ] Rage mode activates for 5 seconds with speed boost and 2x score.
  - [ ] Meter drains properly if no near-misses occur for 3s.
- [ ] **Cosmetics & Shop:**
  - [ ] Coins earned at run end match `floor(score/10) + 2*nearMisses`.
  - [ ] Shop displays all 6 skins with prices and previews.
  - [ ] Skin purchase correctly subtracts coins and equips the skin.
- [ ] **Daily Challenge:**
  - [ ] Today's goal displays correctly with deterministic date seed.
  - [ ] Meeting the goal unlocks the 50-coin reward once per day.
- [ ] **Ads Integration (Test Mode):**
  - [ ] UMP consent dialog displays when applicable.
  - [ ] "Watch an ad: double your coins" button appears on Results overlay when loaded.
  - [ ] Watching rewarded test ad doubles coins earned.
  - [ ] Results screen Retry and Home work without blocking if offline or when ad is closed.
- [ ] **Offline / Airplane Mode:**
  - [ ] Enable airplane mode: app opens, plays, pauses, retries, and saves best scores with zero crashes.

---

## 3. Release Blockers (Spec §17.3)
- [x] No sensitive permissions requested in `AndroidManifest.xml`.
- [x] No debug code or debug overlays active in release build.
- [x] Keystore and signing keys safely excluded from Git (`.gitignore`).
- [x] Target SDK meets Google Play target requirements (Target SDK 36, Min SDK 24).
- [x] AdMob App ID properly declared in `AndroidManifest.xml`.
