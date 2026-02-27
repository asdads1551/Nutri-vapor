# Nutri Vapor 系統設計審查報告

**審查日期**: 2026-02-27
**目的**: 商品化前的系統設計全面檢查
**涵蓋範圍**: 安全性、資料庫設計、API 設計、服務層架構、效能、合規性

---

## 一、總體評估

| 類別 | 評分 | 狀態 |
|------|------|------|
| 安全性 (認證/授權) | 6/10 | ⚠️ 核心正確，但有關鍵缺口 |
| 資料庫設計 | 6/10 | ⚠️ 結構完整，索引和一致性不足 |
| API 設計 | 7/10 | ⚠️ 功能完善，缺少分頁和驗證 |
| 服務層架構 | 2.5/10 | ❌ 服務層完全未被使用 |
| 效能 | 5/10 | ⚠️ 缺少索引、快取、SQL 聚合 |
| 合規性 (GDPR/App Store) | 4/10 | ❌ 帳號刪除不完整 |

---

## 二、嚴重問題 (Critical — 必須在上線前修復)

### C1. JWT Secret 硬編碼回退值

**位置**: `Sources/App/configure.swift:42`

```swift
let jwtSecret = Environment.get("JWT_SECRET") ?? "dev-secret-change-in-production"
```

**風險**: 若未設定環境變數，攻擊者可用已知預設密鑰偽造任何 JWT Token。

**建議**: 生產環境強制要求 `JWT_SECRET`，缺少時 `fatalError()`。

---

### C2. 帳號刪除不符合 App Store / GDPR 合規

**位置**: `Sources/App/Controllers/AuthController.swift`

**問題**:
- `FirebaseAdminService.deleteFirebaseUser()` 是空殼 (stub)，未呼叫 Firebase Admin API
- 僅軟刪除 User，未刪除關聯資料 (FoodEntry、UserProfile、NutritionGoal 等)
- 使用者可用同一個 Firebase UID 重新註冊

**建議**: 在交易 (transaction) 中硬刪除所有使用者資料，並呼叫 Firebase Admin REST API 刪除帳號。

---

### C3. 登出為空操作 (No-op)

**位置**: `Sources/App/Controllers/AuthController.swift:101-104`

**問題**: 登出端點回傳成功訊息但未執行任何操作。被盜的 JWT 在 15 分鐘 TTL 內持續有效。

**建議**: 實作 Token 黑名單機制 (Redis-backed，TTL 與 JWT 一致)。

---

### C4. 資料庫連線未加密

**位置**: `Sources/App/configure.swift:36`

```swift
tls: .disable
```

**風險**: 資料庫憑證和查詢資料以明文傳輸。

**建議**: 生產環境使用 `.require`。

---

### C5. 服務層完全未被使用 — 邏輯重複

**問題**: 5 個 Service 檔案均未被 Controller 呼叫。Controller 直接重新實作了所有業務邏輯，導致:
- **500+ 行程式碼重複**
- 營養評分演算法不一致 (Service 用 `0.4/0.3/0.3` 加權，Controller 用簡單百分比)
- 無法進行單元測試
- 維護困難

| Service | 狀態 | Controller 行為 |
|---------|------|----------------|
| `FirebaseAdminService` | Stub (空殼) | Middleware 直接處理驗證 |
| `PushNotificationService` | 僅寫 DB 日誌，未串接 FCM | 無推播功能 |
| `NutritionService` | 完整但未使用 | Controller 重寫了相同邏輯 |
| `HealthService` | 完整但未使用 | Controller 重寫了相同邏輯 |
| `RecipeService` | 完整但未使用 | Controller 重寫了相同邏輯 |

**建議**: Controller 統一呼叫 Service，移除重複邏輯。

---

### C6. `GET /nutrition/entries` 無分頁 — 記憶體風險

**位置**: `Sources/App/Controllers/NutritionController.swift`

