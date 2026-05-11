# Deployment Guide - Version 1.0.8 (Build 8)
**Date:** May 12, 2026

## 📦 Build Files Ready

### iOS (App Store)
- **File:** `eastern_mangrove_app/build/ios/ipa/eastern_mangrove_app.ipa`
- **Size:** 26.3 MB
- **Version:** 1.0.8
- **Build Number:** 8
- **Bundle ID:** com.kritdev.easternmangrove
- **Min iOS:** 13.0
- **Team ID:** 2TA4S4VU44

### Android (Google Play)
- **File:** `eastern_mangrove_app/build/app/outputs/bundle/release/app-release.aab`
- **Size:** 44.8 MB
- **Version Name:** 1.0.8
- **Version Code:** 8
- **Package Name:** com.kritdev.easternmangrove
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 34 (Android 14)

---

## 🍎 App Store Upload (iOS)

### Method 1: Apple Transporter (Recommended)
1. Open **Transporter** app on Mac
   - Download from: https://apps.apple.com/us/app/transporter/id1450874784
2. Drag and drop: `eastern_mangrove_app/build/ios/ipa/eastern_mangrove_app.ipa`
3. Click **Deliver**
4. Wait for upload to complete
5. Go to App Store Connect

### Method 2: Command Line
```bash
xcrun altool --upload-app --type ios \
  -f eastern_mangrove_app/build/ios/ipa/eastern_mangrove_app.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

### App Store Connect Configuration
1. Go to https://appstoreconnect.apple.com
2. Select **Eastern Mangrove** app
3. Click **+** version → Create **1.0.8**
4. Select the uploaded build (may take 5-15 minutes to appear)
5. Fill in:
   - **What's New in This Version:** See Release Notes below
   - **App Review Information:**
     - Username: `admin`
     - Password: `admin1234`
   - **Demo Account Notes:** See TEST_CREDENTIALS.md for all test accounts
6. Save and **Submit for Review**

---

## 🤖 Google Play Upload (Android)

### Upload to Google Play Console
1. Go to https://play.google.com/console
2. Select **Eastern Mangrove** app
3. Go to **Production** → **Create new release**
4. Upload AAB file:
   ```
   eastern_mangrove_app/build/app/outputs/bundle/release/app-release.aab
   ```
5. Fill in release details:
   - **Release name:** 1.0.8 (8)
   - **Release notes:** See below

### Release Notes (ภาษาไทย)
```
เวอร์ชัน 1.0.8
🔧 แก้ไขและปรับปรุง
• เพิ่มความสามารถในการแก้ไขชื่อผู้ใช้ (username) ในหน้าโปรไฟล์
• ปรับปรุงระบบการลงทะเบียนชุมชนให้รองรับชื่อผู้ใช้
• แก้ไขข้อผิดพลาดในการตรวจสอบข้อมูลชุมชน
• ปรับปรุงความเสถียรของระบบ backend
• แก้ไขปัญหา user_id ในระบบข้อมูลนิเวศและมลพิษ
```

### Release Notes (English)
```
Version 1.0.8
🔧 Fixes and Improvements
• Added ability to edit username in profile screens
• Improved community registration system with username support
• Fixed validation errors in community data
• Enhanced backend system stability
• Fixed user_id issues in ecosystem and pollution data systems
```

### Test Credentials for Review
6. In **App content** → **App access**:
   - Select: "All features are available without login" ❌
   - Select: "App requires login" ✅
   - Provide test credentials:
     ```
     Admin Account:
     Username: admin
     Password: admin1234
     
     Community User:
     Username: user1
     Password: user1234
     
     See full list in notes section
     ```

7. Add note to reviewers:
   ```
   Test Credentials:
   - Admin: username "admin", password "admin1234"
   - Community Leader 1: username "leader1", password "leader1234"
   - Community Leader 2: username "leader2", password "leader2234"
   - Community Leader 3: username "leader3", password "leader3234"
   - Regular User: username "user1", password "user1234"
   
   Login Instructions:
   1. Open the app
   2. Tap "เข้าสู่ระบบ" (Login) button
   3. Enter username and password
   4. Tap "เข้าสู่ระบบ" to login
   
   Community leaders can access ecosystem data, pollution reports, and economic information.
   Admin account has full access to approve registrations and manage all data.
   ```

8. **Review and rollout** → **Start rollout to Production**

---

## 📋 Pre-Submission Checklist

### iOS
- [x] Build IPA successfully (26.3 MB)
- [x] Version number: 1.0.8
- [x] Build number: 8
- [x] Code signing: Automatic (Development Team)
- [x] App icon: Set ⚠️ (Using default launch image - can update later)
- [x] Test credentials ready in TEST_CREDENTIALS.md
- [ ] Upload to App Store Connect
- [ ] Submit for review

### Android
- [x] Build AAB successfully (44.8 MB)
- [x] Version name: 1.0.8
- [x] Version code: 8
- [x] Signed with upload keystore
- [x] ProGuard/R8 enabled
- [x] Test credentials ready in TEST_CREDENTIALS.md
- [ ] Upload to Google Play Console
- [ ] Submit for review

---

## 🔑 Test Credentials Reference
All test credentials are documented in: `TEST_CREDENTIALS.md`

**Quick Reference:**
- Admin: `admin` / `admin1234`
- User 1: `user1` / `user1234`
- Leader 1: `leader1` / `leader1234`
- Leader 2: `leader2` / `leader2234`
- Leader 3: `leader3` / `leader3234`

---

## 🚀 What's New in v1.0.8

### Features Added
1. **Username Editing**
   - Community users can now edit their username in profile settings
   - Admin users can edit their username
   - Duplicate username checking implemented

2. **Improved Community Registration**
   - Updated to use username-based authentication
   - Better validation for community data
   - Fixed firstName/lastName field issues

### Bug Fixes
1. **Backend Routes**
   - Fixed ecosystem data route to use user_id instead of email
   - Fixed pollution report route authentication
   - Fixed economic data route user_id handling
   - Updated admin profile to support username updates

2. **Validation**
   - Removed unused firstName/lastName from community registration
   - Updated Joi validation schemas to match frontend models
   - Added proper username validation (3-50 chars, alphanumeric + underscore)

3. **Database**
   - Added username column to users table
   - Fixed user_id references in communities table
   - Note: 2 users still need manual user_id update (kumnansuc, boontam)

### Technical Changes
- Changed login system from email to username
- Updated all API routes to use username authentication
- Improved error handling and validation messages
- Enhanced backend logging for debugging

---

## 📊 Git Commits for This Release

```
2049a8d - Fix: Update community registration to use contactPerson/communityName
2c814d0 - Fix: Remove firstName and lastName from auth_provider community registration
287641a - Fix: Remove unused firstName and lastName fields from community registration
dd53c55 - Remove duplicate updateUserProfile function causing iOS build error
b740766 - Add username editing to admin profile
5289348 - Add username editing to community profile with validation
f08adf3 - Fix community registration endpoint to include username field
```

---

## ⚠️ Known Issues (Non-Critical)

1. **iOS Launch Image**
   - Currently using default placeholder
   - Can be updated in future version
   - Does not block app functionality

2. **Database User IDs**
   - 2 users (kumnansuc, boontam) have NULL user_id
   - Need to run SQL update after deployment:
     ```sql
     UPDATE communities 
     SET user_id = (SELECT id FROM users WHERE username = 'kumnansuc') 
     WHERE id = 8;
     
     UPDATE communities 
     SET user_id = (SELECT id FROM users WHERE username = 'boontam') 
     WHERE id = 11;
     ```

3. **Package Updates**
   - 38 Flutter packages have newer versions available
   - All are marked as incompatible with current dependency constraints
   - Can be updated in future version if needed
   - Current versions are stable and working

---

## 📞 Support Information

- **App Name:** Eastern Mangrove Communities
- **Developer:** Eastern Mangrove Team
- **Support Email:** (Add your support email)
- **Privacy Policy:** https://your-domain.com/docs/privacy-policy.html
- **Delete Account:** https://your-domain.com/docs/delete-account.html

---

## 🎯 Post-Deployment Tasks

After both platforms approve:
1. Monitor crash reports in:
   - Firebase Crashlytics (if configured)
   - App Store Connect
   - Google Play Console

2. Fix NULL user_id in database:
   - Connect to PostgreSQL
   - Run SQL updates for kumnansuc and boontam

3. Monitor user feedback:
   - Check app store reviews
   - Monitor support emails
   - Track registration success rate

4. Plan next version:
   - Update launch image for iOS
   - Consider updating dependencies
   - Add any requested features

---

**Last Updated:** May 12, 2026  
**Prepared By:** Development Team  
**Status:** ✅ Ready for Upload
