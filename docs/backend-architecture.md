# Nutri 後端架構設計文件（V2 — 上架版）

> **策略：** 移除 AI 助理功能，聚焦核心營養追蹤上架。
> AI 助理（可愛動物 IP）列入 Phase 2 獨立開發。
> 後端採用 **Firebase + 自建 API 混合架構**。

---

## 1. 系統總覽架構（Firebase 混合模式）

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐   │
│  │   iOS App    │    │  watchOS App │    │  Admin Panel     │   │
│  │  (SwiftUI)   │    │  (未來)       │    │  (未來/React)    │   │
│  └──────┬───────┘    └──────┬───────┘    └────────┬─────────┘   │
│         └───────────────────┼─────────────────────┘             │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            │                                    │
            ▼                                    ▼
┌───────────────────────┐          ┌──────────────────────────────┐
│                       │          │                              │
│   FIREBASE SERVICES   │          │     自建 API SERVER          │
│   (Google 託管)        │          │     (Node.js / FastAPI)     │
│                       │          │                              │
│  ┌─────────────────┐ │          │  ┌────────────────────────┐  │
│  │ Firebase Auth   │ │          │  │     API Gateway         │  │
│  │                 │ │  JWT     │  │  (Rate Limit + Auth)    │  │
│  │ • Apple Sign In │─┼────────▶│  └───────────┬────────────┘  │
│  │ • 用戶管理      │ │  驗證    │              │               │
│  └─────────────────┘ │          │  ┌───────────┴────────────┐  │
│                       │          │  │                        │  │
│  ┌─────────────────┐ │          │  │  ┌──────────────────┐  │  │
│  │ Cloud Firestore │ │          │  │  │ Nutrition Service│  │  │
│  │                 │ │          │  │  │ 營養記錄 CRUD    │  │  │
│  │ • 用戶偏好設定  │ │          │  │  │ 每日/週/月摘要   │  │  │
│  │ • 通知設定      │ │          │  │  │ 趨勢分析         │  │  │
│  │ • App 設定      │ │          │  │  └──────────────────┘  │  │
│  │ (輕量 key-value)│ │          │  │                        │  │
│  └─────────────────┘ │          │  │  ┌──────────────────┐  │  │
│                       │          │  │  │ Recipe Service   │  │  │
│  ┌─────────────────┐ │          │  │  │ 食譜查詢/篩選    │  │  │
│  │ Firebase        │ │          │  │  │ 收藏管理         │  │  │
│  │ Storage         │ │          │  │  │ 個人化推薦       │  │  │
│  │                 │ │          │  │  └──────────────────┘  │  │
│  │ • 食物照片      │ │          │  │                        │  │
│  │ • 用戶頭像      │ │          │  │  ┌──────────────────┐  │  │
│  │ • 食譜圖片      │ │          │  │  │ Health Service   │  │  │
│  └─────────────────┘ │          │  │  │ HealthKit 同步   │  │  │
│                       │          │  │  │ 健康趨勢報告     │  │  │
│  ┌─────────────────┐ │          │  │  └──────────────────┘  │  │
│  │ FCM             │ │          │  │                        │  │
│  │ (推播通知)       │ │          │  │  ┌──────────────────┐  │  │
│  │                 │ │          │  │  │ Push Service     │  │  │
│  │ • 用餐提醒      │ │          │  │  │ 智慧推播觸發     │  │  │
│  │ • 喝水提醒      │ │          │  │  │ FCM 呼叫         │  │  │
│  │ • 營養提醒      │ │          │  │  └──────────────────┘  │  │
│  └─────────────────┘ │          │  │                        │  │
│                       │          │  └────────────────────────┘  │
│  ┌─────────────────┐ │          │                              │
│  │ Crashlytics     │ │          │  ┌────────────────────────┐  │
│  │ + Analytics     │ │          │  │     PostgreSQL         │  │
│  │                 │ │          │  │  (營養/食譜/健康數據)   │  │
│  │ • 錯誤追蹤      │ │          │  └────────────────────────┘  │
│  │ • 用戶行為      │ │          │                              │
│  └─────────────────┘ │          └──────────────────────────────┘
│                       │
└───────────────────────┘
                              │
┌─────────────────────────────┴───────────────────────────────────┐
│                      EXTERNAL SERVICES                           │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │    Apple      │  │  RevenueCat  │  │   Payment Gateway   │   │
│  │   Services    │  │              │  │   (未來)              │   │
│  │              │  │ • 訂閱驗證    │  │                      │   │
│  │ • APNs 推播  │  │ • Webhook    │  │ • LINE Pay           │   │
│  │ • Sign In    │  │ • 收據驗證    │  │ • Apple Pay          │   │
│  │   驗證       │  │              │  │                      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Firebase vs 自建 分工原則

