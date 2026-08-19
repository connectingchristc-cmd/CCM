# CCM Melodies - Quick Reference & Testing Guide

## 🚀 **QUICK START**

### **Build & Run the App**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🧪 **TESTING GUIDE**

### **Test Case 1: Member Access**
1. Launch the app
2. Click "Continue as Member"
3. **Expected**: Access all tabs (Home, Songs, More) without admin features
4. **Verify**:
   - ✓ Home tab shows services and Daily Bread
   - ✓ No "Add" button on Daily Bread section
   - ✓ Songs tab shows song list with search
   - ✓ No red FAB button on Songs tab
   - ✓ More tab has 4 "Coming Soon" sections
   - ✓ No Logout button visible

### **Test Case 2: Admin Login with Remember Me**
1. Click "CCM Admin Login"
2. Enter credentials:
   - Username: `CCMAdmin`
   - Password: `CCMAdmin@2026`
3. **Check "Remember Me" checkbox**
4. Click "Login"
5. **Expected**: Access admin app with all features
6. **Verify**:
   - ✓ Home tab shows "Add" button on Daily Bread
   - ✓ Songs tab shows red FAB for adding songs
   - ✓ More tab shows red "Admin Logout" button
   - ✓ Session persists (Navigate away and back)

### **Test Case 3: Add Daily Bread (Admin)**
1. Login as admin
2. Go to Home tab
3. Click "Add" button in Daily Bread section
4. Fill in:
   - Verse: "Your verse text here"
   - Reference: "John 3:16"
   - Image URL: "https://example.com/image.jpg" (optional)
5. Click "Post Daily Bread"
6. **Expected**:
   - ✓ Success message shown
   - ✓ New verse appears in Daily Bread section
   - ✓ Can navigate with Previous/Next buttons

### **Test Case 4: Add Song (Admin)**
1. Login as admin
2. Go to Songs tab
3. Click red "Add Song" FAB
4. Fill in:
   - Title (English): "Song Name"
   - Title (Telugu): "పాట పేరు"
   - Lyrics: "Full song lyrics..."
5. Click "Save & Publish Song"
6. **Expected**:
   - ✓ Success message shown
   - ✓ New song appears in list
   - ✓ Can search and tap to view

### **Test Case 5: Search Songs**
1. Go to Songs tab
2. Type "test" in search bar
3. **Expected**:
   - ✓ Results filter in real-time
   - ✓ Searches both English and Telugu titles
   - ✓ Shows "No songs found" if no matches

### **Test Case 6: View Song Lyrics**
1. Tap any song in the list
2. **Expected**:
   - ✓ Lyrics screen opens
   - ✓ Shows Telugu and English titles
   - ✓ Can adjust font size with +/- buttons
   - ✓ Text is selectable (can copy)

### **Test Case 7: Daily Bread Navigation**
1. Go to Home tab
2. If multiple verses exist, check navigation
3. Click Previous/Next arrows
4. **Expected**:
   - ✓ Verses cycle through history
   - ✓ Counter shows "X of Y"
   - ✓ Image updates if provided

### **Test Case 8: Coming Soon Sections**
1. Go to More tab
2. Tap each section (About Us, Pastoral Team, etc.)
3. **Expected**:
   - ✓ Opens Coming Soon screen
   - ✓ Shows back navigation
   - ✓ All sections look consistent

### **Test Case 9: Admin Logout**
1. Login as admin
2. Go to More tab
3. Click "Admin Logout" button
4. Click "Logout" in confirmation dialog
5. **Expected**:
   - ✓ Returns to Welcome screen
   - ✓ Session cleared
   - ✓ Can login again

### **Test Case 10: Logout Confirmation Cancel**
1. Login as admin
2. Go to More tab
3. Click "Admin Logout" button
4. Click "Cancel" in dialog
5. **Expected**:
   - ✓ Dialog closes
   - ✓ Still on More tab
   - ✓ Still logged in

---

## 📱 **RESPONSIVE TESTING**

### **Test on Different Screen Sizes**
- [ ] Small phone (320px width)
- [ ] Standard phone (375px width)
- [ ] Large phone (412px width)
- [ ] Tablet (600px+ width)
- [ ] Landscape orientation

