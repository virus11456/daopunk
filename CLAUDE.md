# CLAUDE.md

本專案是一個 **Godot 專案**。

## 現行設計基準

2026-09-26起，以 `docs/worldbuilding/README.md` 及使用者最新指示為準。故事圍繞機器人算命、最後人類師門、輪迴記憶與夢境宇宙，融入道家思辨；美術採本次GBA像素 × 東方修仙 × 星球賽博龐克。Blender及Godot是製作工具方向。

舊玩法全部退役，新玩法未定案。`docs/design/`、舊卡牌圖鑑及現有程式只供歷史追溯；不得因舊程式仍存在而恢復卡牌、Tactical Pause或其他舊規格。

現有工程是Godot 4.3（4.x）／typed GDScript歷史原型，主場景為 `res://world/Main.tscn`。本次世界觀並未全部接入程式。

## 如何執行 / 測試

```bash
godot --path .                              # 開始遊戲
godot --headless --editor --quit            # 匯入 + 解析檢查
godot --headless --path . --quit-after 200  # headless 實跑（應無錯誤）
godot --headless --path . tests/Smoke.tscn  # 整合冒煙測試（印出 PASS/FAIL）
```

任何改動後，請跑上述三項確認無 parser / runtime 錯誤，且 Smoke 測試全 PASS。

## 專案結構

```
autoload/        全域單例：GameState、TimeManager、ItemDatabase、Reincarnation、ObserverSystem
characters/      Player 與 NPC（共用 components/：Inventory/Equipment/FiveArts/Wallet/Interactable）
items/           ItemData / WeaponData / ConsumableData（Resource）+ .tres 物品 + ItemPickup
world/           WorldMap（程式生成地面）、Region（建地面/建築/導航）、Main.tscn
ui/              Hud、DebugOverlay、DialoguePanel、MenuPanel 及 inventory/character/shop、InteractionMenu
systems/         FortuneService（算命）等玩法系統
data/            dialogue/*.json（對話樹）、skills/five_arts.json（五術資料）
tests/           Smoke.gd/.tscn（headless 整合測試）
```

## 開發慣例

- typed GDScript、function 短、class 職責單一、用 signal 解耦。
- gameplay 資料優先用 Godot **Resource**（`.tres`）與 JSON，不 hardcode 在 script。
- Player / NPC **共用 component**，不要各寫一套。
- 不做巨型 GameManager；`GameState` 只放共用參照與事件匯流排。
- 不在 `_process()` 做昂貴搜尋；NPC AI 用計時器間隔決策，不每 frame 決策。
- 新增功能請一併擴充 `tests/Smoke.gd` 的檢查。

## 更新與後續工作

- 故事定案時同步對應世界觀文件與 `docs/worldbuilding/authority.json`，並在根 `CHANGELOG.md` 留下日期、变更、退役內容與驗證結果。
- 清楚區分使用者確認、作者提案及尚待解答的伏筆；不要把來源缺漏自動補成既定事實。
- 過往K階段只代表歷史原型，舊路線不再自動適用。新系統實作之前先取得明確的新玩法設計。
- 工具不可用時如實記錄未執行的驗證，不把過往測試數字作本次結果。
