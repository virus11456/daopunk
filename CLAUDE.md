# CLAUDE.md

本專案是一個 **Godot 專案**。

## 專案概述

- **引擎**：Godot 4.3（4.x）+ GDScript（typed）。
- **類型**：2D 高角度俯視、半開放世界 RPG。美術風格參考 RimWorld（俯視 tile、
  小型角色，全部原創 placeholder）；玩法內容採用《Kiro：觀測者之夢》世界觀
  （五術、十宇宙、功德、輪迴、世界變動率）。
- **主場景**：`res://world/Main.tscn`。

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

## 開發路線（Kiro 內容遷移）

已完成：引擎層、K1 五術+功德、K2 歸墟世界+Kiro NPC、K3 Kiro 物品+算命經濟、
K4 世界變動率+輪迴繼承。下一步 K5：戰鬥（五行相剋、傷勢/流血/死亡）+ Tactical Pause。
