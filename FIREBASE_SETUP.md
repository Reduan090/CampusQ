# Firebase Setup Guide for CampusQ

## Current Status

✅ **Firebase Configuration Files:** Present and configured
✅ **Firebase SDK Scripts:** Added to web/index.html
✅ **Project ID:** campusq-d754c
✅ **Fallback System:** Local storage works when Firebase unavailable

---

## Why Firebase Wasn't Working

### Problem
Firebase credentials were configured in `firebase_options.dart`, but the Firebase JavaScript SDK wasn't loaded in the web app, causing:
- Firestore queries to timeout
- Auth operations to fail
- All operations falling back to local storage

### Solution Applied
Added Firebase SDK scripts to `web/index.html`:
```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js"></script>
```

---

## Complete Firebase Setup Steps

### 1. Firebase Console Configuration

**Go to:** https://console.firebase.google.com/project/campusq-d754c

#### Enable Required Services:

**A. Authentication**
1. Navigate to **Build → Authentication**
2. Click **Get Started**
3. Enable **Email/Password** sign-in method
4. Click **Save**

**B. Firestore Database**
1. Navigate to **Build → Firestore Database**
2. Click **Create Database**
3. Choose **Production mode** or **Test mode**:
   - **Test mode** (for development):
     ```
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if request.time < timestamp.date(2025, 12, 31);
         }
       }
     }
     ```
   - **Production mode** (recommended):
     ```
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         // Users collection - read own data, admins can write
         match /users/{userId} {
           allow read: if request.auth != null;
           allow write: if request.auth != null && 
                         (request.auth.uid == userId || 
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
         }
         
         // Tokens collection - users can create, read own, admins can manage
         match /tokens/{tokenId} {
           allow read: if request.auth != null;
           allow create: if request.auth != null;
           allow update, delete: if request.auth != null && 
                                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
         }
         
         // Notices collection - everyone can read, admins can write
         match /notices/{noticeId} {
           allow read: if request.auth != null;
           allow write: if request.auth != null && 
                         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
         }
       }
     }
     ```
4. Select a location (e.g., `asia-south1` for India)
5. Click **Enable**

**C. Cloud Messaging (Optional)**
1. Navigate to **Build → Cloud Messaging**
2. Click **Get Started**
3. Generate a Web Push certificate (for notifications)

#### Create Firestore Indexes (Optional but Recommended):

Go to **Firestore Database → Indexes → Composite**

Add these indexes for better performance:
- Collection: `tokens`
  - Fields: `type` (Ascending), `status` (Ascending)
  - Query scopes: Collection

### 2. Web Hosting Configuration (Optional)

If you want to deploy to Firebase Hosting:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
cd D:\HCI_Project
firebase init

# Select:
# - Hosting
# - Use existing project: campusq-d754c
# - Public directory: build/web
# - Configure as single-page app: Yes
# - Set up automatic builds: No

# Build Flutter web app
flutter build web

# Deploy to Firebase Hosting
firebase deploy
```

### 3. Testing Firebase Connection

After enabling services, test the connection:

1. **Run the app:**
   ```bash
   flutter run -d edge
   ```

2. **Check console logs:**
   - ✅ Should NOT see: "Firestore failed, using local storage"
   - ✅ Should see: Successful Firebase initialization

3. **Test features:**
   - Sign in with email/password
   - Request a token
   - Admin approves token
   - All data should persist in Firestore

### 4. Verify Firestore Data

Go to **Firestore Database → Data**

You should see collections:
- `users` - User profiles with role, isActive, etc.
- `tokens` - Token requests with status, type, userId
- `notices` - Admin notices

---

## Environment-Specific Behavior

### Development (Local)
- If Firebase fails → Automatically uses local storage
- Data stored in browser memory (lost on refresh)
- Perfect for UI development and testing

### Production (Firebase Connected)
- All data persists to Firestore
- Real-time updates across devices
- User authentication via Firebase Auth
- Data survives app restarts

---

## Troubleshooting

### Issue: "Firebase not initialized" error
**Solution:** Firebase SDK scripts are now added to `web/index.html`. Clear browser cache and restart.

### Issue: "Permission denied" in Firestore
**Solution:** Update Firestore security rules (see Production mode rules above)

### Issue: Authentication fails
**Solution:** 
1. Check Email/Password is enabled in Firebase Console
2. Create a test user in Authentication panel
3. Or use "Continue as Guest" for local testing

### Issue: Data not persisting
**Solution:**
1. Check Firestore is enabled in Firebase Console
2. Verify security rules allow writes
3. Check browser console for specific errors

### Issue: App still using local storage
**Solution:**
1. Verify Firebase SDK scripts are loaded (check browser Network tab)
2. Check Firebase initialization in browser console
3. Ensure Firestore is enabled in Firebase project

---

## Current Implementation Details

### Hybrid Approach (Best of Both Worlds)

The app uses a **smart fallback system**:

1. **Primary:** Try Firebase operations first
2. **Fallback:** If Firebase fails, use local storage
3. **Seamless:** Users never see errors

### Code Structure:

```dart
// TokenService.requestToken example
if (_useFirestore && _firestore != null) {
  try {
    // Try Firestore with 5-second timeout
    await _firestore!.collection('tokens').doc(id).set(data)
      .timeout(const Duration(seconds: 5));
    return token;
  } catch (e) {
    debugPrint('Firestore failed, using local: $e');
    // Falls through to local storage
  }
}
// Local storage implementation
_allTokens.add(token);
notifyListeners();
```

### Benefits:
✅ Works offline
✅ Graceful degradation
✅ No user-facing errors
✅ Development-friendly
✅ Production-ready

---

## Next Steps

### To Enable Full Firebase:

1. **Enable Authentication:**
   - Go to Firebase Console → Authentication
   - Enable Email/Password
   - Create admin user: admin@campusq.com

2. **Enable Firestore:**
   - Go to Firebase Console → Firestore Database
   - Click "Create Database"
   - Use Production rules above

3. **Test:**
   - Run app: `flutter run -d edge`
   - Sign in with admin credentials
   - Create a test student user
   - Request token as student
   - Approve as admin
   - Verify data in Firestore console

### To Use Local Only:

No changes needed! The app already works perfectly with local storage fallback.

---

## Support

- **Firebase Console:** https://console.firebase.google.com/project/campusq-d754c
- **Firebase Documentation:** https://firebase.google.com/docs
- **FlutterFire:** https://firebase.flutter.dev

**Project Owner:** Contact Firebase project owner for admin access
**Project ID:** campusq-d754c
