#!/system/bin/sh
# 合并任务：30分钟一次的预警检查 + 到点补发的每日简报（含短信文案）
H="$HOME"
TODAY=$(date +%Y-%m-%d); HM=$(date +%H%M)
A=$(sh "$H/tornado_watch.sh")
NEW=$(printf '%s' "$A" | sed -n 's/.*NEW=\([0-9]*\).*/\1/p' | head -1)
ACT=$(printf '%s' "$A" | sed -n 's/.*ACTIVE=\([0-9]*\).*/\1/p' | head -1)
echo "ALERT_ACTIVE=${ACT:-0} ALERT_NEW=${NEW:-0}"
if [ "${NEW:-0}" -gt 0 ]; then
  printf '%s\n' "$A" | sed -n '/^\[$/,$p' | tr '\n' ' ' | cut -c1-700
  echo "SMS_A=【NWS龙卷预警】$(printf '%s' "$A" | sed -n '/^\[$/,$p' | tr '\n' ' ' | sed 's/地点: //g; s/ 等级: //g; s/ 生效: //g' | cut -c1-600)"
fi

BR=$(sh "$H/inmet_alerts.sh" 2>/dev/null | grep "^BR_SMS=" )
echo "$BR"

LAST=$(cat "$H/digest.last" 2>/dev/null)
if [ "$HM" -ge 900 ] && [ "$LAST" != "$TODAY" ]; then
  B=$(sh "$H/daily_brief.sh")
  YC=$(printf '%s' "$B" | sed -n 's/^YEST_COUNT=//p')
  YT=$(printf '%s' "$B" | sed -n 's/^YEST_TOP=//p')
  CAT=$(printf '%s' "$B" | sed -n 's/^DAY1_CAT=//p')
  PROB=$(printf '%s' "$B" | sed -n 's/^DAY1_TORN_PROB=//p')
  W=$(printf '%s' "$B" | sed -n 's/^ACTIVE_WATCH=//p')
  echo "DIGEST_DUE=1"
  echo "DIGEST_COUNT=${YC:-0} TOP=${YT:-无} CAT=${CAT:-?} PROB=${PROB:-0} WATCH=${W:-0}"
  echo "SMS_D=【龙卷风简报 ${TODAY:5}】昨日${YC:-0}条${YT:+ 热点:$YT}｜今日${CAT:-?} 龙卷${PROB:-0}% 观望${W:-0}"
  echo "$TODAY" > "$H/digest.last"
else
  echo "DIGEST_DUE=0"
fi