```
┌──────────────────┬───────────────────┬──────────────────────────┐
│     功能          │   使用 Firebase   │     使用自建 API          │
├──────────────────┼───────────────────┼──────────────────────────┤
│ 用戶認證          │  ✅ Firebase Auth │                          │
│ 用戶偏好/設定     │  ✅ Firestore    │                          │
│ 檔案上傳          │  ✅ Storage      │                          │
│ 推播通知          │  ✅ FCM          │                          │
│ 錯誤追蹤          │  ✅ Crashlytics  │                          │
│ 行為分析          │  ✅ Analytics    │                          │
│ 營養記錄 CRUD     │                   │  ✅ 需要複雜查詢         │
│ 每日/週/月統計    │                   │  ✅ 需要 GROUP BY        │
│ 食譜搜尋/篩選     │                   │  ✅ 需要全文檢索 + JOIN  │
│ 營養趨勢分析      │                   │  ✅ 需要時間序列聚合     │
│ 健康數據同步      │                   │  ✅ 需要跨表關聯查詢     │
│ 智慧推播觸發      │                   │  ✅ 需要邏輯判斷後呼叫   │
│                   │                   │     FCM                  │
└──────────────────┴───────────────────┴──────────────────────────┘
```

---

## 2. 資料庫設計

### 2.1 Firebase Firestore（輕量 key-value 設定）

```
firestore/
├── users/{uid}/
│   ├── settings/
│   │   ├── preferences        # { diet_type, language, theme }
│   │   ├── notifications      # { meal_remind, water_remind, quiet_hours }
│   │   └── onboarding         # { completed, completed_at }
│   └── devices/
│       └── {device_id}        # { push_token, platform, app_version }
```

### 2.2 PostgreSQL（核心業務數據）

