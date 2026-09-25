# 灰谷（Grey Valley）— 2D 半開放世界 RPG

> 新美術與玩法設計：[十大宇宙 GBA 像素主視覺](docs/art-direction/universes/README.md)、[五術職業與修行樹](docs/art-direction/cards-items/FIVE_ARTS.md)、[卡牌／道具圖鑑](docs/art-direction/cards-items/README.md)、[房產與跨輪迴舊居](docs/design/HOUSING_AND_REINCARNATION.md)。以下為現有可玩原型狀態；新設計尚未接入遊戲。

一款以 **Godot 4.3 + GDScript** 開發的 2D 高角度俯視、半開放世界 RPG。**美術風格**
參考 RimWorld 的高層次理念（俯視 tile 世界、簡潔小型角色、系統化模擬，全部原創
placeholder）；**玩法內容**採用《Kiro：觀測者之夢》世界觀（五術、十宇宙、功德、
輪迴、世界變動率）。

進度：引擎層（探索、背包/裝備、對話/商店、導航）已完成；內容層正逐步換成 Kiro。
- **K1（已完成）**：五術技能樹（山/醫/命/相/卜）+ 功德、世界變動率資源。
- **K2（已完成）**：世界 reskin 為第一宇宙·歸墟·蔓哈頓深坑星，NPC 換成導師/紅/
  星塵/零號/拾荒者，全中文對話。
- **K3（已完成）**：Kiro 物品（銅錢/量子骰子/功德珠/靈魂水晶/體力藥水/賽博羅盤）、
  算命賺錢經濟（對 NPC 卜算→Credits＋卜術/命術熟練度＋功德）、互動選單（E→對話/算命）。
- **K4（已完成）**：世界變動率（五階觀察者偵測＋自然衰減，HUD 顯示階段）、輪迴繼承
  （功德 50%、五術 100%、靈魂磨損 +1%／世；找導師輪迴、靈魂水晶修復磨損）。
- **K5（已完成）**：戰鬥——部位健康/傷勢/流血/死亡、五行相剋、近戰/槍械、敵人 AI
  （追擊/逃跑）、屍體可搜刮、**玩家死亡＝輪迴**、**Tactical Pause**（Space 暫停下令）。
  **→ 核心可玩循環完整。**
- K6+：其餘九大宇宙、感情/記憶繼承、組織/房產、法則碎片/結局。

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
| `E` | 互動 / 對話 / 拾取 / 搜刮（也可關閉對話） |
| `F` | 攻擊最近的敵人 |
| `Space` | Tactical Pause（暫停世界，點敵人下令攻擊） |
| `I` | 開關背包 |
| `Tab` | 開關角色資訊（五術） |
| 滑鼠滾輪 | 縮放鏡頭 |
| 左鍵（開啟 debug 時） | 檢視游標下的 NPC |
| `F1` | 切換 debug 疊層 |
| `Esc` | 關閉對話 / 選單 |

出生在**歸墟·蔓哈頓深坑星**的深坑中央。走近 NPC 按 **E**（或右鍵）會跳出互動選單，可選
**對話**或**算命**。**導師**（方舟隱修院）談夢境與五術、**紅·二師姐**（破爛一條街）是黑市
商人、**星塵**是革命軍領袖、**零號**是改造人僧侶。找 **紅** 對話選 **[交易]** 開商店。

**算命賺錢**：對任何 NPC 選「算命」，用卜術替他卜卦，獲得 Credits＋卜術/命術熟練度＋功德
（背包有銅錢/量子骰子會更準更值錢，每人有冷卻）。`I` 背包、`Tab` 五術；命術越高買越便宜。

**戰鬥**：地圖上有敵人（掠奪者·刃、觀察者殘影）。`F` 攻擊最近敵人，或 `Space` 暫停後點敵人
下令。傷害走**五行相剋**（玩家土、敵人火/金）；受傷會依部位影響移動/攻擊，流血會致死。殺死
敵人後可 `E` **搜刮**屍體取得武器與財物。**玩家死亡＝輪迴**：重開一世，保留五術、功德減半、
靈魂磨損 +1%。找**導師**也可主動輪迴。

---

## 已完成內容

**Milestone 1 — 探索基礎**
- 專案結構 + Autoload（`GameState`、`TimeManager`、`ItemDatabase`）
- `Player`：WASD 移動、奔跑、潛行、可縮放鏡頭、體力
- 程式生成的 tile 地面 + 執行期烘焙、繞開建築的 `NavigationRegion2D`
- `Npc`：Idle / Wander / Talk 狀態機（`NavigationAgent2D` 自主走動）
- 統一 `InteractableComponent`（E 互動）+ 資料驅動分支 `DialoguePanel`
- `Hud`、`F1` `DebugOverlay`

**核心 RPG 層**
- **物品 Resource**：`ItemData` / `WeaponData` / `ConsumableData`，具體物品為 `.tres`
- **背包** `InventoryComponent`：堆疊、容量、增減查詢（Player/NPC 共用）
- **裝備** `EquipmentComponent`：武器槽，裝備／卸下與背包連動
- **金錢** `WalletComponent`：Player 與 NPC 各自持有
- **對話擴充**：節點／選項支援 `conditions`（旗標、物品、金錢、五術熟練度、功德門檻）
  與 `effects`（give_item / remove_item / add_money / set_flag / add_proficiency /
  add_karma / add_world_variance / open_shop）
- **商店** `ShopPanel`：買賣，價格隨命術熟練度浮動並回饋熟練度
- **世界拾取** `ItemPickup`：地上物品，重用互動系統
- UI：背包（I）、角色（Tab）、商店，皆走統一的 `MenuPanel` 基底

**K1 — 五術 + 功德（Kiro 內容層）**
- **五術** `FiveArtsComponent`：山/醫/命/相/卜，每術有熟練度（使用成長），技能依
  熟練度門檻解鎖；技能資料來自 `data/skills/five_arts.json`（取自 Kiro 設定）
- **功德 / 世界變動率**：`GameState` 上的 run 資源，功德可跨輪迴、變動率招來觀察者
- 角色面板（Tab）顯示五術熟練度與已通技能；HUD 顯示功德

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
│   │   ├── FiveArtsComponent.gd   五術（山/醫/命/相/卜）
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
├── data/
│   ├── dialogue/*.json      對話樹
│   └── skills/five_arts.json 五術技能資料（Kiro 設定）
└── tests/Smoke.gd/.tscn     headless 整合測試（26 項檢查）
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
godot --headless --path . tests/Smoke.tscn        # 整合測試：26 項全 PASS
```

---

## 下一步（Kiro 內容遷移）

- **K2 — 世界 reskin**：場景改為第一宇宙·歸墟·蔓哈頓深坑星（破爛一條街、數據陵墓、
  地心、方舟隱修院），NPC 換成導師、紅、星塵、零號等，改中文對話。
- **K3 — Kiro 物品／算命經濟**、**K4 — 世界變動率與輪迴繼承**、**K5 — 戰鬥（五行相剋、
  觀察者/荒獸敵人、Tactical Pause）**。
