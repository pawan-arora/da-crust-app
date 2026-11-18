# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Da Crust — a Flutter Web ordering app for Da Crust Pizzeria & Indian Takeaways (pickup-only, Lumsden NZ). Customers browse the menu, customize items, check out, and pay via Stripe (card/Afterpay) or Paymark Online EFTPOS. Backend is Firebase (Firestore, Cloud Functions, Hosting). Live at https://dacrust.co.nz.

## Commands

```bash
flutter pub get                                    # install deps
flutter run -d chrome --dart-define=ENV=dev         # run locally against the DEV Firebase project
flutter run -d chrome --dart-define=ENV=prod         # run locally against PROD data — use deliberately
flutter build web --dart-define=ENV=prod             # production web build (what CI runs)
flutter analyze                                      # static analysis (flutter_lints)
flutter test                                          # run tests (test/widget_test.dart)
flutter test test/widget_test.dart --plain-name "..." # run a single test by name
dart format lib/                                      # format
```

`ENV` defaults to `dev` (see `lib/main.dart`) specifically so a plain `flutter run` never touches production data — always pass `--dart-define=ENV=prod` explicitly when you need it. Preconfigured VS Code launch profiles for both environments (and LAN device testing) are in `.vscode/launch.json`.

Requires `assets/config.env` (dotenv-loaded, gitignored) — create it locally before running; CI writes it from the `ENV_FILE` GitHub secret. The only key the app reads is `RECAPTCHA_SITE_KEY` (`add_review_dialog.dart`). This file is declared as a Flutter asset, so it is publicly downloadable from the deployed site: never put secrets in it.

Functions read their config from `functions/.env` (gitignored, so absent from a fresh checkout): `APP_ENV`, `LOCAL_URL`/`DEV_URL`/`QA_URL`/`PROD_URL`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `WORLDLINE_API_KEY_ID`, `WORLDLINE_SECRET_API_KEY`, `WORLDLINE_MERCHANT_ID`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_MESSAGING_SERVICE_SID`, `RECAPTCHA_SECRET_KEY`.

Firestore rules live in `firestore.rules`. CI does not deploy them; use `firebase deploy --only firestore:rules --project <da-crust-dev|da-crust-prod>`.

Cloud Functions (`functions/`, Node 20):
```bash
cd functions && npm install
npm run serve     # firebase emulators:start --only functions
npm run shell      # firebase functions:shell
npm run deploy      # firebase deploy --only functions
npm run logs        # firebase functions:log
```
`functions/` has no lint or test script, so the Flutter checks (`flutter analyze`, `flutter test`) are the only automated checks in this repo.

**Traps:**
- `test/widget_test.dart` is still the untouched Flutter counter template (it taps a `+` icon and expects `0`→`1`), so it does not test this app and will fail. There is no real test suite yet. Replace it rather than trying to fix it.
- `.firebaserc` defines only `default: da-crust-prod`, so every `firebase` CLI command, including `npm run deploy`, targets **production** unless you pass `--project da-crust-dev`.
- The FlutterFire block in `firebase.json` maps the dev config to `lib/firebase_options.dart`, but the app imports `lib/firebase_options_dev.dart`. Re-running `flutterfire configure` writes the wrong file; rename the output or fix the mapping.
- Functions read the redirect base URL from the `APP_ENV` plus `LOCAL_URL`/`DEV_URL`/`QA_URL`/`PROD_URL` env vars. `APP_ENV` defaults to `local`, and if the matching `*_URL` var is unset the URL falls back to `https://dacrust.co.nz`. A misconfigured function therefore sends dev payments back to the live site. `APP_ENV` also picks the Paymark endpoint: only `prod` uses the live API, anything else (including unset) uses `apitest.paymark.nz`.
- `npm run deploy` from a checkout without `functions/.env` deploys functions with no gateway keys; `createCheckoutSession` then fails with "Server configuration error."

## Architecture

`lib/` is feature-first: `lib/features/{home,menu,cart,payments,ratings}/` each hold their own screens, widgets, services and state; `lib/core/` is shared (routes, theme, utils, widgets); `lib/data/` has the menu models and repository. `AppConfig` lives at `lib/app_config.dart`, outside `core/`.

This app shares its Firebase projects with the separate `../dacrust-admin-dashboard` repo, which writes `menu`, `categories`, `restaurant` and `admin` and reads `orders`. Renaming a Firestore field either app reads breaks the other, and `firestore.rules` here is the only rules file for both.

### Dual Firebase projects (dev/prod), selected at build time

