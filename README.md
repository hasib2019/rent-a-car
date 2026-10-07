# GariKhata · গাড়ির খাতা

A ledger app for small fleet owners in Bangladesh: people who rent out 2–5 CNGs, cars or pickups and need to track each driver's daily hand-over (জমা), dues (বাকি), fuel, repairs, and which vehicle actually makes money.

Built with Flutter for Android, iOS, web, macOS, Windows and Linux. Data lives in **SQLite** on the device. Backups go to the owner's **Google Drive** or to a local file.

## Features

| | |
|---|---|
| **Daily collection** | One screen for every active vehicle. Tap *Full* or *Off*, or type a partial amount. Any shortfall goes into the driver's due automatically. |
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
flutter pub get
flutter run                 # phone / emulator
flutter run -d chrome       # web
flutter run -d macos        # desktop
flutter test                # unit + repository tests
```

## Project layout

```
lib/
  core/        theme (design tokens), l10n (bn/en strings), format (৳, lakh, Bangla digits), catalog (vehicle types, categories, papers)
  data/        models, repository (all SQL), demo_seed, db_factory_{io,web} (sqflite / ffi / wasm)
  services/    settings (shared_preferences), drive_backup (Google Drive), local_backup (file picker)
  state/       app_state (ChangeNotifier + revision counter)
  ui/          shell (nav), screens/*, widgets/* (number plate, heat-map, charts, ledger tiles…)
tool/          generate_icon_test.dart: renders the app icon from code
web/           sqlite3.wasm + sqflite_sw.js (SQLite in the browser, stored in IndexedDB)
```

### Data model (SQLite)

* `vehicles`: type, reg no, purchase price/date, daily target, assigned driver, status
* `drivers`: phone, NID, licence, opening due
* `incomes`: `kind` is `joma` (daily, has target), `trip`, `due` (recovery) or `off` (vehicle didn't run)
* `expenses`: category, amount, optional quantity and odometer (fuel)
* `papers`: vehicle paper type and expiry date

Driver due = `opening_due + Σ(target − amount)` over `joma` and `due` rows.

## Google Drive setup

Backups use the `drive.appdata` scope. That gives a hidden folder that only this app can see, inside the owner's own Drive.

1. In [Google Cloud Console](https://console.cloud.google.com/), create a project and enable **Google Drive API**.
2. Configure the **OAuth consent screen** and add the scope `.../auth/drive.appdata`.
3. Create the OAuth client IDs:
   * **Web application**: used by web, and as `serverClientId` on Android. Add `http://localhost:PORT` and your domain as authorised JavaScript origins.
   * **Android**: package `com.garikhata.gari_khata` and the SHA-1 of your signing key (`cd android && ./gradlew signingReport`).
   * **iOS / macOS**: bundle id `com.garikhata.gariKhata`.
4. Pass the IDs at build time:

```bash
flutter run --dart-define=GOOGLE_CLIENT_ID=<web-or-ios-client-id> \
            --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

5. **iOS/macOS only**: add the iOS client ID to `ios/Runner/Info.plist` as `GIDClientID`, and its reversed form as a URL scheme (`CFBundleURLTypes`). This is described in the [google_sign_in_ios README](https://pub.dev/packages/google_sign_in_ios).

Until this is configured, the app shows "Google Drive is not configured" and local file backup still works on every platform. Windows and Linux use local file backup only.

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
