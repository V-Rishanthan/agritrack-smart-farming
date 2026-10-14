# AgriTrack (Smart Farming)

AgriTrack is a Flutter app for keeping track of farm operations and records. It includes sign-up and login, a home dashboard, owner records, driver information, tractor expenses, and an analysis screen. Firebase Authentication handles accounts, and Cloud Firestore stores user profiles, owners, and expenses.

## Requirements

- Flutter SDK with Dart **3.11.3 or later**
- Android Studio or Xcode for the mobile platform you plan to run
- A Firebase project with the required mobile apps registered

## Getting started

1. Clone this repository and open its directory:

   ```sh
   git clone <repository-url>
   cd smart_farming
   ```

2. Install the Dart and Flutter dependencies:

   ```sh
   flutter pub get
   ```

3. Create a `.env` file in the project root. It is loaded before Firebase initializes and is excluded from Git. Add the Firebase settings for both mobile platforms:

   ```dotenv
   ANDROID_API_KEY=your-android-api-key
   ANDROID_APP_ID=your-android-app-id
   ANDROID_MESSAGING_SENDER_ID=your-project-number
   ANDROID_PROJECT_ID=your-firebase-project-id
   ANDROID_STORAGE_BUCKET=your-storage-bucket

   IOS_API_KEY=your-ios-api-key
   IOS_APP_ID=your-ios-app-id
   IOS_MESSAGING_SENDER_ID=your-project-number
   IOS_PROJECT_ID=your-firebase-project-id
   IOS_STORAGE_BUCKET=your-storage-bucket
   IOS_BUNDLE_ID=your-ios-bundle-id
   ```

   Get these values from your Firebase project configuration. The variable names must match exactly; the app reads them in `lib/firebase_options.dart`. The `.env` file is declared as a Flutter asset in `pubspec.yaml`, and `main.dart` loads it before `Firebase.initializeApp`.

4. Configure the native Firebase files for your Firebase project. Android uses `android/app/google-services.json`. For iOS, download `GoogleService-Info.plist` from Firebase and add it to the `ios/Runner` target in Xcode. Register apps with the same application IDs used by the native projects. The Dart Firebase options currently include Android and iOS only.

   Enable **Email/Password** sign-in in Firebase Authentication and create a Cloud Firestore database.

5. Run the app on a connected device or emulator:

   ```sh
   flutter run
   ```

   To choose a device, run `flutter devices`, then `flutter run -d <device-id>`.

## Firebase data

The app stores each user's data under their Firebase Authentication UID:

```text
users/{uid}
users/{uid}/owners/{ownerId}
users/{uid}/expenses/{expenseId}
```

Firestore rules should require authentication and restrict access to the signed-in user's own documents. For example, the following rules protect these paths; review them against your complete app needs before deploying:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      match /{collection}/{documentId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }
  }
}
```

The nested rule above permits access to documents one collection level below a user document, including owner and expense records.

## Project structure

```text
lib/
  auth/            Sign-up and login screens
  features/        Dashboard, owners, driver, expenses, analysis, and widgets
  models/          Data models
  routes/          GoRouter configuration and authentication redirects
  services/        Firebase access and shared helpers
  theme/           App colors and theme
  main.dart        Firebase initialization and app entry point
```

## Useful commands

```sh
flutter analyze       # Check Dart code
flutter test          # Run Flutter tests
flutter run           # Launch on a connected device
```

Keep `.env` out of source control. Values bundled into a Flutter app can be extracted from the built app, so Firebase API keys should be treated as client configuration rather than secrets. Protect user data with Firebase Authentication and restrictive Firestore Security Rules.

## Supported platforms

Firebase options are currently configured for **Android and iOS**. Firebase initialization will throw an `UnsupportedError` on web, Windows, macOS, or Linux until options and native configuration for that platform are added.
