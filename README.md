# DAOPUNK｜東方修仙 × 星球賽博龐克

> **機器人也能被算命嗎？**

故事從這個疑問開始。主角出身世界僅存的算命門派，是最後的人類後裔之一；同門學成後各自下山，肩負不同使命。主角在累世輪迴中保留自己的全部記憶，與失散的人重逢，也逐步追問命運、生命與世界的真相。

本作以有趣的人物、日常幽默、謎團與選擇後果承載道家思辨。只有人類能學算命，不代表只有人類值得被理解；知道命運，也未必有權替別人決定人生。

## 目前設計基準

**2026-09-26 世界觀重整版**：保留故事背景與本次 GBA 像素美術，先前玩法規格退役；本次確認保留五術，100種仙術消耗各別功德成本取得且跨世保留；戰鬥方式尚未定案。

| 項目 | 現況 |
|---|---|
| 故事 | 已統整世界骨架、人物、師門、輪迴、宇宙真相及四結局方向；補完提案與已確認設定分開 |
| 地理 | 十大宇宙、40 顆代表星球、100 個城市／聚落／街區地點；新增名稱多仍屬提案 |
| 美術 | 復古小比例像素＋現代精緻細節，16×16不設硬上限；東方修仙與星球科技並存 |
| 既有概念圖 | 十宇宙代表場景、16 張人物／道主／意象圖、40 個地點配置；非已完成遊戲素材 |
| 製作工具 | Blender 與 Godot；既有工程為 Godot 4.3／GDScript 歷史原型 |
| 遊戲程式 | 未依本次重整重寫；原型仍執行舊玩法，不能用它判定現行規則 |
| 未完成 | 新玩法、正式像素素材與動畫、鯤鵬新圖、新增60地點圖、完整劇情腳本及新系統實作 |

![已認可的 GBA 像素街區方向](docs/art-direction/assets/gba-scrap-street-v1.png)

最新：[新版街區概念](docs/art-direction/modern-pixel/README.md) · [四季與天氣設計](docs/worldbuilding/SEASONS_AND_WEATHER.md)。

新增：[開發現況與待確認清單](docs/worldbuilding/DEVELOPMENT_STATUS.md) · [能力限制候選](docs/worldbuilding/ABILITY_BOUNDARIES.md) · [100地點氣候生活配置](docs/worldbuilding/CLIMATE_ATLAS.md)。

## 閱讀入口

以下是作者設定，部分文件含世界真相及導師身分劇透。

| 文件 | 用途 |
|---|---|
| [世界觀總入口](docs/worldbuilding/README.md) | 現行資料與版本優先順序 |
| [故事設定總綱](docs/worldbuilding/STORY_BIBLE.md) | 已確認事實、人物關係與待補設定 |
| [開場與最後人類師門](docs/worldbuilding/OPENING_AND_SECT.md) | 機器人算命疑問、同門使命及跨世相認提案 |
| [宇宙結構與四結局](docs/worldbuilding/ENDINGS_AND_COSMOLOGY.md) | 夢境泡泡、邊緣世界、鯤鵬與結局因果 |
| [道家思想與敘事原則](docs/worldbuilding/DAOIST_NARRATIVE.md) | 齊物、夢、無為等思想如何進入具體故事 |
| [人物與十大道主](docs/worldbuilding/CHARACTERS.md) | 身分、性格與人物分歧 |
| [星球與地點名錄](docs/worldbuilding/ATLAS.md) | 地理、地標、產業、政治與貿易 |
| [矛盾檢查](docs/worldbuilding/CONTINUITY_AUDIT.md) | 39項衝突、缺口與寫作邊界及其處理狀態 |
| [現行美術基準](docs/worldbuilding/ART_BIBLE.md) | 最新風格、角色辨識及素材製作限制 |
| [更新紀錄](CHANGELOG.md) | 本次變更、退役範圍、驗證與未決事項 |

## 世界真相（作者版劇透）