```
┌─────────────────────────────────────────────────────────────┐
│              DATABASE SCHEMA (PostgreSQL)                     │
│              移除: chat_sessions, chat_messages               │
└─────────────────────────────────────────────────────────────┘


 ┌──────────────────────┐          ┌──────────────────────────┐
 │       users          │          │     user_profiles        │
 ├──────────────────────┤          ├──────────────────────────┤
 │ id          UUID  PK │──┐      │ id            UUID  PK   │
 │ firebase_uid VARCHAR │  │      │ user_id       UUID  FK ──│──┐
 │  (Firebase Auth UID) │  │      │ display_name  VARCHAR    │  │
 │ email       VARCHAR  │  │      │ avatar_url    VARCHAR    │  │
 │ first_name  VARCHAR  │  │      │ gender        ENUM       │  │
 │ last_name   VARCHAR  │  │      │  (male/female/other)     │  │
 │ role        ENUM     │  │      │ birth_date    DATE       │  │
 │  (user/admin)        │  │      │ height_cm     DECIMAL    │  │
 │ is_premium  BOOLEAN  │  │      │ weight_kg     DECIMAL    │  │
 │ created_at  TIMESTAMP│  │      │ activity_level ENUM      │  │
 │ updated_at  TIMESTAMP│  │      │  (sedentary/light/       │  │
 │ deleted_at  TIMESTAMP│  │      │   moderate/active/       │  │
 └──────────────────────┘  │      │   very_active)           │  │
                           │      │ diet_type     ENUM       │  │
                           │      │  (standard/vegetarian/   │  │
                           │      │   vegan/keto/            │  │
                           │      │   mediterranean/         │  │
                           │      │   low_carb)              │  │
                           │      │ calorie_goal  INTEGER    │  │
                           │      │ allergies     TEXT[]     │  │
                           │      │ updated_at    TIMESTAMP  │  │
                           │      └──────────────────────────┘  │
     ┌─────────────────────┘                                    │
     │                                                          │
     │                             ┌──────────────────────────┐ │
     │                             │  nutrition_goals         │ │
     │                             ├──────────────────────────┤ │
     │                             │ id            UUID  PK   │ │
     │                             │ user_id       UUID  FK ──│─┘
     │                             │ calories      INTEGER    │
     │                             │ protein_g     DECIMAL    │
     │                             │ carbs_g       DECIMAL    │
     │                             │ fat_g         DECIMAL    │
     │                             │ fiber_g       DECIMAL    │
     │                             │ sugar_g       DECIMAL    │
     │                             │ sodium_mg     DECIMAL    │
     │                             │ water_ml      INTEGER    │
     │                             │ effective_date DATE      │
     │                             │ updated_at    TIMESTAMP  │
     │                             └──────────────────────────┘
     │
     │
     │  ┌──────────────────────────────────────────────────────┐
     │  │                   food_entries                        │
     │  ├──────────────────────────────────────────────────────┤
     ├─▶│ id              UUID       PK                        │
     │  │ user_id         UUID       FK → users.id             │
     │  │ meal_type       ENUM       (breakfast/lunch/dinner/  │
     │  │                             snack)                    │
     │  │ food_name       VARCHAR(200)                         │
     │  │ portion_size    DECIMAL                               │
     │  │ portion_unit    VARCHAR(20) (g / ml / 份)            │
     │  │ image_url       VARCHAR     (Firebase Storage URL)   │
     │  │ source          ENUM        (manual/barcode)         │
     │  │ ──── 巨量營養素 ────                                  │
     │  │ calories        DECIMAL                               │
     │  │ protein_g       DECIMAL                               │
     │  │ carbs_g         DECIMAL                               │
     │  │ fat_g           DECIMAL                               │
     │  │ fiber_g         DECIMAL                               │
     │  │ sugar_g         DECIMAL                               │
     │  │ ──── 微量營養素 ────                                  │
     │  │ sodium_mg       DECIMAL                               │
     │  │ potassium_mg    DECIMAL                               │
     │  │ calcium_mg      DECIMAL                               │
     │  │ iron_mg         DECIMAL                               │
     │  │ zinc_mg         DECIMAL                               │
     │  │ vitamin_c_mg    DECIMAL                               │
     │  │ vitamin_d_mcg   DECIMAL                               │
     │  │ ──── 時間戳記 ────                                    │
     │  │ eaten_at        TIMESTAMP   (實際進食時間)             │
     │  │ created_at      TIMESTAMP                             │
     │  │ updated_at      TIMESTAMP                             │
     │  │                                                       │
     │  │ INDEX: (user_id, eaten_at)                            │
     │  │ INDEX: (user_id, meal_type, eaten_at)                 │
     │  └──────────────────────────────────────────────────────┘
     │
     │
     │  ┌──────────────────────────────────────────────────────┐
     │  │              daily_nutrition_summary                   │
     │  ├──────────────────────────────────────────────────────┤
     ├─▶│ id              UUID       PK                        │
     │  │ user_id         UUID       FK → users.id             │
     │  │ date            DATE                                  │
     │  │ total_calories  DECIMAL                               │
     │  │ total_protein   DECIMAL                               │
     │  │ total_carbs     DECIMAL                               │
     │  │ total_fat       DECIMAL                               │
     │  │ total_fiber     DECIMAL                               │
     │  │ total_sugar     DECIMAL                               │
     │  │ total_sodium    DECIMAL                               │
     │  │ total_water_ml  INTEGER                               │
     │  │ entry_count     INTEGER                               │
     │  │ goal_met        BOOLEAN                               │
     │  │ score           INTEGER    (0-100 營養得分)            │
     │  │ updated_at      TIMESTAMP                             │
     │  │                                                       │
     │  │ UNIQUE: (user_id, date)                               │
     │  └──────────────────────────────────────────────────────┘
     │
     │
     │  ┌───────────────────────┐       ┌────────────────────────┐
     │  │      recipes          │       │   recipe_tags          │
     │  ├───────────────────────┤       ├────────────────────────┤
     │  │ id         UUID   PK │──┬───▶│ recipe_id  UUID  FK    │
     │  │ name       VARCHAR   │  │    │ tag        ENUM        │
     │  │ description TEXT     │  │    │  (low_calorie,         │
     │  │ image_url  VARCHAR   │  │    │   high_protein,        │
     │  │ calories   INTEGER   │  │    │   vegetarian, vegan,   │
     │  │ cooking_time_min INT │  │    │   keto, gluten_free,   │
     │  │ difficulty ENUM      │  │    │   omega3, dairy_free)  │
     │  │  (easy/medium/hard)  │  │    │                        │
     │  │ servings   INTEGER   │  │    │ UNIQUE: (recipe_id,tag)│
     │  │ price_ntd  DECIMAL   │  │    └────────────────────────┘
     │  │ protein_g  DECIMAL   │  │
     │  │ carbs_g    DECIMAL   │  │    ┌────────────────────────┐
     │  │ fat_g      DECIMAL   │  │    │  recipe_ingredients    │
     │  │ fiber_g    DECIMAL   │  │    ├────────────────────────┤
     │  │ steps      JSONB     │  ├───▶│ id         UUID  PK   │
     │  │ is_published BOOLEAN │  │    │ recipe_id  UUID  FK   │
     │  │ created_at TIMESTAMP │  │    │ name       VARCHAR    │
     │  │ updated_at TIMESTAMP │  │    │ amount     VARCHAR    │
     │  └───────────────────────┘  │    │ unit       VARCHAR    │
     │                             │    │ sort_order INTEGER    │
     │                             │    └────────────────────────┘
     │                             │
     │                             │    ┌────────────────────────┐
     │                             │    │   user_favorites       │
     ├─────────────────────────────┴───▶├────────────────────────┤
     │                                  │ user_id   UUID  FK    │
     │                                  │ recipe_id UUID  FK    │
     │                                  │ created_at TIMESTAMP  │
     │                                  │                       │
     │                                  │ PK: (user_id,recipe_id)│
     │                                  └────────────────────────┘
     │
     │
     │  ┌──────────────────────────┐
     │  │   health_sync_logs       │
     │  ├──────────────────────────┤
     ├─▶│ id          UUID  PK    │
     │  │ user_id     UUID  FK    │
     │  │ date        DATE        │
     │  │ steps       INTEGER     │
     │  │ active_cal  DECIMAL     │
     │  │ weight_kg   DECIMAL     │
     │  │ heart_rate  INTEGER     │
     │  │ sleep_hours DECIMAL     │
     │  │ synced_at   TIMESTAMP   │
     │  │                         │
     │  │ UNIQUE: (user_id, date) │
     │  └──────────────────────────┘
     │
     │
     │  ┌──────────────────────────┐
     │  │     push_logs            │
     │  ├──────────────────────────┤
     └─▶│ id         UUID  PK     │
        │ user_id    UUID  FK     │
        │ type       ENUM         │
        │  (meal_remind/water/    │
        │   nutrition_alert/      │
        │   weekly_report)        │
        │ title      VARCHAR      │
        │ body       TEXT         │
        │ status     ENUM         │
        │  (sent/delivered/       │
        │   failed/clicked)       │
        │ sent_at    TIMESTAMP    │
        │ clicked_at TIMESTAMP    │
        └──────────────────────────┘
```

