# 🕉️ BhaktiDhara — Google Play Console Subscription Setup Guide

> **Application**: BhaktiDhara: Aarti Sangrah (`com.kaldhone.bhaktidhara`)  
> **Server Webhook**: `http://46.225.142.210/api/v1/subscription/webhook`  
> **Verification API**: `http://46.225.142.210/api/v1/subscription/verify`  
> **Status API**: `http://46.225.142.210/api/v1/subscription/status`  

---

## 1. Subscription Products Configuration

In the [Google Play Console](https://play.google.com/console):
1. Navigate to **Monetize** ➔ **Products** ➔ **Subscriptions**.
2. Click **Create subscription** for each of the 4 plans below:

| Plan | Product ID | Billing Period | Live Price (INR) | Display MRP | Free Trial Offer |
|------|------------|----------------|------------------|-------------|------------------|
| **Annual (Best Value)** ⭐ | `bhaktidhara_annual_399` | 1 Year | **₹399.00** | ~~₹1,188~~ (66% OFF) | 7-Day Free Trial |
| **6 Months** | `bhaktidhara_halfyearly_229` | 6 Months | **₹229.00** | ~~₹594~~ (61% OFF) | 7-Day Free Trial |
| **3 Months** | `bhaktidhara_quarterly_129` | 3 Months | **₹129.00** | ~~₹297~~ (57% OFF) | 7-Day Free Trial |
| **Monthly** | `bhaktidhara_monthly_51` | 1 Month | **₹51.00** *(or ₹49)* | ~~₹99~~ (48% OFF) | 7-Day Free Trial |

---

## 2. Setting Up 7-Day Free Trial Offers

For **each** of the 4 subscriptions above:
1. In the subscription details, click **Add base plan**:
   - **Base plan ID**: e.g., `annual-p1y`, `monthly-p1m`
   - **Type**: Auto-renewing
   - **Billing period**: Select 1 Year / 6 Months / 3 Months / 1 Month
   - **Grace period**: 3 days
   - **Default price**: Enter price in INR
2. Click **Activate base plan**.
3. Under the base plan, click **Add offer**:
   - **Offer ID**: `7-day-free-trial`
   - **Eligibility**: *New customer acquisition* (Only users who haven't previously used a trial)
   - **Phases**:
     - Click **Add phase** ➔ Type: **Free trial** ➔ Duration: **7 days**
     - Click **Save** and **Activate offer**.

---

## 3. Real-Time Developer Notifications (RTDN Webhook)

RTDN automatically updates subscription status (renewals, cancellations, refunds, grace periods) on your Hetzner backend.

### Step 1: Google Cloud Pub/Sub Topic
1. Go to [Google Cloud Console](https://console.cloud.google.com/) for your project.
2. Search for **Pub/Sub** ➔ **Topics** ➔ Click **Create Topic**.
3. Topic ID: `bhaktidhara-play-subscriptions`
4. In Permissions, add member:
   `google-play-developer-notifications@system.gserviceaccount.com`
   with Role: **Pub/Sub Publisher**.

### Step 2: Create Push Subscription
1. Inside the topic, click **Create Subscription**:
   - **Delivery type**: Push
   - **Endpoint URL**: `http://46.225.142.210/api/v1/subscription/webhook`
   - **Acknowledgement deadline**: 30 seconds

### Step 3: Link to Google Play Console
1. In Google Play Console, go to **Monetization setup** ➔ **Real-time developer notifications**.
2. Enter the full topic name: `projects/<YOUR_GCP_PROJECT_ID>/topics/bhaktidhara-play-subscriptions`
3. Click **Send test notification** and then **Save changes**.

---

## 4. License Testing (Testing Without Real Money)

To test subscription purchases on physical devices without getting charged:
1. In Play Console, go to **Setup** ➔ **License testing**.
2. Add your developer email addresses into the license testers list.
3. Set **License test response** to: `RESPOND_NORMALLY`.
4. Testers can select test payment methods (like "Always approves" or "Always declines") with accelerated test renewal intervals (e.g., 1 month renews in 5 minutes).

---

## 5. Client & Server Architecture Flow

```
[User Taps Subscribe]
         │
         ▼
[Google Play In-App Billing Sheet] ➔ (Native 7-day trial or paid subscription)
         │
         ▼
[PurchaseDetails Stream in App]
         │ (purchaseToken + productId)
         ▼
[POST /api/v1/subscription/verify]
         │
         ├── Server validates & stores in SQLite `subscriptions` table
         ├── Server marks device `is_vip = 1` in `devices` table
         └── Returns verified expiry date + tier
         │
         ▼
[InAppPurchase.completePurchase()] ➔ Google Play finalizes transaction
         │
         ▼
[VIP Unlocked Across App!]
  ├── AdMob Banner Hidden
  ├── All Horoscope & Panchang Muhurtas Crystal Clear (Unblurred)
  ├── Greeting Cards Exported with Zero Watermark
  └── Shimmering Gold 👑 VIP Badge in Header
```