```swift
let entries = try await query.sort(\.$eatenAt, .ascending).all()
```

**風險**: 使用者累積數千筆食物紀錄後，單次請求載入全部資料可能導致 OOM。

**同樣問題的端點**:
- `GET /health/trends` — 無限制的趨勢資料
- `GET /recipes/favorites` — 收藏列表無分頁

**建議**: 所有列表端點加入 offset-based 分頁 (已在 Recipe 端點實作，需擴展至其他端點)。

---

### C7. 推播通知未實作

**位置**: `Sources/App/Services/PushNotificationService.swift`

**問題**: `sendNotification()` 僅將推播紀錄寫入資料庫，未實際呼叫 Firebase Cloud Messaging (FCM)。狀態永遠標記為 `.sent`，但實際上未發送。

**建議**: 串接 FCM REST API，實作正確的狀態機 (`pending → sent → delivered/failed`)。

---

## 三、高優先級問題 (High — 上線前應修復)

### H1. Rate Limiting 為記憶體內存儲

**問題**: `RateLimitStore` 使用 actor 內的 Dictionary，重啟後歸零，多實例部署時各自獨立計數。

**額外問題**:
- 無 `Retry-After` 標頭
- 舊的 key 永遠不清除，存在記憶體洩漏風險
- 使用 `remoteAddress` 而非 `X-Forwarded-For`，在反向代理後不準確

**建議**: 使用 Redis-backed rate limiter。

---

### H2. 缺少 Refresh Token 機制

**問題**: `jwtRefreshExpirationDays = 30` 常數已定義但從未使用。使用者每 15 分鐘必須重新透過 Firebase 驗證。

**影響**: 嚴重影響使用者體驗，頻繁的重新登入會導致使用者流失。

**建議**: 實作 Refresh Token 端點 (`POST /auth/refresh`)。

---

### H3. FoodEntryResponse 遺漏微量營養素

**位置**: `Sources/App/DTOs/NutritionDTO.swift`

**問題**:
- 建立時接受 7 種微量營養素 (sodium, potassium, calcium, iron, zinc, vitaminC, vitaminD)
- 回傳時僅包含巨量營養素 (calories, protein, carbs, fat, fiber)
- **資料寫入後無法完整讀回** — 這是資料遺失

**建議**: 在 `FoodEntryResponse` 中加入所有微量營養素欄位。

---

### H4. 註冊請求無輸入驗證

**位置**: `Sources/App/DTOs/AuthDTO.swift`

```swift
struct RegisterRequest: Content {
    let firstName: String?
    let lastName: String?
    // 無 Validatable 實作
}
```

**建議**: 加入字串長度限制和 email 格式驗證。

---

### H5. Email 更新被忽略 (Bug)

**位置**: `Sources/App/Controllers/UserController.swift`

**問題**: `UpdateUserRequest` 有 `email` 欄位且通過驗證，但 Controller 的更新邏輯中未實際將 email 寫入 User model。

---

### H6. CORS 設定過於開放

**位置**: `Sources/App/configure.swift:51-58`

**問題**: 開發環境 CORS 設為 `.all`，生產環境預設為 `.none`（會阻擋所有跨域請求）。需明確設定 `CORS_ALLOWED_ORIGIN`。

**建議**: 生產環境必須設定明確的前端域名白名單。

---

### H7. 角色權限 (RBAC) 未實施

**問題**: `UserRole` enum (user/admin) 已定義且存入資料庫，但沒有任何中介層或路由檢查角色權限。Admin 端點對一般使用者完全開放。

---

### H8. `NutritionService.updateDailySummary()` 競爭條件

**問題**: 使用 check-then-act 模式（先查詢是否存在，再決定新增或更新），未包在 transaction 或使用 UPSERT，並發請求可能產生重複記錄。

**建議**: 使用 `INSERT ... ON CONFLICT UPDATE` 或 database transaction。

---

## 四、中優先級問題 (Medium)

### M1. 資料庫索引不足

