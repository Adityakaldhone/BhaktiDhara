# BhaktiDhara — Master Google Ads Runbook (3-Gear: tCPI → tCPA → tROAS)

| | |
|---|---|
| **App** | BhaktiDhara: Aarti Sangrah · `com.kaldhone.bhaktidhara` · Firebase `bhaktidhara-app` |
| **Monetisation** | Premium subscription (₹51/mo · ₹129/3 mo · ₹229/6 mo · ₹399/yr, annual is the default) · AdMob banner + rewarded |
| **Audience** | India, core Maharashtra. Marathi + Hindi speakers aged 30–65 who do daily pooja at home. |
| **Finish line** | **118–120%+ ROAS**. Google Play keeps 15% of subscription revenue, so 100 / 0.85 = 117.6% is the real break-even. |
| **Weekly habit** | Export the Google Ads asset report, drop it into Cursor chat and say **"Audit my ads"** |

### What the build tracks

| Gear | Event | Fires when | Value |
|---|---|---|---|
| 1 | `first_open`, `session_start` | Automatically (Firebase starts in `main()`) | — |
| 2 · **main** | `paywall_view` | The premium sheet opens, or the user taps a locked greeting | — |
| 2 · volume | `aarti_completed` | The aarti video ends, or 3 min on the aarti screen | — |
| 2 · deepest | `begin_checkout` | The user taps Subscribe (Play sheet opening) | intent only |
| 2 · bridge | `trial_start` | The user takes a free-trial offer | none |
| 3 | `purchase` (app) | First paid charge: exact price, `INR`, Play order ID | ✅ |
| 3 | `purchase` (server) | Renewals and trial→paid, sent by the backend via GA4 Measurement Protocol | ✅ |
| 3 | `paid_ad_revenue` | Every paid AdMob impression (banner, rewarded) | ✅ |

In debug builds, every event prints `[Analytics] <event> {params}` in the `flutter run` console.

---

## Step 0 — First Production Update & Linking (the day Production access is approved)

### 0.1 Build & upload the release
- [x] `pubspec.yaml` version bumped to **`1.2.0+11`**
- [ ] Play Console → BhaktiDhara → **Test and release → App bundle explorer**: confirm **11** is higher than every versionCode already uploaded, including closed-test builds. If not, set `version: 1.2.0+<highest + 1>`.
- [ ] Build: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- [ ] Play Console → **Test and release → Production → Create new release** → upload the `.aab` → release notes → **Next** → **Staged rollout: 20%** → **Save** → **Send for review**
- [ ] Shorebird can't deliver this release, because `firebase_analytics` is a new native plugin. Future Dart-only fixes can go back to Shorebird patches on top of `1.2.0+11`.

### 0.2 Backend (deploy before the app reaches users)
- [ ] GA4 secret: Firebase console → ⚙ **Project settings → Integrations → Google Analytics → Manage**. In GA4, go to **Admin → Data streams → BhaktiDhara (Android) → Measurement Protocol API secrets → Create** → nickname `rtdn-renewals` → copy the value.
- [ ] Add these to `backend/.env` on the server:
  ```
  GA4_API_SECRET=<secret from above>
  RTDN_PUSH_TOKEN=<long random string, e.g. openssl rand -hex 24>
  ```
- [ ] Deploy: `cd backend && ./deploy.sh`
- [ ] Smoke test: `curl -s -X POST https://bhaktidharaapp.in/api/v1/analytics/app-instance -H 'Content-Type: application/json' -d '{"deviceId":"smoke-test","appInstanceId":"test123"}'` → `{"status":"ok"}`