Two full Firebase project configs live side by side: `lib/firebase_options_dev.dart` (`da-crust-dev`) and `lib/firebase_options_prod.dart` (`da-crust-prod`). `main.dart` reads the `ENV` dart-define and picks one before calling `Firebase.initializeApp`. There's no runtime env switching — it's baked into the build. Firebase Hosting deploys (`firebase.json`) and Cloud Functions run against `da-crust-prod`; `functions/index.js` also branches on an `APP_ENV`/`DOMAIN` map (`local`/`dev`/`qa`/`prod`) for Stripe success/cancel redirect URLs.

### Bootstrap sequence (`lib/main.dart`)

Timezone data init → load `assets/config.env` via dotenv → pick Firebase options by `ENV` → `Firebase.initializeApp` → `AppConfig.instance.init()` (store settings, currently hardcoded defaults — the Firestore fetch is commented out) → `RestaurantService.instance.init()` (must run before `runApp`: the router reads `isRestaurantClosed` synchronously) → `CartManager.instance.initialize()` (restores cart from `SharedPreferences`) → image cache caps (200 images / 50MB — CanvasKit web texture cache guard) → `runApp`.

### Routing

`lib/core/routes/app_router.dart` is a hand-rolled path-based router (`onGenerateRoute`), not `go_router`/named routes. It handles `/`, `/checkout`, `/success` (reads `orderId` query param), `/failed`, defaulting unknown paths to `/`. `/checkout` is gated: if `RestaurantService.instance.isRestaurantClosed`, it serves `RestaurantClosedScreen` instead, so deep links can't bypass the closed-store check that `WelcomeScreen` does for in-app navigation. Any non-`/` initial URL sets `hasHomeScreenInitialized = true` to skip the welcome animations. This matters because Stripe/Paymark redirect the browser back to `https://dacrust.co.nz/#/success?orderId=...` after payment — the router has to reconstruct app state from that URL, not from in-memory navigation.

### State management: singleton `ChangeNotifier`s, no Provider/Riverpod

State lives in plain singletons (`CartManager.instance`, `AppConfig.instance`, `RestaurantService.instance`), each a `ChangeNotifier` accessed directly rather than through `package:provider`/`InheritedWidget`. Screen-level view models (e.g. `CheckoutViewModel`) wrap these singletons, manually `addListener`/`removeListener` in constructor/`dispose`, and expose form `TextEditingController`s that both prefill from and write back to `CartManager` on every keystroke — this is what makes cart/customer-details survive a full browser reload.

`CartManager` persists cart items, order note, scheduled pickup time, customer details, and the current pending `orderId` to `SharedPreferences` (browser localStorage on web). This is essential, not incidental: checkout fully navigates the browser away to Stripe/Paymark and back, so anything not persisted here is lost mid-checkout.

### Menu data shape

Firestore has one document per category in the `menu` collection, each holding `variants` and `extras` arrays. `MenuRepository.streamMenuItems()` flattens all categories into a single `List<MenuItem>` and de-dupes by `menuId` (a plain data field, not the Firestore doc ID — nothing in Firestore enforces uniqueness, and duplicate `menuId`s would crash the UI since widgets key list items by it).

### Checkout → payment → order lifecycle

1. `CheckoutViewModel.submitOrder()` → `CheckoutService.startCheckoutFlow()`.
2. Validates customer details (`CheckoutValidator`).
3. Upserts `orders/{orderId}` in Firestore with `status: 'PENDING'` and a snapshot of cart items/price (order IDs are reused across retries via `CartManager.currentOrderId`, generated as `ORD-XXXXX` only for new orders).
4. Saves the pending order ID to `CartManager` **before** redirecting to payment (redirect unloads the page).
5. `PaymentHandler.process()` calls a Firebase callable function in the `australia-southeast1` region — `createCheckoutSession` (Stripe, card or Afterpay) or `createOnlineEftposSession` (Paymark) — and does a full-page redirect (`url_launcher`, `webOnlyWindowName: '_self'`) to the returned gateway URL.
6. The gateway's webhook (`functions/webhooks.js`) flips the order's status server-side (the intended source of truth for payment success — client code never marks an order paid itself). `createOnlineEftposSession` sets `PENDING_EFTPOS` and writes a `paymark_transactions/{transactionId}` doc, which is how `worldlineWebhook` maps a transaction back to its order. Terminal statuses are `PAID`, `FAILED` and `DECLINED`; `processSuccessfulOrder` returns early on `PAID`, so webhook retries don't re-send notifications.
7. `/success` and `/failed` routes read the outcome via `orderId`, and `OrderSuccessScreen` listens to the order doc for status changes. The gateway redirect can arrive before the webhook has updated the order, so if the order is still loading after 5 seconds the screen shows a "Verify Payment" button that calls the `verifyEftposStatus` callable. It is user-triggered, not automatic, and is a no-op for orders without a `paymarkId`. **Known bug:** `functions/index.js` calls `processSuccessfulOrder` in that callable but never imports it from `./orderProcessor`, so the `AUTHORISED`-and-not-yet-`PAID` path throws a `ReferenceError` (surfaced as an `internal` error).

