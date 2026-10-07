# GariKhata · গাড়ির খাতা

A ledger app for small fleet owners in Bangladesh: people who rent out 2–5 CNGs, cars or pickups and need to track each driver's daily hand-over (জমা), dues (বাকি), fuel, repairs, and which vehicle actually makes money.

Built with Flutter for Android, iOS, web, macOS, Windows and Linux. Data lives in **SQLite** on the device. Backups go to the owner's **Google Drive** or to a local file.

## Features

| | |
|---|---|
| **Daily collection** | One screen for every active vehicle. Tap *Full* or *Off*, or type a partial amount. Any shortfall goes into the driver's due automatically. |
| **Trips** | Which vehicle went where (from → to), the dates, the fare, and every road cost with the place it was spent: fuel, engine oil (mobil), tolls/bridges/ferries, road costs, food/lodging, driver allowance, commission, loading. Shows profit per trip, distance and cost per km. Fares and costs flow into the ledger and reports. |
| **Trip business** | Status (booked, on the road, completed, cancelled), client name and phone, cargo, challan/booking number, and payments from the client: advance and later instalments by cash, bKash, Nagad, bank or cheque. Only trips on the road or completed count as income. |
| **Client ledger** | Every client across all trips: trips done, total fare, received, still owed. Names typed slightly differently are grouped, and the phone number fills in when a known client is picked again. |
| **Garage visits (job card)** | One record per visit to a garage or service centre: date, odometer, workshop, mechanic, job card no., labour charge and every part fitted, each with brand, quantity, price, the shop it was bought from, warranty end date and when to change it next. |
| **Service book** | Visits are marked official service centre or local garage, with a title such as "2nd free service". A visit can set the next general service by date and/or km, which is then tracked and alerted. |
| **Parts & maintenance** | Monthly upkeep spend (servicing, parts, oil, tyres, repairs) with a 6-month trend, the month's garage visits, and what is fitted on each vehicle now. Parts and services that are overdue or due soon show on the dashboard. |
| **Vehicle & driver records** | Chassis and engine numbers, colour, model year, fuel type and capacity per vehicle; driving licence number and expiry per driver (with an alert); document number and issuing office for each paper. |
| **Fast entry** | A custom number pad for fuel (litres/m³ and odometer), repairs and costs (12 categories), trip/hire income and due recovery. Physical keyboards work too. |
| **Per-vehicle profit** | Income − expense per vehicle, average daily income, mileage (km per unit), a 6-month trend and a cost breakdown. |
| **Payback tracker** | Shows how much of the purchase price the vehicle has earned back, and how much is left. |
| **Driver dues** | Running due per driver (opening due + shortfalls − recoveries), a 60-day collection heat-map and one-tap calling. |
| **Paper reminders** | Expiry dates for tax token, fitness, route permit, insurance, registration and licence, with alerts on the dashboard. |
| **Reports** | This month / last month / this year / all time / custom range. Includes a vehicle leaderboard, monthly bars, an expense donut and a dues list. |
| **Bilingual** | Bangla by default (with optional Bangla numerals) and English. Amounts use lakh grouping: ৳1,25,000. |
| **Themes** | Light, dark and system themes. Phones get a floating pill navigation; tablets, desktop and web get a sidebar. |
| **Backup** | Google Drive app-private folder (keeps the last 10, plus optional daily auto-backup) and SQLite file export/import. |
| **Demo data** | About 4 months of realistic data for 4 vehicles, so every screen can be explored straight away. |

## Run

```bash
cp .env.example .env                                  # once: app settings
flutter pub get
flutter run --dart-define-from-file=.env              # phone / emulator
flutter run --dart-define-from-file=.env -d chrome    # web
flutter run --dart-define-from-file=.env -d macos     # desktop
flutter test                                          # unit + repository tests
```

In VS Code, the Run and Debug configs in `.vscode/launch.json` pass `.env` for you.

## Settings (`.env`)

Every build-time setting lives in `.env` in the project root (git-ignored; `.env.example` is the template). Flutter reads it through `--dart-define-from-file`, so no package is needed. The app reads all of it through one class, `lib/core/env.dart`. Add a new key in three places: `.env.example`, `.env` and `Env`.