### 2.3 資料表關聯圖（簡化版）

```
                    ┌────────────┐
                    │   users    │
                    └─────┬──────┘
                          │ 1
          ┌───────────────┼───────────────────────┐
          │               │                       │
          │ 1             │ 1                     │ 1
   ┌──────┴───────┐ ┌────┴──────────┐  ┌────────┴─────────┐
   │user_profiles │ │nutrition_goals│  │health_sync_logs  │
   └──────────────┘ └───────────────┘  └──────────────────┘
          │
          │
          │ N                  N                    N
   ┌──────┴───────┐  ┌────────┴─────────┐  ┌──────┴──────┐
   │ food_entries  │  │ user_favorites   │  │ push_logs   │
   └──────────────┘  └────────┬─────────┘  └─────────────┘
          │                   │
          │ aggregated        │ M
          ▼                   ▼
   ┌──────────────┐  ┌──────────────┐
   │daily_nutri.  │  │   recipes    │
   │  _summary    │  └──────┬───────┘
   └──────────────┘         │
                      ┌─────┼─────┐
                      │ 1:N │     │ 1:N
               ┌──────┴──┐ ┌┴────────────┐
               │recipe_  │ │recipe_      │
               │tags     │ │ingredients  │
               └─────────┘ └─────────────┘
```

---

## 3. API 端點設計（移除 AI Chat 模組）

### 3.1 認證模組 `/api/v1/auth`

```
┌──────────┬─────────────────────────┬──────────────────────────────┐
│  Method  │  Endpoint               │  Description                 │
├──────────┼─────────────────────────┼──────────────────────────────┤
│  POST    │ /auth/register          │ Firebase Token 驗證+建立用戶  │
│  POST    │ /auth/login             │ Firebase Token 驗證+登入      │
│  POST    │ /auth/logout            │ 清除伺服器端 session          │
│  DELETE  │ /auth/account           │ 刪除帳號 (App Store 合規)     │
└──────────┴─────────────────────────┴──────────────────────────────┘

POST /auth/register
  Headers:  Authorization: Bearer <firebase_id_token>
  Request:  { first_name?, last_name? }
  Response: {
    user: { id, email, first_name, is_premium },
    token: "<server_jwt>"     ← 自建 API 用的 token
  }

  流程:
  1. iOS 端先完成 Firebase Auth (Apple Sign In)
  2. 取得 Firebase ID Token
  3. 送至自建 API 驗證
  4. 自建 API 用 Firebase Admin SDK 驗證 token
  5. 建立/查找 PostgreSQL users 記錄
  6. 回傳自建 JWT 給客戶端
```

### 3.2 用戶模組 `/api/v1/users`

```
┌──────────┬─────────────────────────┬──────────────────────────────┐
│  Method  │  Endpoint               │  Description                 │
├──────────┼─────────────────────────┼──────────────────────────────┤
│  GET     │ /users/me               │ 取得目前用戶資料              │
│  PATCH   │ /users/me               │ 更新用戶基本資料             │
│  GET     │ /users/me/profile       │ 取得詳細 Profile             │
│  PUT     │ /users/me/profile       │ 更新 Profile（身高體重等）    │
│  GET     │ /users/me/goals         │ 取得營養目標                 │
│  PUT     │ /users/me/goals         │ 設定/更新營養目標            │
└──────────┴─────────────────────────┴──────────────────────────────┘

PUT /users/me/profile
  Request: {
    display_name: "小明",
    gender: "male",
    birth_date: "1995-03-15",
    height_cm: 175,
    weight_kg: 68.5,
    activity_level: "moderate",
    diet_type: "mediterranean",
    allergies: ["堅果", "蝦"]
  }
```

### 3.3 營養追蹤模組 `/api/v1/nutrition`

