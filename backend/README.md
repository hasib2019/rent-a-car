# GariKhata backend

Laravel 13 website, API and admin panel for the GariKhata app.

* **Website** (`/`): the public landing page, designed with the app's own UI (Bangla and English, fully responsive). It also hosts `/privacy`, `/account-deletion`, `/download/android` and the web app at `/app/`.
* **Login** (`/login`, short link `/l`): an admin sign-in page styled like the app. Signing in opens the admin panel at `/admin`.
* **API** (`/api/v1`, Sanctum tokens): registration, login, password reset by emailed code, profile, account deletion, app config and screen-view analytics.
* **Admin panel** (`/admin`, Filament 5): dashboard, app users, packages and features, subscriptions, screen analytics, activity log, app settings and admins.

The ledger itself (vehicles, collections, expenses…) stays offline in SQLite on each phone. The server only knows **who** the owner is, **what they may use**, and **which screens they open**.

## Run locally

Requirements: PHP 8.3+, Composer, and MySQL/MariaDB (XAMPP works).

```bash
cd backend
composer install
cp .env.example .env && php artisan key:generate   # first time only
# .env → DB_DATABASE=garikhata, DB_USERNAME=root, DB_PASSWORD=
php artisan migrate --seed            # tables + features + first admin (password is printed)
php artisan db:seed --class=DemoSeeder   # optional: 160 fake users + ~2 months of activity
php artisan serve --host=0.0.0.0 --port=8001
```

* Website: http://127.0.0.1:8001 · Login: http://127.0.0.1:8001/login → `/admin`
* Web app: http://127.0.0.1:8001/app/
* API: http://127.0.0.1:8001/api/v1/config

The website's CSS and JS are built with Vite and Tailwind 4: `npm install && npm run build` (or `npm run dev` while editing views).

### Refreshing the web app and the APK

`public/app/` and `public/downloads/` are copies of Flutter build output, and they are git-ignored. From the Flutter project root:

```bash
flutter build web --release --base-href /app/ --dart-define=API_BASE_URL=origin
rm -rf backend/public/app && cp -R build/web backend/public/app
flutter build apk --release --dart-define=API_BASE_URL=https://api.your-domain.com
cp build/app/outputs/flutter-apk/app-release.apk backend/public/downloads/garikhata.apk
```

`API_BASE_URL=origin` makes the web app call the server it is served from.

The first admin is `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `.env`. If those aren't set, the email is `admin@garikhata.app` and a random password is printed once. You can add more admins under **System → Admins**.

The app uses these local URLs by default:

| Where the app runs | API URL |
|---|---|
| Android emulator | `http://10.0.2.2:8001` |
| Web, iOS simulator, macOS | `http://localhost:8001` |
| Real phone or production | `flutter build … --dart-define=API_BASE_URL=https://api.your-domain.com` |

## Access rules (packages)

| User's situation | What the app unlocks |
|---|---|
| No running package | **Everything** (the default) |
| Running package | Only the package's ticked features, plus its vehicle and driver limits |
| Package expired or cancelled | Back to everything |

Admins can change what users **without** a package get, under **App settings → Users without a package get**. The default is full access.

Packages are never shown in the app. A locked feature just says it isn't enabled and shows the support phone or WhatsApp from App settings.

Feature keys live in `config/features.php`. They must match `lib/services/access.dart` in the app. To add a feature:

1. Add it to both files.
2. Gate it in the app with `requireFeature(context, Feature.yourKey)`.
3. Run `php artisan db:seed --class=FeatureSeeder`.

## Analytics

The app reports screen keys (`home`, `reports`, `trip_form`…) in batches to `POST /api/v1/events`. Readable names are in `config/screens.php`.

* **Dashboard**: total, new, online and active users; registrations vs active users; platforms; top screens; package mix.
* **Analytics → Screen analytics**: views, unique users and views per user for each screen. You can filter by period and platform, and **Who opened it** lists the users for a screen.
* **Analytics → Activity log**: every single screen view, with filters for user, screen and date.
* **Each user's page**: profile, current access, most used screens, packages, full screen activity and devices.

## API

All requests send `Accept: application/json`. The app also sends `Accept-Language: bn|en`, so validation messages come back in Bangla, plus `X-Platform`, `X-App-Version` and `X-Device-Id`. Authenticated routes need `Authorization: Bearer <token>`.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/config` | – | Version gate, maintenance, registration open, support contacts |
| POST | `/auth/register` | – | `name, username, email, phone, password, password_confirmation` (+ optional `business_name, district, fleet_size, device{}`). Returns `{token, user, access}` |
| POST | `/auth/login` | – | `login` (email, phone or username) and `password`. Returns `{token, user, access}` |
| POST | `/auth/forgot-password` | – | `email`. Emails a 6-digit code that is valid for 15 minutes |
| POST | `/auth/reset-password` | – | `email, code, password, password_confirmation` |
| POST | `/auth/logout` | ✓ | Revokes the current token |
| GET | `/me` | ✓ | `{user, access}`. The app calls this on start |
| PUT | `/me` | ✓ | Update any profile field |
| PUT | `/me/password` | ✓ | `current_password, password, password_confirmation`. Signs out the user's other devices |
| DELETE | `/me` | ✓ | `password`. Permanent account deletion (required by the Play Store) |
| POST | `/events` | ✓ | `{events: [{screen, viewed_at, session_id}]}` (up to 100 per call) |

`access` looks like this:

```json
{"mode": "full|package|fallback",
 "features": {"daily_collection": true, "reports": false, "…": true},
 "limits": {"max_vehicles": 2, "max_drivers": null},
 "expires_at": "2026-11-06T23:48:54+06:00"}
```

Errors the app handles: `422` field errors, `401` (signed out), `403 {code: account_suspended | registration_closed}` and `503 {code: maintenance}`.

Phones are normalised to `01XXXXXXXXX`; `+880…`, `880…` and Bangla digits are accepted. Usernames and emails are stored in lowercase.

## Tests

```bash
php artisan test      # 25 tests: auth, access rules, events, every admin page, package assignment, settings, website and login
```

## Production checklist

* Serve over **HTTPS**, and set `APP_ENV=production`, `APP_DEBUG=false` and `APP_URL`.
* Set `MAIL_*` to a real SMTP provider. Password reset codes are emailed (`MAIL_MAILER=log` only writes them to `storage/logs`).
* Set `ADMIN_EMAIL` and `ADMIN_PASSWORD`, then run `php artisan migrate --force && php artisan db:seed --force`.
* Run `php artisan optimize && php artisan filament:optimize` on each deploy.
* Never run `DemoSeeder` in production.
* Build the app with `--dart-define=API_BASE_URL=https://…`. Android release builds only allow plain HTTP for local dev hosts (`android/app/src/main/res/xml/network_security_config.xml`).
