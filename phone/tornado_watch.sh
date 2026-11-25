#!/system/bin/sh
# NWS tornado realtime monitor: prints only NEW alerts (dedup via seen file).
HOME_DIR="$HOME"
EVENT="${1:-Tornado Warning}"
UA="dsh-tornado-monitor/1.0 (personal weather research)"
TMP="$HOME_DIR/tw_alerts.json"
SEEN="$HOME_DIR/tw_seen.txt"
OUT="$HOME_DIR/tw_new.txt"

ENC=$(printf '%s' "$EVENT" | sed 's/ /%20/g')
URL="https://api.weather.gov/alerts/active?event=$ENC&status=actual"

curl -s -A "$UA" -m 45 "$URL" -o "$TMP" || { echo "FETCH_FAIL"; exit 0; }
[ -s "$TMP" ] || { echo "EMPTY_RESPONSE"; exit 0; }
grep -q '"type": "FeatureCollection"' "$TMP" || { echo "FETCH_FAIL_HTTP"; exit 0; }

awk '
function flush() { if (id != "") print id "|" hl "|" ad "|" sev "|" on "|" en; id=""; hl=""; ad=""; sev=""; on=""; en="" }
function strip(s) { sub(/",?$/, "", s); return s }
{
  l = $0
  if (l ~ /^            "id": "https:\/\/api\.weather\.gov\/alerts\//) {
    flush()
    id = l; sub(/^.*alerts\//, "", id); id = strip(id)
    next
  }
  s = l; sub(/^ +/, "", s)
  if (index(s, "\"headline\": \"") == 1) { hl = strip(substr(s, 14)) }
  else if (index(s, "\"areaDesc\": \"") == 1) { ad = strip(substr(s, 14)) }
  else if (index(s, "\"severity\": \"") == 1) { sev = strip(substr(s, 14)) }
  else if (index(s, "\"onset\": \"") == 1)    { on = strip(substr(s, 11)) }
  else if (index(s, "\"ends\": \"") == 1)     { en = strip(substr(s, 10)) }
}
END { flush() }
' "$TMP" > "$OUT"

TOTAL=$(wc -l < "$OUT" | tr -d ' ')
[ -f "$SEEN" ] || : > "$SEEN"

NEW=0
MSG=""
while IFS='|' read -r id hl ad sev on en; do
    [ -n "$id" ] || continue
    grep -Fxq "$id" "$SEEN" && continue
    NEW=$((NEW + 1))
    echo "$id" >> "$SEEN"
    MSG="$MSG[
$hl
地点: $ad | 等级: $sev | 生效: $on 至 $en]"
done < "$OUT"

if [ "$(wc -l < "$SEEN" | tr -d ' ')" -gt 3000 ]; then
    tail -n 3000 "$SEEN" > "$SEEN.tmp" && mv "$SEEN.tmp" "$SEEN"
fi

printf 'ACTIVE=%s NEW=%s\n' "${TOTAL:-0}" "$NEW"
[ "$NEW" -gt 0 ] && printf '%s\n' "$MSG"
exit 0
