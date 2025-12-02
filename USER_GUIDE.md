# CampusQ - Quick Start Guide

## 🚀 Running the Application

### Step 1: Install Dependencies
```powershell
flutter pub get
```

### Step 2: Run the App
```powershell
flutter run
```
Select your target device when prompted (Windows, Chrome, or Edge).

## 👤 User Roles & Access

### Admin Account (First Time)
1. Click **"Continue as Guest"**
2. Toggle role to **Admin** (using the switch)
3. Click **"Continue as Guest"**
4. You're now in the Admin Dashboard

### Creating Student Accounts
1. Login as Admin
2. Navigate to **"Users"** (4th icon in NavigationRail)
3. Click **"Add User"** button
4. Fill in user details:
   - Email (required)
   - Name, Student ID, Department, Blood Group (optional)
   - Role: Student or Admin
5. Click **"Create"**

### Student Login
1. Students can only login if their account was created by admin
2. Enter email and password (same as Firebase Auth)
3. Click **"Sign In"**
4. If account is deactivated, login will be blocked

## 📋 Student Features Guide

### 1. Dashboard (Home)
- View summary cards:
  - Waiting tokens
  - Near turn tokens
  - Active tokens
  - Completed tokens
- Read quick tips

### 2. Request Token
- Click **"Request"** in NavigationRail
- Select a service (Library, Cafeteria, Lab, Exam, Transport)
- Add an optional message for the admin
- Click **"Request Token"**
- Token status: **Pending Approval**

### 3. Active Tokens
- View all your pending and active tokens
- See queue position and estimated wait
- Cancel tokens if needed
- Real-time updates

### 4. History
- View completed, rejected, and expired tokens
- Check completion timestamps

### 5. Notices
- Read campus-wide notices posted by admin
- Pull down to refresh
- Sorted by most recent first

### 6. Stats
- View bar chart of your token requests by service
- Analyze your usage patterns

### 7. Profile
- View your profile information
- Click **Edit** (pencil icon) to update:
  - Name
  - Student ID
  - Department
  - Blood Group
  - Picture URL (for avatar)
- Click **Checkmark** to save changes

## 🔧 Admin Features Guide

### 1. Admin Dashboard
- Overview of system status
- Pending approvals count
- Active tokens count
- Completed tokens count

### 2. Pending Requests
- View all pending token requests
- Read student messages
- **Approve**: Click green "Approve" button
- **Reject**: Click red "Reject" button
- Approved tokens enter the queue

### 3. Manage Queues
- View all active tokens across services
- Cancel or complete tokens
- Monitor queue progression

### 4. Manage Users
- **View Users**: Toggle between Active/Inactive
- **Create User**: Click "Add User" button
  - Enter email, name, student ID, department, blood group
  - Select role (Student/Admin)
- **Edit User**: Click menu (⋮) → Edit
  - Update user profile fields
- **Activate/Deactivate**: Click menu → Activate/Deactivate
  - Deactivated users cannot login
- **Delete User**: Click menu → Delete (with confirmation)
- **Export PDF**: Click print icon in app bar
  - Generate user directory PDF
  - Print or save to file

### 5. Manage Notices
- **Create Notice**: Click "New Notice" button
  - Enter title and content
  - Notice is active by default
- **Edit Notice**: Click menu → Edit
  - Update title and content
- **Show/Hide**: Click menu → Hide/Show
  - Hidden notices won't appear to students
- **Delete Notice**: Click menu → Delete (with confirmation)

### 6. Stats & Analytics
- View service usage statistics
- Queue performance metrics

### 7. Settings
- View Firebase connection status
- Sign out

## 🔄 Complete Token Workflow

### Student Side:
1. **Request** a token (Library, Cafeteria, etc.)
2. Add optional **message** explaining the request
3. Token status: **Pending Approval**
4. Wait for admin to review

### Admin Side:
1. Navigate to **Pending** tab
2. Review request and student **message**
3. **Approve** or **Reject** the request

### After Approval:
1. Token status: **Approved**
2. Token enters the queue
3. Queue position updates in real-time
4. When 3 or fewer ahead: **Near Your Turn** (notification)
5. When position = 1: **Active** (student is called)
6. Admin marks token as **Completed**
7. Appears in student's **History**

## 🎯 Key Features

### Real-time Updates
- All data syncs automatically via Firestore
- No need to refresh manually
- See changes instantly across all devices

### Approval Workflow
- All token requests require admin approval
- Prevents spam and ensures control
- Admins can see context via student messages

### User Management
- Only admin can create accounts
- Controlled signup prevents unauthorized access
- Activate/deactivate users without deletion

### PDF Export
- Export complete user directory
- Print or save for records
- Includes all profile fields

### Profile System
- Students can edit their own profiles
- Admins can edit any user profile
- Profile pictures via URL

### Notices System
- Campus-wide announcements
- Admins create and manage
- Students read-only access

## 🔐 Security Notes

1. **Controlled Signup**: Students cannot self-register
2. **Account Activation**: Admins can disable access instantly
3. **Role-based Access**: Students and admins see different interfaces
4. **Firebase Auth**: Secure authentication backend
5. **Firestore Rules**: User-scoped data access

## ❓ Common Questions

**Q: How do I create the first admin account?**
A: Use "Continue as Guest" with Admin role toggle on first launch.

**Q: Can students create their own accounts?**
A: No, only admins can create user accounts.

**Q: What happens if I deactivate a user?**
A: They cannot login until reactivated by an admin.

**Q: Can I delete notices?**
A: Yes, admins can delete notices permanently.

**Q: How do I export user data?**
A: In Manage Users screen, click the print icon → PDF will open.

**Q: Can students see all pending requests?**
A: No, students only see their own tokens. Admins see all.

**Q: What if I forget my password?**
A: Contact an admin to reset your account (future feature: Firebase password reset).

## 🐛 Troubleshooting

**App won't start:**
- Run `flutter pub get`
- Check Flutter doctor: `flutter doctor`

**Firebase errors:**
- Verify `firebase_options.dart` exists
- Check Firebase project configuration

**Login fails:**
- Verify account was created by admin
- Check account is active
- Ensure correct email/password

**Notices not showing:**
- Check notice is marked as "Active"
- Pull down to refresh

**Profile won't update:**
- Ensure you clicked the checkmark to save
- Check Firebase connection

## 📞 Support

For issues, questions, or feature requests:
- Check `IMPLEMENTATION_SUMMARY.md` for detailed feature list
- Review GitHub repository: https://github.com/Reduan090/CampusQ
- Check Flutter/Firebase documentation

---

**Last Updated**: December 2, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
