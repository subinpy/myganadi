# myganadi

손그림 하얀 강아지 **가나디**를 [claudlet](https://github.com/YeeDochi/Claudlet) 데스크톱 펫 크리처로 만든 것.
로그인하면 자동으로 바탕화면에 떠 있다.

## 구성

| 경로 | 내용 |
|---|---|
| `*.png` (루트) | 원본 그림 5장 |
| `creature/myganadi/` | claudlet 크리처 패키지 (배경 제거·크기 맞춘 스프라이트 + 그리는 코드) |
| `systemd/claudlet-myganadi.service` | 로그인 시 펫을 띄우는 systemd user 서비스 |
| `install.sh` | 위 두 개를 설치하고 자동 실행까지 켜는 스크립트 |

### 상태별 그림

| 그림 | 쓰이는 상황 |
|---|---|
| `work_computer` | 편집·명령 실행·서브에이전트·스킬 |
| `attention` | 권한 요청·질문 대기 |
| `celebrate` | 작업 완료, 점프·손 흔들기 |
| `error` | 에러·화남·떨어짐 |
| `idle` | 나머지 전부 — 통통 튀며 걷기, 기울기, 소품(돋보기·Zzz·말풍선)을 얹어서 |

펫 설정에서 색을 바꾸면 흰 몸에만 곱해져 입혀지고 검은 선은 그대로 남는다.

## 다른 PC에 설치 (Ubuntu / GNOME)

```bash
pipx install claudlet && claudlet-install
git clone git@github.com:subinpy/myganadi.git
cd myganadi && ./install.sh
```

`install.sh`가 하는 일:
1. `creature/myganadi` → `~/.config/claudlet/creatures/myganadi` 복사
2. `claudlet-config wear myganadi`
3. `config/config.json`의 모션 매핑·한국어(`lang`)·말투를 `~/.config/claudlet/config.json`에 합침 (아래 [모션 매핑 설정](#모션-매핑-설정))
4. 서비스 파일을 `~/.config/systemd/user/`에 설치하고 enable 후 restart

`active (running)`이 보이면 끝. 색·크기는 이미 있으면 그대로 두므로 PC마다 `claudlet-config ui`에서 맞춘다.
claudlet 훅은 새로 연 Claude Code 세션부터 적용된다.

## 관리

```bash
systemctl --user restart claudlet-myganadi        # 우클릭 → 종료로 끈 뒤 다시 띄우기
systemctl --user disable --now claudlet-myganadi  # 자동 실행 끄기
systemctl --user status claudlet-myganadi         # 상태 확인
```

- 비정상 종료면 5초 뒤 다시 뜬다. 우클릭 → 종료로 끄면 다음 로그인까지 꺼진 채로 있다.
- 실행되자마자 꺼지면 같은 세션의 펫이 이미 떠 있는 것 — 그 펫을 끄고 restart.
- `systemctl --user is-active graphical-session.target`이 `active`가 아닌 데스크톱 환경이면 systemd 대신 `~/.config/autostart/`에 `.desktop` 파일로 등록해야 한다.
- 이 상시 펫은 특정 세션에 묶여 있지 않아 작업에 반응하지 않는다. Claude Code 세션마다 반응하는 펫은 claudlet 훅이 따로 붙여 준다.

## 크리처 수정

`creature/myganadi/__init__.py`를 고친 뒤 `./install.sh`를 다시 실행하고 펫을 restart.
그림을 추가하려면 `sprites/`에 PNG(투명 배경, 320×320, 발이 아래쪽 끝에 닿게)를 넣고 `SPRITES`와 `SPRITE_FOR`에 등록한다.

## 모션 매핑 설정

`config/config.json`은 내가 쓰는 claudlet 설정 스냅샷이다. Claude Code 활동별로 어떤 모션을 보여줄지(`events`, `tools`, `raw_events`), 언어(`lang: ko`), 대화창에 가나디가 직접 답하기(`pointer.brain`), 가나디 색·크기·말투(`creatures`)가 들어 있다.
`pointer.brain`이 켜져 있으면 말을 걸 때마다 claude(haiku) 호출이 한 번 나간다. 꺼져 있으면 세션에 안 붙은 펫은 대답하지 않는다.

| 상황 | 모션 |
|---|---|
| 세션 시작 / 서브에이전트 종료 | `wave` |
| 프롬프트 입력 | `thinking` |
| 작업 완료 | `celebrate` |
| 에러 | `error` |
| 권한 요청 | `attention` |
| 입력 대기 | `sleeping` |
| 컨텍스트 압축 직전 | `sing` |
| Bash·Edit·Write | `work_computer` |
| Read·Grep·Glob | `work_search` |
| WebSearch·WebFetch | `work_web` |
| Agent / Skill | `work_agent` / `work_skill` |

`install.sh`가 자동으로 합친다. `lang`·`events`·`tools`·`raw_events`·`pointer.brain`과 가나디 말투(`persona`·`background`·`nickname`)는 덮어쓰고, 색·크기 등 나머지 크리처 설정은 없을 때만 채운다. `dock`은 화면마다 다르니 가져오지 않는다.
설정을 바꾸면 이 파일을 고치고 `./install.sh`를 다시 실행한다.