```
┌──────────┬──────────────────────────────┬─────────────────────────┐
│  Method  │  Endpoint                    │  Description            │
├──────────┼──────────────────────────────┼─────────────────────────┤
│  POST    │ /nutrition/entries           │ 新增食物記錄             │
│  GET     │ /nutrition/entries           │ 查詢記錄                │
│          │   ?date=2025-06-15           │   (按日期)              │
│          │   &meal_type=breakfast       │   (按餐別)              │
│  GET     │ /nutrition/entries/:id       │ 單筆記錄詳情             │
│  PATCH   │ /nutrition/entries/:id       │ 修改記錄                │
│  DELETE  │ /nutrition/entries/:id       │ 刪除記錄                │
│  GET     │ /nutrition/summary/daily     │ 當日營養摘要             │
│          │   ?date=2025-06-15           │                         │
│  GET     │ /nutrition/summary/weekly    │ 週營養統計               │
│  GET     │ /nutrition/summary/monthly   │ 月營養統計               │
│  GET     │ /nutrition/trends            │ 長期趨勢（圖表數據）     │
│          │   ?metric=calories           │                         │
│          │   &range=30d                 │                         │
│  POST    │ /nutrition/sync             │ 離線記錄批量同步          │
└──────────┴──────────────────────────────┴─────────────────────────┘

POST /nutrition/entries
  Request: {
    meal_type: "breakfast",
    food_name: "地中海沙拉",
    portion_size: 1,
    portion_unit: "份",
    calories: 320,
    protein_g: 15.2,
    carbs_g: 28.5,
    fat_g: 18.3,
    fiber_g: 5.1,
    sugar_g: 8.2,
    sodium_mg: 380,
    eaten_at: "2025-06-15T08:30:00Z"
  }
  Response: {
    id: "uuid",
    ...entry_data,
    daily_summary: {        ← 順便回傳更新後的當日摘要
      total_calories: 320,
      calorie_goal: 2000,
      progress_pct: 16
    }
  }

GET /nutrition/trends?metric=calories&range=30d
  Response: {
    metric: "calories",
    range: "30d",
    data: [
      { date: "2025-05-17", value: 1850 },
      { date: "2025-05-18", value: 2100 },
      ...
    ],
    average: 1920,
    goal: 2000,
    days_goal_met: 18
  }

POST /nutrition/sync  (離線→上線批量同步)
  Request: {
    entries: [ ...pending_entries ],
    last_sync_at: "2025-06-14T23:00:00Z"
  }
  Response: {
    synced: [ ...confirmed_entries ],
    server_updates: [ ...entries_modified_on_other_devices ]
  }
```

### 3.4 食譜模組 `/api/v1/recipes`

```
┌──────────┬──────────────────────────────┬─────────────────────────┐
│  Method  │  Endpoint                    │  Description            │
├──────────┼──────────────────────────────┼─────────────────────────┤
│  GET     │ /recipes                     │ 食譜列表                │
│          │   ?page=1&limit=20           │   (分頁)               │
│          │   &tags=high_protein,vegan   │   (標籤篩選)           │
│          │   &search=沙拉               │   (關鍵字搜尋)         │
│          │   &sort=calories_asc         │   (排序)               │
│          │   &max_calories=500          │   (熱量上限)           │
│          │   &max_cooking_time=30       │   (時間上限)           │
│  GET     │ /recipes/:id                 │ 食譜詳情 (含食材+步驟)  │
│  GET     │ /recipes/popular             │ 熱門食譜 (按收藏數)     │
│  GET     │ /recipes/recommended         │ 根據營養缺口推薦        │
│  POST    │ /recipes/favorites/:id       │ 加入收藏                │
│  DELETE  │ /recipes/favorites/:id       │ 取消收藏                │
│  GET     │ /recipes/favorites           │ 我的收藏列表            │
└──────────┴──────────────────────────────┴─────────────────────────┘

GET /recipes/recommended
  (後端邏輯: 查詢用戶今日營養缺口 → 匹配食譜標籤)
  Response: {
    gaps: { protein_g: -30, fiber_g: -8 },
    recipes: [
      {
        ...recipe,
        match_reason: "高蛋白 — 補充今日蛋白質缺口"
      }
    ]
  }
```

### 3.5 健康數據模組 `/api/v1/health`

```
┌──────────┬──────────────────────────────┬─────────────────────────┐
│  Method  │  Endpoint                    │  Description            │
├──────────┼──────────────────────────────┼─────────────────────────┤
│  POST    │ /health/sync                 │ 同步 HealthKit 數據     │
│  GET     │ /health/summary              │ 健康摘要                │
│          │   ?date=2025-06-15           │                         │
│  GET     │ /health/trends               │ 健康趨勢                │
│          │   ?metric=steps&range=30d    │                         │
│  GET     │ /health/report/weekly        │ 週報 (營養+運動綜合)    │
└──────────┴──────────────────────────────┴─────────────────────────┘
```

### 3.6 推播通知模組 `/api/v1/notifications`

```
┌──────────┬──────────────────────────────┬─────────────────────────┐
│  Method  │  Endpoint                    │  Description            │
├──────────┼──────────────────────────────┼─────────────────────────┤
│  GET     │ /notifications/settings      │ 取得通知設定 (Firestore)│
│  PUT     │ /notifications/settings      │ 更新通知設定            │
│  GET     │ /notifications/history       │ 推播歷史                │
└──────────┴──────────────────────────────┴─────────────────────────┘
```