十大宇宙是造物主夢中的泡泡，一個泡泡是一個宇宙級世界。宇宙間隙存在邊緣世界，其最底層連著夢境底層；鯤鵬是三大創世生命之一，形態為有翅膀的巨大鯨魚。道主們知道世界的本質，知情者對喚醒、維持沉睡或取代造物主有不同立場。

抹殺只是將人送入輪迴；大部分人會失去前世記憶，主角則記得自己經歷的一切。完整記憶不等於全知。同門相認依相遇狀態而定：留世者可相認，轉生者通常失憶但修行能解鎖記憶，導師始終認得。相認不等於必定幫忙。

四個敘事方向為守護夢境、喚醒真實、弒神奪位與煉假成真。具體因果及代價逐步補完，不把任何一路預先視為標準答案。

## 舊資料與工程

[退役範圍](docs/worldbuilding/RESET_SCOPE.md)包含舊即時／卡牌戰鬥、225卡數量、兩術兼修、技能樹、歷史肉鴿流程、購屋、城市隨機生成及NPC排程等規格。歷史檔案留作追溯；不得自動恢復為現行設計。

如需查看舊工程，可用 Godot 4.3 開啟根目錄的 `project.godot`；操作資料見[歷史原型說明](docs/archive/LEGACY_PROTOTYPE_README.md)。這不是新世界觀版本的可玩驗收。

## 後續更新方式

每次故事定案，同步更新對應文件、[設定權威索引](docs/worldbuilding/authority.json)及 [CHANGELOG](CHANGELOG.md)。紀錄日期、確認／提案狀態、取代哪些舊說法、驗證結果及仍待回答的問題，避免不同版本同時生效。

世界持續前進、主角每世仍為人類已確認；下一批優先釐清轉生耗時與改造後的算命資格、造物主醒／死後眾生的延續、主角記憶例外原因與觀察者權限，再逐步完成開場及同門重逢。

最新能力基準：[100種跨世仙術](docs/worldbuilding/IMMORTAL_ARTS_FRAMEWORK.md)。一般99年為基礎；醫術與換身延壽只限本世，延壽仙術跨世保留。

歸墟最新背景：與我們所在宇宙及地球相連，如今不穩且破碎，原因未知；地球與蔓哈頓深坑星的關係仍待確認。

本批：[十大道主能力詳案](docs/worldbuilding/DAO_RULER_POWERS.md) · [交給Claude的故事提示詞](docs/worldbuilding/CLAUDE_STORY_PROMPT.md)。

中立組織（含殺手組織）可透過新聞與口述持續出現，不要求每世直接接觸：[近況敘事規格](docs/worldbuilding/NEUTRAL_ORGANIZATION_NEWS.md)。

實作準備：[輪迴保存契約](docs/contracts/REINCARNATION_DATA.md)。離線檢查命令：`python3 tools/check_reincarnation_contract.py`，目前17項通過；不是新版Godot遊戲驗收。

已收[Claude第一批A～D故事草稿](docs/story-drafts/claude-batch-01/README.md)，保留原文並附一致性檢查；尚未將新增真相全部定案或接入Godot。

已續收[R01紅篇《一盞燈的高度》](docs/story-drafts/red-r01/README.md)，與第一批S01及未來S02分開管理。

故事續稿：[Z01零號篇《半邊夢》](docs/story-drafts/zero-z01/README.md)已收錄；全部交稿、已答決策與修訂入口見[故事交稿索引](docs/story-drafts/README.md)。

本次續收[X01星塵篇](docs/story-drafts/stardust-x01/README.md)、[D01首次死亡](docs/story-drafts/death-d01/README.md)、[S02紅重逢v2](docs/story-drafts/red-reunion-s02-v2/README.md)、[M01大師兄篇](docs/story-drafts/elder-m01/README.md)及[F01四師姐篇](docs/story-drafts/fourth-sister-f01/README.md)：共36場原稿與66項文本檢查，附逐篇Claude修訂提示；尚未定稿或接入Godot。

續收[Y01閻羅X篇《未交接》](docs/story-drafts/yanluo-y01/README.md)：七場原稿、14項檢查及修訂提示。交接印、封存權限及棋局仍是提案；未授予新法則或接入Godot。