| 缺少的索引 | 影響的查詢 |
|-----------|-----------|
| `food_entries(user_id, meal_type, eaten_at)` | 按餐次篩選 (CLAUDE.md 規格要求) |
| `recipes(is_published)` | 食譜列表 (所有查詢都過濾 is_published) |
| `push_logs(user_id, sent_at)` | 推播歷史查詢 |
| `push_logs(status)` | 失敗推播篩選 |
| `daily_nutrition_summary(date)` | 日期範圍查詢 |

---

### M2. Soft Delete 模式不一致

| Model | 有 Soft Delete? |
|-------|----------------|
| User | ✅ 有 `deletedAt` |
| FoodEntry | ❌ 無 |
| Recipe | ❌ 無 |
| 其他所有 Model | ❌ 無 |

**CLAUDE.md 寫「所有模型使用 Soft Delete」，但僅 User 實作。**

**影響**: User 軟刪除後，子記錄因 CASCADE DELETE 被硬刪除，資料不一致。

---

### M3. 資料型別設計問題

| 欄位 | 目前型別 | 應改為 | 原因 |
|------|---------|--------|------|
| `RecipeIngredient.amount` | String | Double | 數值計算需要 |
| `RecipeIngredient.unit` | String | Enum | 避免不一致的單位文字 |
| `NotificationSetting.quietHoursStart/End` | String | Time 或 Int (分鐘) | 字串解析脆弱 |
| `UserProfile.allergies` | String[] | AllergenDB[] | 應使用已定義的 enum |

---

### M4. `NutritionGoal` 缺少唯一約束

**問題**: 同一使用者同一天可以有多筆 NutritionGoal，且 `user_id` 上無索引。

**建議**: 加入 `UNIQUE(user_id, effective_date)` 約束。

---

### M5. 效能 — 記憶體內聚合

**問題**: 多個端點將所有記錄載入記憶體後用 Swift 計算聚合值：

```swift
// 月摘要回退邏輯 — 可能載入數千筆
let entries = try await FoodEntry.query(on: req.db)
    .filter(\.$eatenAt >= monthAgo)
    .all()  // 全部載入記憶體
```

**建議**: 使用 SQL `SUM()` / `GROUP BY` 在資料庫端聚合。

---

### M6. NotificationController DTO 定義位置錯誤

**問題**: `NotificationSettingsResponse` 定義在 Controller 內而非 DTOs/ 目錄下，違反分層架構。

---

### M7. Recipe 營養值語義不明確

**問題**: Recipe model 的 `calories`, `proteinG` 等欄位未明確標示是「每份」還是「總量」。`servings` 欄位存在，但與營養值的關係不清楚。

---

### M8. 測試覆蓋率接近零

**問題**: Tests/ 目錄幾乎為空，關鍵業務邏輯（營養計算、評分演算法、認證流程）無單元測試。

---

### M9. 缺少安全事件日誌

**問題**:
- 認證失敗無日誌記錄
- 帳號變更無審計追蹤
- Rate limit 觸發無告警
- Service 層完全無日誌

---

### M10. 無 CI/CD Pipeline

**問題**: 無自動化建構、測試、部署流程。

---

## 五、架構改善建議

### 5.1 服務層重構 (最高優先)

```
目前:
Controller → 直接操作 DB (業務邏輯散落在 Controller)
Service → 未被使用

建議:
Controller → Service → Repository/DB
              ↓
           Validation + Business Logic + Transaction
```

### 5.2 錯誤處理標準化

```swift
// 建議: 定義域層級錯誤
enum NutritionError: AbortError {
    case entryNotFound(UUID)
    case invalidNutrientValue(String, Double)
    case dailyLimitExceeded

    var status: HTTPResponseStatus { ... }
    var reason: String { ... }
}

// 統一錯誤回應格式
struct APIErrorResponse: Content {
    let error: Bool = true
    let code: String
    let reason: String
    let details: [String: String]?
}
```

