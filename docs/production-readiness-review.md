# Nutri Vapor — 產品化準備度審查報告

> 審查日期：2026-02-27
> 審查範圍：系統架構、安全性、效能、可靠性、可觀測性、部署

---

## 摘要

本報告針對 Nutri Vapor 後端服務進行產品化準備度審查，共發現 **7 個關鍵問題（Critical）**、**8 個高優先級問題（High）**、**6 個中優先級問題（Medium）**。以下按優先順序逐一說明。

---

## 1. 🔴 Critical — Firebase Token 簽章驗證未實作

**檔案**：`Sources/App/Middleware/FirebaseAuthMiddleware.swift:14-16`

**現況**：目前只對 Firebase Token 做 Base64 解碼讀取 payload，**完全沒有驗證數位簽章**。程式碼中有 TODO 註解：

```swift
// Decode Firebase token (simplified — in production, verify against Google JWKS)
// TODO: Implement full JWKS verification using Google's public certificates
```

**風險**：任何人都可以手工構造一個格式正確的 JWT，填入任意 `sub`（UID），即可冒充任何使用者。**等同於沒有認證**。

**建議**：
- 使用 Vapor 的 JWT 套件搭配 Google JWKS 端點進行完整簽章驗證
- 快取 Google 公鑰（建議 TTL 1 小時），避免每次請求都去抓
- 驗證 `iss`、`aud`、`exp`、`iat` 等所有標準 claims
- 確認 `aud` 必須等於 Firebase Project ID

```swift
// 建議實作方向
let jwks = try await req.application.jwt.keys.add(jwks: fetchGoogleJWKS())
let payload = try await req.jwt.verify(bearerToken, as: FirebaseTokenPayload.self)
```

---

## 2. 🔴 Critical — Rate Limiting 寫好了但沒掛上去

**檔案**：`Sources/App/Middleware/RateLimitMiddleware.swift`（已實作）
**檔案**：`Sources/App/routes.swift`（未使用）

**現況**：`RateLimitMiddleware` 已經完整實作，`Constants.swift` 也定義了 `authRateLimit = 5` 和 `generalRateLimit = 100`，但 **routes.swift 裡完全沒有把它掛到任何 route 上**。

**風險**：
- 登入 / 註冊端點無限制 → 暴力破解攻擊
- API 端點無限制 → 資源耗盡 / DDoS

**建議**：
```swift
// routes.swift 中加入
let authRateLimit = RateLimitMiddleware(maxRequests: APIConstants.authRateLimit, windowSeconds: 60)
let generalRateLimit = RateLimitMiddleware(maxRequests: APIConstants.generalRateLimit, windowSeconds: 60)

let firebaseAuth = api.grouped(authRateLimit).grouped(FirebaseAuthMiddleware())
let jwtAuth = api.grouped(generalRateLimit).grouped(JWTAuthMiddleware())
```

此外，In-Memory Rate Limiter 在多實例部署時各自獨立計數。若有水平擴展計劃，需改用 Redis 作為共用儲存。

---

## 3. 🔴 Critical — 註冊流程無 Transaction，可產生孤兒資料

**檔案**：`Sources/App/Controllers/AuthController.swift:42-57`

**現況**：註冊時依序建立 3 筆資料（User → UserProfile → NutritionGoal），沒有包在 Transaction 中：

```swift
try await user.save(on: req.db)           // ✅ 成功
let profile = UserProfile(userID: user.id!, ...)
try await profile.save(on: req.db)        // ❌ 若失敗 → User 已存在但沒有 Profile
let goals = NutritionGoal(userID: user.id!)
try await goals.save(on: req.db)          // ❌ 若失敗 → User + Profile 存在但沒有 Goals
```

**風險**：部分寫入成功後失敗，留下不完整的使用者資料，後續 API 會拿不到 Profile/Goals 導致 500。

**建議**：
```swift
try await req.db.transaction { db in
    try await user.save(on: db)
    try await profile.save(on: db)
    try await goals.save(on: db)
}
```

其他需要 Transaction 的地方：
- `NutritionController.sync`（批次同步多筆 entry）
- `AuthController.deleteAccount`（應連帶刪除所有關聯資料）

---

## 4. 🔴 Critical — 帳號刪除只做 Soft Delete User，關聯資料全部留存

**檔案**：`Sources/App/Controllers/AuthController.swift:108-122`

**現況**：
```swift
func deleteAccount(req: Request) async throws -> SuccessResponse {
    // ...
    try await user.delete(on: req.db)  // 只 soft delete User
    return SuccessResponse(message: "Account deleted successfully")
}
```

