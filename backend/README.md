# BhaktiDhara Sacred Backend (Python FastAPI)

High-performance, privacy-first backend built for deployment on your **Hetzner VPS**.

---

## 🌟 Key Features

1. **Daily Gemini Caching Engine**:
   - Pre-caches today's 12 Rashis and Top Cities' Panchang (Marathi & Hindi, 36 readings) every night from **00:05 AM IST**.
   - Built for the Gemini **free tier**: every call (users + precache) shares one limit of `GEMINI_RPM` calls/min (default 10). The precache is paced at `PRECACHE_RPM` (default 5/min, ~8 minutes total), so users always keep the rest.
   - Cache-first: the first request for a reading calls Gemini and stores it; everyone after gets it from SQLite. Simultaneous requests for the same reading share one Gemini call, and the precache skips anything users already generated.
   - When the quota is full, the API answers `503` immediately (the app falls back to its offline calculation) and generates the reading in the background so the next request hits cache.
   - Serves cached responses to devotees in **< 10 milliseconds**.
2. **Anonymous Device & Download Tracking (100% Privacy-Preserving)**:
   - Tracks unique installs, Daily Active Users (DAU), Monthly Active Users (MAU), and VIP subscribers.
   - **ZERO personal information collected** (no phone numbers, no emails, no names, no passwords).
3. **Secret API Key Protection**:
   - `GEMINI_API_KEY` stays private on your Hetzner server and is never exposed in the client app.
4. **Admin Control Room** at `/admin` (login with `ADMIN_SECRET`):
   - **Overview**: downloads, new installs, DAU/WAU/MAU, stickiness, VIP conversion, dormant users, trends, platforms, languages, app versions, peak hours, top cities/states.
   - **Users**: search/filter/sort every device, CSV export, per-user activity, grant complimentary VIP, block, notes, delete (privacy requests).
   - **Engagement**: most used features and most opened aartis, paywall → VIP funnel.
   - **Retention**: D1/D7/D30 and weekly install cohorts.
   - **Announcements**: in-app messages per language (`GET /api/v1/announcements`).
   - **App Control**: remote config — force update, maintenance mode, feature flags (`GET /api/v1/config`).
   - **System**: cache hit rate, Gemini usage, job runs, manual precache, cache clearing, admin audit log.

5. **Firebase Push Notifications** (dashboard → 🔔 Push):
   - Send now or schedule (one-off or daily repeating) to everyone, VIP, free, inactive users, or a single device, filtered by language and platform.
   - Tap opens a screen in the app (aarti, panchang, jaap, horoscope, bhajans). Opens are tracked per campaign.
   - Invalid/uninstalled tokens are cleaned up automatically.

### Push setup (one time)
1. Firebase console → project **bhaktidhara-app** → ⚙️ Project settings → **Service accounts** → **Generate new private key**.
2. Copy it to the server as `data/firebase-service-account.json`:
   ```bash
   scp ~/Downloads/bhaktidhara-app-*.json root@<YOUR_HETZNER_IP>:/root/bhaktidhara-backend/data/firebase-service-account.json
   ```
3. `docker compose up -d --force-recreate` — the Push tab shows **● Ready** when it works.

---

## 🚀 1-Minute Deployment on Hetzner

### Option A: Using Docker (Recommended)

1. SSH into your Hetzner VPS:
   ```bash
   ssh root@<YOUR_HETZNER_IP>
   ```

2. Copy the `backend/` folder to your server:
   ```bash
   scp -r backend root@<YOUR_HETZNER_IP>:/root/bhaktidhara-backend
   ```

3. On your Hetzner server:
   ```bash
   cd /root/bhaktidhara-backend
   cp .env.example .env
   nano .env  # Add your GEMINI_API_KEY and change ADMIN_SECRET
   ```

4. Launch with Docker Compose:
   ```bash
   docker compose up -d
   ```
   *Your API is now live at `http://<YOUR_HETZNER_IP>:8000`!*

---

### Option B: Running with Python & Systemd

1. Install Python 3.11+ & Virtualenv on Ubuntu/Debian:
   ```bash
   sudo apt update && sudo apt install -y python3-pip python3-venv
   ```

2. Setup project:
   ```bash
   cd /root/bhaktidhara-backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   cp .env.example .env
   nano .env
   ```

3. Run with systemd or Uvicorn:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

---

## 🔒 Free HTTPS / SSL with Nginx & Certbot

Point your subdomain (e.g. `api.yourdomain.com`) to your Hetzner IP, then run:

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

Add an Nginx reverse proxy configuration in `/etc/nginx/sites-available/bhaktidhara`:
```nginx
server {
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable site and get free SSL certificate:
```bash
sudo ln -s /etc/nginx/sites-available/bhaktidhara /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d api.yourdomain.com
```

---

## 📊 API Documentation & Endpoints

Interactive Swagger UI is available at:
`https://api.yourdomain.com/docs`

### 1. Daily Horoscope
```http
GET /api/v1/horoscope?rashi=aries&period=today&lang=mr
```

### 2. Vedic Panchang
```http
GET /api/v1/panchang?city=pune&lang=mr
```

### 3. Anonymous Heartbeat / Install Ping
```http
POST /api/v1/telemetry/ping
Content-Type: application/json

{
  "deviceId": "anon-device-uuid-1234",
  "platform": "android",
  "appVersion": "1.0.4",
  "locale": "mr",
  "isVip": false
}
```

### 4. Feature usage events
```http
POST /api/v1/telemetry/event
Content-Type: application/json

{ "deviceId": "anon-device-uuid-1234", "events": [{ "name": "aarti_open", "props": { "item": "Ganpati Aarti" } }] }
```

### 5. Admin API
All `/api/v1/admin/*` endpoints require the `X-Admin-Secret` header (the legacy `?secret=` query param still works).
```http
GET /api/v1/admin/stats
X-Admin-Secret: YOUR_ADMIN_SECRET
```
Example JSON Response:
```json
{
  "status": "success",
  "metrics": {
    "total_installs": 14200,
    "daily_active_users_dau": 5820,
    "monthly_active_users_mau": 12400,
    "vip_subscribers": 310,
    "platforms": { "android": 12100, "ios": 1800, "web": 300 },
    "locales": { "mr": 10500, "hi": 3200, "en": 500 },
    "cache_entries": { "horoscope_count": 72, "panchang_count": 24 }
  }
}
```
