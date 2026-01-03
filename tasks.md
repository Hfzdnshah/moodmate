# MoodMate Development Tasks

This document breaks down the use cases into actionable development tasks, organized by feature area and priority.

## Tech Stack

- **Frontend:** Flutter (iOS, Android, Web)
- **Backend:** Firebase
  - **Authentication:** Firebase Authentication
  - **Database:** Cloud Firestore
  - **Functions:** Firebase Cloud Functions (Node.js/TypeScript)
  - **Messaging:** Firebase Cloud Messaging (FCM)
  - **Storage:** Firebase Storage (if needed)
  - **Analytics:** Firebase Analytics
  - **Crash Reporting:** Firebase Crashlytics
- **AI Integration:** OpenAI API (via Cloud Functions)
- **State Management:** TBD (Provider, Riverpod, or Bloc)

## 1. Authentication & User Management

### Task 1.1: User Registration (UC-01) ✅

**Priority:** High  
**Dependencies:** None

- [x] Design and implement user registration UI (sign-up form)
- [x] Set up Firebase Authentication
- [x] Create user document schema in Firestore (name, email, role, timestamps)
- [x] Implement Firebase Auth registration method
- [x] Add email validation logic
- [x] Add password strength validation
- [x] Handle duplicate email check (Firebase built-in)
- [x] Send email verification using Firebase Auth
- [x] Create user profile document in Firestore after successful registration
- [x] Handle alternate flow: email already exists error

### Task 1.2: User Login (UC-02) ✅

**Priority:** High  
**Dependencies:** Task 1.1

- [x] Design and implement login UI
- [x] Implement Firebase Auth sign-in method
- [x] Handle authentication state changes
- [x] Implement session persistence (Firebase Auth automatic)
- [x] Create dashboard/home screen
- [x] Add "invalid credentials" error handling
- [x] Implement retry mechanism for failed login attempts
- [x] Fetch user role from Firestore after login
- [x] Add role-based access (User vs Counsellor)

### Task 1.3: User Roles & Permissions ✅

**Priority:** High  
**Dependencies:** Task 1.2

- [x] Define user role enum (User, Counsellor, Admin)
- [x] Implement role assignment during registration in Firestore
- [x] Create Firestore Security Rules for role-based access control
- [x] Add permission checks using Firestore Security Rules
- [x] Implement client-side role checks for UI navigation

---

## 2. Mood Tracking & Journaling

### Task 2.1: Daily Mood Entry (UC-03) ✅

**Priority:** High  
**Dependencies:** Task 1.2

- [x] Design mood entry UI with text input
- [x] Create "New Entry" button/navigation
- [x] Define mood entry document structure in Firestore (user_id, date, text, timestamp)
- [x] Create Firestore collection for mood entries
- [x] Add validation for empty input
- [x] Ensure one entry per day constraint (or allow multiple)
- [x] Store entry in Firestore
- [x] Trigger Cloud Function for AI analysis upon submission
- [x] Show submission confirmation to user

### Task 2.2: AI Mood Analysis Integration (UC-04) ✅

**Priority:** High  
**Dependencies:** Task 2.1

- [x] Set up Firebase Cloud Functions
- [x] Set up OpenAI API integration in Cloud Functions
- [x] Configure API keys using Firebase environment config
- [x] Design prompt for emotion detection
- [x] Create Cloud Function triggered by new mood entry
- [x] Call OpenAI API from Cloud Function
- [x] Parse and extract emotion category and confidence score
- [x] Store analysis results in Firestore (emotion, score, timestamp)
- [x] Update mood entry document with analysis results
- [x] Handle API failures gracefully in Cloud Function
- [x] Implement fallback/retry mechanism
- [x] Mark failed analyses as "pending/failed" in Firestore

### Task 2.3: Mood-Based Recommendations (UC-05) ✅

**Priority:** Medium  
**Dependencies:** Task 2.2

- [x] Create mood-to-prompt mapping logic in Cloud Function
- [x] Design prompts for generating tips/quotes per mood
- [x] Call OpenAI API from Cloud Function to generate personalized suggestions
- [x] Store generated suggestions in Firestore
- [x] Display suggestions to user after mood entry
- [x] Implement fallback static tips for each mood category
- [x] Handle cases when AI is unavailable
- [x] Add option to save favorite suggestions to Firestore

