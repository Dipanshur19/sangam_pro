# Sangam Pro — Full-Stack Edition

Premium rebuild of Sangam with phone+OTP auth, 3D animated UI, Firebase-ready backend, and full interactive screens.

## What's new vs the original Sangam app

- **Configurable for any shop** — set your shop name, owner, and location on first launch; the whole app personalises to your store
- **Owner & staff modes** — full owner view plus a read-only balance lookup for staff
- **Animated splash screen** — 3D rotating Sangam logo with particle background
- **3-slide onboarding + guided store setup** — start fresh or with sample data
- **3D tilt dashboard card** — uses your phone's accelerometer for a parallax effect on the hero card
- **Live donut chart** — UPI breakdown visualised with fl_chart
- **Smooth animations everywhere** — flutter_animate powers fade/slide/scale transitions on every screen
- **Premium design system** — gradient cards, glass-morphism, custom typography (Poppins)
- **Optional phone + OTP login** — via Firebase Auth when configured (app is fully offline otherwise)
- **All screens fully wired** — Splash → Onboarding → Store Setup → Login → Dashboard → Add → Customers → Customer Detail → Report → Staff → Settings → SMS Queue → Photo Import

## Quick start (works offline, zero setup)

```bash
flutter pub get
flutter run
```

The app works immediately — no Firebase or account required.

### First launch

1. A 3-slide intro explains what Sangam does.
2. **Set up your shop** — enter your shop name (and optionally owner name and
   location). This personalises the whole app, so **any shop owner can use it**.
3. Choose how to begin:
   - **Start fresh** — an empty ledger for real use.
   - **Try with sample data** — demo customers and transactions to explore.

You can edit your shop details, load demo data, or **clear all data** anytime
from **Settings**. On the login screen, **Quick access → Owner / Staff** lets you
switch between the full owner view and the read-only staff lookup.

## Enabling real phone + OTP login

This requires Firebase. Steps:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then in `lib/main.dart`, uncomment:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

And in `android/app/build.gradle`, add:
```gradle
plugins {
    id "com.google.gms.google-services"
}
```

In Firebase Console → Authentication → Sign-in method → enable **Phone**.

## Enabling AI Khata Photo import

1. Get an Anthropic API key at console.anthropic.com
2. Open the app → Dashboard → Settings (gear icon)
3. Paste your key under "AI Photo Parsing"
4. Go to Add Transaction → Khata Photo → take a photo of any handwritten register page

## Project structure

```
lib/
├── main.dart                    Entry point
├── router.dart                  GoRouter — all 13 routes
├── firebase_options.dart        Run flutterfire configure to populate
├── core/
│   ├── theme.dart               Full design system: colors, gradients, shadows, text styles
│   ├── constants.dart           App-wide constants
│   └── utils.dart                Formatting helpers
├── domain/
│   ├── entities/                Transaction, Customer, SmsEntry, DailyTotals, OverdueCustomer
│   └── usecases/
│       └── sms_parser.dart      Regex parser for Paytm/GPay/PhonePe SMS
├── presentation/
│   ├── providers/
│   │   └── providers.dart       All Riverpod state — auth, transactions, customers, SMS queue
│   ├── screens/
│   │   ├── splash/              3D animated splash with particle background
│   │   ├── onboarding/          3-slide custom-painted onboarding
│   │   ├── auth/                Phone login + OTP verification
│   │   ├── dashboard/           3D tilt hero card + donut chart + overdue list
│   │   ├── add_transaction/     Manual / SMS paste / Camera entry
│   │   ├── customers/           List + detail with payment recording
│   │   ├── report/              End-of-day reconciliation report
│   │   ├── staff/                Read-only balance lookup
│   │   ├── sms_queue/           Auto-detected UPI SMS assignment
│   │   ├── photo_import/        AI khata photo parsing
│   │   └── settings/            API key, PINs, data reset
│   └── widgets/
│       └── bottom_nav.dart      Animated pill-highlight bottom navigation
└── services/
    ├── sms_service.dart         SMS permission + demo data (native integration point for Phase 2)
    ├── claude_service.dart      Anthropic Vision API for khata photo parsing
    └── notification_service.dart  Local push notifications
```

## Demo data

Demo data is **opt-in**. Choose "Try with sample data" during setup, or load it
later from **Settings → Data → Load demo data** (7 sample customers with
realistic transaction history). Real shops should choose "Start fresh".

## Build for the Play Store

### 1. Create a release keystore (one time)

```bash
keytool -genkey -v -keystore ~/sangam-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias sangam
```

### 2. Add signing config

Copy `android/key.properties.example` to `android/key.properties` and fill in
your keystore path and passwords. This file is git-ignored and must never be
committed. If it is absent, release builds fall back to debug signing so the
project still builds locally.

### 3. Build

```bash
# App Bundle (recommended for Play Store upload)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab

# Or a release APK for sideloading
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Release builds use R8 code shrinking and resource shrinking (see
`android/app/proguard-rules.pro`).

### Store listing checklist

- **Package name:** `com.sangam.app`
- **Privacy policy:** host [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) at a public
  URL and add it in the Play Console (update the contact email first).
- **Permissions:** Camera/Photos (khata import) and Notifications only. The app
  deliberately requests **no SMS, contacts, or location** permissions.
- **Data safety form:** ledger data stays on-device; photos are only sent to
  Anthropic if the user enables AI import with their own key.

## Known limitations / roadmap

- **UPI SMS auto-detection** is shown as a preview with sample entries. True
  background SMS reading is intentionally not enabled because Google Play
  restricts SMS permissions; a future version may use a user-initiated import.
- **Firebase sync / phone login** requires running `flutterfire configure` and
  uncommenting the init in `lib/main.dart`. The default build is fully offline.
- **Push notifications** need Firebase Cloud Messaging configured from a backend.
