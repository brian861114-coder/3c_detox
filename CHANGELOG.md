# FocusFlow 修改紀錄 (Changelog)

---

## 2026-03-12 — 排程功能大幅強化

### 一、排程頁面新增封鎖名單選擇功能

**修改檔案：**
- `lib/models/schedule.dart`
- `lib/providers/language_provider.dart`
- `lib/screens/schedule_screen.dart`

**修改內容：**
1. `FocusSchedule` 模型新增 `blockListId` 欄位（可選，nullable）  
   - 若為 `null`，代表使用當前活躍的封鎖名單（向後相容舊資料）
2. 排程建立表單底部新增「封鎖名單」下拉選單  
   - 可選擇「預設（當前使用中）」或任何已建立的封鎖名單
3. 排程列表中，每筆排程下方顯示所關聯的封鎖名單名稱（帶 🚫 圖示）
4. 新增翻譯 key：`block_list`、`default_list`（支援 EN / 中文 / 日文）

---

### 二、排程啟用/停用開關

**修改檔案：**
- `lib/models/schedule.dart`
- `lib/providers/schedule_provider.dart`
- `lib/screens/schedule_screen.dart`

**修改內容：**
1. `FocusSchedule` 模型新增 `isEnabled` 欄位（預設 `true`）和 `blockListChanged` 欄位（預設 `false`）
2. 新增 `copyWith()` 方法，方便更新不可變物件的個別欄位
3. `ScheduleProvider` 新增方法：
   - `toggleScheduleEnabled(id)` — 切換排程啟用/停用
   - `clearBlockListChangedFlag(id)` — 清除封鎖名單變動警告
4. Schedule 頁面每筆排程右側加入 **Switch 開關**
   - 停用的排程：文字變淡、加刪除線、顯示「已停用」標籤
   - 重新啟用時自動清除警告標記
5. `isCurrentlyInScheduledFocus()` 加入 `isEnabled` 判斷，停用的排程不會觸發專注模式

---

### 三、刪除/修改封鎖名單時的保護機制

**修改檔案：**
- `lib/providers/schedule_provider.dart`
- `lib/providers/language_provider.dart`
- `lib/screens/block_list_db_screen.dart`
- `lib/screens/schedule_screen.dart`

**修改內容：**
1. `ScheduleProvider` 新增方法：
   - `getSchedulesUsingBlockList(blockListId)` — 查詢使用特定封鎖名單的排程
   - `onBlockListChanged(blockListId)` — 自動停用受影響的排程並標記 `blockListChanged = true`
2. `BlockListDbScreen` 新增 `_confirmBlockListAction()` 方法：
   - 刪除、編輯、點擊進入編輯三個入口都有保護
   - 跳出紅色警告對話框，列出所有受影響的排程時間
   - 使用者必須點擊「確認」才能繼續
   - 確認後自動停用相關排程
3. Schedule 頁面：
   - 當排程的封鎖名單被刪除/修改後，名稱變紅、旁邊出現 **紅色驚嘆號** ⚠️
   - 排程卡片邊框變紅色
4. 封鎖名單管理頁面：被排程使用中的名單旁顯示小日曆圖示 📅
5. 新增翻譯 key：`blocklist_in_use_warning`、`blocklist_in_use_desc`、`schedule_disabled`、`blocklist_changed_hint`（三語支援）

---

### 四、排程觸發邏輯優化：自動套用指定封鎖名單

**修改檔案：**
- `lib/providers/schedule_provider.dart`
- `lib/providers/focus_provider.dart`
- `lib/main.dart`

**修改內容：**
1. `ScheduleProvider` 新增 `getCurrentActiveSchedule()` 方法
   - 回傳當前時段匹配的完整 `FocusSchedule` 物件（而不只是 `bool`）
   - `isCurrentlyInScheduledFocus()` 改為呼叫此方法判斷
2. `FocusProvider` 新增：
   - `getBlockListApps(blockListId)` — 取得指定封鎖名單的 apps
   - `startScheduledFocus({durationSeconds, blockListId})` — 以排程指定的時長和封鎖名單啟動專注
3. `main.dart` 排程定時器邏輯更新：
   - 取得觸發排程的完整物件
   - **計算排程剩餘秒數**（非使用者設定的固定時長）
   - 使用 `startScheduledFocus()` 傳入正確的封鎖名單 ID 和持續時間

---

### 五、UI 細節修正

**修改檔案：**
- `lib/screens/schedule_screen.dart`

**修改內容：**
- 「新增排程」按鈕文字顏色改為**白色粗體**（原本因預設主題色太暗導致不易閱讀）
- 設定 `foregroundColor: Colors.white` 及 `TextStyle(color: Colors.white, fontWeight: FontWeight.bold)`

---

### 本次修改涉及的所有檔案一覽

| 檔案 | 修改類型 |
|------|---------|
| `lib/models/schedule.dart` | 新增 `blockListId`、`isEnabled`、`blockListChanged` 欄位，新增 `copyWith()` |
| `lib/providers/schedule_provider.dart` | 新增排程管理方法、排程觸發回傳完整物件 |
| `lib/providers/focus_provider.dart` | 新增 `startScheduledFocus()`、`getBlockListApps()` |
| `lib/providers/language_provider.dart` | 新增 6 個翻譯 key（EN/中文/日文） |
| `lib/screens/schedule_screen.dart` | 全面重構 UI：封鎖名單選擇、開關、警告提示 |
| `lib/screens/block_list_db_screen.dart` | 新增刪除/編輯前警告對話框 |
| `lib/main.dart` | 排程觸發邏輯支援指定封鎖名單和正確時長 |
