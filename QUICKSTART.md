# Quick Start Guide 🚀

## Running the App

1. **Make sure Flutter is installed**
   ```bash
   flutter doctor
   ```

2. **Install dependencies** (already done)
   ```bash
   flutter pub get
   ```

3. **Connect a device or start an emulator**
   - Android: Start Android Emulator from Android Studio
   - iOS: Start iOS Simulator: `open -a Simulator`
   - Physical device: Connect via USB and enable USB debugging

4. **Run the app**
   ```bash
   flutter run
   ```

   Or press **F5** in VS Code

## Testing the App Flow

### Basic Workflow
1. ✅ Launch the app → You'll see the Request screen
2. ✅ Tap on "Library" (or any service)
3. ✅ A dialog shows your token details
4. ✅ Click "OK" → Token appears in the Active tab
5. ✅ Watch the queue position decrease automatically
6. ✅ When position ≤ 3: Orange "Near Turn" notification appears
7. ✅ When position = 1: Green "Active" notification appears
8. ✅ Tap "Complete" to finish the token
9. ✅ Check History tab to see completed token

### Try Multiple Tokens
- Request tokens for different services (Cafeteria, Lab, etc.)
- All active tokens appear in the Active tab
- Each token progresses independently

### Test Cancellation
- Request a token
- Before it becomes active, tap "Cancel"
- Token moves to History with "Expired" status

## App Navigation

📱 **Bottom Navigation Bar:**
- 🏠 **Request** - Request new tokens
- 🎫 **Active** (with badge) - View active tokens
- 📜 **History** - View past tokens

## What to Look For

✨ **Automatic Queue Updates**
- Queue positions update every ~10 seconds
- Status badges change color (Blue → Orange → Green)
- Notification banners appear on cards

✨ **Real-time UI Updates**
- Active tab badge shows count
- Cards update without refreshing
- Pull-down to refresh works

✨ **Console Notifications**
- Check Debug Console for notification logs
- Format: "🔔 NOTIFICATION: Your [Service] token is near!"

## Troubleshooting

### App won't run
```bash
flutter clean
flutter pub get
flutter run
```

### No device found
```bash
flutter devices
# Then select a device or start emulator
```

### Hot reload not working
- Press `r` in terminal
- Or press `R` for hot restart
- Or save file in VS Code (if enabled)

## Notes

- Queue simulation runs automatically in the background
- Tokens progress realistically (not instant)
- Multiple tokens can be active simultaneously
- App state persists during hot reload

Enjoy testing your Virtual Token System! 🎉
