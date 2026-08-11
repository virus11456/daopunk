# 灰谷（Grey Valley）— 2D 半開放世界 RPG

一款以 **Godot 4.3 + GDScript** 開發的 2D 高角度俯視、半開放世界 RPG。設計上僅
把 RimWorld 當作**高層次**參考（俯視 tile 世界、簡潔小型的角色、系統化模擬）——
本專案的美術、名稱、世界觀與程式碼全部為原創 placeholder。

目前進度：**Milestone 1（探索原型）+ Phase 2（核心 RPG 層）**。戰鬥、健康／部位
系統、Tactical Pause 屬於 **Phase 3**，尚未實作。

---

## 如何執行

用 Godot 4.3（或更新的 4.x）開啟專案後按 **F5**，或用指令：

```bash
godot --path .
```

### 操作

| 輸入 | 動作 |
|------|------|
| `W A S D` / 方向鍵 | 移動 |
| `Shift` | 奔跑（消耗體力） |
| `Ctrl` | 潛行（減速） |
| `E` | 互動 / 對話 / 拾取（也可關閉對話） |
| `I` | 開關背包 |
| `Tab` | 開關角色資訊（技能） |
| 滑鼠滾輪 | 縮放鏡頭 |
| 左鍵（開啟 debug 時） | 檢視游標下的 NPC |
| `F1` | 切換 debug 疊層 |
| `Esc` | 關閉對話 / 選單 |

出生在灰谷鎮中央。走近村民按 **E** 對話；地上的方塊是可拾取物品；找 **Doran**
（雜貨店）對話選 **[Trade]** 開商店買賣。背包裡武器可裝備、消耗品可使用。交易會
提升 Trading 技能，技能越高買越便宜、賣越貴。

---

## 已完成內容

**Milestone 1 — 探索基礎**
- 專案結構 + Autoload（`GameState`、`TimeManager`、`ItemDatabase`）
- `Player`：WASD 移動、奔跑、潛行、可縮放鏡頭、體力
- 程式生成的 tile 地面 + 執行期烘焙、繞開建築的 `NavigationRegion2D`
- `Npc`：Idle / Wander / Talk 狀態機（`NavigationAgent2D` 自主走動）
- 統一 `InteractableComponent`（E 互動）+ 資料驅動分支 `DialoguePanel`
- `Hud`、`F1` `DebugOverlay`

**Phase 2 — 核心 RPG 層**
- **物品 Resource**：`ItemData` / `WeaponData` / `ConsumableData`，具體物品為 `.tres`
- **背包** `InventoryComponent`：堆疊、容量、增減查詢（Player/NPC 共用）
- **裝備** `EquipmentComponent`：武器槽，裝備／卸下與背包連動
- **技能** `SkillComponent`：9 種技能、0–20、透過使用成長
- **金錢** `WalletComponent`：Player 與 NPC 各自持有
- **對話擴充**：節點／選項支援 `conditions`（旗標、物品、金錢、技能門檻）與
  `effects`（give_item / remove_item / add_money / set_flag / add_skill_xp / open_shop）
- **商店** `ShopPanel`：買賣，價格隨 Trading 技能浮動並回饋經驗
- **世界拾取** `ItemPickup`：地上物品，重用互動系統
- UI：背包（I）、角色（Tab）、商店，皆走統一的 `MenuPanel` 基底

---

## 架構與主要 class

```
res://
├── project.godot            輸入對應、autoload、主場景
├── autoload/
│   ├── GameState.gd         全域參照、對話/商店事件匯流排、世界旗標
│   ├── TimeManager.gd       遊戲時鐘、time_scale
│   └── ItemDatabase.gd      以 id 註冊所有物品資源
├── characters/
│   ├── components/          Player 與 NPC 共用的元件
│   │   ├── InteractableComponent.gd
│   │   ├── InventoryComponent.gd
│   │   ├── EquipmentComponent.gd
│   │   ├── SkillComponent.gd
│   │   └── WalletComponent.gd
│   ├── player/Player.gd/.tscn
│   └── npc/Npc.gd/.tscn      含商人（is_merchant / shop_stock）
├── items/
│   ├── ItemData.gd          基底 Resource
│   ├── weapons/WeaponData.gd + knife/wooden_club/revolver/shotgun/rifle .tres
│   ├── consumables/ConsumableData.gd + bandage/canned_food/water .tres
│   ├── equipment/*.tres
│   └── ItemPickup.gd/.tscn   世界拾取物
├── world/
│   ├── WorldMap.gd          程式生成 TileMapLayer + TileSet
│   ├── Region.gd            建地面、建築、烘焙導航
│   └── Main.tscn            可玩場景
├── ui/
│   ├── MenuPanel.gd         全螢幕選單基底（切換、互斥、Esc、in_menu）
│   ├── hud/Hud.gd + DebugOverlay.gd
│   ├── dialogue/DialoguePanel.gd   條件 + 效果
│   ├── inventory/InventoryPanel.gd
│   ├── character/CharacterPanel.gd
│   └── shop/ShopPanel.gd
├── data/dialogue/*.json     對話樹
└── tests/Smoke.gd/.tscn     headless 整合測試（21 項檢查）
```

已遵守的設計原則：

- **不做巨型 manager。** 邏輯拆進單一職責的元件；`GameState` 只保存共用參照、事件
  匯流排與世界旗標。
- **Component 化，Player 與 NPC 共用。** 背包／裝備／技能／錢包對兩者是同一套元件。
- **Resource / 資料驅動。** 物品是 `.tres`；對話、商店庫存、起始裝備都以 id 引用，
  不寫死路徑。
- **UI 解耦。** 實體透過 signal 匯流排請求對話／商店，從不引用 UI 節點。
- **AI 顧及效能。** NPC 只在閒置且計時器到期時才重新決策。

### 驗證可執行

```bash
godot --headless --editor --quit                 # 匯入 + 解析檢查
godot --headless --path . --quit-after 240       # headless 實跑（無錯誤）
godot --headless --path . tests/Smoke.tscn        # 整合測試：21 項全 PASS
```

---

## 下一個 milestone

**Phase 3 — 戰鬥與健康**：`HealthComponent` + 部位系統（Head/Torso/Arms/Legs）、
近戰與一種槍械、受傷／流血／昏迷／死亡、以及 **Tactical Pause**（Space 暫停下令）。
NPC 死亡後世界狀態需保留（商店關閉、任務失效等），為 Phase 5/6 的任務與存檔鋪路。