**風險**：
- **GDPR / 個資法合規問題**：使用者要求刪除帳號，但 FoodEntry、HealthSyncLog、UserProfile、NutritionGoal、UserFavorite、PushLog 全部還在
- **App Store 審核**：Apple 要求提供帳號刪除功能，若關聯資料未刪除可能被拒審

**建議**：
```swift
try await req.db.transaction { db in
    try await FoodEntry.query(on: db).filter(\.$user.$id == user.id!).delete()
    try await HealthSyncLog.query(on: db).filter(\.$user.$id == user.id!).delete()
    try await UserFavorite.query(on: db).filter(\.$user.$id == user.id!).delete()
    try await PushLog.query(on: db).filter(\.$user.$id == user.id!).delete()
    try await NutritionGoal.query(on: db).filter(\.$user.$id == user.id!).delete()
    try await DailyNutritionSummary.query(on: db).filter(\.$user.$id == user.id!).delete()
    try await UserProfile.query(on: db).filter(\.$user.$id == user.id!).delete()
    try await user.delete(force: true, on: db)  // hard delete
}
```

---

## 5. 🔴 Critical — 輸入驗證幾乎不存在

**影響範圍**：所有 Controller

**現況**：
| 問題 | 範例 |
|------|------|
| 營養數值可以是負數 | `calories = -9999` 可以寫入 |
| 沒有上限檢查 | `calories = 999999999` 可以寫入 |
| 字串無長度限制 | `foodName` 可以送 1MB 的字串 |
| 同步批次無上限 | `/nutrition/sync` 可送 100 萬筆 entries |
| 日期無範圍檢查 | 可送 `2099-12-31` 或 `1900-01-01` |
| Email 格式不驗證 | 任意字串都可以當 email |

**建議**：建立統一的 Validation 層：

```swift
// 在 CreateFoodEntryRequest 加入驗證
struct CreateFoodEntryRequest: Content, Validatable {
    // ...
    static func validations(_ validations: inout Validations) {
        validations.add("food_name", as: String.self, is: .count(1...200))
        validations.add("calories", as: Double.self, is: .range(0...10000))
        validations.add("protein_g", as: Double?.self, required: false, is: .range(0...500))
    }
}

// Controller 中使用
try CreateFoodEntryRequest.validate(content: req)
```

對 `/nutrition/sync` 加入批次上限：
```swift
guard body.entries.count <= 100 else {
    throw Abort(.badRequest, reason: "Maximum 100 entries per sync")
}
```

---

## 6. 🔴 Critical — CORS 允許所有來源

**檔案**：`Sources/App/configure.swift:34-38`

```swift
app.middleware.use(CORSMiddleware(configuration: .init(
    allowedOrigin: .all,  // ← 允許任何網域
    // ...
)))
```

**風險**：若未來有 Web 介面，任何網站都能發起 CORS 請求到 API。結合 Firebase 認證未驗簽的問題，風險極大。

**建議**：改為白名單模式，或者既然目前只有 iOS App，可以直接移除 CORS middleware：
```swift
allowedOrigin: .custom("https://your-admin-domain.com")
```

---

## 7. 🔴 Critical — JWT Secret Key 未設定

**檔案**：`Sources/App/configure.swift`

**現況**：整個 `configure.swift` 中**沒有任何 JWT key 的設定**。Vapor 的 JWT 套件若沒有明確設定 signing key，將無法正確簽發或驗證 JWT。

**建議**：
```swift
// configure.swift 中加入
let jwtSecret = Environment.get("JWT_SECRET") ?? {
    fatalError("JWT_SECRET environment variable is required")
}()
await app.jwt.keys.add(hmac: HMACKey(from: Data(jwtSecret.utf8)), digestAlgorithm: .sha256)
```

---

## 8. 🟠 High — 沒有 Dockerfile，無法容器化部署

**現況**：只有 `docker-compose.yml`（僅定義 PostgreSQL），沒有 App 本身的 Dockerfile。無法打包成 Docker Image 進行部署。

**建議**：新增標準 Vapor Dockerfile：

```dockerfile
# Build
FROM swift:6.0-noble AS build
WORKDIR /app
COPY Package.* ./
RUN swift package resolve
COPY . .
RUN swift build -c release

# Run
FROM swift:6.0-noble-slim
WORKDIR /app
COPY --from=build /app/.build/release/App .
EXPOSE 8080
ENTRYPOINT ["./App", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
```

同時更新 `docker-compose.yml` 加入 app service。

---

## 9. 🟠 High — 沒有 CI/CD Pipeline