---

## 4. 認證流程圖（Firebase Auth 混合模式）

```
┌──────────┐          ┌──────────┐          ┌──────────┐
│ iOS App  │          │ Firebase │          │自建 API  │
└────┬─────┘          └────┬─────┘          └────┬─────┘
     │                     │                     │
     │ 1. Sign in with     │                     │
     │    Apple (系統彈窗)  │                     │
     │────────────────────▶│                     │
     │                     │                     │
     │ 2. Firebase Auth    │                     │
     │    回傳成功          │                     │
     │    + Firebase UID   │                     │
     │◀────────────────────│                     │
     │                     │                     │
     │ 3. 取得 Firebase    │                     │
     │    ID Token         │                     │
     │────────────────────▶│                     │
     │◀────────────────────│                     │
     │                     │                     │
     │ 4. POST /auth/register                    │
     │    Authorization: Bearer <firebase_token> │
     │──────────────────────────────────────────▶│
     │                     │                     │
     │                     │  5. Firebase Admin   │
     │                     │     SDK 驗證 token   │
     │                     │◀────────────────────│
     │                     │────────────────────▶│
     │                     │     ✓ Valid          │
     │                     │                     │
     │                     │  6. 建立 users 記錄  │
     │                     │     (PostgreSQL)     │
     │                     │     產生 server JWT  │
     │                     │                     │
     │ 7. Response                               │
     │    { user, server_token }                 │
     │◀──────────────────────────────────────────│
     │                     │                     │
     │ 8. 存 server_token  │                     │
     │    至 iOS Keychain  │                     │
     │                     │                     │
     │ ═══ 後續 API 請求 ═══                     │
     │                     │                     │
     │ 9. GET /nutrition/entries                 │
     │    Authorization: Bearer <server_token>   │
     │──────────────────────────────────────────▶│
     │                     │                     │
     │ 10. 驗證 server JWT │                     │
     │     提取 user_id    │                     │
     │                     │                     │
     │ 11. Response { data }                     │
     │◀──────────────────────────────────────────│
```

---

## 5. 核心資料流向圖（無 AI）

```
┌─────────────────────────────────────────────────────────────────┐
│                        核心資料流向                               │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │    iOS App   │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
  ┌────────────┐   ┌────────────┐   ┌────────────┐
  │  手動記錄  │   │  食譜瀏覽  │   │ HealthKit  │
  │  食物攝取  │   │  收藏食譜  │   │  數據同步  │
  └─────┬──────┘   └─────┬──────┘   └─────┬──────┘
        │                │                │
        ▼                ▼                ▼
  ┌──────────────────────────────────────────────┐
  │                自建 API Server                │
  │                                               │
  │  ┌─────────────────────────────────────────┐ │
  │  │            Firebase Auth 驗證            │ │
  │  └──────────────────┬──────────────────────┘ │
  │                     │                         │
  │     ┌───────────────┼───────────────┐        │
  │     ▼               ▼               ▼        │
  │ ┌─────────┐  ┌───────────┐  ┌───────────┐   │
  │ │Nutrition│  │  Recipe   │  │  Health   │   │
  │ │Service  │  │  Service  │  │  Service  │   │
  │ │         │  │           │  │           │   │
  │ │ 存記錄  │  │ 查詢/篩選 │  │ 存 HK 數據│   │
  │ │ 算摘要  │  │ 收藏管理  │  │ 算趨勢    │   │
  │ │ 趨勢    │  │ 缺口推薦  │  │           │   │
  │ └────┬────┘  └─────┬─────┘  └─────┬─────┘   │
  │      │             │              │          │
  │      ▼             ▼              ▼          │
  │ ┌────────────────────────────────────────┐   │
  │ │            PostgreSQL                   │   │
  │ │                                         │   │
  │ │  food_entries ─────▶ daily_summary      │   │
  │ │                          │              │   │
  │ │  recipes ◀── user_favorites             │   │
  │ │                          │              │   │
  │ │  health_sync_logs ───────┘              │   │
  │ │                                         │   │
  │ └────────────────────────────────────────┘   │
  │                     │                         │
  │                     ▼                         │
  │  ┌──────────────────────────────────────┐    │
  │  │         Push Service                  │    │
  │  │                                       │    │
  │  │  每日檢查:                            │    │
  │  │  • 用戶今日攝取 < 目標 80% → 提醒    │    │
  │  │  • 蛋白質嚴重不足 → 推薦食譜          │    │
  │  │  • 到達用餐時間 → 提醒記錄            │    │
  │  │                                       │    │
  │  │  呼叫 FCM 送推播 ──────────────────┐ │    │
  │  └──────────────────────────────────┐ │ │    │
  └─────────────────────────────────────┘ │ │    │
                                          │ │    │
                    ┌─────────────────────┘ │    │
                    ▼                       │    │
          ┌──────────────────┐              │    │
          │   Firebase FCM   │◀─────────────┘    │
          │   推播至 iOS App │                    │
          └──────────────────┘                    │
```

