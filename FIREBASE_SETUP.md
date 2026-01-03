# Firebase Setup Instructions

## Task 1.1: User Registration - Implementation Complete ✅

### Completed Features

1. **Firebase Dependencies** ✅

   - Added firebase_core (^3.8.1)
   - Added firebase_auth (^5.3.4)
   - Added cloud_firestore (^5.5.2)
   - Added provider (^6.1.2) for state management
   - Added email_validator (^3.0.0)

2. **User Model** ✅

   - Created `UserModel` class with id, name, email, role, timestamps
   - Implemented UserRole enum (user, counsellor, admin)
   - Added Firestore serialization/deserialization methods
   - Firestore collection: `users`

3. **Authentication Service** ✅

   - Created `AuthService` with complete authentication methods:
     - registerWithEmailAndPassword()
     - signInWithEmailAndPassword()
     - signOut()
     - getUserProfile()
     - updateUserProfile()
     - Email verification methods
   - Comprehensive error handling for Firebase Auth exceptions
   - Automatic user profile creation in Firestore on registration

4. **Form Validation** ✅

   - Email validation with regex pattern
   - Password strength validation (min 8 chars, uppercase, lowercase, number, special char)
   - Name validation (min 2 chars, letters/spaces/hyphens only)
   - Confirm password matching validation

5. **Registration UI** ✅

   - Full registration form with:
     - Name input
     - Email input
     - Password input with visibility toggle
     - Confirm password input with visibility toggle
     - Role selection dropdown (User/Counsellor)
   - Loading states and error handling
   - Success/error messages via SnackBar
   - Navigation to login screen after registration
   - Material Design 3 styling

6. **App Configuration** ✅
   - Updated main.dart with Firebase initialization
   - Configured Provider for dependency injection
   - Set up navigation routes (/register, /login, /home)
   - Custom Material Design 3 theme with:
     - Deep purple color scheme
     - Rounded input fields
     - Elevated button styling

### Next Steps - Firebase Console Setup

**IMPORTANT:** To run the app, you need to configure Firebase:

1. **Create Firebase Project**

   - Go to https://console.firebase.google.com/
   - Click "Add project"
   - Name: "moodmate" (or your preferred name)
   - Disable Google Analytics (optional for now)
   - Click "Create project"

2. **Add Android App**

   - Click Android icon
   - Package name: `com.example.moodmate` (from android/app/src/main/AndroidManifest.xml)
   - Download `google-services.json`
   - Place in: `android/app/google-services.json`

3. **Add iOS App**

   - Click iOS icon
   - Bundle ID: `com.example.moodmate` (from ios/Runner/Info.plist)
   - Download `GoogleService-Info.plist`
   - Place in: `ios/Runner/GoogleService-Info.plist`

4. **Add Web App**

   - Click Web icon
   - App nickname: "moodmate-web"
   - Copy the Firebase configuration
   - Create `lib/firebase_options.dart` using FlutterFire CLI (recommended)

5. **Run FlutterFire CLI (Recommended)**

   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Configure Firebase for all platforms
   flutterfire configure
   ```

   This will automatically:

   - Create firebase_options.dart
   - Configure all platforms
   - Set up Firebase initialization

6. **Enable Authentication**

   - In Firebase Console, go to Authentication
   - Click "Get started"
   - Enable "Email/Password" provider
   - Click "Save"

7. **Set Up Firestore Database**

   - In Firebase Console, go to Firestore Database
   - Click "Create database"
   - Choose "Start in test mode" (change to production rules later)
   - Select your region
   - Click "Enable"

8. **Firestore Security Rules** (Update after testing)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users collection
       match /users/{userId} {
         // Allow users to read/write their own profile
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### Testing the Registration Feature

Once Firebase is configured:

1. Run the app: `flutter run`
2. Fill in the registration form:
   - Enter your full name
   - Enter a valid email
   - Create a strong password (8+ chars, uppercase, lowercase, number, special char)
   - Confirm password
   - Select role (User or Counsellor)
3. Click "Create Account"
4. Check your email for verification link
5. User profile will be created in Firestore `users` collection

### File Structure

```
lib/
├── main.dart                          # App entry point with Firebase init
├── models/
│   └── user_model.dart               # User data model with Firestore schema
├── services/
│   └── auth_service.dart             # Authentication service
├── utils/
│   └── validators.dart               # Form validation utilities
└── screens/
    ├── auth/
    │   ├── register_screen.dart      # Registration UI
    │   └── login_screen.dart         # Login UI (placeholder)
    └── home/
        └── home_screen.dart          # Home screen (placeholder)
```

### Next Tasks

- **Task 1.2:** Implement User Login screen
- **Task 1.3:** Add role-based permissions and routing
- **Task 2.1:** Implement daily mood entry feature

### Notes

- Email verification is sent automatically on registration
- Passwords are hashed by Firebase Authentication
- User profiles are stored in Firestore for additional metadata
- The app uses Provider for state management (can switch to Riverpod/Bloc if needed)
- All Firebase errors are caught and displayed to users