**現況**：沒有 `.github/workflows/`、沒有任何 CI/CD 設定。

**建議**：至少建立：
- **PR 檢查**：`swift build` + `swift test`
- **Main branch**：自動建置 Docker image + 推送到 Registry
- **Staging deploy**：合併到 main 後自動部署到 staging

---

## 10. 🟠 High — 測試覆蓋率極低

**現況**：`Tests/AppTests/AppTests.swift` 只有 2 個測試（health check），**所有商業邏輯零測試**。

**風險**：任何程式碼修改都可能在不知情的情況下破壞現有功能。

**建議優先補上測試**：
1. Auth 流程（註冊、登入、token 簽發）
2. Nutrition CRUD（建立、查詢、更新、刪除 food entry）
3. 輸入驗證（邊界值、非法輸入）
4. 權限隔離（User A 不能存取 User B 的資料）

---

## 11. 🟠 High — N+1 Query 問題

**影響端點**：

### `GET /recipes`（RecipeController.swift:47-57）
```swift
let total = try await query.count()           // Query 1
let recipes = try await query.with(\.$tags)   // Query 2
    .range(...).all()
let favoriteRecipeIDs = try await UserFavorite // Query 3（載入所有收藏）
    .query(on: req.db)
    .filter(\.$user.$id == userID)
    .all()
    .map { $0.$recipe.id }
```
每次列表頁都載入該使用者**所有**收藏記錄到記憶體中，只為了做 `contains` 檢查。

### `GET /recipes/recommended`（RecipeController.swift:210）
```swift
let favoriteIDs: [UUID] = [] // Simplified ← 直接寫死空陣列
```
`isFavorite` 永遠回傳 `false`。

**建議**：
- 收藏檢查改用 `Set<UUID>` + 只查當頁 recipe IDs
- 或用 SQL LEFT JOIN 一次查完

---

## 12. 🟠 High — 通知設定沒有實際儲存

**檔案**：`Sources/App/Controllers/NotificationController.swift:53-81`

**現況**：
```swift
func getSettings(...) {
    // Default settings — in production, read from Firestore or local DB
    return NotificationSettingsResponse(mealRemind: true, ...)  // 永遠回傳預設值
}

func updateSettings(...) {
    // TODO: Save to Firestore or local DB
    return NotificationSettingsResponse(...)  // 收到什麼就回什麼，不存
}
```

**風險**：使用者以為已儲存通知設定，實際上重啟後全部還原。

**建議**：在 PostgreSQL 新增 `notification_settings` 表，或直接寫入 Firestore。

---

## 13. 🟠 High — Notification History 洩漏內部欄位

**檔案**：`Sources/App/Controllers/NotificationController.swift:85-92`

```swift
func getHistory(req: Request) async throws -> [PushLog] {  // ← 直接回傳 Model
    return try await PushLog.query(on: req.db)
        .filter(\.$user.$id == userID)
        .limit(50).all()
}
```

**風險**：`PushLog` 是 Fluent Model，直接作為 Response 會暴露 `id`、`user_id`、`deleted_at` 等內部欄位。

**建議**：建立 `PushLogResponse` DTO，只回傳前端需要的欄位。

---

## 14. 🟠 High — Health Check 太簡單

**檔案**：`Sources/App/routes.swift:5-7`

```swift
app.get("health") { req in
    ["status": "ok"]
}
```

**現況**：只回傳靜態 JSON，不檢查資料庫連線狀態。即使 DB 已斷線，health check 仍回傳 ok。

**建議**：
```swift
app.get("health") { req async throws -> [String: String] in
    // 驗證 DB 連線
    _ = try await (req.db as! SQLDatabase).raw("SELECT 1").all()
    return ["status": "ok", "database": "connected"]
}
```

---

## 15. 🟠 High — 沒有 Graceful Shutdown 處理

**現況**：沒有處理 SIGTERM / SIGINT 時的優雅關閉。在容器化環境中，Pod 被終止時可能中斷正在處理的請求。

**建議**：Vapor 4 內建支援 graceful shutdown，但需確保：
- 長時間請求有 timeout 設定
- DB connection pool 正確關閉
- 設定 `app.http.server.configuration.requestDecompression` 等 server config

---

## 16. 🟡 Medium — 沒有結構化日誌 (Structured Logging)

**現況**：少數地方有 `req.logger.info(...)` 但多數操作無日誌。沒有 Request ID 追蹤。

