# drive_sync_app

A new Flutter project.

# Drive Sync Flutter App

This application scans the local Android file system for files, stores their paths in a local Sembast database, and uploads them to Google Drive using a multi-threaded, background-aware process.

## 🛠️ Setup Instructions

### 1. Google Cloud Console & Firebase

This app requires Google Drive API credentials to function.

1.  **Create a Google Cloud Project:** Go to the [Google Cloud Console](https://console.cloud.google.com/) and create a new project.
2.  **Enable Google Drive API:** In your project dashboard, go to "APIs & Services" > "Library" and search for "Google Drive API". Enable it.
3.  **Configure OAuth Consent Screen:** Go to "APIs & Services" > "OAuth consent screen".
    * Choose **External** user type.
    * Fill in the required app name, user support email, and developer contact information.
    * **Add Scopes:** Click "Add or Remove Scopes" and add the `.../auth/drive.file` scope. This allows the app to create files in the user's Google Drive.
4.  **Create OAuth 2.0 Client ID:**
    * Go to "APIs & Services" > "Credentials".
    * Click "Create Credentials" > "OAuth client ID".
    * Select **Android** as the application type.
    * Provide a name and the **Package Name** of your app (e.g., `com.drive.drive_sync_app`).
    * **Generate SHA-1 Fingerprint:** You need to provide the SHA-1 fingerprint of your debug keystore. Open a terminal and run:
        ```bash
        # For macOS/Linux
        keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

        # For Windows
        keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
        ```
    * Copy the SHA-1 value and paste it into the Google Cloud Console form.
    * Click "Create".

### 2. Flutter Project Setup

1.  **Clone the repository.**
2.  **Add Dependencies:** Make sure your `pubspec.yaml` matches the one provided and run `flutter pub get`.
3.  **Android Permissions:** The `AndroidManifest.xml` file has been configured, but ensure you understand the permissions, especially `MANAGE_EXTERNAL_STORAGE` for modern Android versions.

### 3. Running the App

1.  **Request Permissions:** When you first run the app, it will ask for storage permissions. For Android 11+, you may need to manually enable "All files access" in your phone's settings for the app.
2.  **Run the app:**
    ```bash
    flutter run
    ```
3.  **Workflow:**
    * Click "Sign in with Google" and authenticate.
    * Click "Start File Scan". This will scan your device's storage (this can take time).
    * The app will automatically start uploading files in the background, 4 at a time.
    * Even if you close the app, the `workmanager` will trigger an upload cycle approximately every 15 minutes.