---

## 3. Mood History & Visualization

### Task 3.1: View Mood History (UC-06) ✅

**Priority:** Medium  
**Dependencies:** Task 2.1

- [x] Design mood history/trends UI
- [x] Query Firestore to fetch user's mood logs
- [x] Implement date range filtering using Firestore queries (week, month, custom)
- [x] Display mood entries in a list or timeline view
- [x] Implement pagination using Firestore query cursors
- [x] Handle empty state (no data message)
- [x] Add search/filter functionality with Firestore queries

### Task 3.2: Mood Trend Visualization ✅

**Priority:** Medium  
**Dependencies:** Task 3.1, Task 2.2

- [x] Choose charting library (e.g., charts_flutter, fl_chart)
- [x] Design chart types (line chart, bar chart, mood calendar)
- [x] Aggregate mood data by time period
- [x] Generate visualizations for mood trends
- [x] Implement interactive chart features
- [x] Add export/share functionality for reports

---

## 4. Counsellor Features

### Task 4.1: Contact Counsellor (UC-07) ✅

**Priority:** Medium  
**Dependencies:** Task 1.2

- [x] Design counsellor contact/request UI
- [x] Define counsellor document schema in Firestore
- [x] Implement counsellor listing or selection screen using Firestore query
- [x] Define support request document structure in Firestore (user_id, counsellor_id, status, timestamp)
- [x] Create support request document in Firestore
- [x] Implement Firebase Cloud Messaging for counsellor notifications
- [x] Define conversation thread collection in Firestore
- [x] Link support request to conversation thread using document references
- [x] Handle "no counsellor available" scenario
- [x] Add request status tracking in Firestore (pending, accepted, completed)

### Task 4.2: Counsellor Views User Mood Summary (UC-08)

**Priority:** Medium  
**Dependencies:** Task 4.1, Task 3.1

- [ ] Design counsellor dashboard UI
- [ ] Implement user selection/assignment logic in Firestore
- [ ] Query Firestore for assigned user data
- [ ] Enforce user consent and privacy permissions using Firestore Security Rules
- [ ] Display user mood trends and charts
- [ ] Query and show recent mood entries from Firestore
- [ ] Implement access control checks using Firestore Security Rules
- [ ] Handle "access denied" for unauthorized requests
- [ ] Add filtering and date range options with Firestore queries

### Task 4.3: Counsellor Provides Advice (UC-09)

**Priority:** Medium  
**Dependencies:** Task 4.1

- [ ] Design chat/advice UI for counsellors
- [ ] Define message document structure in Firestore (sender_id, receiver_id, content, timestamp)
- [ ] Create messages subcollection in conversation thread
- [ ] Implement real-time messaging using Firestore snapshots
- [ ] Store messages in Firestore conversation thread
- [ ] Send push notifications using Firebase Cloud Messaging when advice is received
- [ ] Handle offline mode with Firebase offline persistence
- [ ] Implement automatic retry with Firestore client
- [ ] Add message read status tracking in Firestore

---

## 5. Privacy & Security

### Task 5.1: Data Protection & Encryption (UC-10)

**Priority:** High  
**Dependencies:** Task 1.1

- [ ] Use Firebase Authentication (passwords automatically hashed)
- [ ] Enable HTTPS/TLS (Firebase default)
- [ ] Enable Firestore data encryption at rest (Firebase default)
- [ ] Use Firebase secure connections for data in transit (automatic)
- [ ] Implement secure token management using Firebase Auth tokens
- [ ] Configure App Check for additional security
- [ ] Set up Firestore Security Rules for data protection

### Task 5.2: Access Control & Authentication (UC-10)

**Priority:** High  
**Dependencies:** Task 1.3

- [ ] Implement role-based access control using Firestore Security Rules
- [ ] Enforce authentication in Firestore Security Rules
- [ ] Add permission checks in Firestore Security Rules before data access
- [ ] Create audit log collection in Firestore (user_id, action, resource, timestamp)
- [ ] Use Cloud Functions to log access attempts
- [ ] Implement rate limiting using Firebase App Check
- [ ] Configure Firebase Security features for abuse prevention

### Task 5.3: User Consent & Privacy Settings