### 5.3 快取策略

| 資源 | 建議快取時間 | 失效策略 |
|------|------------|---------|
| 食譜列表 | 60s (已實作) | 新增食譜時失效 |
| 食譜詳情 | 300s (已實作) | 更新時失效 |
| 食譜推薦 | 1 小時 | 每小時重新計算 |
| 每日摘要 | 直到新增/修改食物紀錄 | 寫入時失效 |
| 健康趨勢 | 30 分鐘 | 同步時失效 |

### 5.4 部署前環境變數檢查清單

```bash
# 必須設定
JWT_SECRET=<至少 32 bytes 隨機字串>
DATABASE_URL=postgres://user:pass@host:5432/db  # TLS enabled
FIREBASE_PROJECT_ID=nutri-app-c0d75
CORS_ALLOWED_ORIGIN=https://your-domain.com

# 建議設定
LOG_LEVEL=info
RATE_LIMIT_REDIS_URL=redis://...
```

---

## 六、修復優先級路線圖

### Phase 1: 阻擋上線的問題 (第 1 週)

1. ❌ 強制 `JWT_SECRET` 環境變數 (C1)
2. ❌ 完整實作帳號刪除 — 硬刪除所有資料 + Firebase (C2)
3. ❌ 啟用資料庫 TLS (C4)
4. ❌ 所有列表端點加入分頁 (C6)
5. ❌ FoodEntryResponse 加入微量營養素 (H3)
6. ❌ 修復 email 更新 bug (H5)
7. ❌ 加入缺少的資料庫索引 (M1)

### Phase 2: 上線前加固 (第 2-3 週)

8. ⚠️ 實作 Token 黑名單 + 登出 (C3)
9. ⚠️ Controller 改為呼叫 Service 層 (C5)
10. ⚠️ Redis-backed Rate Limiting (H1)
11. ⚠️ 實作 Refresh Token (H2)
12. ⚠️ 加入角色權限中介層 (H7)
13. ⚠️ 修復 DailySummary 競爭條件 (H8)
14. ⚠️ 加入輸入驗證到所有 DTO (H4)

### Phase 3: 商品化品質 (第 4-6 週)

15. 💡 實作 FCM 推播通知 (C7)
16. 💡 統一錯誤處理格式
17. 💡 加入結構化日誌和監控
18. 💡 建立單元測試和整合測試
19. 💡 建立 CI/CD Pipeline
20. 💡 修復資料型別問題 (M3)
21. 💡 統一 Soft Delete 策略 (M2)
22. 💡 SQL 聚合取代記憶體聚合 (M5)

---

## 七、安全性總結

| 元件 | 狀態 | 說明 |
|------|------|------|
| Firebase Token 驗證 | ✅ 安全 | RS256 + JWKS 完整實作 |
| JWT 簽發與驗證 | ✅ 良好 | HMAC-SHA256, 15 分鐘 TTL |
| JWT Secret 管理 | ❌ 危險 | 硬編碼回退值 |
| Token 撤銷 | ❌ 未實作 | 無法在到期前失效 Token |
| Rate Limiting | ⚠️ 可用 | 單實例可用，不支援水平擴展 |
| 使用者資料隔離 | ✅ 安全 | 所有查詢以 user_id 過濾 |
| RBAC | ❌ 未實作 | 角色已定義但未強制執行 |
| 輸入驗證 | ⚠️ 部分 | 營養/健康有驗證，認證無驗證 |
| CORS | ⚠️ 需設定 | 生產環境需明確白名單 |
| 資料庫 TLS | ❌ 停用 | 所有環境均為明文傳輸 |

---

> **結論**: 專案核心架構設計合理，Firebase 認證流程實作完整，資料模型涵蓋完善。但在安全加固、服務層整合、分頁完整性、合規性等方面存在多個必須修復的問題，建議按照上述路線圖分階段處理後再進行商品化發布。
