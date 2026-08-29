# CMIT Field Data App

A cross-platform mobile application built with Flutter that lets field teams manage and report field inquiries from anywhere. It handles the full inquiry lifecycle — from assignment and site visits to findings, required documents, annexes, and finalization — with offline-first support and real-time push notifications.

## Project Status

| Item | Status |
|------|--------|
| Project Status | **Completed** |
| Last Completed Task | **Push Notifications** |
| Current Pending Task | None — all tasks completed |

## Last Completed Task: Push Notifications

- Integrated **Firebase Cloud Messaging (FCM)** for remote push notifications on both Android and iOS.
- Local notifications rendered via `flutter_local_notifications` while the app is in the foreground.
- FCM token generation, auto-refresh, and secure storage with local persistence.
- FCM token registration and cleanup against the backend (`/fcm-token` endpoint).
- Handles notification taps in all app states — terminated, background, and foreground.
- Notifications stored locally with read/unread state and displayed in the in-app notification screen.

## Technology Stack

- **Framework:** Flutter (Dart)
- **Platforms:** Android, iOS, Windows
- **Backend Integration:** RESTful API (via `dio` and `http`) — `https://cmit.sata.pk/api/v1`
- **Push Notifications:** Firebase Cloud Messaging + `flutter_local_notifications`
- **Authentication:** Custom JWT login, Google Sign-In, Apple Sign-In, Facebook Login, OTP/phone verification, biometric unlock (`local_auth`)
- **State & Storage:** `shared_preferences`, `flutter_secure_storage`, `localstorage`
- **Offline Support:** Local caching with background sync
- **Other Libraries:** `qr_flutter` / `barcode_widget` (QR & barcode generation), `printing` + `flutter_pdfview` (PDF), `file_picker` / `image_picker`, `flutter_quill` / `flutter_html` (rich text & HTML rendering), `intl_phone_field`, `flutter_otp_text_field`, `lottie`, `connectivity_plus`, `google_fonts`

## Features

- **Splash & Onboarding** — branded splash screen with a 2s timer and an onboarding walkthrough.
- **Authentication** — login, sign-up, social sign-in (Google / Apple / Facebook), OTP verification, password reset, and biometric authentication.
- **Inquiry Management** — assign-to-me list, inquiry details, site visits, findings, finalized findings, and complete-inquiry workflow.
- **Document Handling** — required documents, file uploads, annexes, and attachment uploads.
- **Recommendation & Finding Updates** — add recommendations and update findings with rich text.
- **Offline Mode** — browse cached inquiries offline and sync when connectivity returns.
- **Profile & Settings** — profile data, security settings, and app configuration.
- **Statistics** — inquiry statistics dashboard on the home screen.
- **Push Notifications** — real-time alerts with local storage, read/unread tracking, and deep navigation on tap.
- **Sharing & Printing** — share data and print via `share_plus` and `printing`.

## Project Structure

```
lib/
├── main.dart                  # App entry point — Firebase + notification init
├── app.dart                   # Root MaterialApp with routing
├── config/                    # API endpoints, routes, theme
├── core/                      # Services, API client, storage, widgets
├── models/                    # Shared models (e.g., NotificationModel)
├── screens/                   # Misc screens (e.g., NotificationScreen)
├── services/                  # Notification service + storage
└── features/                  # Feature modules (feature-first)
    ├── auth/                  # Login, onboarding
    ├── home/                  # Home, notifications, drawer
    ├── inquiries/             # Full inquiry workflow + details
    ├── offline/               # Offline cache, details, sync
    ├── profile/               # Profile management
    ├── shared/                # Reusable helpers & widgets
    ├── splash/                # Splash (MVP presenter pattern)
    └── statistics/            # Settings / statistics screen
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.3`
- A Firebase project with an Android (`google-services.json`) and iOS (`GoogleService-Info.plist`) config file
- A running backend API at the base URL defined in `lib/config/api.dart`

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Add your Firebase config files
#   - android/app/google-services.json
#   - ios/Runner/GoogleService-Info.plist

# 3. Update the API base URL if needed
#   lib/config/api.dart

# 4. Run the app
flutter run
```

### Build

```bash
flutter build apk            # Android APK
flutter build ios            # iOS (macOS only)
flutter run -d windows       # Windows desktop
```

## Firebase Configuration

1. Create a Firebase project and register your Android & iOS apps (package id `com.cmit.app`).
2. Enable **Firebase Cloud Messaging** for both platforms.
3. Place the generated config files in the correct locations (see Setup).
4. Verify APNs is configured for iOS push delivery.

## License

All rights reserved.
