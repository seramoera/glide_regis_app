# Glide

**Find your crew, faster.**

Glide is a Flutter app for discovering and registering for student organizations at Holy Angel University. Students sign up, complete a one-time registration profile, then browse, search, and join orgs — and members get a feed of announcements and events from the orgs they belong to.

<img src="lib/assets/images/glide_logo.png" alt="Glide logo" width="180" />

---

## About

Organization fairs are crowded, sign-up sheets get lost, and announcements scatter across group chats. Glide puts the whole process in one place:

- Browse every org in a single grid, filtered by category (`SOC`, `Uniwide`)
- Register or unregister from an org in one tap
- See membership fees and open/closed status before committing
- Read announcements and events from orgs you've joined
- Keep a profile with your details and joined orgs in one account

The app is built around a dark, glassmorphic UI (blurred cards over a photo background) with custom typography.

---

## Features

### Accounts & onboarding
- Email/password sign-up and login backed by **Firebase Authentication**
- Animated splash screen with swipe-to-start; `main.dart` restores any existing Firebase session and routes to onboarding or the app shell
- One-time registration form collecting first/last name, date of birth, email, 11-digit contact number, and address (street, barangay, city), with per-field validation
- The `hasRegistered` flag on the user document decides whether onboarding or the main app is shown

### Discovery
- Home screen grid of all organizations with `All` / `SOC` / `Uniwide` filter chips and live text search
- **Registered** badge on orgs the user has already joined
- Dedicated Search tab with recent-search history (last 10, saved per user in Firestore), one-tap removal, and clear-all

