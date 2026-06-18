# Privacy Policy — Sangam

_Last updated: 17 June 2026_

Sangam ("the app") helps shop owners keep a single ledger for UPI, cash, and
credit (udhar). This policy explains what data the app handles and how.

## Summary

- Your ledger data stays **on your device** by default.
- The app works **offline**. No central account is required.
- We do **not** sell your data or use third-party advertising.

## Accounts on your device

The shop owner creates an **Admin** account (username + password). The admin can
create additional **Staff** logins, each with their own password and either
"can edit" or "view only" access. Passwords are stored only on the device as a
salted hash — never in plain text and never uploaded.

## Data stored on your device

- Store profile (shop name, owner name, location)
- Team accounts (name, username, salted password hash, role)
- Customers (name and optional phone number)
- Transactions (amount, payment type, notes, date)

You can erase customers and transactions anytime from
**Settings → Data → Clear all data**.

## SMS access (optional, opt-in)

If you turn on **Auto-read UPI SMS** in Settings, the app asks for permission to
read your SMS so it can detect payment messages from Paytm, GPay and PhonePe and
suggest them for your ledger.

- SMS reading is **off until you explicitly enable it** and grant permission.
- Only payment-related messages are parsed; the rest are ignored.
- Your SMS content stays on your device **unless** you have configured the
  optional Groq parsing key (see below).
- The app never sends SMS messages and never reads OTPs for any third party.

## Optional cloud parsing (Groq)

A build of the app may include a Groq API key (provided by the developer at
build time, never shown in the app) used to better understand payment SMS that
the on-device parser can't read. When configured, the **text of a payment SMS**
may be sent to Groq's API to extract the amount and source. If no key is
configured, all parsing happens on-device and nothing is sent anywhere. Data
sent to Groq is subject to Groq's privacy policy.

## Permissions we request

- **SMS (READ_SMS / RECEIVE_SMS)** — only after you enable auto-read, to detect
  UPI payments.
- **Notifications** — to show local payment and reminder alerts.
- **Internet** — used only for optional Groq parsing or future cloud sync.

The app does **not** request contacts, location, microphone, or camera.

## Google Play note

Reading SMS requires sensitive permissions that Google Play restricts. If you
publish this app on Google Play you must complete the Permissions Declaration
and justify SMS use, or distribute via direct APK / a private channel. See the
README for details.

## Children's privacy

Sangam is a business tool for shop owners and is not directed at children.

## Your choices

- Use the app fully offline by leaving auto-read off and not configuring Groq.
- Clear all ledger data from Settings at any time.
- Uninstalling the app removes all locally stored data.

## Contact

For privacy questions, contact the developer at: **your-email@example.com**

_(Replace this address with your support email before publishing.)_
