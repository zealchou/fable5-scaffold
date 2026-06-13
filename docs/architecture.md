# 架構：6 環節全生命週期 Scaffold

把模型的「內生推理流程」拆成 Claude Code 生命週期上的 6 個觸發點，每個點掛一道 hook。

```
session 開始
   │
   ├─ 環節 1：載入記憶        [SessionStart]
   │     開機注入專案長期記憶、近期教訓、待辦狀態
   │
使用者發言
   │
   ├─ 環節 2：發言前自我質疑   [UserPromptSubmit]  ← scaffold 的核心
   │     偵測深度任務 → 注入「初稿不是結論，跑 Round 1→2→3 驗證」
   │
模型決定動手
   │
   ├─ 環節 3：動手前驗證       [PreToolUse: Edit|Write]
   │     偵測「建新東西」→ 強制先盤點現有資產（防造輪子）
   │     偵測「系統自述」→ 強制先 ls/grep/跑一次再描述
   │
   ├─ 環節 4：動手後驗證       [PreToolUse: Bash / PostToolUse]
   │     commit 前 → 提示驗證（test? runtime? subject 對齁 staged?）
   │     改 runtime code → 提示 commit 後重啟驗證生效
   │
   ├─ 環節 5：多 agent 編排    （工作模式，非 hook）
   │     規劃 → 對抗式反思 → 串行執行 → 整合
   │
session 收尾
   │
   └─ 環節 6：收尾結晶         [Stop]
         提示記錄「這次學到什麼」，固化成下次能讀到的筆記
```

## 各環節對應的 hook 檔

| 環節 | hook 檔 | 觸發時機 |
|---|---|---|
| 2. 自我質疑 | `hooks/self_challenge_gate.sh` | UserPromptSubmit |
| 3. 防造輪子 | `hooks/asset_inventory_gate.sh` | UserPromptSubmit |
| 3. 自述查證 | `hooks/ls_real_preflight.sh` | UserPromptSubmit |
| 4. commit 前驗證 | `hooks/verify_before_commit.sh` | PreToolUse[Bash] |
| 4. 重啟提示 | `hooks/restart_reminder.sh` | PostToolUse[Bash] |
| 5. 多 agent 編排 | `skills/deep-work` + `skills/adversarial-verify` | 召喚 `/deep-work`、`/adversarial-verify` |
| 6. 收尾結晶 | `hooks/session_retro.sh` | UserPromptSubmit（偵測收尾字眼）|

> 環節 5 不附 hook，改用 **skill**：因為它需要「主動 spawn 子 agent」，hook 結構上做不到（hook 只能注入提示、不能開新 agent）。所以做成可召喚的 `/deep-work`（編排）與 `/adversarial-verify`（對抗驗證）。
> 環節 1（載入記憶）刻意留白：它高度依賴你專案的記憶格式，給範本反而綁死你——下方留設計指引，你自己填。

## 環節 5 多 agent 編排（已做成 skill，下為原理）

難任務的標準分工，靠你在對話裡主動觸發：

1. **規劃者**：一個 agent 把大任務拆成 N 個獨立子任務。
2. **對抗式反思**：拆完後，spawn 一個獨立 agent（最好換個角度/更強 model）審查方案，prompt 它「找這個計畫的漏洞，預設它有 60% 機率漏抓」。
3. **執行者**：逐子任務執行。**動同一 git 樹的要串行**（見 CLAUDE.md 第 7 條）；互不相干的才並行。
4. **整合者**：把結果收斂，重新驗證一次治本是否真的生效（不收「我做完了」的自報，要看真實 evidence）。

## 客製化

- 每個 hook 開頭都有觸發詞變數，改成你領域的字眼。
- 太囉嗦就從 `settings.json` 移除個別 hook。
- hook 全部是「提示注入」（advisory），不會 block 你的操作——它們只是在對的時機把該想的事推到模型眼前。