統整交接：[給Claude的九篇全稿整理指令](docs/story-drafts/CLAUDE_CONSOLIDATION_PROMPT.md) · [跨篇故事資料契約](docs/contracts/STORY_EVENT_DATA.md) · [製作工作清單](docs/production/STORY_PRODUCTION_PLAN.md)。本批完成文件與依賴盤點，尚未接入引擎。

故事更新：[共同年表及五篇新版](docs/story-drafts/revisions-batch-01/README.md)已收錄，另附16項二次檢查與續修提示。這批以原稿修訂補丁交付，未經作者定案的人口／回歸方案仍保持待定。

最新故事背景：[《燈還掛著》v1.2](docs/story-drafts/background-v1.2/README.md)，已收17項稿內決定與15項連貫性檢查；仍需補齊引用母稿，未視為完整可玩劇本。另新增[NPC知識與秘密分層](docs/contracts/NPC_KNOWLEDGE_BOUNDARIES.md)。

新增[山海探索圖鑑](docs/worldbuilding/SHANHAI_EXPLORATION_CODEX.md)：古籍是遊戲內的宇宙探索紀錄，最早宇宙不只十個；圖鑑允許缺頁、過時與互相矛盾的見聞。[交給Claude的下一批](docs/story-drafts/background-v1.2/NEXT_WRITING_PROMPT.md)。

最新：[山海經v1.1](docs/story-drafts/shanhai-v1.1/README.md)已更新三項決定；[NPC生活離線模型](docs/contracts/NPC_LIFE_DATA.md)通過14項檢查，尚未接入Godot。

[山海圖鑑設計v1.1](docs/story-drafts/shanhai-codex-v1.1/README.md)：開局上百條未見經文、不收一般人物、師父批註提供另一線索路徑已定；內容與圖像尚待逐條製作。

NPC美術進度：[1000位居民圖庫](docs/art-direction/npc-1000/README.md)。目前2位有圖、4個版本，正式驗收0位；v2仍待像素修整，尚有998位未生成。

NPC第二批修訂：修理工v3已保存；共2位、5個版本，正式驗收仍為0位，均勻像素格與漸層修整尚未達標。

NPC第三批：修理工v4為描述重繪試驗，2位共6版本、正式驗收0；像素後製方式待使用者回覆。

## 最新主線v2：肉鴿階段结构

[現行主線v2](docs/story-drafts/main-v2/README.md)確認肉鴿定位、取消固定三世與必死事件；世界持續惡化但終局由玩家觸發，人類不歸零，第一輪15歲下山、後續14～15歲覺醒開局，正式輪迴不回溯。戰鬥仍未定，旧數值不恢復。[給Claude的修訂提示](docs/story-drafts/main-v2/FOLLOWUP_PROMPT.md)。

最新收稿：[完整背景v1.3](docs/story-drafts/background-v1.3/README.md)已保存，附最新年齡／時限覆蓋與15項檢查。分頭完成[隨機事件契約](docs/contracts/RANDOM_EVENT_DATA.md)22項、[圖鑑證據契約](docs/contracts/CODEX_EVIDENCE_DATA.md)19項離線檢查；未接Godot。[舊稿修改對照](docs/production/MAIN_V2_MIGRATION.md)。

## 最新交付：前10位NPC與山海收稿

NPC已有10位正面靜態設計通過檢查（990位待生成），原稿與固定像素清理版均保留，見[圖庫](docs/art-direction/npc-1000/gallery.html)。

山海第二批[古籍與探索者](docs/story-drafts/shanhai-explorers-v1/README.md)、第三批[兩段支線](docs/story-drafts/shanhai-sidequests-v1/README.md)、第四批上[主線缺頁綱要](docs/story-drafts/main-missing-scenes-v1/README.md)已收稿與檢查，尚非遊戲實作。

## 最新進度：數據陵墓居民與第四批下篇

