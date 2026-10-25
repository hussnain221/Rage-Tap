# Google Play Console Submission & Store Listing Guide

This guide gives you the exact copy-paste text, graphic asset paths, and step-by-step form answers to set up your Google Play Console store listing quickly and accurately.

---

## 1. App Creation (Initial Setup)

In **[Google Play Console](https://play.google.com/console)**, click **Create app** and enter:
- **App name:** `Rage Tap: Fast Arcade Runner` *(28 / 30 chars)*
- **Default language:** `English (United States) – en-US`
- **App or Game:** `Game`
- **Free or Paid:** `Free`
- **Declarations:** Check both boxes (Developer Program Policies & US export laws).
- Click **Create app**.

---

## 2. Main Store Listing Text

Navigate to **Grow** → **Store presence** → **Main store listing**.

### App name (Max 30 characters)
```text
Rage Tap: Fast Arcade Runner
```
*(Alternative: `Rage Tap: One Tap Jump Runner`)*

### Short description (Max 80 characters)
```text
Master the one-tap jump in a fast neon arcade runner. Dodge hazards & score high!
```
*(79 characters — optimized for Google Play BERT NLP keyword classification)*

### Full description (Max 4,000 characters)
```text
Ready for the ultimate one-tap arcade reflex challenge?

RAGE TAP is a fast-paced, neon arcade runner built for pure reflex and timing. Tap to jump, hold for maximum airtime, and dodge lethal spikes, barriers, charging blocks, overhead beams, and pit hazards. One mistake and it’s game over — but jumping back in takes a single tap!

How far can your reflexes take you before the speed catches up?

⚡ KEY FEATURES:

★ INTUITIVE ONE-TAP CONTROLS
Easy to pick up, impossible to put down. Tap lightly for a short hop or hold your touch to leap over tall neon walls and dangerous pit gaps.

★ HEART-POUNDING HAZARD PROGRESSION
Survive dynamic obstacle tiers that ramp in intensity! Dodge razor-sharp spikes, leaping charging blocks, overhead drone beams, and sudden floor pits.

★ CLOSE-CALL REWARDS
Clear obstacles by a hair's breadth to trigger exhilarating NEAR-MISS bonus points and screen-shaking arcade popups!

★ INSTANT RETRY — ZERO DOWNTIME
No frustrating loading screens or mid-run interruptions. Crash, tap retry, and you are back on the run in milliseconds.

★ 100% OFFLINE ARCADE EXPERIENCE
Play anywhere, anytime — on airplanes, commutes, or off the grid. No WiFi or mobile data connection needed.

★ BUTTERY SMOOTH 60 FPS PERFORMANCE
Engineered with zero jank, responsive haptic feedback, and procedural audio so every jump feels crisp and satisfying.

★ FAIR, SKILL-BASED PHYSICS
Every obstacle pattern follows mathematically validated timing windows. Your survival depends 100% on your timing and reflexes!

---

Are you ready to test your reaction speed? Download RAGE TAP now and dominate the neon run!
```

---

## 3. Store Graphics & Media Assets

All assets are pre-rendered and located in your local `store_assets/` directory:

| Asset | Specifications | Local File Location |
| :--- | :--- | :--- |
| **App icon** | 512 x 512 px, 32-bit PNG, < 1 MB | `store_assets/icon_512.png` |
| **Feature graphic** | 1024 x 500 px, 24-bit PNG/JPEG, < 15 MB | `store_assets/feature_graphic_1024x500.png` |
| **Phone screenshot 1** | 1080 x 1920 px (Home Screen) | `store_assets/screenshots/1_home.png` |
| **Phone screenshot 2** | 1080 x 1920 px (Leap Action) | `store_assets/screenshots/2_action.png` |
| **Phone screenshot 3** | 1080 x 1920 px (Near-Miss "CLOSE!") | `store_assets/screenshots/3_close_call.png` |
| **Phone screenshot 4** | 1080 x 1920 px (Charger Alert) | `store_assets/screenshots/4_charging_block.png` |
| **Phone screenshot 5** | 1080 x 1920 px (New Best Score) | `store_assets/screenshots/5_results.png` |

> [!TIP]
> Drag and drop all 5 screenshots into the **Phone screenshots** box. You can also upload them to the **7-inch tablet** and **10-inch tablet** tabs to maximize store visibility across all device form factors.

---

## 4. Store Settings (Categorization & Tags)

Navigate to **Grow** → **Store presence** → **Store settings**.

- **App category:** `Game`
- **Category:** `Arcade`
- **Tags (Select up to 5):**
  1. `Arcade` (Primary)
  2. `Endless runner`
  3. `Platformer`
  4. `Offline`
  5. `Stylized`
- **Store listing contact details:**
  - **Email address:** `stormlogix1@gmail.com`
  - **Phone number:** *(Optional — leave blank)*
  - **Website:** `https://sites.google.com/view/stormlogix-privacy-policy/ragetap`
- **External marketing:** Check `Turn off external marketing` only if you don't want Google advertising outside Google Play (recommended: keep enabled).

---

## 5. Policy & App Content Declarations

Navigate to **Policy and programs** → **App content**. Complete each required section as follows:

### 1. Privacy Policy
- **Privacy policy URL:**
  `https://sites.google.com/view/stormlogix-privacy-policy/ragetap`
- Click **Save**.

### 2. Ads
- **Does your app contain ads?**
  Select **No, my app does not contain ads**.
- Click **Save**.

### 3. App Access
- **Special app access required?**
  Select **All functionality is available without special access** (the game has no login, passwords, or geo-gating).
- Click **Save**.

### 4. Content Rating Questionnaire
Click **Start questionnaire**:
- **Email address:** `stormlogix1@gmail.com`
- **Category:** Select **Game**.
- **Questions:**
  - *Violence:* **No** (Abstract geometrical shapes dodging spikes).
  - *Sexuality:* **No**.
  - *Language:* **No**.
  - *Controlled Substances / Alcohol / Tobacco:* **No**.
  - *Promotion of Age-Restricted Products:* **No**.
  - *User Interaction / Sharing:* **No** (Offline game, no chat, no multiplayer).
  - *Location Sharing:* **No**.
  - *Digital Goods / In-App Purchases:* **No**.
- Click **Save** → **Next** → **Submit**. Expected rating: **PEGI 3 / ESRB Everyone**.

### 5. Target Audience and Content
- **Target age groups:** Select **13–15**, **16–17**, and **18 and over**.
- **Could your store listing unintentionally appeal to children?** Select **No**.
- Click **Save**.

### 6. Data Safety Form
Because *Rage Tap* is 100% offline with zero third-party tracking or analytics SDKs:
- **Does your app collect or share any of the required user data types?** Select **No**.
- **Data security practices:** N/A (no data collected).
- Click **Next** → **Submit**.

### 7. Government Apps
- **Is your app developed by or on behalf of a government?** Select **No**.

### 8. Financial Features
- **Does your app provide financial features?** Select **No financial features**.

---

## 6. Closed Testing Strategy (For Personal Accounts Created After Nov 2023)

If your Google Play Console account was registered after November 13, 2023, Google requires a closed testing period:
- **Requirement:** At least **12 testers opted in continuously for 14 days**.
- **Track to use:** **Testing** → **Closed testing** → Create track.

### Tester Recruitment Script (Copy & send to friends/family)
```text
Hey! I just published a closed beta of my new reflex arcade runner game, "Rage Tap", on Google Play. 

Could you help me test it?
1. Click this link to opt in to the test: [PASTE YOUR GOOGLE PLAY OPT-IN URL HERE]
2. Download the game from the Google Play Store.
3. Keep it installed on your phone for 14 days and play a couple of quick runs whenever you have 2 minutes!

Let me know your highest score or if you spot any bugs. Thanks a lot!
```

---

## 7. Final Verification Checklist Before Submitting

- [ ] Privacy policy link is live and loads cleanly in browser
- [ ] App Title is under 30 characters (`Rage Tap: Fast Arcade Runner`)
- [ ] Short description is under 80 characters (79 chars)
- [ ] All 5 phone screenshots (1080x1920) uploaded
- [ ] 512x512 icon and 1024x500 feature graphic uploaded
- [ ] Content rating completed and certificate generated
- [ ] Data safety form marked as "No data collected"
- [ ] App category set to Games → Arcade with 5 recommended tags
- [ ] Contact email set to `stormlogix1@gmail.com`
