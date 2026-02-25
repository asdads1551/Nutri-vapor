# Nutri Vapor Backend

## 專案概述
Nutri 的後端 API 服務，使用 Swift Vapor 框架開發，提供營養追蹤、食譜管理、健康資料同步等 RESTful API。

## 技術棧
- **框架**: Vapor 4.99+
- **ORM**: Fluent 4.11+
- **資料庫**: PostgreSQL (FluentPostgresDriver 2.9+)
- **認證**: Firebase Admin Token 驗證 + JWT 5.1+ (15 分鐘 TTL)
- **部署**: Docker (docker-compose.yml)

## 專案結構
```
Sources/App/
├── Controllers/     # 路由控制器 (Auth, User, Nutrition, Recipe, Health, Notification)
├── DTOs/            # 資料傳輸物件 (Request/Response)
├── Middleware/       # 中介層 (Firebase 驗證, JWT 驗證, Rate Limiting)
├── Migrations/      # 資料庫遷移 (13 個 migration 檔案)
├── Models/          # Fluent ORM 模型 (13 個)
├── Services/        # 商業邏輯服務 (5 個)
├── Shared/          # 共用常數、列舉
├── configure.swift  # App 初始化設定
├── entrypoint.swift # 進入點
└── routes.swift     # 路由註冊
```

## 前端專案
- **路徑**: `/Users/janus/Nutri`
- **類型**: iOS SwiftUI App
- **Firebase Project**: `nutri-app-c0d75`
- **Bundle ID**: `com.janus.nutri`

## API 路由總覽 (Prefix: `/api/v1`)

### Auth (`/auth`) — 無需 JWT
| 方法 | 路徑 | 說明 |
|------|------|------|
| POST | `/auth/register` | Firebase Token 註冊 |
| POST | `/auth/login` | Firebase Token 登入 |
| POST | `/auth/logout` | 登出 |
| DELETE | `/auth/account` | 刪除帳號 (App Store 合規) |

### Users (`/users`) — 需 JWT
| 方法 | 路徑 | 說明 |
|------|------|------|
| GET | `/users/me` | 取得使用者資訊 |
| PATCH | `/users/me` | 更新使用者資訊 |
| GET/PUT | `/users/me/profile` | 使用者詳細檔案 |
| GET/PUT | `/users/me/goals` | 營養目標設定 |

### Nutrition (`/nutrition`) — 需 JWT
| 方法 | 路徑 | 說明 |
|------|------|------|
| POST | `/nutrition/entries` | 新增食物紀錄 |
| GET | `/nutrition/entries` | 列表 (支援 date/meal 篩選) |
| GET | `/nutrition/entries/:id` | 單筆紀錄 |
| PATCH | `/nutrition/entries/:id` | 更新紀錄 |
| DELETE | `/nutrition/entries/:id` | 刪除紀錄 |
| GET | `/nutrition/summary/daily` | 每日營養摘要 |
| GET | `/nutrition/summary/weekly` | 每週營養摘要 |
| GET | `/nutrition/summary/monthly` | 每月營養摘要 |
| GET | `/nutrition/trends` | 營養趨勢資料 |
| POST | `/nutrition/sync` | 離線同步批次端點 |

### Recipes (`/recipes`) — 需 JWT
| 方法 | 路徑 | 說明 |
|------|------|------|
| GET | `/recipes` | 列表/搜尋/篩選 |
| GET | `/recipes/:id` | 食譜詳情 (含食材、步驟) |
| GET | `/recipes/popular` | 熱門食譜 |
| GET | `/recipes/recommended` | 推薦食譜 |
| POST/DELETE | `/recipes/favorites` | 收藏管理 |

### Health (`/health`) — 需 JWT
| 方法 | 路徑 | 說明 |
|------|------|------|
| POST | `/health/sync` | HealthKit 資料同步 |
| GET | `/health/summary` | 健康摘要 |
| GET | `/health/trends` | 健康趨勢 |
| GET | `/health/weekly-report` | 週報 |

### Notifications (`/notifications`) — 需 JWT
| 方法 | 路徑 | 說明 |
|------|------|------|
| GET/PUT | `/notifications/settings` | 通知偏好設定 |
| GET | `/notifications/history` | 推播歷史紀錄 |

## 資料庫模型
- **User** — Firebase UID, email, 姓名, premium 標記
- **UserProfile** — 身高, 體重, 年齡, 性別, 活動量, 飲食類型, 過敏原
- **NutritionGoal** — 每日巨量/微量營養素目標
- **FoodEntry** — 食物紀錄 (巨量營養素 + 7 種微量營養素)
- **DailyNutritionSummary** — 每日聚合資料與評分
- **Recipe** — 食譜 (名稱, 營養, 烹飪時間, 難度, 價格)
- **RecipeIngredient** — 食材 (名稱, 份量, 單位)
- **RecipeTagModel** — 食譜標籤
- **UserFavorite** — 收藏對應
- **HealthSyncLog** — HealthKit 同步資料
- **PushLog** — 推播紀錄追蹤

## 共用列舉值 (Shared/Enums.swift)
- **MealType**: breakfast, lunch, dinner, snack
- **DietType**: standard, vegetarian, vegan, keto, paleo, mediterranean, lowCarb, highProtein
- **Allergen**: gluten, dairy, nuts, shellfish, soy, eggs
- **RecipeTag**: low_calorie, high_protein, vegan, vegetarian, keto, quick, budget, meal_prep
- **RecipeDifficulty**: easy, medium, hard

## 認證流程
```
iOS App → Apple Sign In → Firebase Auth → Firebase ID Token
    ↓
POST /api/v1/auth/login (帶 Firebase Token)
    ↓
Vapor 後端驗證 Firebase Token → 產生 JWT (15 min TTL)
    ↓
iOS App 使用 JWT 呼叫其他 API
```

## 開發指令
```bash
# 啟動 PostgreSQL
docker-compose up -d

# 執行伺服器
swift run App serve --hostname 0.0.0.0 --port 8080

# 執行測試
swift test

# 資料庫遷移
swift run App migrate
```

## 開發注意事項
- 所有模型使用 Soft Delete (deleted_at)
- 資料庫索引: (user_id, eaten_at), (user_id, meal_type, eaten_at) on food_entries
- CORS 已開啟 (所有來源)
- TLS 1.3 強制啟用
- Sendable 安全: 所有模型標記 `@unchecked Sendable`
- 詳細架構文件見 `docs/backend-architecture.md`