---

## 6. 安全設計

```
┌──────────────────────────────────────────────────────────────┐
│                        安全架構                                │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─ 傳輸層 ────────────────────────────────────────────┐     │
│  │ • TLS 1.3 強制 (HTTPS only)                         │     │
│  │ • App Transport Security (iOS 端)                   │     │
│  │ • HSTS Header                                       │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                                │
│  ┌─ 認證層 ────────────────────────────────────────────┐     │
│  │ • Firebase Auth 管理用戶身份                         │     │
│  │ • 自建 API 用 Firebase Admin SDK 驗證 token         │     │
│  │ • Server JWT (15 min TTL) 存 iOS Keychain           │     │
│  │ • 所有 API Key 存後端環境變數                        │     │
│  │   (Firebase config 不含 secret)                     │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                                │
│  ┌─ 應用層 ────────────────────────────────────────────┐     │
│  │ • Rate Limiting:                                     │     │
│  │   - 認證 API: 5 req/min per IP                      │     │
│  │   - 一般 API: 100 req/min per user                  │     │
│  │ • Input Validation (Zod schema)                     │     │
│  │ • Parameterized Queries (防 SQL Injection)          │     │
│  │ • CORS 白名單                                       │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                                │
│  ┌─ 資料層 ────────────────────────────────────────────┐     │
│  │ • PostgreSQL SSL 連線                                │     │
│  │ • Firebase Security Rules 限制 Firestore 讀寫       │     │
│  │ • Firebase Storage Rules 限制檔案存取               │     │
│  │ • 定期備份 (Daily)                                   │     │
│  │ • Soft Delete (deleted_at)                          │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## 7. 離線同步策略

```
┌──────────────────────────────────────────────────────────────┐
│                   離線 → 上線 同步流程                          │
└──────────────────────────────────────────────────────────────┘

  ┌──────────────┐                       ┌──────────────┐
  │   iOS App    │                       │  自建 API +  │
  │ (Core Data   │                       │  PostgreSQL  │
  │  本地快取)    │                       └──────┬───────┘
  └──────┬───────┘                              │
         │                                      │
  [離線狀態]                                     │
         │                                      │
         │  用戶記錄食物                          │
         │  → 存入 Core Data                     │
         │  → 標記 sync_status = "pending"       │
         │                                      │
  [恢復連線]                                     │
         │                                      │
         │  1. 查詢所有 pending 記錄             │
         │                                      │
         │  2. POST /nutrition/sync             │
         │     { entries: [...],                │
         │       last_sync_at }                 │
         │─────────────────────────────────────▶│
         │                                      │
         │                        3. Upsert 記錄 │
         │                           合併衝突    │
         │                           (Last Write │
         │                            Wins)      │
         │                                      │
         │  4. Response                         │
         │     { synced, server_updates }       │
         │◀─────────────────────────────────────│
         │                                      │
         │  5. 更新 Core Data                    │
         │     sync_status = "synced"           │
