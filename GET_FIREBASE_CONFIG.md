# Quick Firebase Configuration Guide

## You're almost there! Just need to configure Firebase.

The app is trying to run but needs your Firebase project configuration.

### Quick Steps:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Sign in with your Google account (oldpistol@gmail.com)

2. **Create or Select a Project**
   - Click "Add project" or select existing
   - Name: "moodmate" (or any name you prefer)

3. **Add Web App**
   - Click the Web icon `</>`
   - App nickname: "moodmate-web"
   - Check "Also set up Firebase Hosting" (optional)
   - Click "Register app"

4. **Copy Your Configuration**
   You'll see something like:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSyC...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:abc123"
   };
   ```

5. **Update firebase_options.dart**
   - Open `lib/firebase_options.dart`
   - Replace the `web` configuration values with your actual values:
   
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'YOUR_API_KEY_HERE',           // From apiKey
     appId: 'YOUR_APP_ID_HERE',             // From appId
     messagingSenderId: 'YOUR_SENDER_ID',   // From messagingSenderId
     projectId: 'YOUR_PROJECT_ID',          // From projectId
     authDomain: 'YOUR_AUTH_DOMAIN',        // From authDomain
     storageBucket: 'YOUR_STORAGE_BUCKET',  // From storageBucket
   );
   ```

6. **Enable Authentication**
   - In Firebase Console → Authentication
   - Click "Get started"
   - Click "Email/Password"
   - Enable the first toggle
   - Click "Save"

7. **Create Firestore Database**
   - In Firebase Console → Firestore Database
   - Click "Create database"
   - Select "Start in test mode"
   - Choose closest region
   - Click "Enable"

8. **Run the App Again**
   ```bash
   flutter run -d chrome
   ```

---

## Example (with fake values):

If your config looks like this:
```javascript
apiKey: "AIzaSyC1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p"
authDomain: "moodmate-12345.firebaseapp.com"
projectId: "moodmate-12345"
storageBucket: "moodmate-12345.appspot.com"
messagingSenderId: "987654321"
appId: "1:987654321:web:abc123def456ghi789"
```

Update your `lib/firebase_options.dart` like this:
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyC1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p',
  appId: '1:987654321:web:abc123def456ghi789',
  messagingSenderId: '987654321',
  projectId: 'moodmate-12345',
  authDomain: 'moodmate-12345.firebaseapp.com',
  storageBucket: 'moodmate-12345.appspot.com',
);
```

---

## Need Help?

Once you have the Firebase config values, just paste them here and I can update the firebase_options.dart file for you!
