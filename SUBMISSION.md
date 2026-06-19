# Sangam — POC Demo Submission

> Week 4 · BUILD — 2-min screen recording of a working prototype.

---

## Form fields (copy-paste ready)

### GitHub repository URL
```
https://github.com/Dipanshur19/sangam_pro
```
> View access shared with **finternship@okcredit.in** before submitting.

### Tool / Tech stack
```
Flutter (Dart) · Riverpod (state) · GoRouter (navigation) · SharedPreferences (offline-first local DB) · crypto (salted SHA-256 multi-user auth) · another_telephony (auto UPI-SMS reading) · Groq API – llama-3.3-70b (LLM SMS parsing, server-side key) · fl_chart + flutter_animate + Google Fonts (UI) · Supabase (cross-device cloud sync — roadmap)
```

### Live product link (optional)
```
Android APK: https://github.com/Dipanshur19/sangam_pro/releases/latest
(Runs on a real Android phone; not on x86_64 emulators.)
```

### 2-min POC screen recording URL
```
<paste your Loom / Google Drive / unlisted YouTube link here>
```

---

## Asks from the OKC panel
1. **Onboarding friction** — First run is intro → shop + admin setup → dashboard. Is creating an admin username/password too much for a 55-year-old kirana owner? Should staff join via a short shop-code/QR instead of credentials?
2. **Auto UPI-SMS capture vs Play policy** — We auto-read Paytm/GPay/PhonePe SMS (regex + Groq fallback). Google Play restricts SMS permissions. Pursue the Permissions Declaration, or pivot to a non-SMS capture (notification listener / merchant-VPA reconciliation)?
3. **Multi-user model** — On-device admin + staff works today (shared shop phone). Should true cross-device cloud sync be day-one, or is single-device multi-user enough for the initial wedge?
4. **Differentiation / retention** — What's the daily hook that keeps a kirana owner on this vs OkCredit/Khatabook — the unified UPI+cash+udhar view, or the auto-SMS capture?
5. **Distribution** — Any contacts at FMCG distributors / kirana associations in Lucknow/Patna who'd pilot 10–20 shops?

---

## Notes for judges
Sangam — "Sab ka ek hisaab": one ledger for UPI (Paytm/GPay/PhonePe) + cash + udhar for kirana shops.

**What's working** (Flutter, offline-first, no backend required to demo):
- First-run: onboarding → shop & admin setup → dashboard.
- **Multi-user login**: Admin (owner) + Staff accounts created by admin, each with its own password and can-edit / view-only permission (salted SHA-256, on-device).
- **Automatic UPI-SMS detection** → parsed-payments queue → one-tap assign to a customer (on-device regex parser + Groq LLM fallback for unusual formats; API key stays server/build-side, never shown in app).
- **Unified dashboard** (today's collection, UPI breakdown donut), customers with balances, **WhatsApp** payment reminders, end-of-day report.
- Professional indigo/emerald redesign + custom "confluence" brand logo & adaptive launcher icon.

**How to try:**
- Real Android phone (recommended): install the APK / `flutter run --release`.
- x86_64 emulator: use `flutter run` (debug) — Flutter release/AOT can't run on x86_64 emulators (known emulator limitation, not an app bug).
- Optional Groq parsing: build with `--dart-define=GROQ_API_KEY=...`; without it, parsing falls back to on-device regex.

**Known limitations / roadmap:**
- Cross-device cloud sync (Supabase) is designed and opt-in; on-device multi-user works today.
- Auto-SMS needs a Play Store Permissions Declaration before public release.

---

## 2:00 demo recording script (shot-by-shot, timed)

Record in **debug on the emulator** (`flutter run`) or release on a real phone — choose **"Create with sample data"** at setup so the dashboard looks full.

| Time | Screen | Say / Do |
|------|--------|----------|
| 0:00–0:12 | Splash + logo | "Kirana owners juggle Paytm, GPay, PhonePe, cash and a paper khata every night. Sangam puts them in one ledger." |
| 0:12–0:30 | Onboarding → Shop setup | Swipe slides; on setup type shop name + owner + admin password; tap **Create with sample data**. |
| 0:30–0:55 | Dashboard | Point to today's collection, the **UPI breakdown donut**, outstanding/overdue. "One tap, the whole day's money — every app plus cash and udhar." |
| 0:55–1:15 | Add transaction | Tap **+**, pick a type (e.g. Udhar), enter amount + customer, save; show it land in Recent. |
| 1:15–1:35 | Customer detail | Open a customer → outstanding balance → **WhatsApp reminder**, then **Record payment**. |
| 1:35–1:52 | Team + SMS | Settings → **Team**: add a view-only Staff login; quickly show **Auto-read UPI SMS** toggle + the **UPI Payments** queue (sample detections). |
| 1:52–2:00 | Dashboard | Close: "One ledger — UPI, cash, and udhar — for every shop. That's Sangam." |

**Recording tips:** record at phone resolution, narrate calmly, keep each tap deliberate. If a step runs long, drop the customer-detail "Record payment" sub-step to stay under 2:00.

---

## Pre-submit checklist
- [ ] Merge the feature PR into `main` so the default branch shows the finished app.
- [ ] Add `finternship@okcredit.in` as a repo viewer (Settings → Collaborators).
- [ ] Upload `app-release.apk` to a GitHub Release (or Google Drive) and paste the link.
- [ ] Record + upload the 2-min video; paste the share link.
- [ ] (If using Groq) rotate the API key before sharing the build publicly.
