# Firebase 設定指南

## 前置需求
- Apple Developer Account (已設定 Sign in with Apple)
- Firebase 帳號

---

## 步驟 1：建立 Firebase 專案

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 點擊「新增專案」
3. 輸入專案名稱：`nutri-app`
4. 啟用 Google Analytics（建議）
5. 點擊「建立專案」

---

## 步驟 2：註冊 iOS App

1. 在 Firebase Console 專案頁面，點擊 iOS 圖示
2. 填入：
   - **Apple Bundle ID**: `com.janus.nutri`
   - **App 暱稱**: Nutri (選填)
   - **App Store ID**: (選填，上架後填)
3. 點擊「註冊應用程式」
4. **下載 `GoogleService-Info.plist`**

---

## 步驟 3：加入設定檔至 Xcode

1. 將 `GoogleService-Info.plist` 拖入 Xcode 專案
2. 確認勾選：
   - ✅ Copy items if needed
   - ✅ Create folder references
   - ✅ Target: Nutri
3. 確認檔案在 `Nutri/` 資料夾下

---

## 步驟 4：安裝 Firebase SDK (Swift Package Manager)

1. 在 Xcode 選擇 `File` → `Add Package Dependencies...`
2. 輸入 URL：
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. 選擇版本規則：`Up to Next Major Version` (11.0.0)
4. 選擇需要的套件：
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseStorage
   - ✅ FirebaseMessaging
   - ✅ FirebaseCrashlytics
   - ✅ FirebaseAnalytics
5. 點擊「Add Package」

---

## 步驟 5：啟用 Firebase Authentication

### 5.1 在 Firebase Console 啟用 Apple 登入

1. 前往 Firebase Console → Authentication → Sign-in method
2. 點擊「Apple」
3. 啟用開關
4. 需要填入：
   - **Services ID**: (通常是 `com.janus.nutri.signin`)
   - **Apple Team ID**: 在 Apple Developer 帳號可找到
   - **Key ID**: 建立 Sign in with Apple 金鑰時產生
   - **Private Key**: 上傳 `.p8` 私鑰檔案

### 5.2 在 Apple Developer 設定

1. 前往 [Apple Developer](https://developer.apple.com/account/)
2. Certificates, Identifiers & Profiles → Identifiers
3. 選擇你的 App ID (`com.janus.nutri`)
4. 確認已啟用 **Sign in with Apple**
5. 建立 Services ID（用於 Web/Firebase）:
   - Identifiers → 點擊 `+` → Services IDs
   - 輸入：`com.janus.nutri.signin`
   - 啟用 Sign in with Apple
   - Configure: 加入 Firebase 的 callback URL

### 5.3 Firebase Callback URL

在 Firebase Console → Authentication → Sign-in method → Apple 中複製 callback URL：
```
https://nutri-app-xxxxx.firebaseapp.com/__/auth/handler
```
將此 URL 加入 Apple Developer 的 Services ID 設定中。

---

## 步驟 6：設定 Firestore Database

1. Firebase Console → Firestore Database
2. 點擊「建立資料庫」
3. 選擇「正式版模式」
4. 選擇位置：`asia-east1` (台灣)
5. 設定 Security Rules：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Recipes are read-only for authenticated users
    match /recipes/{recipeId} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only via Firebase Admin SDK
    }
  }
}
```

---

## 步驟 7：設定 Firebase Storage

1. Firebase Console → Storage
2. 點擊「開始使用」
3. 選擇「正式版模式」
4. 選擇位置：與 Firestore 相同
5. 設定 Security Rules：

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User files
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024; // 10MB limit
    }

    // Recipe images (read-only)
    match /recipes/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

---

## 步驟 8：設定 FCM 推播 (選擇性)

1. Firebase Console → Cloud Messaging
2. 上傳 APNs 認證金鑰：
   - 前往 Apple Developer → Keys
   - 建立新金鑰，啟用 Apple Push Notifications service (APNs)
   - 下載 `.p8` 檔案
3. 在 Firebase 上傳：
   - Key ID
   - Team ID
   - `.p8` 檔案

---

## 步驟 9：啟用 Crashlytics (選擇性)

1. Firebase Console → Crashlytics
2. 點擊「開始使用」
3. 在 Xcode Build Phases 加入 Run Script：

```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

4. Input Files 加入：
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist
$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
```

---

## 驗證設定

執行 App，確認以下功能正常：

- [ ] App 啟動無錯誤
- [ ] Sign in with Apple 可以登入
- [ ] Firebase Console 顯示新用戶
- [ ] Firestore 有用戶資料
- [ ] 圖片可以上傳至 Storage

---

## 常見問題

### Q: 出現 "Firebase not configured" 錯誤
A: 確認 `GoogleService-Info.plist` 已正確加入專案，且檔名完全正確。

### Q: Apple Sign In 失敗
A:
1. 確認 Xcode → Signing & Capabilities 已加入 "Sign in with Apple"
2. 確認 Firebase Console 的 Apple 設定正確
3. 確認 Apple Developer 的 callback URL 設定正確

### Q: Firestore 寫入被拒絕
A: 檢查 Security Rules 是否正確，確認用戶已登入。

---

## 下一步

Firebase 設定完成後：

1. 將 `AuthenticationManager` 替換為 `FirebaseAuthManager`
2. 更新 UI 使用新的驗證 Manager
3. 開始使用 `FirestoreService` 和 `StorageService`