**建議**：
- 加入 Request ID middleware（Vapor 內建 `RequestIDMiddleware`）
- 關鍵操作加入日誌：使用者註冊、刪除帳號、認證失敗、資料同步
- 使用 JSON 格式日誌便於 ELK / CloudWatch 收集

```swift
// configure.swift
app.middleware.use(RequestIDMiddleware())
```

---

## 17. 🟡 Medium — DateFormatter 重複建立

**影響範圍**：幾乎所有 Controller

**現況**：每個 request 都 `new DateFormatter()`，設定 `dateFormat = "yyyy-MM-dd"`。DateFormatter 建立成本高。

**建議**：建立共用的 static formatter：
```swift
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Taipei")
        return f
    }()
}
```

注意：同時要設定 `timeZone`，否則不同伺服器時區會導致日期計算錯誤。

---

## 18. 🟡 Medium — Calendar/TimeZone 沒有明確指定

**影響範圍**：所有使用 `Calendar.current` 的地方

**現況**：
```swift
let calendar = Calendar.current  // 使用伺服器系統時區
let today = calendar.startOfDay(for: Date())
```

**風險**：伺服器若部署在 UTC 時區，台灣使用者在晚上 8 點查「今日摘要」會拿到 UTC 的「今日」（也就是台灣的「明日」開始的資料）。

**建議**：
- API 接受 `timezone` 參數，或從 User Profile 讀取
- 統一使用明確時區的 Calendar

---

## 19. 🟡 Medium — 環境變數 Fallback 到開發預設值

**檔案**：`Sources/App/configure.swift:16-20`

```swift
let username = Environment.get("DB_USERNAME") ?? "nutri"
let password = Environment.get("DB_PASSWORD") ?? "nutri_dev"
```

**風險**：生產環境忘記設定環境變數時，會靜默使用開發用密碼連線，可能連到錯誤的資料庫。

**建議**：在 production 環境中，缺少必要環境變數應直接 crash：
```swift
if app.environment == .production {
    guard let _ = Environment.get("DB_PASSWORD") else {
        fatalError("DB_PASSWORD is required in production")
    }
}
```

---

## 20. 🟡 Medium — 沒有 Response 快取策略

**現況**：所有 API 回應都沒有 HTTP Cache-Control header。

**影響**：
- 食譜列表、熱門食譜等不常變動的資料，每次都完整查詢
- 同一個使用者短時間內重複呼叫相同 API，全部打到 DB

**建議**：
- 靜態類資料（食譜列表）加入 `Cache-Control: public, max-age=300`
- 個人資料加入 `ETag` + `304 Not Modified` 支援
- 考慮 Redis 作為 application-level cache

---

## 21. 🟡 Medium — Monthly Summary 載入所有 Entry 到記憶體

**檔案**：`Sources/App/Controllers/NutritionController.swift:296-329`

**現況**：30 天的所有 FoodEntry 全部載入記憶體後用 Swift 做 groupBy + reduce。

**風險**：重度使用者一天 10 筆 × 30 天 = 300 筆還可以，但若有批次同步或長期使用，資料量會越來越大。

**建議**：改用 SQL `GROUP BY DATE(eaten_at)` 做聚合，大幅減少傳輸量與記憶體使用。

---

## 整體優先順序建議

### 第一階段 — 上線前必須完成（1-2 週）
| # | 項目 | 嚴重度 |
|---|------|--------|
| 1 | Firebase Token 簽章驗證 | Critical |
| 7 | JWT Secret Key 設定 | Critical |
| 2 | 掛上 Rate Limiting | Critical |
| 5 | 輸入驗證層 | Critical |
| 3 | 註冊流程 Transaction | Critical |
| 4 | 帳號刪除完整清理 | Critical |
| 6 | CORS 白名單 | Critical |

### 第二階段 — 上線後第一版優化（2-4 週）
| # | 項目 | 嚴重度 |
|---|------|--------|
| 8 | Dockerfile | High |
| 9 | CI/CD Pipeline | High |
| 14 | Health Check 含 DB 檢查 | High |
| 12 | 通知設定持久化 | High |
| 13 | PushLog Response DTO | High |
| 11 | N+1 Query 修復 | High |
| 15 | Graceful Shutdown | High |

### 第三階段 — 穩定運營（4-8 週）
| # | 項目 | 嚴重度 |
|---|------|--------|
| 10 | 補寫測試 | High |
| 16 | 結構化日誌 | Medium |
| 17 | DateFormatter 共用 | Medium |
| 18 | TimeZone 處理 | Medium |
| 19 | 環境變數安全 | Medium |
| 20 | Response 快取 | Medium |
| 21 | DB 聚合查詢 | Medium |