| Key | What it does |
|---|---|
| `API_BASE_URL` | Backend address. `http://localhost:8001` works for web, desktop and the Android emulator (rewritten to `10.0.2.2`). On a real phone, use the computer's LAN IP. For production, use `https://…`. To build the web app the backend serves at `/app/`, use `origin`. |
| `API_TIMEOUT_SECONDS` | Seconds before an API call counts as offline (default 20). |
| `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID` | OAuth client IDs for Drive backup (see Google Drive setup below). |

* Values are compiled into the app. Never put a server secret here.
* After you change a value, restart the app. Hot reload does not pick it up.
* `--dart-define=KEY=value` overrides the same key in the file, for example `--dart-define=API_BASE_URL=origin` for the web build.
* Debug Android builds allow plain HTTP to any host, so a LAN IP works. Release builds allow plain HTTP only to `localhost` and `10.0.2.2` (`android/app/src/main/res/xml/network_security_config.xml`).

## Accounts, packages and the admin backend

The app now requires an account. After onboarding, owners log in or register: name, username, **email** and **mobile** are required, and business name, district and number of vehicles are optional. There is also a forgot-password flow with a 6-digit code sent by email. The ledger data stays on the phone. The server ([backend/](backend/), Laravel 13 + Filament 5) stores the account, what the account may use, and which screens are opened.

* **Packages**: users without a package get every feature. Once an admin assigns a package, only its features and its vehicle and driver limits apply. The app never shows package names; a locked feature shows a lock sheet with the support call and WhatsApp buttons. See `lib/services/access.dart` and `lib/ui/widgets/access_gate.dart`.
* **Screen analytics**: every pushed page is an `AppRoute` (`lib/ui/routes.dart`) that reports its screen key. Tabs and sheets report theirs too. Events are queued on the device (so screens opened offline or before login are kept) and sent in batches (`lib/services/analytics.dart`).
* **Account page** (Settings → My account): edit profile, change password, log out and delete the account. Deleting the account also erases the ledger on the phone, as the Play Store requires.
* **Server switches**: the admin can force an update, pause the API for maintenance, close registration and set support contacts.

The backend also serves the public **website** at `/`, which uses the app's design. Its **Login** opens the admin panel, and the web app is hosted at `/app/`.

Run the backend (see `../rent-a-car owner-backend/README.md`), then point the app at it with `API_BASE_URL` in `.env`:

```bash
php artisan serve --host=0.0.0.0 --port=8001               # in the backend folder: API + admin at /admin
flutter run --dart-define-from-file=.env                   # API_BASE_URL=http://localhost:8001 (emulator → 10.0.2.2)
flutter build apk --release --dart-define-from-file=.env   # with API_BASE_URL=https://api.your-domain.com
```

## Project layout

```
lib/
  core/        env (.env settings), theme (design tokens), l10n (bn/en strings), format (৳, lakh, Bangla digits), catalog (vehicle types, categories, papers)
  data/        models, repository (all SQL), demo_seed, db_factory_{io,web} (sqflite / ffi / wasm)
  services/    settings (shared_preferences), drive_backup (Google Drive), local_backup (file picker)
  state/       app_state (ChangeNotifier + revision counter)
  ui/          shell (nav), screens/*, widgets/* (number plate, heat-map, charts, ledger tiles…)
tool/          generate_icon_test.dart: renders the app icon from code
web/           sqlite3.wasm + sqflite_sw.js (SQLite in the browser, stored in IndexedDB)
```

### Data model (SQLite)

