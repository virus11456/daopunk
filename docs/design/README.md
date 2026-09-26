# 新版本設計與完成狀態

> 最新擴充：[五術 15 分支、45 卡](../art-direction/five-arts-v2/README.md)、[隨機與升級平衡](CARD_PROGRESSION_BALANCE.md)、[40 星球與 100 城鎮](world-100/README.md)、[99 歲／抹殺／永久仙術邊界](REINCARNATION_CANON_V2.md)。下表早期卡圖數量以新文件為準。

目標：GBA 像素肉鴿，Godot + Blender。設計文件與現行可玩原型分開標示。

| 項目 | 已完成 | 尚缺 |
|---|---|---|
| [肉鴿核心](ROGUELITE_LOOP.md) | 循環、重置／繼承與城市路線原則 | 輪長、終點、生成權重、可玩整輪驗證 |
| [五術](../art-direction/cards-items/FIVE_ARTS.md) | 五職業方向、修行分支、30 招轉譯與概念卡圖 | 完整卡池、戰鬥平衡、Godot 卡牌系統 |
| [十大宇宙](../art-direction/universes/README.md) | 10 張代表場景、[40 張完整配置概念圖](../art-direction/cities/README.md) | 區塊圖集、新增星球城市、可玩地圖 |
| [十大道主席位](DAO_RULERS.md) | 10 位道主（含導師）概念圖＋1 張揭露前意象已入庫 | 動畫、正式素材、完整對話、實作與數值 |
| [星主](PLANET_LORDS.md) | 固定稱號、隨機姓名規則；[首批 20 稱號](PLANET_LORD_CATALOG.md)、10 組姓名池及交接提案 | 星名提案確認、角色美術、事件腳本、平衡與實作 |
| [星球網絡](PLANET_NETWORKS.md) | 每宇宙 4 星與 1 主星；40 稱號、60 貿易航線、30 政治關係提案 | 新星城市、跨宇宙外交、具體數值、實作 |
| [生活世界與 NPC AI](LIVING_WORLD_AND_NPCS.md) | 跨世演進、隨機事件、個體作息、需求、AI 對話權限與回退設計 | 排程實作、完整角色時間表、模型選型、持久存檔與測試 |
| [新聞與商隊消息](NEWS_AND_RUMORS.md) | 三種消息管道、傳播延遲、查證、更正與 AI 邊界 | 新聞介面、傳播排程、事件模板與實作 |
| [模組城市](MODULAR_CITIES.md) | 固定城市身分、每輪區塊重組、地址錨點與連通約束 | 區塊圖集、生成器、導航、跨世遷址測試 |
| 核心角色 | [5 位首版概念圖已入庫](../art-direction/characters/README.md) | 正式素材、動畫、劇情分支 |
| [房屋](HOUSING_AND_REINCARNATION.md) | 購屋、來訪、舊居、封存規則 | 室內圖、介面、存檔與系統實作 |
| [卡牌與道具](../art-direction/cards-items/README.md) | 40 種卡牌、17 道具概念圖 | 獨立透明素材、共通／敵人／狀態牌擴充 |
| 夢境與結局 | 保留既有來源索引 | 底層結構、鯤鵬是否存在、四結局觸發條件 |
| 製作整合 | 既有即時探索與戰鬥原型 | 新肉鴿版本、Blender 來源、可玩美術、持久存檔 |

「草案完成」不等於正史全部定案；「圖已生成」不等於遊戲素材已接入。新增設定保留來源與提案標記。

其他規格：[購屋星球](HOUSING_PLANETS.md) · [東方賽博與跨星勢力](EASTERN_CYBERPUNK_FACTIONS.md) · [卡牌戰鬥流程](CARD_BATTLE_FLOW.md) · [導師身分揭露](MASTER_REVEAL.md)。
