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

# claudlet 버그 패치: 세션 펫을 띄울 때 PYTHONPATH에 claudlet 패키지 폴더 자체를 넣어서
# 그 안의 claudlet/platform/ 이 표준 모듈 platform 을 가린다 → 세션 펫이 뜨자마자 죽어서
# VSCode 등 Claude Code 세션에서 모션이 안 나온다. 한 단계 위(site-packages)를 가리키게 고친다.
# pipx 로 claudlet 을 다시 설치하면 원래대로 돌아가니 그때 install.sh 를 다시 실행한다.
"$(head -1 "$(command -v claudlet)" | sed 's/^#!//')" - <<'EOF'
import os
from claudlet.core import hostinfo
pkg = os.path.dirname(os.path.dirname(os.path.abspath(hostinfo.__file__)))
old = "src_dir = os.path.dirname(os.path.dirname(os.path.abspath(hostinfo.__file__)))\n"
new = "src_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(hostinfo.__file__))))\n"
for f in ("cli/hook.py", "cli/attach.py"):
    p = os.path.join(pkg, f)
    s = open(p).read()
    if old in s:
        open(p, "w").write(s.replace(old, new))
        print("patched", p)
EOF

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