NPC-0011～0020完成正面靜態設計與像素清理，累計20位，980位待生成。[角色圖庫](docs/art-direction/npc-1000/gallery.html)。[第四批下篇台詞](docs/story-drafts/main-missing-dialogue-v1.1/README.md)與[背景v1.4](docs/story-drafts/background-v1.4/README.md)已收稿；Q11已再次確認維持玩家觸發結局，兩份稿件附定向修訂全文，原件保留。

## NPC進度：沉環京批次

NPC-0021～0030已完成正面靜態設計、40×48像素清理及逐張檢查；累計30位，970位待生成。[圖庫](docs/art-direction/npc-1000/gallery.html)。動畫及Godot整合未完成。

## 最新交付：NPC-0031 與 Y01 v1.1

[角色圖庫](docs/art-direction/npc-1000/gallery.html)累計31位，969位待生成；回收聚落修理工完成40×48清理與檢查。[Y01 v1.1收稿](docs/story-drafts/yanluo-y01-v1.1/README.md)保留原稿並列修訂事項，未接入Godot。

## NPC-0032 與共同年表 v1.1

[搬運員與圖庫](docs/art-direction/npc-1000/gallery.html)：累計32位靜態設計，968位待生成。[共同年表收稿與修正](docs/story-drafts/common-timeline-v1.1/REVIEW.md)：十五歲下山優先，死亡與遺物交接採条件分支。

## NPC百位階段與故事修訂

[圖庫](docs/art-direction/npc-1000/gallery.html)：NPC-0033～0042完成，累計42位。新階段共100位（0033～0132），每批10位，完成累計132位後先停。[共同年表修訂](docs/story-drafts/common-timeline-v1.1/REVISION_v1.2.md)已採本輪確認。開場與紅篇v1.1保留原稿並附檢查。

## NPC百位階段：第二批

NPC-0043～0052已完成靜態設計與像素清理，累計52位。本階段20／100位；[圖庫](docs/art-direction/npc-1000/gallery.html)，下一批從0053接續。

## NPC百位階段：第三批

NPC-0053～0062已完成靜態設計與像素清理，累計62位。本階段30／100位；[圖庫](docs/art-direction/npc-1000/gallery.html)，下一批從0063接續。

## NPC百位階段：第四批

NPC-0063～0072已完成靜態設計與像素清理，累計72位。本階段40／100位；[圖庫](docs/art-direction/npc-1000/gallery.html)，下一批從0073接續。

## 額外10位NPC與零號篇收稿

[額外NPC-0133～0142總覽](docs/art-direction/npc-1000/contact-sheet-0133-0142.png)，累計82位通過靜態檢查；另2位只有原稿。原排程維持40／100，額外批次不占原排程名額。

[零號篇v1.1收稿與修訂清單](docs/story-drafts/zero-z01-v1.1/README.md)，新提案尚未批准，未接Godot。

## 時代與隨機事件池收稿

[時代事件工作修訂與30地點候選](docs/story-drafts/eras-events-v1.1/README.md)：維持玩家觸發四結局，修正世界時限矛盾；300模板配額與地點版本均為待製作提案。

## 燈籍家庭候選收稿

[十戶家庭提案與修訂清單](docs/story-drafts/lamp-families-v1/README.md)：核對8個城市、整理出生至覺醒的家庭變化；四項作者選擇待回覆，未把提案視為正史。

## 燈籍家庭v1.1收稿

[半選擇與親屬限制修訂檢查](docs/story-drafts/lamp-families-v1.1/README.md)：保留v1，十年上限與等待期經驗待確認；更正自動終局引用。


### 八位道主總綱 v1 收稿與修訂
已收錄[總綱摘要與審閱](docs/story-drafts/dao-rulers-v1/README.md)，列出 16 項一致性修訂及給 Claude 的續寫指示。原對話為完整來源；新立場與事件仍為提案，未實作玩法。


### G01 蓋亞篇 v1 收稿
[收稿摘要、16 項審閱與 Claude 修訂指示](docs/story-drafts/gaia-g01-v1/README.md)。重點為 Y01 聯絡與資料用途權限、瀾的自主意願、跨時代授法及玩家觸發結局。新增內容仍為提案，未實作。
