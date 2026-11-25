#!/system/bin/sh
# 每日龙卷简报：昨日 SPC 报告 + 今日 Day1 风险 + 活跃龙卷观望
# 用法: sh daily_brief.sh [YYMMDD]  默认取昨日
UA="dsh-tornado-monitor/1.0 (personal weather research)"
T="$HOME/db_tmp"; mkdir -p "$T"
if [ -n "$1" ]; then
  URL="https://www.spc.noaa.gov/climo/reports/$1_rpts_torn.csv"
else
  URL="https://www.spc.noaa.gov/climo/reports/yesterday_torn.csv"
fi
curl -s -A "$UA" -m 40 "$URL" -o "$T/y.csv"
grep -q '^Time,' "$T/y.csv" || { echo "YEST_FETCH_FAIL"; }
YCNT=$(grep -vc '^Time,' "$T/y.csv" 2>/dev/null | tr -d ' ')
YTOP=$(awk -F, 'FNR>1 && NF>=8{c[$5]++}END{for(k in c)print c[k]" "k}' "$T/y.csv" | sort -rn | head -4 | awk '{printf "%s(%s) ", $2, $1}')
awk -F, 'FNR>1 && NF>=8{printf "- %s, %s 县 %s 州 (%s) \n",$3,$4,$5,$1}' "$T/y.csv" | head -6 > "$T/y_lines"

curl -s -A "$UA" -m 40 "https://www.spc.noaa.gov/products/outlook/day1otlk_cat.lyr.geojson" -o "$T/cat.json"
RISK=$(grep -o '"LABEL": *"[A-Z]*"' "$T/cat.json" | sed 's/.*"LABEL": *"//; s/"//' | awk 'BEGIN{r["TSTM"]=1;r["MRGL"]=2;r["SLGT"]=3;r["ENH"]=4;r["MDT"]=5;r["HIGH"]=6}
{k=r[$1]; if(k>m){m=k;lab=$1}}END{print lab}')

curl -s -A "$UA" -m 40 "https://www.spc.noaa.gov/products/outlook/day1otlk_torn.lyr.geojson" -o "$T/torn.json"
TPROB=$(grep -o '"LABEL": *"[^"]*"' "$T/torn.json" | sed 's/.*"LABEL": *"//; s/"//' | awk '{v=$0; if(v=="") next; gsub(/[^0-9.].*/,"",v); if (v !~ /[0-9]/) v=0; if(v+0>m)m=v+0}END{if(m=="")print 0; else print m}')

WATCH=$(curl -s -A "$UA" -m 40 "https://api.weather.gov/alerts/active?event=Tornado%20Watch" | grep -c '"id": "https://api.weather.gov/alerts/')

echo "YEST_COUNT=$YCNT"
echo "YEST_TOP=$YTOP"
echo "YEST_LINES:"; cat "$T/y_lines"
echo "DAY1_CAT=$RISK"
echo "DAY1_TORN_PROB=$TPROB"
echo "ACTIVE_WATCH=$WATCH"
