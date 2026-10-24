#!/bin/bash
# 사용법: bash render.sh data.json
# data.json 을 template.html 에 넣어 briefings/YYYY-MM-DD.{html,png,pdf} 를 만든다.
set -euo pipefail
cd "$(dirname "$0")"
DATA="${1:-data.json}"
DAY="$(TZ=Asia/Seoul date +%F)"
OUT="briefings/$DAY"
mkdir -p briefings

# 한글 폰트
if ! fc-list :lang=ko family 2>/dev/null | grep -q "Noto Sans CJK"; then
  (apt-get update -qq && apt-get install -y -qq fonts-noto-cjk) >/dev/null 2>&1 || echo "WARN: font install failed"
fi

# data.json 검증 후 템플릿에 주입
python3 - "$DATA" "$OUT.html" <<'PY'
import json, re, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
tpl = open("template.html", encoding="utf-8").read()
payload = json.dumps(data, ensure_ascii=False).replace("</", "<\\/")
html = re.sub(r"/\*DATA_START\*/.*?/\*DATA_END\*/", lambda m: "/*DATA_START*/" + payload + "/*DATA_END*/", tpl, flags=re.S)
open(sys.argv[2], "w", encoding="utf-8").write(html)
PY

# 브라우저 찾기 (사전 설치된 Playwright Chromium 우선)
CHROME=""
for c in $(ls -d /opt/pw-browsers/chromium-*/chrome-linux*/chrome /opt/pw-browsers/chromium_headless_shell-*/chrome-headless-shell-linux64/chrome-headless-shell /opt/pw-browsers/chromium_headless_shell-*/chrome-linux/headless_shell 2>/dev/null | sort -V -r) \
         "$(command -v chromium || true)" "$(command -v google-chrome || true)"; do
  [ -n "$c" ] && [ -x "$c" ] && CHROME="$c" && break
done
[ -z "$CHROME" ] && { echo "ERROR: chromium not found"; exit 1; }
case "$CHROME" in *headless_shell) HL="--headless" ;; *) HL="--headless=new" ;; esac
URL="file://$PWD/$OUT.html"
COMMON="$HL --no-sandbox --disable-gpu --hide-scrollbars --disable-dev-shm-usage --virtual-time-budget=4000"

"$CHROME" $COMMON --force-device-scale-factor=2 --window-size=1123,794 --screenshot="$PWD/$OUT.png" "$URL" >/dev/null 2>&1
"$CHROME" $COMMON --no-pdf-header-footer --print-to-pdf="$PWD/$OUT.pdf" "$URL" >/dev/null 2>&1

for f in "$OUT.png" "$OUT.pdf"; do
  [ -s "$f" ] || { echo "ERROR: $f not created"; exit 1; }
done
echo "OK $OUT.png $(stat -c%s "$OUT.png")B / $OUT.pdf $(stat -c%s "$OUT.pdf")B (browser: $CHROME)"

# 메일 첨부용 썸네일(640px JPEG). base64를 25,000자 조각으로 나눠 /tmp/thumb_part_* 에 저장
rm -f /tmp/thumb_part_*
if convert "$OUT.png" -resize 640x -strip -quality 50 -sampling-factor 4:2:0 "$OUT-thumb.jpg" 2>/dev/null; then
  base64 -w0 "$OUT-thumb.jpg" > /tmp/thumb.b64
  split -b 25000 -d -a 1 /tmp/thumb.b64 /tmp/thumb_part_
  echo "THUMB $OUT-thumb.jpg $(stat -c%s "$OUT-thumb.jpg")B, base64 $(stat -c%s /tmp/thumb.b64) chars, parts: $(ls /tmp/thumb_part_* | tr '\n' ' ')"
else
  echo "WARN: thumbnail failed"
fi
