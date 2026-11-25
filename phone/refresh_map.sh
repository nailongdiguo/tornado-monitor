#!/system/bin/sh
# 增量抓取当年 SPC 逐日龙卷报告并重建分布图
H="$HOME"; Y=$(date +%Y); D="$H/tw$Y"; mkdir -p "$D"
YST=$(date -d "@$(( $(date +%s) - 86400 ))" +%y%m%d 2>/dev/null)
[ -n "$YST" ] || YST=$(date +%y%m%d)
awk -v yy="$Y" -v end="$YST" 'BEGIN{
  split("31 28 31 30 31 30 31 31 30 31 30 31",dm," ");
  if ((yy%4==0 && yy%100!=0) || yy%400==0) dm[2]=29
  for(m=1;m<=12;m++) for(d=1;d<=dm[m];d++){ s=sprintf("%02d%02d%02d", yy%100, m, d); if (s>end) exit; print s }
}' > "$H/needed.txt"
: > "$H/fetch.txt"
while read -r d; do [ -f "$D/$d.csv" ] || echo "$d" >> "$H/fetch.txt"; done < "$H/needed.txt"
N=$(wc -l < "$H/fetch.txt" | tr -d ' ')
if [ "$N" -gt 0 ]; then
  cat "$H/fetch.txt" | xargs -n 1 -P 6 sh -c 'curl -s -A "dsh-research/1.0" -m 45 "https://www.spc.noaa.gov/climo/reports/$0_rpts_torn.csv" -o "'"$D"'/$0.csv"'
fi
sh "$H/build_page.sh"
echo "NEW_DAYS=$N"
