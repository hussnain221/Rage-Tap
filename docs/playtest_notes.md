# Rage Tap — Playtest Notes (Phase 6 / Gate 2)

## 1. Playtest Protocol (Spec §18.1)

- **Audience:** 5 people who have **not** seen or played the game before.
- **Rule:** Do **not** explain how to play or give tips.
- **Observation:** Watch silently for **5 minutes** per tester.
- **Recording:** Fill out the observations and feedback in the table below immediately after each session.

---

## 2. Pass Criteria (Spec §18.1)

All criteria must be met to pass Gate 2 and continue to store release preparations:

| Metric | Required Pass Threshold |
|---|---|
| **Controls Understanding** | ≥ 4 of 5 understand tap-to-jump within 3 attempts |
| **Unprompted Replay** | ≥ 4 of 5 press Retry 3+ times without being asked |
| **Fairness Perception** | ≥ 4 of 5 describe deaths as "my fault" (mostly fair) |
| **Clarity of Concept** | ≥ 3 of 5 can describe the game in one clear sentence afterwards |

> [!IMPORTANT]
> **Gate Decision:** If pass criteria are met, proceed to marketing assets and release prep. If any criterion fails, STOP and adjust the core feel (jump timing, hazard spacing, scroll speed, hitboxes, or restart latency) using Prompt 6.3 before re-testing with new participants.

---

## 3. Tester Observation Table

| Tester | (1) Understood controls in ≤ 3 tries? | (2) Deaths mostly fair ("my fault")? | (3) Unprompted retries (count) | (4) One-sentence description | (5) Top 3 confusions / complaints | (6) Seeds of any unfair-feeling deaths |
|---|---|---|---|---|---|---|
| **Tester 1** | [ ] Yes &nbsp; [ ] No | [ ] Yes &nbsp; [ ] No | _____ | | 1.<br>2.<br>3. | |
| **Tester 2** | [ ] Yes &nbsp; [ ] No | [ ] Yes &nbsp; [ ] No | _____ | | 1.<br>2.<br>3. | |
| **Tester 3** | [ ] Yes &nbsp; [ ] No | [ ] Yes &nbsp; [ ] No | _____ | | 1.<br>2.<br>3. | |
| **Tester 4** | [ ] Yes &nbsp; [ ] No | [ ] Yes &nbsp; [ ] No | _____ | | 1.<br>2.<br>3. | |
| **Tester 5** | [ ] Yes &nbsp; [ ] No | [ ] Yes &nbsp; [ ] No | _____ | | 1.<br>2.<br>3. | |

---

## 4. Overall Gate 2 Outcome

- **Controls Understood:** ___ / 5 (Pass: ≥ 4)
- **3+ Retries Unprompted:** ___ / 5 (Pass: ≥ 4)
- **Deaths Fair:** ___ / 5 (Pass: ≥ 4)
- **One-Sentence Description:** ___ / 5 (Pass: ≥ 3)

**Result:** [ ] PASS &nbsp;&nbsp;&nbsp; [ ] NEEDS TUNING (PROMPT 6.3)

---

## 5. Build & Installation Instructions (for Tester Devices)

### Profile Mode Build (Recommended for Playtesting — High Performance + Logging)
```bash
# 1. Build profile APK
flutter build apk --profile --target-platform android-arm64

# 2. Install on connected phone
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

### Release Mode Build (Final Production Performance)
```bash
# 1. Build release APK
flutter build apk --release --target-platform android-arm64

# 2. Install on connected phone
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
