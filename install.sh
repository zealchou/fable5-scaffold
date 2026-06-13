#!/usr/bin/env bash
# Fable Scaffold 安裝器 — 把 6 個 hook merge 進 ~/.claude/settings.json
# 安全：先備份、不覆蓋你現有的 hook、防重複註冊。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

command -v jq >/dev/null 2>&1 || { echo "❌ 需要 jq。請先安裝：brew install jq （macOS）/ apt install jq （Linux）"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ 需要 python3。"; exit 1; }

chmod +x "$REPO_DIR"/hooks/*.sh
mkdir -p "$HOME/.claude"

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
  echo "📦 已備份現有 settings.json → $SETTINGS.bak.*"
else
  echo '{}' > "$SETTINGS"
fi

python3 - "$SETTINGS" "$REPO_DIR" <<'PYEOF'
import json, sys
settings_path, repo = sys.argv[1], sys.argv[2]
with open(settings_path) as f:
    s = json.load(f)
hooks = s.setdefault("hooks", {})

def add(event, matcher, script):
    cmd = f"bash {repo}/hooks/{script}"
    arr = hooks.setdefault(event, [])
    for entry in arr:
        for h in entry.get("hooks", []):
            if h.get("command", "").endswith(script):
                return  # 已註冊，跳過（防重複）
    entry = {"hooks": [{"type": "command", "command": cmd}]}
    if matcher:
        entry["matcher"] = matcher
    arr.append(entry)

add("UserPromptSubmit", None, "self_challenge_gate.sh")
add("UserPromptSubmit", None, "asset_inventory_gate.sh")
add("UserPromptSubmit", None, "ls_real_preflight.sh")
add("UserPromptSubmit", None, "session_retro.sh")
add("PreToolUse", "Bash", "verify_before_commit.sh")
add("PostToolUse", "Bash", "restart_reminder.sh")

with open(settings_path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
print("✅ 已註冊 6 個 hook 進", settings_path)
PYEOF

echo ""
echo "完成！下一步："
echo "  1. 開一個新的 Claude Code session（hook 在 session 啟動時載入）"
echo "  2. （可選）把 CLAUDE.md.template 挑你認同的併進你專案的 CLAUDE.md"
echo "  3. 太囉嗦？編輯 $SETTINGS 移除個別 hook，或跑 ./uninstall.sh"