### Organization details
- Cover image, description, category, membership fee, and open/closed status
- Register / unregister with a confirmation dialog on unregister
- Registration is disabled when an org's status is `Closed`
- Members-only section showing that org's announcements and events
- "Pay Membership" button that opens an external Google Form (payment link is a placeholder — see [Known limitations](#known-limitations))

### Saved & notifications
- **Saved** tab groups joined orgs by category
- In-app notification center built from the `posts` collection, filtered by audience (`all` vs `org-members`) and by the user's memberships
- Real-time unread indicator (red dot) on the bell across Home, Search, and Account
- Swipe to dismiss a notification, or clear all; dismissals persist on the user document

### Account
- Profile card with registration details and a list of joined organizations
- Profile picture picked from the gallery and stored locally on the device
- Sign out and delete account (removes the Firestore user document, then the auth user)

---

## App flow

```
Splash
  ├─ no session ──▶ Login ⇄ Sign Up
  │                   └─▶ Registration form ──▶
  └─ session ────────▶ hasRegistered? ──▶ User Shell
                                            ├─ Home
                                            ├─ Search
                                            ├─ Saved
                                            └─ Account
```

---

## Tech stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter (Dart SDK `>=3.3.0 <4.0.0`), Material 3 |
| Auth | `firebase_auth` — email/password |
| Database | `cloud_firestore` |
| Core | `firebase_core` |
| Media | `image_picker`, `flutter_svg` |
| Linking | `url_launcher` (membership form) |
| Legacy local storage | `sqflite`, `shared_preferences` (see [Known limitations](#known-limitations)) |

App version: `1.0.0+1`. Android application ID: `com.example.glide_regis_app`, display name **Glide**. Android, iOS, web, macOS, Linux, and Windows targets are scaffolded.

---

## Project structure

```
lib/
├── main.dart                     # Firebase init, auth gate, theme
├── firebase_options.dart         # Generated FlutterFire config
├── models/
│   └── orgs.dart                 # Org model + the 10 seeded organizations
├── screens/
│   ├── splash_screen.dart        # Animated splash / session check
│   ├── registration_screen.dart  # One-time profile form
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   └── user/
│       ├── user_shell.dart       # Bottom-nav shell (4 tabs)
│       ├── user_home.dart        # Discover grid + filters + search
│       ├── search_tab.dart       # Search + recent searches
│       ├── saved_tab.dart        # Joined orgs by category
│       ├── account_tab.dart      # Profile, joined orgs, sign out
│       ├── org_details.dart      # Org page, registration, posts
│       └── notifications_page.dart
├── services/
│   ├── auth_service.dart         # Auth + Firestore user/org operations
│   └── app_database.dart         # Legacy local SQLite/SharedPreferences store
└── assets/
    ├── fonts/                    # Afacad, League Spartan
    ├── icons/                    # Lock, Person, logo marks
    └── images/                   # Background, org banners, Glide logo
```

---

## Getting started

### Prerequisites
- Flutter SDK 3.3 or newer (`flutter --version`)
- A Firebase project — this repo is configured for **`glide-regis-app`**
- Android Studio / Xcode / a browser, depending on where you want to run
- For Android: JDK 17+ (as required by the current Android Gradle Plugin)

### Run it

```bash
flutter pub get
flutter run
```

Choose a device with `flutter devices`, or target one explicitly with `flutter run -d chrome` / `-d windows`.

### Firebase configuration

The FlutterFire config is already checked in:

- `lib/firebase_options.dart` — generated options for Android, iOS, macOS, web, and Windows
- `android/app/google-services.json`
- `firebase.json` — maps the FlutterFire project, app IDs, and output paths

To point the app at **your own** Firebase project instead:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This regenerates `firebase_options.dart` and `firebase.json`, and writes `android/app/google-services.json`. Enable **Email/Password** in Firebase Authentication, then create the Firestore collections described below.

---

## Firestore data model

### `users/{uid}`

| Field | Type | Notes |
| --- | --- | --- |
| `email` | string | Set at sign-up |
| `createdAt` | timestamp | Server timestamp at sign-up |
| `firstName`, `lastName` | string | From the registration form |
| `dob` | string | `day-Mon-year` from the dropdowns |
| `contact` | string | 11 digits |
| `street`, `barangay`, `city` | string | Address |
| `hasRegistered` | bool | Gates onboarding vs. main app |
| `registeredOrgs` | array<map> | `{id, name, imageUrl, category, status, fee}` |
| `dismissedNotifications` | array<string> | Post IDs the user cleared |
| `recentSearches` | array<string> | Most recent first, capped at 10 |
| `updatedAt` | string | ISO-8601, written on registration |

### `posts/{postId}`

| Field | Type | Notes |
| --- | --- | --- |
| `orgId` | number/string | Owning organization |
| `audience` | string | `all` or `org-members` |
| `type` | string | `event` for events, anything else is an announcement |
| `title` | string | Events only |
| `content` | string | `<br>` is rendered as a newline |
| `eventDate` | timestamp/string | Events only |
| `timestamp` | timestamp | Used for ordering and display |

### `orgs/{orgId}` (optional)

Used only as a fallback when an org passed into the details page is missing description, image, fee, status, or category. Fields: `name`, `description`, `imageUrl`, `status`, `fee`, `category`.

The ten organizations that ship with the app are currently hardcoded in `lib/models/orgs.dart` (and duplicated in `lib/screens/user/user_home.dart`):

Access Point · Code Geeks · CSIA · LOOP · MAFIA · GDSC · HAU Debate Congress · Juris Orbis · Apl.de.Ap Music Studio · AWS Learning Club

---

## Design

- Dark Material 3 theme with a black scaffold and blue seed color
- Glassmorphism throughout: `BackdropFilter` blur over a shared background image, translucent white fills, and 1px borders
- Frosted floating bottom navigation bar in the user shell
- Custom fonts: **Afacad** (body/UI) and **League Spartan** (splash tagline)

---

## Known limitations

These are accurate as of the current code, and are good first issues:

- **Payment link is a placeholder.** `lib/screens/user/org_details.dart` opens `https://forms.gle/YOUR_GOOGLE_FORM_LINK`. Fees are informational only; nothing is processed in-app.
- **Notifications are in-app only.** There is no Firebase Cloud Messaging integration; the bell is driven by Firestore `posts` snapshots.
- **Profile pictures are device-local.** They are saved to the app documents directory and never uploaded (`firebase_storage` is declared but unused).
- **Legacy local database still initializes.** `AppDatabase` opens a SQLite database on startup and seeds `admin@school.edu` / `admin123` plus demo clubs. The app no longer authenticates against it — it's dead weight and should be removed along with `sqflite`/`shared_preferences`.
- **Org data is duplicated and hardcoded** between `models/orgs.dart` and `screens/user/user_home.dart`, so the `orgs` collection isn't the source of truth.
- **Unused dependencies:** `smooth_page_indicator`, `firebase_storage`, `permission_handler`, `intl`.
- **Unused/empty widgets:** `lib/widgets/inputs.dart` isn't referenced, and `lib/widgets/org_card.dart` is an empty file.
- **Broken dead route on splash.** `SplashScreen` calls `Navigator.pushReplacementNamed(context, '/login')`, but the app registers no named routes, so that branch would throw. Sign-in normally flows through `main.dart` and the explicit `LoginScreen` navigation instead.
- **Account deletion** deletes the Firestore document and then calls `user.delete()`. Firebase requires a recent login for that call, so users may see an error and need to re-authenticate first.
- **No automated tests.** `test/widget_test.dart` is entirely commented out.
- **Personal data in Firestore.** Names, dates of birth, contact numbers, and addresses are stored in clear text, so Firestore security rules must be locked down before this is used by real students.

> ⚠️ The Firebase client config committed here (`firebase_options.dart`, `google-services.json`) is not a secret, but this is a **public** repository. Make sure your Firestore rules only allow users to read/write their own document, and that `posts`/`orgs` are read-only to clients.

---

## License

No license has been added yet. Until one is, the code is all rights reserved.
