#!/usr/bin/env bash
# Fable Scaffold 解除安裝器 — 從 ~/.claude/settings.json 移除本專案註冊的 hook
set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
command -v python3 >/dev/null 2>&1 || { echo "❌ 需要 python3。"; exit 1; }
[ -f "$SETTINGS" ] || { echo "找不到 $SETTINGS，無需移除。"; exit 0; }

cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
echo "📦 已備份 → $SETTINGS.bak.*"

python3 - "$SETTINGS" <<'PYEOF'
import json, sys
settings_path = sys.argv[1]
OURS = {
    "self_challenge_gate.sh", "asset_inventory_gate.sh", "ls_real_preflight.sh",
    "session_retro.sh", "verify_before_commit.sh", "restart_reminder.sh",
}
with open(settings_path) as f:
    s = json.load(f)
hooks = s.get("hooks", {})
removed = 0
for event, arr in list(hooks.items()):
    new_arr = []
    for entry in arr:
        keep = []
        for h in entry.get("hooks", []):
            cmd = h.get("command", "")
            if any(cmd.endswith(name) for name in OURS):
                removed += 1
            else:
                keep.append(h)
        if keep:
            entry["hooks"] = keep
            new_arr.append(entry)
    if new_arr:
        hooks[event] = new_arr
    else:
        del hooks[event]
with open(settings_path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
print(f"✅ 已移除 {removed} 個 fable-scaffold hook 註冊")
PYEOF

echo "完成。開新 session 生效。"
