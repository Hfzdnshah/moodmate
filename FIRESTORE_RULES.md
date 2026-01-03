# Firestore Security Rules Setup

## Overview

The `firestore.rules` file defines security rules for Cloud Firestore, implementing role-based access control (RBAC) for the MoodMate application.

## Roles

The application supports three user roles:

1. **User** (`user`): Regular users who can track their mood, receive recommendations, and connect with counsellors
2. **Counsellor** (`counsellor`): Mental health professionals who can manage clients and view their mood entries
3. **Admin** (`admin`): System administrators with full access to all features

## Collections & Rules

### 1. Users Collection (`/users/{userId}`)

**Read**: Any authenticated user can read any user profile (needed for counsellor matching)

**Create**: 
- Users can only create their own profile
- Must include: `name`, `email`, `role`, `createdAt`, `updatedAt`
- Role must be one of: `user`, `counsellor`, `admin`

**Update**:
- Users can only update their own profile
- Cannot change their role

**Delete**: Only admins can delete user profiles

### 2. Mood Entries Collection (`/mood_entries/{entryId}`)

**Read**:
- Users can read their own mood entries
- Counsellors can read entries from their assigned clients

**Create**:
- Users can only create mood entries for themselves
- Must include: `userId`, `text`, `timestamp`

**Update**:
- Users can update their own entries
- Only within 24 hours of creation

**Delete**:
- Users can delete their own entries
- Admins can delete any entry

### 3. Counsellor Assignments (`/counsellor_assignments/{userId}`)

**Read**:
- Users can read their own assignment
- Counsellors can read assignments they're part of

**Create**: Only counsellors can create assignments for themselves

**Update**: Only the assigned counsellor or admin

**Delete**: Only admins

### 4. Messages Collection (`/messages/{messageId}`)

**Read**: Users can read messages where they are sender or recipient

**Create**:
- Users can message their assigned counsellor
- Counsellors can message their assigned clients

**Update**: Sender can update message status (for soft delete)

**Delete**: Hard delete not allowed

### 5. Recommendations Collection (`/recommendations/{recommendationId}`)

**Read**: Users can read their own recommendations

**Create/Update/Delete**: Only via Cloud Functions (not directly by users)

### 6. Admin Collection (`/admin/{document=**}`)

**Read/Write**: Only admins have access

## Deploying Rules

### Using Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (mindmate-6b273)
3. Navigate to **Firestore Database** → **Rules**
4. Copy the contents of `firestore.rules`
5. Paste into the rules editor
6. Click **Publish**

### Using Firebase CLI

```bash
# Make sure you're in the project directory
cd /path/to/moodmate

# Deploy rules
firebase deploy --only firestore:rules
```

## Testing Rules

### Test in Firebase Console

1. Go to **Firestore Database** → **Rules**
2. Click the **Rules playground** tab
3. Test different scenarios:
   - Try to read a user document as an authenticated user
   - Try to create a mood entry as a user
   - Try to delete a user as a non-admin

### Test Examples

```javascript
// Example 1: User reading their own profile
// Location: /users/user123
// Auth: user123
// Operation: get
// Expected: Allow

// Example 2: User trying to delete another user
// Location: /users/user456
// Auth: user123
// Operation: delete
// Expected: Deny

// Example 3: Counsellor reading assigned client's mood entry
// Location: /mood_entries/entry123
// Auth: counsellor123 (with assignment to owner of entry)
// Operation: get
// Expected: Allow
```

## Security Best Practices

1. **Always authenticate**: All operations require authentication
2. **Principle of least privilege**: Users only have access to what they need
3. **Validate data**: Rules check required fields and data types
4. **Time-based restrictions**: Mood entries can only be edited within 24 hours
5. **Role immutability**: Users cannot change their own roles
6. **Soft deletes**: Messages use status updates instead of hard deletes

## Helper Functions

The rules include several helper functions:

- `isAuthenticated()`: Check if user is logged in
- `isOwner(userId)`: Check if user owns a resource
- `getUserRole()`: Get the current user's role
- `isAdmin()`: Check if user is an admin
- `isCounsellor()`: Check if user is a counsellor
- `isUser()`: Check if user is a regular user
- `isAssignedCounsellor(userId)`: Check if counsellor is assigned to a user

## Migration from Test Mode

If you currently have Firestore in test mode:

1. **Backup your data** (export from Firestore)
2. Update rules to the production rules in `firestore.rules`
3. Deploy the new rules
4. Test thoroughly with different user roles
5. Monitor for any access denied errors

## Troubleshooting

### Common Issues

**Issue**: "Missing or insufficient permissions" error

**Solution**: Check that:
- User is authenticated
- User has the correct role
- Resource path matches the rules
- All required fields are present

**Issue**: Cloud Functions can't write to collections

**Solution**: Cloud Functions run with admin privileges by default, but make sure your service account has proper permissions.

## Next Steps

1. Deploy these rules to your Firebase project
2. Test with different user roles
3. Monitor Firestore usage in Firebase Console
4. Adjust rules as new features are added

## Related Files

- `lib/utils/permissions.dart`: Client-side permission checks
- `lib/widgets/permission_guard.dart`: UI permission guards
- `lib/models/user_model.dart`: User model with role enum
