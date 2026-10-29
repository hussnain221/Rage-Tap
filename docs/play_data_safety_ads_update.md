# Google Play Console Data Safety & Ads Declaration Guide

This document details the exact changes to make in the **Google Play Console** for **Rage Tap** following the addition of the Google Mobile Ads SDK (AdMob) in Prompt 8.5.

---

## 1. App Content → Ads Declaration

1. Go to **Google Play Console** → Select **Rage Tap**.
2. In the left navigation, scroll to **Policy and programs** → **App content**.
3. Under **Ads**, click **Manage** (or **Start**).
4. For *"Does your app contain ads?"*:
   - Select **Yes, my app contains ads**.
5. Click **Save**.

---

## 2. App Content → Data Safety Form

1. In **App content**, find **Data safety** and click **Manage** (or **Start**).
2. **Data collection and security:**
   - *"Does your app collect or share any of the required user data types?"* → Select **Yes**.
   - *"Is all of the user data collected by your app encrypted in transit?"* → Select **Yes**.
   - *"Do you provide a way for users to request that their data be deleted?"* → Select **No** (AdMob data is ephemeral and handled directly per Google's privacy policy).
   - Click **Next**.

3. **Data Types to Check:**
   Expand the categories below and check the following items collected by the Google Mobile Ads SDK:

   ### A. Location
   - Check **Approximate location** (Coarse location inferred from IP).

   ### B. App info and performance
   - Check **Crash logs**.
   - Check **Diagnostics**.

   ### C. Device or other IDs
   - Check **Device or other IDs** (Google Advertising ID / GAID).

   Click **Next**.

4. **Data Usage and Handling Details for Each Type:**

   #### For Approximate Location:
   - Collected? → **Yes**
   - Shared? → **Yes** (shared with third-party service Google AdMob)
   - Processed ephemerally? → **Yes**
   - Required or optional? → **Data collection is required** (cannot be turned off when watching ads)
   - Why is this data collected? → Check **Advertising or marketing** and **Fraud prevention, security, and compliance**.

   #### For Crash logs & Diagnostics:
   - Collected? → **Yes**
   - Shared? → **Yes**
   - Processed ephemerally? → **Yes**
   - Required or optional? → **Data collection is required**
   - Why is this data collected? → Check **Analytics** and **Fraud prevention, security, and compliance**.

   #### For Device or other IDs (GAID):
   - Collected? → **Yes**
   - Shared? → **Yes** (shared with Google AdMob)
   - Processed ephemerally? → **No**
   - Required or optional? → **Data collection is required**
   - Why is this data collected? → Check **Advertising or marketing**, **Analytics**, and **Fraud prevention, security, and compliance**.

5. Click **Next** → Review the Preview → Click **Save** / **Submit**.

---

## 3. Privacy Policy URL
Ensure your live Privacy Policy link is up to date in **App content → Privacy policy**:
`https://sites.google.com/view/stormlogix-privacy-policy/ragetap`
(The policy HTML and Markdown files in `docs/` have been updated with AdMob and UMP disclosures).

