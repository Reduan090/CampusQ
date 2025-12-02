# Quick Firebase Setup Guide

## ✅ Setup Complete! You now have:

### Files Created:
1. **`setup_firebase.html`** - Browser-based setup tool (RECOMMENDED)
2. **`firestore.rules`** - Security rules for your database
3. **`lib/setup_firebase_data.dart`** - Dart setup script (alternative)

---

## 🚀 Run the Setup (2 Easy Steps)

### Step 1: Open Setup Page
The setup page should have opened in your browser automatically.

If not, manually open: **`d:\HCI_Project\setup_firebase.html`**

### Step 2: Click "Start Firebase Setup"
The setup will automatically:
- ✅ Create admin account
- ✅ Create 5 student accounts
- ✅ Create sample notices
- ✅ Create sample tokens
- ✅ Set up complete database structure

---

## 📝 Login Credentials (After Setup)

### 👤 Admin Account:
- **Email:** admin@campusq.com
- **Password:** admin123

### 👥 Student Accounts:

1. **John Doe** (Computer Science)
   - Email: john.doe@student.campusq.com
   - Password: student123
   - ID: CSE2021001

2. **Jane Smith** (Electrical Engineering)
   - Email: jane.smith@student.campusq.com
   - Password: student123
   - ID: EEE2021002

3. **Mike Johnson** (Mechanical Engineering)
   - Email: mike.johnson@student.campusq.com
   - Password: student123
   - ID: ME2021003

4. **Sarah Williams** (Business Administration)
   - Email: sarah.williams@student.campusq.com
   - Password: student123
   - ID: BBA2021004

5. **David Brown** (Computer Science)
   - Email: david.brown@student.campusq.com
   - Password: student123
   - ID: CSE2021005

---

## 📊 Database Structure Created

### Collections:

**`users`** - User profiles
- 1 Admin user
- 5 Student users
- Fields: uid, email, role, isActive, name, studentId, department, bloodGroup, pictureUrl, createdAt

**`notices`** - Admin announcements
- 4 Sample notices
- Fields: id, title, content, isActive, createdBy, createdAt

**`tokens`** - Token requests
- Sample tokens in different states (pending, approved, waiting, completed)
- Fields: id, userId, type, status, tokenNumber, queuePosition, totalInQueue, requestedAt, message, completedAt

---

## ✅ Verify Setup

### 1. Check Firebase Console:
Visit: https://console.firebase.google.com/project/campusq-d754c/firestore

You should see:
- ✅ `users` collection with 6 documents
- ✅ `notices` collection with 4 documents
- ✅ `tokens` collection with sample tokens

### 2. Test the App:
```bash
flutter run -d edge
```

Then try:
- Sign in as admin (admin@campusq.com / admin123)
- Sign in as student (john.doe@student.campusq.com / student123)
- Request tokens, approve/reject them
- View notices

---

## 🔧 Troubleshooting

### If setup fails:

**Error: "Permission denied"**
- Solution: Make sure Firestore security rules are set to test mode temporarily:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if request.time < timestamp.date(2025, 12, 31);
      }
    }
  }
  ```
- After setup completes, apply the production rules from `firestore.rules`

**Error: "Email already in use"**
- This is normal! It means the accounts already exist
- The script will skip creating them and continue

**Error: "Authentication not enabled"**
- Go to Firebase Console → Authentication → Sign-in method
- Enable "Email/Password" provider

**Error: "Firestore not created"**
- Go to Firebase Console → Firestore Database
- Click "Create database"
- Choose test mode or production mode

---

## 🎯 Next Steps

After successful setup:

1. **Run the Flutter app:**
   ```bash
   flutter run -d edge
   ```

2. **Test admin features:**
   - Login as admin
   - Approve/reject pending tokens
   - Create/manage users
   - Post notices

3. **Test student features:**
   - Login as student
   - Request tokens
   - View profile
   - Read notices

4. **Apply production security rules:**
   - Copy rules from `firestore.rules`
   - Paste in Firebase Console → Firestore → Rules
   - Publish

---

## 📱 Production Deployment

When ready for production:

1. **Update security rules** (from `firestore.rules`)
2. **Change default passwords** for all accounts
3. **Build Flutter app:**
   ```bash
   flutter build web
   ```
4. **Deploy to Firebase Hosting:**
   ```bash
   firebase deploy
   ```

---

## 🆘 Support

- **Firebase Console:** https://console.firebase.google.com/project/campusq-d754c
- **Check setup logs:** Look at the browser console in setup page
- **Re-run setup:** Just click the button again (it handles existing data)

---

**🎉 You're all set! Enjoy using CampusQ!**