**Priority:** Medium  
**Dependencies:** Task 1.2

- [ ] Create privacy settings UI
- [ ] Store user consent preferences in Firestore
- [ ] Add counsellor access permission toggles in Firestore user document
- [ ] Create privacy policy page
- [ ] Implement data deletion using Cloud Functions (GDPR compliance)
- [ ] Implement data export using Cloud Functions
- [ ] Allow users to revoke counsellor access by updating Firestore permissions

---

## 6. Testing & Quality Assurance

### Task 6.1: Unit Testing

**Priority:** Medium  
**Dependencies:** All feature tasks

- [ ] Write unit tests for authentication logic
- [ ] Write unit tests for mood entry validation
- [ ] Write unit tests for AI integration service
- [ ] Write unit tests for data models
- [ ] Achieve >80% code coverage

### Task 6.2: Integration Testing

**Priority:** Medium  
**Dependencies:** All feature tasks

- [ ] Test end-to-end user registration and login flow
- [ ] Test mood entry to AI analysis pipeline
- [ ] Test counsellor-user interaction flow
- [ ] Test API endpoints with various scenarios

### Task 6.3: UI/UX Testing

**Priority:** Low  
**Dependencies:** All feature tasks

- [ ] Conduct usability testing with target users
- [ ] Test on multiple devices (iOS, Android, Web)
- [ ] Verify accessibility features
- [ ] Test edge cases (slow network, no data, errors)

---

## 7. Deployment & Infrastructure

### Task 7.1: Firebase Backend Setup

**Priority:** High  
**Dependencies:** None

- [ ] Create Firebase project in Firebase Console
- [ ] Set up Cloud Firestore database
- [ ] Configure Firestore Security Rules
- [ ] Set up Firebase Authentication
- [ ] Initialize Firebase Cloud Functions project
- [ ] Configure Firebase environment variables
- [ ] Set up Firebase Storage (if needed for future features)

### Task 7.2: Flutter Frontend Setup

**Priority:** High  
**Dependencies:** None

- [ ] Initialize Flutter project structure
- [ ] Add Firebase Flutter dependencies (firebase_core, firebase_auth, cloud_firestore)
- [ ] Configure Firebase for iOS and Android
- [ ] Set up state management (Provider, Riverpod, Bloc, etc.)
- [ ] Configure routing (go_router or similar)
- [ ] Create Firebase service layer for Firestore and Auth
- [ ] Implement error handling and loading states
- [ ] Set up Firebase offline persistence

### Task 7.3: Deployment

**Priority:** Low  
**Dependencies:** All feature tasks

- [ ] Set up CI/CD pipeline (GitHub Actions, Codemagic, etc.)
- [ ] Deploy Cloud Functions to Firebase
- [ ] Configure Firestore production indexes
- [ ] Configure production environment variables in Firebase
- [ ] Set up Firebase Performance Monitoring
- [ ] Enable Firebase Analytics
- [ ] Deploy mobile apps to stores (App Store, Google Play)
- [ ] Set up Firebase Crashlytics for crash reporting
- [ ] Configure Firebase App Distribution for beta testing

---

## Task Summary by Priority

### High Priority (MVP)

- User Registration (1.1)
- User Login (1.2)
- User Roles & Permissions (1.3)
- Daily Mood Entry (2.1)
- AI Mood Analysis (2.2)
- Data Protection & Encryption (5.1)
- Access Control & Authentication (5.2)
- Backend Setup (7.1)
- Frontend Setup (7.2)

### Medium Priority

- Mood-Based Recommendations (2.3)
- View Mood History (3.1)
- Mood Trend Visualization (3.2)
- Contact Counsellor (4.1)
- Counsellor Views User Mood Summary (4.2)
- Counsellor Provides Advice (4.3)
- User Consent & Privacy Settings (5.3)
- Unit Testing (6.1)
- Integration Testing (6.2)

### Low Priority

- UI/UX Testing (6.3)
- Deployment (7.3)

---

## Notes

- **Dependencies** indicate which tasks should be completed before starting a given task
- **Priority** levels help focus development efforts on core features first
- Some tasks can be worked on in parallel if dependencies allow
- Consider breaking down larger tasks into smaller subtasks during sprint planning
- Regularly review and update this task list as requirements evolve
