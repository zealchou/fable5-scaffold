# Fable Scaffold

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Claude Code](https://img.shields.io/badge/Claude%20Code-hooks-blueviolet)
![Shell](https://img.shields.io/badge/shell-bash-green)
![Bilingual](https://img.shields.io/badge/docs-繁中%20%2F%20EN-blue)

> **用外部工程 scaffold 逼近 Fable-5 級工作流程。**
> 把你的 Claude Code（Opus 4.8 或任何 model）包進一層「全生命週期推理 scaffold」，逼近高階模型的**工作流程嚴謹度**：開機載記憶 → 發言前強制自我質疑 → 動手前驗證前提 → 動手後接通驗證 → 收尾結晶。
>
> **Approximate a Fable-5-grade workflow with an external engineering scaffold.**
> Wrap your Claude Code (Opus 4.8 or any model) in a full-lifecycle reasoning scaffold that approximates the *workflow rigor* of a frontier model: load memory on start → force self-challenge before answering → verify assumptions before acting → verify wiring after acting → crystallize lessons on wrap-up.

---

## ⚠️ 先讀這段（誠實 disclaimer）/ Read This First (an honest disclaimer)

**這個專案逼近的是「行為與流程」，不是「智商」。**
**What this approximates is *behavior and process*, not *intelligence*.**

- 它**不會**改變你底層 model 的推理能力。Opus 4.8 裝了它還是 Opus 4.8。
  It does **not** change your underlying model's reasoning ability. Opus 4.8 with this installed is still Opus 4.8.
- 它做的是：用 Claude Code 的 hook 機制，在每個生命週期節點**強制注入紀律**——逼模型在下結論前自我質疑、動手前盤點、commit 前驗證、收尾時固化經驗。
  What it does: use Claude Code's hook mechanism to **inject discipline** at each lifecycle point — forcing the model to self-question before concluding, inventory before building, verify before committing, and crystallize lessons at the end.
- 真實效果：減少「自信地給出沒驗證的答案」「憑記憶描述不存在的東西」「改一處沒查連動」「single-pass 就交付」這類錯誤。在多步驟 coding / 除錯 / 研究任務上，產出的**可靠度**會明顯上升。
  Real effect: fewer "confidently unverified answers," "describing things from memory that no longer exist," "changing one place without checking dependents," and "single-pass delivery." On multi-step coding / debugging / research tasks, output **reliability** rises noticeably.
- 代價：**更慢、更耗 token**（強制思考 = 多生成）。這是「用算力換嚴謹」的取捨。只在難任務上值得，簡單問答關掉它更好。
  Cost: **slower and more tokens** (forced thinking = more generation). It's a "compute-for-rigor" trade-off. Worth it only on hard tasks; turn it off for simple Q&A.

**它逼近不了的**：高階 model 內生的洞察深度、一次抓到問題本質的能力、底層硬體優化帶來的效率。經驗法則是 **80/20**——能補上 80% 的「流程紀律」差距，剩下 20% 的「原生智商」差距補不了。
**What it can't approximate**: a frontier model's native insight depth, ability to nail the essence in one shot, and hardware-level efficiency. Rule of thumb: **80/20** — it closes ~80% of the "process discipline" gap; the remaining 20% "raw intelligence" gap is on the model itself.

> **與 Anthropic 無關**：本專案非 Anthropic 官方產品、不隸屬於 Anthropic。「Fable」「Claude」為 Anthropic 之商標，此處僅作能力對標的描述性引用。本專案不含任何 Anthropic 模型權重或私有資訊，純粹是 prompt/hook 層的開源工作流模板。
> **Not affiliated with Anthropic**: This is not an official Anthropic product. "Fable" and "Claude" are Anthropic trademarks, referenced here descriptively for capability benchmarking. This project contains no Anthropic model weights or proprietary information — it is purely an open-source prompt/hook-layer workflow template.

---

## 為什麼需要這個（一個真實的小故事）/ Why This Exists (a true short story)

做這個專案的時候，我寫了一個 hook，叫「**建新東西前先盤點現有的**」——因為重複造輪子是最常見的浪費。

然後，就在我**剛寫完這個 hook 的下一步**，我和協作的 AI 準備動手建兩個新工具，差點沒先盤點就開工——直到一句「這個你原本不是已經有了嗎？」加上一次真實的 `ls`，才發現那兩樣早就有功能更強的版本躺在那裡。

連**剛寫完這條紀律的人**，下一秒都會忘。

這就是為什麼這些紀律不能只躺在文件裡——要做成「在對的時機自動跳出來」的 hook。**文件會被忘記，hook 不會。**

---

While building this project, I wrote a hook that says "**inventory what exists before building something new**" — because reinventing the wheel is the most common waste.

Then, the very next step after writing that hook, my AI collaborator and I were about to build two new tools — and almost started without inventorying first. It took one question — "don't you already have these?" — plus an actual `ls` to discover that stronger versions of both already existed.

Even **the person who just wrote the rule** forgot it one step later.

That's why these disciplines can't just live in a document — they have to become hooks that **fire automatically at the right moment.** Docs get forgotten. Hooks don't.

---

## 核心理念 / Core Idea

把模型的「內生思考」拆成「外部生命週期觸發點」。高階推理模型的可靠度，很大一部分來自它在回答前的內部「拆解 → 自我糾錯 → 驗證」。本專案的假設是：**這套內生流程，可以用 Claude Code 的 hook 在外部重建**，拆成 6 個生命週期環節，每個環節掛一個強制 hook。

Decompose the model's "internal thinking" into "external lifecycle trigger points." Much of a frontier model's reliability comes from its internal "decompose → self-correct → verify" before answering. This project's bet: **that internal process can be rebuilt externally with Claude Code hooks**, split into 6 lifecycle stages, each with a forcing hook.

| 環節 / Stage | 時機 / When (hook) | 做什麼 / What it does |
|---|---|---|
| 1. 載入記憶 / Load memory | `SessionStart` | 開機注入長期記憶、近期教訓、待辦 / Inject project memory, recent lessons, open items |
| 2. 發言前自我質疑 / Self-challenge | `UserPromptSubmit` | 偵測深度任務 → 強制 Round 1→2→3 驗證 / Detect deep tasks → force Round 1→2→3 verification |
| 3. 動手前驗證 / Pre-action check | `PreToolUse[Edit\|Write]` | 偵測「建新東西」→ 先盤點現有資產 / Detect "build new" → inventory existing assets first |
| 4. 動手後驗證 / Post-action check | `PreToolUse[Bash]` / `PostToolUse` | commit 前驗證、改 runtime 後提示重啟 / Verify before commit, restart-reminder after runtime changes |
| 5. 多 agent 編排 / Multi-agent | （工作模式 / work mode）| 規劃 → 對抗式反思 → 串行執行 → 整合 / Plan → adversarial review → serial execute → synthesize |
| 6. 收尾結晶 / Crystallize | `Stop` | 偵測收尾 → 提示記錄學到什麼 / Detect wrap-up → prompt to record lessons |

詳見 [`docs/architecture.md`](docs/architecture.md) 與 [`docs/philosophy.md`](docs/philosophy.md)。
See [`docs/architecture.md`](docs/architecture.md) and [`docs/philosophy.md`](docs/philosophy.md).

---

## 30 秒體驗 / 30-Second Demo

安裝後，下次你對 Claude Code 說「**幫我分析這個 bug 的根因**」，發言前會自動跳出這段提示，逼模型先驗證再下結論：
After install, next time you tell Claude Code "**analyze the root cause of this bug**," this prompt auto-injects *before* it answers, forcing it to verify before concluding:

```
🔬 深度任務偵測 — 初稿不是結論，跑 3 輪再交付：
  Round 1（草稿·不要直接輸出）
  Round 2（驗證·強制 grep/read 每個 claim）
  Round 3（框架質疑·若前提被推翻就重做）
```

而當你說「**幫我建一個新的 script 做 X**」，它會先擋你一下：
And when you say "**build me a new script that does X**," it stops you first:

```
🧰 建新東西偵測 — 動手前先盤點：
  多數「我需要新 X」其實是「我沒找到已有的 X」。
  先 ls/grep 看看能不能擴既有的。
```

這些都是 **advisory（只提示不擋）** — 它們只是在對的時機把該想的事推到模型眼前。
These are all **advisory (nudge, never block)** — they just surface the right thought at the right moment.

---

## 附帶 2 個 Skill / Two Bundled Skills

hook 是被動提示，但 fable 5 工作流有些核心動作需要「**主動 spawn 子 agent**」——這是 hook 做不到的。所以另外附 2 個可召喚的 skill 補上這塊。
Hooks are passive nudges, but some core moves in the fable-5 workflow require **actively spawning subagents** — which hooks can't do. Two callable skills are bundled to cover that.

| Skill | 做什麼 / What it does |
|---|---|
| **`/deep-work`** | 多 agent 編排：規劃 → 對抗式反思 → 串行執行 → 整合驗證，給「會動很多地方」的複雜任務。<br>Multi-agent orchestration: plan → adversarial review → serial execute → synthesize — for complex tasks that touch many places. |
| **`/adversarial-verify`** | 把你剛產出的結論/code，spawn 一個獨立 agent 去「找碴」，預設它有高機率漏抓。<br>Spawn an independent agent to *refute* what you just produced, assuming it's likely wrong. |

> 這 2 個是給「還沒有更完整工具箱」的人的**入門款**。如果你已經有更強的編排/驗證 skill，把它們當起點就好。
> These two are **entry-level** for those without a fuller toolkit yet. If you already have stronger orchestration/verify skills, treat these as a starting point.

詳細方法論與 prompt 模板見 [`skills/deep-work/SKILL.md`](skills/deep-work/SKILL.md) 與 [`skills/adversarial-verify/SKILL.md`](skills/adversarial-verify/SKILL.md)。
Full methodology and prompt templates in [`skills/deep-work/SKILL.md`](skills/deep-work/SKILL.md) and [`skills/adversarial-verify/SKILL.md`](skills/adversarial-verify/SKILL.md).

---

## 安裝 / Install

```bash
git clone https://github.com/zealchou/fable5-scaffold.git
cd fable5-scaffold
./install.sh      # 把 hook 註冊 merge 進 ~/.claude/settings.json（會先備份）
                  # Merges hook registration into ~/.claude/settings.json (backs up first)
```

安裝後 / After install:
1. 把 `CLAUDE.md.template` 的內容**挑你認同的**併進你專案的 `CLAUDE.md`（不要照單全收——紀律要你自己認同才有用）。
   Merge the parts of `CLAUDE.md.template` **you agree with** into your project's `CLAUDE.md` (don't take it wholesale — discipline only works if you buy into it).
2. 開新的 Claude Code session，hook 就會在對應時機觸發。
   Start a new Claude Code session; hooks fire at their stages.
3. 覺得太囉嗦 → 編輯 `~/.claude/settings.json` 移除不要的 hook，或調 hook 內的觸發詞。
   Too noisy? Edit `~/.claude/settings.json` to remove hooks, or tweak trigger words inside each hook.

## 解除安裝 / Uninstall

```bash
./uninstall.sh    # 從 settings.json 移除本專案註冊的 hook，還原備份
                  # Removes this project's hooks from settings.json, restores backup
```

---

## 緣起：一個被收走的模型，留下的方法 / Origin: A Model Taken Away, A Method Left Behind

Fable 5 是 Anthropic Mythos 級別的旗艦模型，推理能力在 Opus 之上。它在 2026 年 6 月上線，**三天後——6 月 12 日**——Anthropic 依美國政府的出口管制指令，停止了所有非美國公民（無論身在美國境內或境外）對 Fable 5 與孿生的 Mythos 5 的存取。由於無法即時區分使用者國籍，實務上形同**全球關閉**。對美國以外的我們來說，它就這樣消失了。

Fable 5 was Anthropic's Mythos-class flagship, with reasoning above Opus. It launched in June 2026 — and **three days later, on June 12**, Anthropic, complying with a US government export-control directive, cut off all access to Fable 5 and its twin Mythos 5 for every non-US national, whether inside or outside the United States. Unable to separate users by nationality in real time, the practical result was a **worldwide shutdown**. For those of us outside the US, it simply vanished.

> 報導與官方聲明 / Coverage & official statement (2026/6/12–13):
> [Anthropic 官方聲明 / Official statement](https://www.anthropic.com/news/fable-mythos-access) ·
> [CNBC](https://www.cnbc.com/2026/06/12/anthropic-disables-access-to-fable-5-and-mythos-5-to-comply-with-government-directive.html) ·
> [Bloomberg](https://www.bloomberg.com/news/articles/2026-06-13/anthropic-says-us-limits-foreign-access-to-fable-5-mythos-5) ·
> [9to5Mac](https://9to5mac.com/2026/06/12/anthropic-pulls-claude-mythos-5-and-claude-fable-5-following-us-government-directive/)

我剛好在那短短幾天的窗口內，用 Fable 5 完整跑完了一個真實的大型專案——一次跨多天的全系統審計與修復，35+ 個 bug、零資料損失、每個修復都過對抗式驗證。

I happened to use Fable 5 within that brief window to fully complete a real, large project — a multi-day full-system audit and repair: 35+ bugs, zero data loss, every fix passing adversarial verification.

**模型可以被收走，但它做事的方法不會。** 那次經驗讓我看清：Fable 5 的強，很大一部分不是「天生聰明」，而是它在每一步都極度嚴謹——下結論前先自我質疑、動手前先盤點、commit 前先驗證、收尾時把經驗固化下來。而這套「工作流程的嚴謹度」，可以用 Claude Code 的 hook 在外部重建。

**A model can be taken away, but its way of working cannot.** That experience made one thing clear: Fable 5's strength was largely not "innate intelligence," but extreme rigor at every step — self-question before concluding, inventory before acting, verify before committing, crystallize lessons at the end. And that "workflow rigor" can be rebuilt externally with Claude Code hooks.

所以趁記憶還新，我把那次專案裡 Fable 5 的工作方式**逆向工程**出來，提煉成這個 repo——讓任何人的 Claude Code（Opus 4.8 或其他還能用的 model）都能套上同一層 scaffold，把那套嚴謹度帶進自己的工作流。模型被收走了，方法留下來。分享給大家。

So while the memory was fresh, I **reverse-engineered** Fable 5's way of working from that project and distilled it into this repo — so anyone's Claude Code (Opus 4.8 or whatever model still works) can wear the same scaffold and bring that rigor into their own workflow. The model was taken; the method stays. Shared for everyone.

> 提煉過程已剔除所有原專案的私有內容，這裡是乾淨的通用模板。能用的是「方法」，不是任何特定專案的資料。
> All private content from the original project has been stripped; this is a clean, generic template. What's reusable is the *method*, not any project's data.

— 周逸達 Zeal Chou

---

## License

MIT — 隨意 fork、改、商用，只要保留版權聲明。詳 [`LICENSE`](LICENSE)。
MIT — fork, modify, and use commercially freely, as long as you keep the copyright notice. See [`LICENSE`](LICENSE).