```

---

## 8. Firebase 設定清單

```
┌──────────────────────────────────────────────────────────────┐
│                   Firebase 專案設定 TODO                       │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  1. Firebase Console 建立專案                                  │
│     □ 專案名稱: nutri-app                                     │
│     □ 啟用 Google Analytics                                   │
│                                                                │
│  2. iOS App 註冊                                              │
│     □ Bundle ID: com.janus.nutri                              │
│     □ 下載 GoogleService-Info.plist                           │
│     □ 加入 Xcode 專案                                         │
│                                                                │
│  3. Firebase Auth                                              │
│     □ 啟用 Apple Sign In provider                             │
│     □ 設定 Apple Services ID                                  │
│     □ 設定 Apple 私鑰 (.p8)                                   │
│                                                                │
│  4. Cloud Firestore                                           │
│     □ 建立資料庫 (production mode)                             │
│     □ 設定 Security Rules:                                    │
│       rules_version = '2';                                    │
│       service cloud.firestore {                               │
│         match /databases/{database}/documents {               │
│           match /users/{uid}/{document=**} {                  │
│             allow read, write:                                │
│               if request.auth != null                         │
│               && request.auth.uid == uid;                     │
│           }                                                   │
│         }                                                     │
│       }                                                       │
│                                                                │
│  5. Firebase Storage                                          │
│     □ 建立 bucket                                             │
│     □ 設定 Storage Rules:                                     │
│       rules_version = '2';                                    │
│       service firebase.storage {                              │
│         match /b/{bucket}/o {                                 │
│           match /users/{uid}/{allPaths=**} {                  │
│             allow read: if request.auth != null;              │
│             allow write:                                      │
│               if request.auth != null                         │
│               && request.auth.uid == uid                      │
│               && request.resource.size < 10 * 1024 * 1024;   │
│           }                                                   │
│           match /recipes/{allPaths=**} {                      │
│             allow read: if request.auth != null;              │
│             allow write: if false;  // admin only             │
│           }                                                   │
│         }                                                     │
│       }                                                       │
│                                                                │
│  6. FCM (Cloud Messaging)                                     │
│     □ 上傳 APNs 認證金鑰 (.p8)                                │
│     □ 設定 APNs Team ID                                       │
│                                                                │
│  7. Crashlytics                                               │
│     □ 啟用 Crashlytics                                        │
│     □ 加入 build phase script                                 │
│                                                                │
│  8. 後端 Firebase Admin SDK                                   │
│     □ 產生 Service Account Key                                │
│     □ 存入後端環境變數 (勿放入 Git)                            │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. 開發階段規劃（上架版）

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  Phase 1 ─ 上架 MVP                                              │
│  (目標: App Store 上架)                                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ □ Firebase 專案建立 + iOS SDK 整合                       │    │
│  │ □ Firebase Auth (Apple Sign In)                         │    │
│  │ □ 自建 API 專案初始化 + PostgreSQL Schema               │    │
│  │ □ Auth 模組 (Firebase token → server JWT)               │    │
│  │ □ 用戶 Profile CRUD                                     │    │
│  │ □ 營養記錄 CRUD + 每日摘要                              │    │
│  │ □ 食譜列表/詳情/搜尋/收藏                               │    │
│  │ □ Firebase Storage (食物照片上傳)                       │    │
│  │ □ iOS 客戶端改接 API (移除 UserDefaults)                │    │
│  │ □ 基本錯誤處理 + Crashlytics                           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  Phase 2 ─ 體驗優化                                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ □ HealthKit 數據同步至後端                               │    │
│  │ □ FCM 推播通知 (用餐/喝水/營養提醒)                     │    │
│  │ □ 營養趨勢分析 (週/月統計圖表)                          │    │
│  │ □ 智慧食譜推薦 (根據營養缺口)                           │    │
│  │ □ 離線模式 (Core Data + 同步)                           │    │
│  │ □ RevenueCat 訂閱整合                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  Phase 3 ─ AI 助理（獨立版本更新）                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ □ 設計可愛動物 IP 角色 (插畫/動畫)                      │    │
│  │ □ 角色人設定義 + 對話語氣設計                           │    │
│  │ □ 後端 AI Proxy (Claude API)                           │    │
│  │ □ 用戶營養 Context 注入 → 個人化建議                    │    │
│  │ □ SSE 串流對話                                          │    │
│  │ □ 對話歷史持久化                                        │    │
│  │ □ AI 食物照片辨識                                       │    │
│  │ □ 角色動畫 + 情緒系統                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
│  Phase 4 ─ 商業化                                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ □ 訂單系統 + 支付整合                                   │    │
│  │ □ 管理後台                                              │    │
│  │ □ 社群功能                                              │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. AI 助理 IP 角色規劃（Phase 3 備忘）

```
┌──────────────────────────────────────────────────────────────┐
│              AI 助理 — 可愛動物 IP 規劃                       │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─ 角色設計方向 ──────────────────────────────────────┐     │
│  │                                                      │     │
│  │  候選動物 IP:                                        │     │
│  │  🐸 小綠蛙 — 延續目前「小綠」概念，綠色=健康        │     │
│  │  🐱 營養貓 — 討喜易傳播，適合貼圖行銷               │     │
│  │  🐰 健康兔 — 吃蔬菜形象，與營養主題契合             │     │
│  │  🦊 營養狐 — 聰明形象，適合「智慧建議」定位         │     │
│  │                                                      │     │
│  │  設計要素:                                           │     │
│  │  • 主色調與 App nutriGreen (#4A7C59) 搭配           │     │
│  │  • 需要多種表情/情緒 (開心/思考/驚訝/加油)          │     │
│  │  • 可延伸為 LINE 貼圖、App Icon 變體               │     │
│  │  • 動畫: Lottie 格式，支援互動動效                  │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
│  ┌─ 功能規劃 ──────────────────────────────────────────┐     │
│  │                                                      │     │
│  │  核心對話:                                           │     │
│  │  • 每日營養建議 (根據當日攝取自動分析)              │     │
│  │  • 食譜推薦對話                                     │     │
│  │  • 健康小知識推送                                   │     │
│  │  • 鼓勵/提醒語氣（非冰冷 AI 感）                   │     │
│  │                                                      │     │
│  │  互動體驗:                                           │     │
│  │  • 拖曳移動（目前已有基礎）                         │     │
│  │  • 點擊觸發隨機動畫                                 │     │
│  │  • 達成營養目標 → 角色開心動畫                      │     │
│  │  • 連續打卡 → 角色進化/換裝                        │     │
│  │                                                      │     │
│  │  後端需求 (Phase 3 才建):                            │     │
│  │  • AI Proxy Server (保護 Claude API Key)            │     │
│  │  • chat_sessions + chat_messages 表                 │     │
│  │  • 用戶營養數據 Context 自動注入                    │     │
│  │  • SSE 串流回覆                                     │     │
│  │  • 對話歷史儲存 + 上下文管理                        │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```