`CartManager._verifyAbandonedCartStatus()` reconciles on load: if a pending order was already marked `PAID` in Firestore (e.g. user paid, then reopened the app before the client caught up), it clears the local cart.

Pricing is computed on the client (NZD, GST-inclusive), including the 2% surcharge from `AppConfig.cardSurchargeRate`, which applies to card only (not Afterpay or Online EFTPOS). The payment callables charge whatever `amount` they are sent.

### Firestore security rules

Rules grant by union, so the catch-all `match /{document=**}` at the bottom of `firestore.rules` (read/write for `isAdmin()`) overrides the "lock everything" block at the top. `isAdmin()` is currently just `request.auth != null`. Customers are unauthenticated, so the customer flows depend on the public allowances: `orders` allows public create/get/update (which means the webhook-only `PAID` transition above is a convention the rules don't enforce), and `sms_messages`/`mail` allow public create. Any new client write to a collection needs a matching rule.

### Cloud Functions (`functions/`)

The code uses the v1 API (`require("firebase-functions/v1")`) even though `package.json` depends on `firebase-functions` ^7, so keep using the `/v1` import style. Region is `australia-southeast1`. SMS is queue-driven: writing a doc to `sms_messages` (done by `orderProcessor.js`) fires the `sendSmsNotification` Firestore trigger. Email is queued the same way in the `mail` collection, but no function in this repo consumes it, so delivery happens outside this codebase. The owner SMS is delayed by `ownerSmsDelaySeconds` on the restaurant doc (default 30) using a `setTimeout` inside the webhook invocation, and no function sets a custom timeout, so the delay has to fit within the default 60-second limit (the value isn't capped in code). The order is committed as `PAID` before the wait, so if the function times out the owner SMS is lost and a webhook retry won't resend it. `index.js` holds the two payment-session callables plus other HTTPS entry points; `webhooks.js` handles gateway webhook callbacks; `orderProcessor.js` contains order-side business logic triggered off those events; `emailBuilder.js`/`smsBuilder.js` generate order-confirmation email/SMS content (Twilio, only initialized if `TWILIO_ACCOUNT_SID`/`TWILIO_AUTH_TOKEN` env vars are set); `reviewHandler.js` backs the review/feedback feature.

### Restaurant status (open/closed, hours, address)

Single-document `restaurant` Firestore collection, cached in `RestaurantService` singleton (fetched once, cached in memory — call sites don't re-fetch). Opening hours live under the misspelled field `openingHourse`; that is the real Firestore key, so don't "fix" it in code. `isRestaurantClosed` + `nextOpeningDate` drive an auto-reopen check that runs only on the first, uncached fetch (once per page load): if the stored reopen time (compared in NZ local time) has passed, the client itself flips `isRestaurantClosed` back to `false` in Firestore. A dedicated rule permits this anonymous write only if it changes that one field and `nextOpeningDate` has passed on the server clock, so `_autoReopenIfDue` can't write anything else.

### Timezone handling

All scheduling (pickup times, restaurant hours, auto-reopen) is pinned to NZ local time via `package:timezone`, not device-local time — see `lib/core/utils/date_time_utils.dart` (`DateTimeUtils.nzLocation`, `getNzTime()`, `hasNzTimeReached()`). Use these helpers rather than raw `DateTime.now()` for anything user-facing around ordering/pickup times.

### Deployment

GitHub Actions (`.github/workflows/firebase-hosting-merge.yml`) builds and deploys to Firebase Hosting on push to the `prod` branch (this repo's default/main branch); `firebase-hosting-pull-request.yml` builds a preview channel per PR. Work happens on `dev` and reaches `prod` through a PR, so merging to `prod` is a production release. Cloud Functions are not deployed by CI; deploy them by hand with `npm run deploy`. Both workflows write `assets/config.env` from the `ENV_FILE` secret and always build with `--dart-define=ENV=prod`, so PR previews talk to the production backend. The Flutter version (`3.41.6`) is deliberately pinned in both workflows rather than floating on `stable` — bump it intentionally (and re-test) rather than letting CI silently pick up a new release; keep it in sync with local dev.
