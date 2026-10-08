#!/usr/bin/env bash
# myganadi 크리처 설치 + 로그인 시 자동 실행 등록 (Ubuntu/GNOME, systemd user)
set -euo pipefail
cd "$(dirname "$0")"

command -v claudlet >/dev/null || { echo "claudlet 이 없습니다: pipx install claudlet && claudlet-install"; exit 1; }

dest="${XDG_CONFIG_HOME:-$HOME/.config}/claudlet/creatures/myganadi"
mkdir -p "$(dirname "$dest")"
rm -rf "$dest"
cp -r creature/myganadi "$dest"
claudlet-config wear myganadi

# config/config.json 의 모션 매핑·언어·말투를 기존 설정에 합친다.
# 색·크기는 PC마다 다르니 이미 있으면 건드리지 않고, dock 위치는 가져오지 않는다.
python3 - "${XDG_CONFIG_HOME:-$HOME/.config}/claudlet/config.json" config/config.json <<'EOF'
import json, os, sys
dst, src = sys.argv[1], sys.argv[2]
cur = json.load(open(dst)) if os.path.exists(dst) else {}
new = json.load(open(src))
for k in ("lang", "events", "tools", "raw_events"):
    cur[k] = new[k]
cur.setdefault("pointer", {}).update(new["pointer"])   # brain: 대화창에 가나디가 직접 답한다
mine = cur.setdefault("creatures", {}).setdefault("myganadi", {})
for k, v in new["creatures"]["myganadi"].items():
    if k in ("persona", "background", "nickname"):
        mine[k] = v
    else:
        mine.setdefault(k, v)
json.dump(cur, open(dst, "w"), ensure_ascii=False, indent=2)
EOF

unit="$HOME/.config/systemd/user/claudlet-myganadi.service"
mkdir -p "$(dirname "$unit")"
sed "s#^ExecStart=.*#ExecStart=$(command -v claudlet)#" systemd/claudlet-myganadi.service > "$unit"
systemctl --user daemon-reload
systemctl --user enable claudlet-myganadi.service
systemctl --user restart claudlet-myganadi.service
systemctl --user --no-pager status claudlet-myganadi.service | head -3
