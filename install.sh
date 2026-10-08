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

unit="$HOME/.config/systemd/user/claudlet-myganadi.service"
mkdir -p "$(dirname "$unit")"
sed "s#^ExecStart=.*#ExecStart=$(command -v claudlet)#" systemd/claudlet-myganadi.service > "$unit"
systemctl --user daemon-reload
systemctl --user enable --now claudlet-myganadi.service
systemctl --user --no-pager status claudlet-myganadi.service | head -3
