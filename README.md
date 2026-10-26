# BuildingFex — App de Residentes (Flutter)

Resident-facing mobile app for the BuildingFex condominium. Built with Flutter +
Riverpod, it talks to the same backend as the admin (Jetpack Compose) app with
no server-side changes.

The admin functionality lives in the Compose app (`../Clases/FrontEnd`); this
app is resident-only. Admin accounts are blocked from signing in here
(`err.ADMIN_LOGIN_BLOCKED`), and residents are blocked from the Compose app
(`err.RESIDENT_LOGIN_BLOCKED`).

## Features (7 screens)

- **Login + invite activation** — sign in with email/password, or activate a
  resident account with an invitation code (`304-k7m2` style; paste the whole
  invite message and the code is extracted automatically).
- **Dashboard** — greeting, pending balance, open/in-progress/resolved incident
  counts, today's and upcoming reservations, active announcements.
- **Finances** — pending balance, total paid, merged fees (receipts + fees via
  `mapFees`), Mercado Pago Checkout Pro (demo flow or real WebView checkout with
  redirect-param confirmation), and payment history.
- **Common areas** — browse published spaces, pick a date/time slot (with already
  booked slots shown), and reserve with client-side field/time/overlap
  validation.
- **My reservations** — edit each reservation's guest list (max 5), show a
  guest-check-in QR, and share the invite link (expires 25 min after start).
- **Incidents** — report new incidents, review status, edit description, delete.
- **Support** — static FAQ catalog + support chat (create a ticket, append
  messages).
- **Settings** — profile, language toggle (ES/EN), log out.

## Architecture

Clean Architecture by feature + repository pattern + Riverpod state
(Notifier/StateNotifier) + manual DI (`lib/core/repositories.dart`).

- `lib/core/` — API client (dio + Bearer/401 interceptor + `apiCall` error
  mapping), session (persisted via `shared_preferences`), i18n catalog (ES/EN),
  dates, invite-code helpers, shared widgets, manual DI providers.
- `lib/features/<name>/` — per feature: `*_repository.dart` (data),
  `*_controller.dart` (state), `*_screen.dart` (UI), `*_models.dart` (domain).

State management and i18n mirror the admin app's patterns and key-based catalog
so both clients stay in sync. Riverpod was chosen for the Mercado Pago flow and
future SMS/email notifications (deferred until the backend exposes endpoints).

## Configuration

The backend base URL is injected at build time and defaults to the deployed
backend:

```
flutter run --dart-define=API_BASE_URL=http://localhost:5211   # local
flutter run                                                     # uses default
```

## Build & test

```
flutter pub get
flutter analyze      # 0 issues
flutter test         # unit tests for InviteCodes, ReservationRules, i18n
flutter build apk --debug
```

## Testing seeds

- Admin: `admin@buildingfex.test` / any password (use the Compose app).
- Resident: `residente@buildingfex.test`, invite code `301`,
  `ownerAdminId: admin-seed-1`.
