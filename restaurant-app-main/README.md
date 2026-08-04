<div align="center">

# 🍽️ Restaurant Automation

### One restaurant. Five workspaces. One beautifully connected experience.

A cross-platform Flutter application that brings customers, administrators,
waiters, kitchen teams, and cashiers together in a single restaurant ecosystem.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?style=for-the-badge&logo=dart)
![Riverpod](https://img.shields.io/badge/State-Riverpod-6E56CF?style=for-the-badge)
![License](https://img.shields.io/badge/License-Private-E4572E?style=for-the-badge)

</div>

---

## ✨ The idea

Restaurant Automation is the digital heartbeat of a modern restaurant. Guests
can discover dishes and place orders, while every team—from the dining floor to
the kitchen and checkout counter—gets a focused workspace built for its role.

> From “What should I eat?” to “Order served!”—the whole journey lives here.

## 🎭 Experiences for every role

| Role | Workspace highlights |
| --- | --- |
| 👤 **Customer** | Browse menus and categories, manage a cart, checkout, scan, reorder, use coupons, manage addresses and profile |
| 🧑‍💼 **Admin / Manager** | Dashboard, orders, menu, inventory, tables, staff, reservations, offers, reports and settings |
| 🤵 **Waiter** | A dedicated waiter dashboard for front-of-house operations |
| 👨‍🍳 **Kitchen / Chef** | A focused kitchen dashboard for food preparation workflows |
| 💳 **Cashier** | A dedicated POS dashboard for counter and payment operations |

Role-aware routing sends authenticated users directly to the right workspace.

## 🧩 Built with

- **Flutter & Dart** for a shared Android, iOS, web and desktop codebase
- **Riverpod** for predictable application state
- **GoRouter** for role-aware navigation
- **Dio** for authenticated REST API communication
- **Hive** for fast local session storage
- **Google Sign-In** for convenient authentication
- **Socket.IO Client** for real-time-ready communication
- **Google Fonts** for a polished visual system

## 🗺️ Project map

```text
lib/
├── core/
│   ├── network/       # API client and restaurant endpoints
│   ├── router/        # Routes and role-based redirects
│   ├── storage/       # Local Hive persistence
│   └── theme/         # Light and dark visual themes
└── features/
    ├── auth/          # Login, sign-up and session handling
    ├── customer/      # Discovery, cart, checkout and profile
    ├── admin/         # Restaurant operations and management
    ├── waiter/        # Waiter workspace
    ├── kitchen/       # Kitchen workspace
    ├── pos/           # Cashier / POS workspace
    └── legal/         # Terms, privacy and content policies
```

## 🚀 Run it locally

### Prerequisites

- Flutter SDK compatible with Dart `^3.12.2`
- A device, emulator, or supported browser
- The companion backend running on port `5000`

### Start the app

```bash
git clone <your-repository-url>
cd restaurant2/flutter_app
flutter pub get
flutter run
```

The REST client currently connects to:

```text
http://localhost:5000/api/v1
```

When running on a physical device or Android emulator, update the API host in
`lib/core/network/api_client.dart` so it points to an address the device can
reach. Android emulators commonly use `10.0.2.2` to access the host machine.

## 🔐 Google Sign-In

Create the required OAuth clients in Google Cloud Console for the Android
package `com.restaurant.restaurant_automation`, including the correct signing
SHA-1 and SHA-256 fingerprints. The backend and Flutter app must use the same
Web OAuth client ID.

Run on mobile:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

Run on web:

```bash
flutter run -d chrome \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

See [GOOGLE_SIGN_IN_SETUP.md](GOOGLE_SIGN_IN_SETUP.md) for the concise setup
checklist.

## 🧪 Quality checks

```bash
flutter analyze
flutter test
```

To create a production build, choose the target you need:

```bash
flutter build apk      # Android
flutter build web      # Web
flutter build windows  # Windows
```

## 🌱 Product direction

The feature-based structure is ready to grow into richer live order tracking,
kitchen ticket updates, payment integrations, analytics, notifications, and
multi-restaurant operations without turning the codebase into a crowded menu.

---

<div align="center">

**Designed to keep service moving and every table smiling.** 🥂

</div>