### 0.3 Play subscription notifications (RTDN), the feed for renewal revenue
- [ ] Google Cloud console (the project linked to Play Console) → **Pub/Sub → Topics → Create topic** → ID `play-rtdn` → Create
- [ ] Open the topic → **Permissions** (Show info panel) → **Add principal** → `google-play-developer-notifications@system.gserviceaccount.com` → role **Pub/Sub Publisher** → Save
- [ ] Topic → **Create subscription** → ID `play-rtdn-push` → Delivery type **Push** → Endpoint `https://bhaktidharaapp.in/api/v1/subscription/webhook?auth=<RTDN_PUSH_TOKEN>` → Create
- [ ] Play Console → BhaktiDhara → **Monetize with Play → Monetization setup → Real-time developer notifications** → Topic name `projects/<gcp-project-id>/topics/play-rtdn` → Notifications: **Subscriptions** → **Send test notification** → **Save changes**
- [ ] Server logs show a webhook hit with no error: `docker logs bhaktidhara_backend --since 5m | grep -i webhook`
- [ ] Validate GA4 forwarding without recording any data. Take your own device's `app_instance_id` from the `devices` table, then run: `docker compose exec bhaktidhara-api python -m app.ga4_forwarder <app_instance_id>` → expect `"validationMessages": []`

Until 0.2 and 0.3 are done, renewals still extend premium on the backend, but no renewal revenue reaches Google Ads.

