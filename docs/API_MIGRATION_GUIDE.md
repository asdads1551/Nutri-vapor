# Nutri Backend API 變更指南 (2026-02-28)

> 此文件記錄後端 `Nutri-vapor` 的 API 變更，供前端 iOS App 配合更新。
> 後端分支: `claude/review-system-design-8b8ax`

---

## Breaking Changes

### 1. `POST /api/v1/auth/logout` — 認證方式變更

**Before**: 使用 Firebase Token（Authorization: Bearer <firebase_token>）
**After**: 使用 JWT Token（Authorization: Bearer <jwt_token>）

```
// 前端修改: 登出時改送 JWT，不再送 Firebase Token
POST /api/v1/auth/logout
Authorization: Bearer <jwt_token>

// Response (不變)
{ "success": true, "message": "Logged out successfully" }
```

後端會將該 JWT 加入黑名單，立即失效。

---

### 2. `GET /api/v1/nutrition/entries` — 回傳格式改為分頁

**Before**: 直接回傳陣列 `[FoodEntryResponse]`
**After**: 回傳分頁包裝 `PagedResponse<FoodEntryResponse>`

**新增 Query Parameters**:
| 參數 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `page` | Int | 1 | 頁碼（從 1 開始） |
| `limit` | Int | 20 | 每頁數量（上限由後端 `APIConstants.maxPageSize` 控制） |
| `date` | String | — | 篩選日期 `yyyy-MM-dd`（不變） |
| `meal_type` | String | — | 篩選餐別（不變） |

**Response 格式**:
```json
{
  "data": [FoodEntryResponse],
  "page": 1,
  "per_page": 20,
  "total": 58,
  "total_pages": 3
}
```

---

### 3. `GET /api/v1/recipes/favorites` — 回傳格式改為分頁

**Before**: 直接回傳陣列 `[RecipeListItem]`
**After**: 回傳分頁包裝 `PagedResponse<RecipeListItem>`

**新增 Query Parameters**:
| 參數 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `page` | Int | 1 | 頁碼 |
| `limit` | Int | 20 | 每頁數量 |

**Response 格式**:
```json
{
  "data": [RecipeListItem],
  "page": 1,
  "per_page": 20,
  "total": 12,
  "total_pages": 1
}
```

---

### 4. `FoodEntryResponse` — 欄位變更

**新增欄位** (7 個微量營養素):
```json
{
  "sugar_g": 0.0,
  "sodium_mg": 0.0,
  "potassium_mg": 0.0,
  "calcium_mg": 0.0,
  "iron_mg": 0.0,
  "zinc_mg": 0.0,
  "vitamin_c_mg": 0.0,
  "vitamin_d_mcg": 0.0
}
```

**移除欄位**:
```
"daily_summary": null  ← 已移除，不再回傳
```

**完整 FoodEntryResponse**:
```json
{
  "id": "uuid",
  "meal_type": "早餐",
  "food_name": "雞胸肉",
  "calories": 165.0,
  "protein_g": 31.0,
  "carbs_g": 0.0,
  "fat_g": 3.6,
  "fiber_g": 0.0,
  "sugar_g": 0.0,
  "sodium_mg": 74.0,
  "potassium_mg": 256.0,
  "calcium_mg": 11.0,
  "iron_mg": 0.7,
  "zinc_mg": 0.8,
  "vitamin_c_mg": 0.0,
  "vitamin_d_mcg": 0.0,
  "eaten_at": "2026-02-28T12:00:00Z"
}
```

---

## 前端 Model 更新建議

### Swift FoodEntry Model
```swift
struct FoodEntryResponse: Codable {
    let id: UUID
    let mealType: String
    let foodName: String
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
    let sugarG: Double          // 新增
    let sodiumMg: Double        // 新增
    let potassiumMg: Double     // 新增
    let calciumMg: Double       // 新增
    let ironMg: Double          // 新增
    let zincMg: Double          // 新增
    let vitaminCMg: Double      // 新增
    let vitaminDMcg: Double     // 新增
    let eatenAt: Date
    // dailySummary 已移除

    enum CodingKeys: String, CodingKey {
        case id
        case mealType = "meal_type"
        case foodName = "food_name"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case potassiumMg = "potassium_mg"
        case calciumMg = "calcium_mg"
        case ironMg = "iron_mg"
        case zincMg = "zinc_mg"
        case vitaminCMg = "vitamin_c_mg"
        case vitaminDMcg = "vitamin_d_mcg"
        case eatenAt = "eaten_at"
    }
}
```

### Swift PagedResponse Model
```swift
struct PagedResponse<T: Codable>: Codable {
    let data: [T]
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case data, page, total
        case perPage = "per_page"
        case totalPages = "total_pages"
    }
}
```

### API Client 修改範例
```swift
// Before
func fetchEntries(date: String?) async throws -> [FoodEntryResponse] {
    // GET /api/v1/nutrition/entries?date=2026-02-28
}

// After
func fetchEntries(date: String?, page: Int = 1, limit: Int = 20) async throws -> PagedResponse<FoodEntryResponse> {
    // GET /api/v1/nutrition/entries?date=2026-02-28&page=1&limit=20
}

// Before
func logout() async throws {
    // POST /api/v1/auth/logout with Firebase Token
}

// After
func logout() async throws {
    // POST /api/v1/auth/logout with JWT Token (Bearer header)
}
```

---

## 非 Breaking Changes（向下相容）

這些變更不需要前端修改，但建議了解：

| 端點 | 變更 |
|------|------|
| `GET /nutrition/trends` | 新增 metric 參數驗證，無效值回傳 400 |
| `GET /health/trends` | 同上 |
| `PUT /notifications/settings` | quiet_hours 格式驗證 (`HH:MM`) |
| `POST /auth/register` | firstName/lastName 長度驗證 (1-100 字) |
| 所有 API | Rate limit 超限時回傳 `Retry-After` 標頭 |

---

## 後端環境變數（部署注意）

| 變數 | 必要性 | 說明 |
|------|--------|------|
| `JWT_SECRET` | 生產必填 | 不設定會 fatalError |
| `CORS_ALLOWED_ORIGIN` | 生產建議設定 | 不設定則阻擋所有跨域請求 |
| `DATABASE_URL` 或 `DB_PASSWORD` | 生產必填 | 不設定會 fatalError |
| DB TLS | 自動 | 生產環境自動啟用 TLS 加密 |
