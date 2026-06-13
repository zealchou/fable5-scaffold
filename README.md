# Fable Scaffold — 用外部工程 scaffold 逼近 Fable-5 級工作流

> 把你的 Claude Code（Opus 4.8 或任何 model）包進一層「全生命週期推理 scaffold」，
> 逼近高階模型的**工作流程嚴謹度**：開機載記憶 → 發言前強制自我質疑 → 動手前驗證前提 → 動手後接通驗證 → 收尾結晶。

---

## ⚠️ 先讀這段（誠實 disclaimer，不是免責套話）

**這個專案逼近的是「行為與流程」，不是「智商」。**

- 它**不會**改變你底層 model 的推理能力。Opus 4.8 裝了它還是 Opus 4.8。
- 它做的是：用 Claude Code 的 hook 機制，在每個生命週期節點**強制注入紀律**——逼模型在下結論前自我質疑、在動手前盤點、在 commit 前驗證、在收尾時固化經驗。
- 真實效果：減少「自信地給出沒驗證的答案」「憑記憶描述不存在的東西」「改一處沒查連動」「single-pass 就交付」這類錯誤。在多步驟 coding / 除錯 / 研究任務上，產出的**可靠度**會明顯上升。
- 代價：**更慢、更耗 token**（強制思考 = 多生成）。這是「用算力換嚴謹」的取捨。只在難任務上值得，簡單問答關掉它更好。

**它逼近不了的**：高階 model 內生的洞察深度、一次抓到問題本質的能力、KV cache/並行優化帶來的效率。經驗法則是 **80/20**——能補上 80% 的「流程紀律」差距，剩下 20% 的「原生智商」差距補不了。

> **與 Anthropic 無關**：本專案非 Anthropic 官方產品、不隸屬於 Anthropic。「Fable」「Claude」為 Anthropic 之商標，此處僅作能力對標的描述性引用。本專案不包含任何 Anthropic 模型權重或私有資訊，純粹是 prompt/hook 層的開源工作流模板。

---

## 核心理念：把「內生思考」拆成「外部生命週期觸發點」

高階推理模型之所以可靠，很大一部分是它在回答前做了大量內部的「拆解 → 自我糾錯 → 驗證」。本專案的假設是：**這套內生流程，可以用 Claude Code 的 hook 在外部重建**，拆成 6 個生命週期環節，每個環節掛一個強制 hook：

| 環節 | 時機（Claude Code hook） | 這個 scaffold 做什麼 |
|---|---|---|
| 1. 載入記憶 | `SessionStart` | 開機注入專案長期記憶 / 近期教訓 / 待辦狀態 |
| 2. 發言前自我質疑 | `UserPromptSubmit` | 偵測深度任務 → 強制「初稿不是結論，跑 Round 1→2→3 驗證」 |
| 3. 動手前驗證 | `PreToolUse[Edit\|Write]` | 偵測「建新東西」→ 強制先盤點現有資產（防造輪子）|
| 4. 動手後驗證 | `PreToolUse[Bash]` / `PostToolUse` | commit 前驗證、改 runtime code 後提示重啟驗證 |
| 5. 多 agent 編排 | （工作模式，非 hook）| 規劃 → 對抗式反思 → 串行執行 → 整合 |
| 6. 收尾結晶 | `Stop` | 偵測收尾 → 提示記錄這次學到什麼 |

詳見 [`docs/architecture.md`](docs/architecture.md) 與 [`docs/philosophy.md`](docs/philosophy.md)。

---

## 安裝

```bash
git clone https://github.com/<your-name>/fable-scaffold.git
cd fable-scaffold
./install.sh      # 把 hook 註冊 merge 進你的 ~/.claude/settings.json（會先備份）
```

安裝後：
1. 把 `CLAUDE.md.template` 的內容**挑你認同的**併進你專案的 `CLAUDE.md`（不要照單全收——紀律要你自己認同才有用）。
2. 開新的 Claude Code session，hook 就會在對應時機觸發。
3. 覺得太囉嗦 → 編輯 `~/.claude/settings.json` 移除不要的 hook，或調 hook 內的觸發詞。

## 解除安裝

```bash
./uninstall.sh    # 從 settings.json 移除本專案註冊的 hook，還原備份
```

---

## 緣起：一個被收走的模型，留下的方法

Fable 5 是 Anthropic Mythos 級別的旗艦模型，推理能力在 Opus 之上。它在 2026 年 6 月上線，**三天後——6 月 12 日**——Anthropic 依美國政府的出口管制指令，停止了所有非美國公民（無論身在美國境內或境外）對 Fable 5 與孿生的 Mythos 5 的存取。由於無法即時區分使用者國籍，實務上形同**全球關閉**。對美國以外的我們來說，它就這樣消失了。

> 報導與官方聲明（2026/6/12–13）：
> [Anthropic 官方聲明](https://www.anthropic.com/news/fable-mythos-access) ·
> [CNBC](https://www.cnbc.com/2026/06/12/anthropic-disables-access-to-fable-5-and-mythos-5-to-comply-with-government-directive.html) ·
> [Bloomberg](https://www.bloomberg.com/news/articles/2026-06-13/anthropic-says-us-limits-foreign-access-to-fable-5-mythos-5) ·
> [9to5Mac](https://9to5mac.com/2026/06/12/anthropic-pulls-claude-mythos-5-and-claude-fable-5-following-us-government-directive/)

我剛好在那短短幾天的窗口內，用 Fable 5 完整跑完了一個真實的大型專案——一次跨多天的全系統審計與修復，35+ 個 bug、零資料損失、每個修復都過對抗式驗證。

**模型可以被收走，但它做事的方法不會。** 那次經驗讓我看清：Fable 5 的強，很大一部分不是「天生聰明」，而是它在每一步都極度嚴謹——下結論前先自我質疑、動手前先盤點、commit 前先驗證、收尾時把經驗固化下來。而這套「工作流程的嚴謹度」，可以用 Claude Code 的 hook 在外部重建。

所以趁記憶還新，我把那次專案裡 Fable 5 的工作方式**逆向工程**出來，提煉成這個 repo——讓任何人的 Claude Code（Opus 4.8 或其他還能用的 model）都能套上同一層 scaffold，把那套嚴謹度帶進自己的工作流。

模型被收走了，方法留下來。分享給大家。

> 提煉過程已剔除所有原專案的私有內容，這裡是乾淨的通用模板。能用的是「方法」，不是任何特定專案的資料。

— 周逸達 Zeal Chou


## License

MIT — 隨意 fork、改、商用。詳 [`LICENSE`](LICENSE)。
