# Sangam — Sab ka ek hisaab

A professional, OkCredit-style ledger for Indian kirana shops. One place for UPI
(Paytm / GPay / PhonePe), cash and udhar (credit) — with a multi-user
owner/staff login and automatic UPI-SMS detection.

## Highlights

- **Multi-user login (Admin + Staff)** — the owner is the Admin. The owner can
  create Staff logins from Settings, each with its own password and either
  "can edit" or "view only" access. The login screen has an Admin / Staff
  selector. Accounts and salted password hashes are stored on-device.
- **Automatic UPI SMS reading** — with permission, Sangam reads incoming payment
  SMS from Paytm, GPay and PhonePe, parses the amount/source, and queues them
  for one-tap assignment to a customer.
- **Groq-powered parsing (backend only)** — a Groq API key supplied at build
  time (never shown in the app) is used to parse tricky SMS; on-device regex is
  the always-available fallback.
- **Configurable for any shop** — set shop name, owner and location during
  guided setup; the whole app personalises to that store.
- **Professional design** — indigo/emerald palette, refined logo, animated
  splash, glass cards, donut UPI breakdown, smooth motion.
- **Works offline** — all ledger data is local; demo data is opt-in.

## Quick start

```bash
flutter pub get
flutter run
```

To enable Groq SMS parsing, pass your key at build/run time (kept out of the UI
and out of source):

```bash
flutter run --dart-define=GROQ_API_KEY=gsk_your_key_here
```

### First launch

1. A short intro explains what Sangam does.
2. **Set up your shop** — shop name, owner name, location, and the **admin
   username + password**.
3. Choose **Create shop & start** (empty ledger) or **Create with sample data**.

The owner is now logged in as Admin. From **Settings → Team** the owner can add
Staff logins. Staff log in via the **Staff** tab on the login screen.

## Roles

| Capability                    | Admin | Staff (can edit) | Staff (view only) |
|-------------------------------|:-----:|:----------------:|:-----------------:|
| View dashboard & customers    |  ✓    |        ✓         |         ✓         |
| Add / edit transactions       |  ✓    |        ✓         |         —         |
| Add customers                 |  ✓    |        ✓         |         —         |
| Manage team, store, data      |  ✓    |        —         |         —         |

## Automatic UPI SMS detection

1. Settings → **Auto-read UPI SMS** → grant SMS permission, or open the
   **UPI Payments** screen and tap **Allow SMS access**.
2. Sangam scans recent inbox messages and listens for new ones while open.
3. Detected payments appear in the **UPI Payments** queue — pick a customer and
   tap Save.

Parsing order: on-device regex first; if it can't read the amount and a Groq key
is configured, the SMS text is sent to Groq to extract the details.

> **Google Play note:** `READ_SMS` / `RECEIVE_SMS` are restricted permissions.
> To publish on Google Play you must complete the Permissions Declaration and
> justify SMS use, or distribute via direct APK / private channel. The app
> works fully without SMS access — it just won't auto-detect payments.

## Build for release

### 1. Create a keystore (one time)

```bash
keytool -genkey -v -keystore ~/sangam-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias sangam
```

### 2. Add signing config

Copy `android/key.properties.example` to `android/key.properties` and fill in
your keystore path and passwords. It is git-ignored; if absent, release builds
fall back to debug signing so the project still builds.

### 3. Build

```bash
flutter build appbundle --release --dart-define=GROQ_API_KEY=gsk_your_key_here
# Output: build/app/outputs/bundle/release/app-release.aab
```

Release builds use R8 + resource shrinking (`android/app/proguard-rules.pro`).

### Store listing checklist

- **Package name:** `com.sangam.app`
- **Privacy policy:** host [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) publicly and
  add the URL in the Play Console (update the contact email first).
- **Permissions:** SMS (auto-read, opt-in) + Notifications. No contacts,
  location, camera or microphone.
- **Data safety:** ledger stays on-device; SMS text is sent to Groq only if a
  Groq key was built in.

## Cross-device sync (roadmap)

Multi-user login works on a shared shop device today. To let the owner and staff
use **separate phones** on the same shop data, a cloud backend (e.g. Firebase
Firestore or Supabase) is needed. The data layer is structured so a cloud source
can be added; reach out to wire it once a project is created.

## Project structure

```
lib/
├── main.dart                    Entry point
├── router.dart                  GoRouter routes
├── core/                        theme (design system), constants, utils
├── domain/
│   ├── entities/                transaction, customer, sms_entry, store_profile, app_user
│   └── usecases/sms_parser.dart Regex parser for UPI SMS
├── presentation/
│   ├── providers/providers.dart Riverpod state — auth/session, data, SMS auto-read
│   ├── screens/                 splash, onboarding, store_setup, auth (admin/staff),
│   │                            dashboard, add_transaction, customers, report,
│   │                            staff, sms_queue, settings
│   └── widgets/                 sangam_logo, bottom_nav
└── services/
    ├── auth_service.dart        Local multi-user accounts (salted SHA-256)
    ├── sms_service.dart         SMS reading via another_telephony + parsing
    ├── groq_service.dart        Groq API parsing (key via --dart-define)
    └── notification_service.dart Local notifications
```

## Demo data

Opt-in: choose "Create with sample data" during setup, or load it later from
**Settings → Data → Load demo data**. Real shops should start fresh.