* `vehicles`: type, reg no, purchase price/date, daily target, assigned driver, status, chassis/engine no., colour, year, fuel, capacity
* `drivers`: phone, NID, licence no. and expiry, opening due
* `incomes`: `kind` is `joma` (daily, has target), `trip`, `due` (recovery) or `off` (vehicle didn't run)
* `expenses`: category, amount, optional quantity and odometer (fuel), place
* `papers`: vehicle paper type, expiry date, document number, issuing office
* `trips`: vehicle, driver, origin, destination, dates, status, client and phone, cargo, challan no., fare, start/end odometer. While the trip is on the road or completed, the fare is mirrored as a `trip` income; road costs are `expenses` rows with a `place`; all are linked by `trip_id`.
* `trip_payments`: what the client paid against a trip (date, amount, method). Client due = fare − payments.
* `service_visits`: garage/service-centre job card (date, odometer, official or local, workshop, mechanic, job no., title, labour, next service date/km). Labour is an `expenses` row linked by `visit_id`.
* `parts`: part type, brand, quantity, cost, shop, warranty, fitting date and odometer, next change date/km, optional `visit_id`. The cost is an `expenses` row linked by `part_id`. The newest fitting per vehicle and part is the current one.

Driver due = `opening_due + Σ(target − amount)` over `joma` and `due` rows.

Schema version 2 added `trips` and `parts`; version 3 added `service_visits`, `trip_payments` and the new columns. Older databases and backups are upgraded when opened.

## Google Drive setup

Backups use the `drive.appdata` scope. That gives a hidden folder that only this app can see, inside the owner's own Drive.

1. In [Google Cloud Console](https://console.cloud.google.com/), create a project and enable **Google Drive API**.
2. Configure the **OAuth consent screen** and add the scope `.../auth/drive.appdata`.
3. Create the OAuth client IDs:
   * **Web application**: used by web, and as `serverClientId` on Android. Add `http://localhost:PORT` and your domain as authorised JavaScript origins.
   * **Android**: package `com.garikhata.gari_khata` and the SHA-1 of your signing key (`cd android && ./gradlew signingReport`).
   * **iOS / macOS**: bundle id `com.garikhata.gariKhata`.
4. Put the IDs in `.env`:

```bash
GOOGLE_CLIENT_ID=<web-or-ios-client-id>
GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

5. **iOS/macOS only**: add the iOS client ID to `ios/Runner/Info.plist` as `GIDClientID`, and its reversed form as a URL scheme (`CFBundleURLTypes`). This is described in the [google_sign_in_ios README](https://pub.dev/packages/google_sign_in_ios).

Until this is configured, the app shows "Google Drive is not configured" and local file backup still works on every platform. Windows and Linux use local file backup only.

## Android signing

Release APKs are signed with a project key so every build (on any machine) can update the installed app:

* `android/keys/garikhata-debug.jks` (alias `garikhata`, RSA 2048, valid ~27 years)
* `android/key.properties` (path + passwords)

Both are git-ignored. **Back them up privately.** If they are lost, phones that already have the app must uninstall it (and lose local data unless backed up) before installing a new build. If `key.properties` is missing, Gradle falls back to the machine's default debug key.

Certificate fingerprints (also needed for the Android OAuth client in Google Cloud):

```
SHA-1:   D8:E5:81:0A:EE:AF:ED:24:D4:A3:CB:6D:B8:94:60:8F:04:DF:97:62
SHA-256: C7:31:82:67:F7:25:03:E1:EB:8B:8D:2E:A2:E8:74:C7:A2:D5:89:68:A1:27:F1:70:EB:D0:B1:73:C8:09:1A:FD
```

Build:

```bash
flutter build apk --release --dart-define-from-file=.env                  # universal APK
flutter build apk --release --dart-define-from-file=.env --split-per-abi  # smaller per-CPU APKs
```

For the Play Store, build an App Bundle (`flutter build appbundle`) and decide whether this key becomes the upload key or a new one is created.

## Web: SQLite files

`web/sqlite3.wasm` and `web/sqflite_sw.js` are already committed. To regenerate them:

```bash
dart run sqflite_common_ffi_web:setup
```

With Flutter 3.47, that setup currently fails inside its own build step (a build_runner/analyzer version mismatch). The workaround: add `dependency_overrides: analyzer: ">=10.0.0 <14.5.0"` to `.dart_tool/sqflite_common_ffi_web/setup/1.2.0/pubspec.yaml`, run `dart run webdev:webdev build -o web:build` there, then copy `build/sqflite_sw.dart.js` to `web/sqflite_sw.js`.

## App icon

The icon is drawn in code (`tool/generate_icon_test.dart`):

```bash
flutter test tool/generate_icon_test.dart
dart run flutter_launcher_icons
```