### 0.4 Privacy Policy (`docs/privacy.html`) — add a section covering
- [ ] **Google Analytics for Firebase:** app usage events (screens, aartis completed, paywall views), purchase/subscription events (product, price, currency), app-instance ID, Android Advertising ID, approximate location from a masked IP
- [ ] **Purpose:** analytics and measuring/optimising Google Ads. Data is shared with Google (Analytics, Ads, AdMob).
- [ ] **Opt-out:** Android Settings → Google → Ads → *Delete advertising ID*. Link to [policies.google.com/technologies/partner-sites](https://policies.google.com/technologies/partner-sites).
- [ ] **Deletion:** a contact email for deletion requests. Retention follows GA4 → Admin → Data collection and modification → **Data retention** (set it to 14 months).

### 0.5 Play Console → Data safety (Analytics + Advertising ID)
**Policy and programs → App content → Data safety → Manage → Next**

- [ ] **Does your app collect or share any of the required user data types?** → Yes
- [ ] **Is all user data encrypted in transit?** → Yes
- [ ] **Do you provide a way for users to request that their data is deleted?** → Yes (the method from 0.4)
- [ ] Tick these data types. Keep everything already declared (location for Panchang, AdMob data, etc.):

| Category → Data type | Collected | Shared | Ephemeral? | Required? | Purposes |
|---|---|---|---|---|---|
| **Location → Approximate location** | ✅ | ✅ | No | Required | Analytics, Advertising or marketing |
| **Financial info → Purchase history** | ✅ | ✅ | No | Required | Analytics, Advertising or marketing |
| **App activity → App interactions** | ✅ | ✅ | No | Required | Analytics, Advertising or marketing |
| **Device or other IDs → Device or other IDs** | ✅ | ✅ | No | Required | Analytics, Advertising or marketing |

- [ ] **Next → Save → Submit**
- [ ] **App content → Advertising ID → Manage** → "Does your app use advertising ID?" **Yes** → tick **Analytics** and **Advertising or marketing** → Save
- [ ] **App content → Ads** stays "Yes, my app contains ads"

Source: Google's [Analytics Play data-disclosure guide](https://support.google.com/analytics/answer/11582702). "Shared" is ticked because events and audiences are exported to Google Ads, so confirm that against your own legal position.

### 0.6 Verify on a real device (release build, before going to 100%)
```bash
flutter build apk --release && adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell setprop debug.firebase.analytics.app com.kaldhone.bhaktidhara
# Firebase console → Analytics → DebugView → your device
adb shell setprop debug.firebase.analytics.app .none.   # when finished
```
- [ ] **Gear 1:** clear app data and launch → `first_open`, `session_start`
- [ ] **Gear 2:** stay 3 min on an aarti → `aarti_completed`. Open the premium sheet → `paywall_view`. Tap Subscribe → `begin_checkout`.
- [ ] **Gear 3:** buy with a license-tester account (Play Console → **Settings → License testing**) → `purchase` with `value`, `currency=INR` and a `transaction_id` starting `GPA.`. A trial offer logs `trial_start` instead.
- [ ] **Don't** check `paid_ad_revenue` by viewing your own production ads (invalid traffic). 24–48 h into the staged rollout, check Firebase → Analytics → **Events** for `paid_ad_revenue`, then raise the rollout to 100%.

### 0.7 Link the accounts
- [ ] **Firebase → Google Ads:** Firebase console → ⚙ **Project settings → Integrations → Google Ads → Link** → select the Google Ads customer ID → keep **Enable personalized advertising** ON → **Link to Google Ads**
- [ ] **Google Play → Google Ads:** Play Console (all apps view) → **Setup → Linked services → Google Ads → Link** → enter the Google Ads customer ID → Send. Then in Google Ads: **Tools → Data manager → Google Play → Manage and link → Approve**.
- [ ] **AdMob → Google Ads:** AdMob → **Settings → Linked services → Google Ads → Link** → choose the Google Ads account → Link
- [ ] **Firebase key events:** Firebase console → **Analytics → Events** → toggle **Mark as key event** on `paywall_view`, `aarti_completed`, `begin_checkout`, `trial_start`, `purchase`, `paid_ad_revenue`. If an event isn't listed yet, wait 24 h after rollout.

### 0.8 Import conversions into Google Ads
**Google Ads → Goals → Conversions → Summary → + New conversion action → App → Google Analytics 4 properties (Firebase) → Continue →** tick the events below **→ Import and continue → Done**. Then click each action → **Edit settings**:

| Event | Goal & action optimisation | Value | Count | Window |
|---|---|---|---|---|
| `paywall_view` | **Primary** (Gear 1 + 2) | Don't use a value | One | 7 d |
| `aarti_completed` | Secondary (Primary only if it becomes the Gear 2 bid event) | Don't use a value | One | 7 d |
| `begin_checkout` | Secondary | **Don't use a value** | One | 7 d |
| `trial_start` | Secondary | Don't use a value | One | 7 d |
| `purchase` | Secondary → **Primary in Gear 3** | **Use the value from the event** | Every | 30 d |
| `paid_ad_revenue` | Secondary → **Primary in Gear 3** | **Use the value from the event** | Every | 30 d |

- [ ] **Do not** import (or keep Secondary): Firebase auto `in_app_purchase` and `ad_impression`, and Google Play-sourced in-app purchase conversions. They duplicate `purchase` / `paid_ad_revenue`, which would inflate ROAS and make the algorithm overbid.
- [ ] Wait for status **"Recording conversions"** on `paywall_view` before launching Gear 1.

---

## Gear 1 Runbook (Days 1–7) — Advanced tCPI Launch

### 1.1 Create `BD-G1-tCPI`
- [ ] Google Ads → **+ Create → Campaign → Objective: App promotion → Campaign type: App → Subtype: App installs → Platform: Android →** search `com.kaldhone.bhaktidhara` → Continue
- [ ] **Locations:** India (or start with Maharashtra, Goa, Karnataka, Madhya Pradesh) → **Location options → Include: "Presence: People in or regularly in your targeted locations"**
- [ ] **Languages:** Marathi, Hindi, English
- [ ] **Bidding:** "What do you want to focus on?" **Install volume** → "How do you want to track install conversions?" **Firebase** → **Target cost per install: ₹12** (range ₹10–₹15)
- [ ] ✅ **"Target users most likely to perform an in-app action"** → select **`paywall_view`**
- [ ] **Budget: ₹400/day** (≈ 33 × tCPI; allowed range ₹300–₹500 = 30–50 × CPI)
- [ ] **Ad group assets:** paste the headlines and descriptions below, add a 15–30 s portrait video (aarti playing, then the jaap counter, then a greeting being shared), plus 3 portrait and 3 landscape screenshots
- [ ] **Publish.** No edits for 7 days.

#### Headlines (≤ 30 chars, validated)

| # | Theme | Headline | Chars |
|---|---|---|---|
| 1 | Core Utility | `Daily Aarti with Lyrics` | 23 |
| 2 | Core Utility | `Marathi & Hindi Aarti Sangrah` | 29 |
| 3 | Pain-Point Resolver | `Never Forget Aarti Words Again` | 30 |
| 4 | Pain-Point Resolver | `Free Naam Jaap Mala Counter` | 27 |
| 5 | Social Proof/Speed | `Start Your Pooja in One Tap` | 27 |

#### Descriptions (≤ 90 chars, validated)

| # | Theme | Description | Chars |
|---|---|---|---|
| 1 | Core Utility | `Ganpati, Swami Samarth, Vitthal & more aartis with full lyrics. Install free.` | 77 |
| 2 | Core Utility | `Aarti, bhajan, chalisa & granth in Marathi, Hindi or English. One app. Download now.` | 84 |
| 3 | Pain-Point Resolver | `Large, clear lyrics so the whole family can sing every aarti together. Try it free.` | 83 |
| 4 | Pain-Point Resolver | `Count naam jaap on a digital mala & keep your daily streak going. Start free today.` | 83 |
| 5 | Social Proof/Speed | `Opens instantly with today's Panchang, rashi bhavishya & festival greetings. Get it.` | 84 |

### 1.2 Day 8 check (fill in, then say "Audit my ads" with the CSV)

| Metric (Days 1–7) | Formula | Yours | Healthy |
|---|---|---|---|
| Spend | Google Ads | ₹ ____ | ≈ budget × 7 |
| Installs | Google Ads | ____ | |
| **Actual CPI** | Spend / Installs | ₹ ____ | ≤ ₹14.4 (120% of ₹12) |
| Paywall reach | `paywall_view` / Installs | ____ % | |
| Activation | `aarti_completed` / Installs | ____ % | ≥ 30% |
| Checkout intent | `begin_checkout` / `paywall_view` | ____ % | |
| Purchase rate | `purchase` / Installs | ____ % | |
| Ad revenue / install | `paid_ad_revenue` value / Installs | ₹ ____ | |
| **`paywall_view` per day** | 7-day count / 7 | ____ /day | **≥ 10–15 → Gear 2** |
| `aarti_completed` per day | 7-day count / 7 | ____ /day | fallback Gear 2 event |

- [ ] **New tCPI** = actual CPI if it's outside ±20% of ₹12, applied in ≤ 20% steps
- [ ] CPI ≤ ₹14.4 → budget ₹400 → **₹480** (+20%). CPI > ₹18 → hold the budget and replace assets marked "Low".
- [ ] Pause assets with spend > 2 × tCPI and 0 conversions

---

## Gear 2 Runbook (Weeks 2–4) — Shift to tCPA

### 2.1 Trigger rule
- [ ] Gear up only when the bid event averages **10–15 actions/day** over the last 7 days:
  - `paywall_view`: ____ /day
  - Not there by Day 14? Use **`aarti_completed`** as the bid event instead (more volume, weaker signal), and switch to `paywall_view` once that hits 10/day.

### 2.2 Bidding math
- [ ] **Historical CPA = Total spend / Actions** (last 7–14 days, all G1 traffic)
  - Example: ₹2,800 / 90 `paywall_view` = ₹31.11
  - Yours: ₹ ____ / ____ = ₹ ____
- [ ] **Target CPA = Historical CPA × 1.20** → example ₹37 · yours ₹ ____
- [ ] **Daily budget = 10 × Target CPA** → example ₹370 · yours ₹ ____

### 2.3 Create `BD-G2-tCPA`
- [ ] **+ Create → Campaign → App promotion → App → App installs → Android** → same app, locations (**Presence** option), and languages
- [ ] **Bidding → "What do you want to focus on?" In-app actions → Target cost per action: ₹ ____ → In-app action: `paywall_view`** (or `aarti_completed`)
- [ ] **Budget:** ₹ ____ (10 × tCPA) · copy the "Best"/"Good" assets from G1 plus new replacements for the "Low" ones
- [ ] Same day: lower the **G1 budget by 20%**. Keep G1 running ≥ 7 days, then keep moving 20% at a time to G2.

### 2.4 Weekly monitoring (every Monday: "Audit my ads")

| Week | Actions/day | CPA vs tCPA | `purchase` (30 d) | Value events (30 d) | Next move |
|---|---|---|---|---|---|
| 2 | ____ | ₹ ____ / ₹ ____ | ____ | ____ | |
| 3 | ____ | ₹ ____ / ₹ ____ | ____ | ____ | |
| 4 | ____ | ₹ ____ / ₹ ____ | ____ | ____ | |

- [ ] CPA ≤ tCPA: budget +20%. CPA > 130% of tCPA for 7 days: tCPA +10%. Never two changes within 3 days.
- [ ] Pause G1 once G2 delivers ≥ 80% of G1's installs

---

## Gear 3 Runbook (Week 4+) — Graduate to tROAS (Money Recovery Engine)

### 3.1 Trigger rule
- [ ] Google Ads → Goals → Conversions → Summary, last 30 days: **`purchase` + `paid_ad_revenue` ≥ 30–50 conversions** → yours: ____
- [ ] **and `purchase` ≥ 10** → yours: ____ (banner impressions alone don't prove buyers)

### 3.2 Starting bid math
- [ ] Campaigns report, **last 14 days**, all app campaigns: **ROAS₁₄ = Conv. value / Cost × 100**
  - Example: ₹4,620 / ₹9,240 = 50%. Yours: ₹ ____ / ₹ ____ = **____ %**
- [ ] **Initial tROAS = ROAS₁₄ × 0.90–0.95** (5–10% below) → example **46%** · yours **____ %**

### 3.3 Create `BD-G3-tROAS`
- [ ] **+ Create → Campaign → App promotion → App → App installs → Android** → same app, locations (**Presence**), languages
- [ ] **Bidding → "What do you want to focus on?" In-app action value → Target return on ad spend: ____ %** → value actions **`purchase`** + **`paid_ad_revenue`**
- [ ] Goals → Conversions: set `purchase` and `paid_ad_revenue` to **Primary**
- [ ] **Budget:** start at the G2 budget, then shift G2 → G3 in 20% steps. Keep G2 running ≥ 7 days.
- [ ] No target edits for the first 10–14 days. If < 50% of budget is spent for 3 days in a row → tROAS −10%.

### 3.4 Scaling ladder to 118–120%+

Step up **+10–15% every 10–14 days**, only if the last window hit ≥ 90% of target and volume fell < 20%. Budget +20% about midway through each window, never on the same day as a target change. If volume falls > 30% after a step, roll back and hold 14 days.

| Step | Day from G3 launch | tROAS (+15% steps) | Your target | Hit ≥ 90%? |
|---|---|---|---|---|
| 0 | 0 | **46%** | ____ % | ☐ |
| 1 | 10–14 | 53% | ____ % | ☐ |
| 2 | 20–28 | 61% | ____ % | ☐ |
| 3 | 30–42 | 70% | ____ % | ☐ |
| 4 | 40–56 | 80% | ____ % | ☐ |
| 5 | 50–70 | 92% | ____ % | ☐ |
| 6 | 60–84 | **106%** (gross break-even passed) | ____ % | ☐ |
| 7 | 70–98 | **122%** (past the **118%** real break-even, now profitable) | ____ % | ☐ |

### Levers that move ROAS faster than bids
1. **Keep the annual plan (₹399) as the default.** It puts 8× the monthly value into the first `purchase`.
2. **Renewal revenue matters.** Make sure Step 0.2–0.3 are live so trial→paid and renewals are counted. Without them, the 118% line is very hard to reach.
3. **Refresh creative every 14 days** using the replacements from "Audit my ads".