### **Expected Behavior**
- All text readable
- Buttons touch-friendly (50px minimum height)
- Images scale properly
- Gradients display correctly
- No horizontal scrolling (except search)

---

## 🔴 **ERROR HANDLING TESTS**

### **Test 1: Invalid Admin Credentials**
1. Click "CCM Admin Login"
2. Enter wrong username or password
3. Click Login
4. **Expected**: SnackBar shows "Invalid admin username or password."

### **Test 2: Firebase Connection Error**
1. Disconnect internet or disable Firebase
2. Open Songs tab
3. **Expected**: Error message or loading state handled gracefully

### **Test 3: Invalid Image URL**
1. Add Daily Bread with invalid image URL
2. View Daily Bread section
3. **Expected**: Image placeholder shown instead of error

### **Test 4: Empty Search Results**
1. Search for non-existent song
2. **Expected**: "No songs found" message displayed

---

## 🎨 **VISUAL/UI TESTING**

### **Color Verification**
- [ ] Primary red (#C41E3A) used for:
  - AppBar backgrounds
  - Main buttons
  - Accent text
  - Service card gradient
  
- [ ] Secondary blue (#003DA5) used for:
  - Daily Bread section
  - Secondary buttons
  - Accent elements
  
- [ ] White (#FFFFFF) backgrounds visible and clean

### **Gradient Testing**
- [ ] Welcome screen shows Red→Blue gradient
- [ ] Service cards show Red→Blue gradient
- [ ] Daily Bread shows Blue→Red gradient
- [ ] Form backgrounds subtle and non-intrusive

### **Typography Testing**
- [ ] All text is readable
- [ ] Telugu text displays correctly
- [ ] Font sizes are appropriate
- [ ] Font weights are consistent

### **Spacing & Layout Testing**
- [ ] No overlapping elements
- [ ] Consistent padding throughout
- [ ] Proper spacing between sections
- [ ] Safe area respected on notched devices

---

## 🔐 **ADMIN FEATURES VERIFICATION**

### **Features Available Only to Admin**

| Feature | Location | Verified |
|---------|----------|----------|
| Add Daily Bread | Home tab (top right "Add") | ☐ |
| Add Song | Songs tab (Red FAB) | ☐ |
| Logout Button | More tab (Bottom red button) | ☐ |
| Remember Me | Login screen | ☐ |

### **Features NOT Available to Members**

| Feature | Verified Hidden |
|---------|-----------------|
| Add Daily Bread button | ☐ |
| Add Song FAB | ☐ |
| Logout button | ☐ |

---

## 🔄 **NAVIGATION TESTING**

### **Tab Switching**
- [ ] Can switch between Home, Songs, More tabs
- [ ] Tab state is preserved when switching away and back
- [ ] Animations are smooth
- [ ] Correct icon and label shown for each tab

### **Screen Navigation**
- [ ] Can go from Welcome → Admin Login → Main App
- [ ] Can go from Welcome → Member → Main App
- [ ] Back buttons work correctly
- [ ] Navigation history is logical

### **Deep Linking Ready**
- [ ] App handles direct screen access
- [ ] No crashes when skipping screens

---

## 📊 **FIREBASE TESTING**

### **Songs Collection**
```javascript
// Test document structure
{
  title_english: "Test Song",
  title_telugu: "పరీక్ష పాట",
  lyrics: "Test lyrics content...",
  created_at: Timestamp(date)
}
```

### **Daily Bread Collection**
```javascript
// Test document structure
{
  verse: "Test bible verse...",
  reference: "John 3:16",
  imageUrl: "https://example.com/image.jpg",
  created_at: Timestamp(date)
}
```

### **Testing Firebase Operations**
- [ ] Create new song - appears in list
- [ ] Create new Daily Bread - appears in Home
- [ ] Search queries work correctly
- [ ] Timestamp ordering works
- [ ] Images load from URLs
- [ ] Data persists across app restart

---

## 🎯 **PERFORMANCE TESTING**

### **Load Times**
- [ ] App launch: < 3 seconds
- [ ] Tab switching: Instant
- [ ] Song list loads: < 2 seconds
- [ ] Search results: Real-time (<500ms)
- [ ] Image loading: Acceptable

### **Memory Usage**
- [ ] App doesn't crash with many songs
- [ ] Images load without memory issues
- [ ] Smooth scrolling in long lists
- [ ] No memory leaks detected

---

## 🌍 **LOCALIZATION TEST**

### **Telugu Language Support**
- [ ] Telugu text in song titles displays correctly
- [ ] Telugu lyrics render properly
- [ ] Telugu font sizes are appropriate
- [ ] No character corruption

### **English Language Support**
- [ ] All English text displays correctly
- [ ] Mixed Telugu/English works
- [ ] Search handles both languages

---

## 🎬 **ANIMATION & INTERACTION TESTING**

### **Transitions**
- [ ] Bottom nav tab switching: Smooth
- [ ] Screen navigation: Proper route animation
- [ ] Button presses: Visual feedback

### **Interactive Elements**
- [ ] All buttons are clickable
- [ ] Form fields accept input
- [ ] TextFields show cursor
- [ ] Checkboxes toggle properly
- [ ] Scrolling is smooth

---

## 📝 **NOTES FOR DEPLOYMENT**

### **Pre-Release Checklist**
- [ ] All tests pass (above test cases)
- [ ] No console errors or warnings
- [ ] Firebase Firestore rules are configured
- [ ] App icon and splash screen set
- [ ] Version number updated (currently 1.0.0+1)
- [ ] README.md updated with new features
- [ ] All dependencies up to date
- [ ] Code reviewed for quality

### **Deployment Steps**
1. Update version in `pubspec.yaml`
2. Update CHANGELOG with new features
3. Test on real device (not just emulator)
4. Build APK/IPA for distribution
5. Store credentials securely
6. Document any setup steps needed

---

## 📞 **SUPPORT & TROUBLESHOOTING**

### **Common Issues**

**Issue: Firebase not connecting**
- Solution: Check Firebase project setup
- Check internet connection
- Verify firebase_options.dart

**Issue: Images not loading**
- Solution: Check image URLs are valid
- Verify network access enabled
- Check image URL format

**Issue: Telugu text not displaying**
- Solution: Check Google Fonts dependency
- Verify font is included
- Check Flutter rendering

**Issue: Buttons not responding**
- Solution: Check navigation routes exist
- Verify Firebase initialization
- Check for navigation errors

---

## 📚 **DOCUMENTATION FILES INCLUDED**

1. **REDESIGN_SUMMARY.md** - Complete overview of all changes
2. **VISUAL_GUIDE.md** - Screen layouts and visual reference
3. **QUICK_REFERENCE.md** (this file) - Testing and deployment guide
4. **main.dart** - Complete source code with comments

---

## 🎓 **DEVELOPER NOTES**

### **Code Structure**
- Main entry point: `void main()`
- Theme constants: Color definitions at top
- Screens organized in logical order
- Each screen is a separate StatefulWidget/StatelessWidget
- Firebase operations handled in respective screens

### **State Management**
- Using StatefulWidget for state changes
- setState() for local state updates
- StreamBuilder for Firebase real-time updates
- No external state management needed for MVP

### **Key Classes**
- `CCMMelodiesApp` - Main app configuration
- `WelcomeScreen` - Entry screen
- `AdminLoginScreen` - Admin authentication
- `MainApp` - Bottom nav container
- `HomeScreen` - Home tab content
- `SongsScreen` - Songs tab content
- `MoreScreen` - More tab content

---

## ✅ **FINAL VERIFICATION**

Before considering the redesign complete:

- [ ] All requirements implemented
- [ ] Color scheme (Red/Blue/White) throughout
- [ ] Bottom tabs (Home, Songs, More)
- [ ] Services section in Home
- [ ] Daily Bread with admin upload
- [ ] Songs list with search
- [ ] Admin Remember Me checkbox
- [ ] Logout button for admin
- [ ] All "Coming Soon" sections
- [ ] No errors in console
- [ ] App runs smoothly
- [ ] Firebase integration working
- [ ] Images loading correctly
- [ ] Telugu text displaying correctly
- [ ] All buttons functional

**Status**: ✅ Ready for Testing & Deployment

---

**Last Updated**: August 20, 2026
**Version**: 1.0.0+1
**Flutter Version**: 3.13.0+
