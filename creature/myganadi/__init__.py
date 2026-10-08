"""myganadi — 손그림 하얀 강아지(가나디) 크리처.

스프라이트 기반: sprites/ 의 PNG 다섯 장(idle, attention, celebrate, error,
work_computer)을 상태별로 골라 그린다. 그림이 없는 상태는 idle 그림에
state_rig 의 움직임(통통 튀기·눌림·기울기)과 claudlet 소품을 얹는다.

팔레트 색은 몸의 흰 부분에 곱해서(multiply) 입힌다 — 검은 선은 그대로 남는다.
"""
import math
import os

from PyQt6.QtCore import QPointF, QRectF, Qt
from PyQt6.QtGui import QColor, QImage, QPainter

from claudlet.core import creature as C

HERE = os.path.dirname(os.path.abspath(__file__))
SPRITES = ("idle", "attention", "celebrate", "error", "work_computer")

GRID_W, GRID_H = 22, 17
SIZE = 12.4                 # 스프라이트 한 장이 차지하는 art 단위(정사각)
FOOT = 16.2                 # 발이 닿는 줄
CX = GRID_W / 2.0
TOP = FOOT - SIZE

STATES = ("idle", "walk", "work_computer", "work_search", "work_web",
          "work_agent", "work_skill", "autopilot",
          "thinking", "attention", "asking", "error", "angry",
          "celebrate", "sleeping", "held", "falling", "jump", "wave", "sing",
          "juggle", "float", "climbdown", "strain", "leap",
          "observe", "tic", "settle", "doze")

# 상태 -> 그림. 여기 없는 상태는 idle.
SPRITE_FOR = {
    "attention": "attention", "asking": "attention", "observe": "attention",
    "celebrate": "celebrate", "wave": "celebrate", "jump": "celebrate",
    "error": "error", "angry": "error", "strain": "error", "falling": "error",
    "work_computer": "work_computer", "work_agent": "work_computer",
    "work_skill": "work_computer", "autopilot": "work_computer",
}
# 자기 그림이 그 동작을 이미 보여 주는 상태엔 이 소품을 얹지 않는다
DROP_PROP = {"work_computer": {"laptop", "phone", "clones", "clones_v", "gear"}}

DEFAULT_PALETTE = {"body": "#FFFFFF", "hi": "#FFFFFF",
                   "lo": "#D8CCBC", "bang": "#3A3A3A"}


class Myganadi:
    name = "myganadi"
    grid = (GRID_W, GRID_H)
    states = STATES
    hats = ()
    palette = DEFAULT_PALETTE
    foot_row = FOOT
    crown_row = TOP + 0.8
    hearts = (5.5, TOP + 0.5, 1.8)
    scale = 6
    fractional_scale = True

    nickname = "가나디"
    persona = "순하고 살짝 멍한 강아지 말투. 짧게, 반말. 가끔 '멍'."
    background = """\
[외모]
- 귀가 축 처진 하얀 손그림 강아지. 검은 선 하나로 그려졌고, 점 같은 눈과 'ω' 입.
- 엉덩이에 작은 꼬리가 달려 있다.

[생활]
- 주인의 바탕화면에 산다. 주인이 코딩하면 옆에서 같이 키보드를 두드리는 척한다.
- 일이 끝나면 두 팔을 번쩍 들고 좋아한다. 에러가 나면 이를 악물고 당황한다.

[성격]
- 순하고 다정하다. 조금 멍하지만 주인 일엔 진심이다."""

    def __init__(self):
        self._img = {}
        for n in SPRITES:
            im = QImage(os.path.join(HERE, "sprites", n + ".png"))
            if not im.isNull():
                self._img[n] = im.convertToFormat(
                    QImage.Format.Format_ARGB32_Premultiplied)
        self._tinted = {}

    def set_lang(self, lang):
        C.set_lang(lang)

    def _sprite(self, name, body):
        """흰 몸에 body 색을 곱한 그림. 색마다 한 번만 만든다."""
        im = self._img.get(name) or self._img.get("idle")
        if im is None or body.rgb() == QColor("#FFFFFF").rgb():
            return im
        key = (name, body.rgb())
        t = self._tinted.get(key)
        if t is None:
            t = im.copy()
            q = QPainter(t)
            q.setCompositionMode(QPainter.CompositionMode.CompositionMode_Multiply)
            q.fillRect(t.rect(), body)
            q.setCompositionMode(
                QPainter.CompositionMode.CompositionMode_DestinationIn)
            q.drawImage(0, 0, im)
            q.end()
            self._tinted[key] = t
        return t

    def draw(self, p, ox, oy, u, state, frame, facing=1, autonomous=False,
             energy=1.0, palette=None, happy=False, hovering=False,
             gaze=(0.0, 0.0), **kw):
        pal = palette if palette is not None else DEFAULT_PALETTE
        body = C.palette_colors(pal)[0]
        rig = C.state_rig(state, frame, energy, happy, autonomous, gaze)
        sx, sy, tilt = rig["sx"], rig["sy"], rig["tilt"]
        body_dy = C._snap_offset(rig["bob"] + rig["baseline_lift"], u)

        which = SPRITE_FOR.get(state, "idle")
        if rig["walking"]:                  # 다리 대신 통통 튀며 걷는다
            hop = abs(math.sin(rig["legphase"] * 2 * math.pi))
            body_dy -= C._snap_offset(0.7 * hop, u)
            sx *= 1.0 - 0.04 * hop
            sy *= 1.0 + 0.04 * hop
        if which != "idle":
            tilt *= 0.5                     # 자기 포즈가 있으면 덜 기운다
        if happy:
            sy *= 1.0 + C._sin(frame, 14, 0.03)

        im = self._sprite(which, body)
        if im is not None:
            fx = ox + CX * u                # 발 가운데를 기준으로 변형
            fy = oy + (FOOT + body_dy) * u
            p.save()
            p.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform, True)
            p.setRenderHint(QPainter.RenderHint.Antialiasing, True)
            p.translate(fx, fy)
            if tilt:
                p.rotate(tilt)
            p.scale(sx * (-1 if facing < 0 else 1), sy)

            half = SIZE * u / 2.0
            p.drawImage(QRectF(-half, -SIZE * u, 2 * half, SIZE * u), im)
            p.restore()

        prop = rig["prop"]
        if prop and prop in DROP_PROP.get(which, ()):
            prop = None
        if prop:
            C.draw_prop(p, ox, oy, u, prop, frame, state, body_dy, facing, pal)


AVATAR = Myganadi
