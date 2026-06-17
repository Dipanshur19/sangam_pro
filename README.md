# Sangam Pro — Full-Stack Edition

Premium rebuild of Sangam with phone+OTP auth, 3D animated UI, Firebase-ready backend, and full interactive screens.

## What's new vs the original Sangam app

- **Real login** — phone number + OTP via Firebase Auth (with demo PIN shortcuts for quick testing)
- **Animated splash screen** — 3D rotating Sangam logo with particle background
- **3-slide onboarding** — custom-painted illustrations, parallax background
- **3D tilt dashboard card** — uses your phone's accelerometer for a parallax effect on the hero card
- **Live donut chart** — UPI breakdown visualised with fl_chart
- **Smooth animations everywhere** — flutter_animate powers fade/slide/scale transitions on every screen
- **Premium design system** — gradient cards, glass-morphism, custom typography (Poppins)
- **All 10 screens fully wired** — Splash → Onboarding → Login → OTP → Dashboard → Add → Customers → Customer Detail → Report → Staff → Settings → SMS Queue → Photo Import

## Quick start (works offline, zero setup)

```bash
flutter pub get
flutter run
```

The app works immediately with local demo data — no Firebase required to test it. On the login screen, tap **"Owner (1234)"** or **"Staff (5678)"** under "Demo access" to skip phone verification entirely.

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

Seeded automatically on first launch — 7 customers (Ramesh, Kavita, Mohan, Sunita, Raju, Priya, Vikram) with realistic transaction history matching real-world kirana store patterns. Reset anytime from Settings → "Reset to demo data".

## Build release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Known limitations (Phase 2 roadmap)

- SMS auto-read currently shows demo data — native Android `READ_SMS` MethodChannel integration is the next step (code structure already in `sms_service.dart`)
- Firebase sync requires `flutterfire configure` — app works fully offline without it
- Push notifications need Firebase Cloud Messaging configured to fire from a backend (Cloud Functions)
