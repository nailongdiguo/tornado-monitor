#!/bin/bash
# 增量抓取本年 SPC 逐日龙卷报告，然后重建分布图
BASE=/opt/tornado; Y=$(date +%Y); D="$BASE/data/$Y"; mkdir -p "$D"
YST=$(date -d yesterday +%y%m%d)
awk -v yy="$Y" -v end="$YST" 'BEGIN{
  split("31 28 31 30 31 30 31 31 30 31 30 31",dm," ");
  if ((yy%4==0 && yy%100!=0) || yy%400==0) dm[2]=29
  for(m=1;m<=12;m++) for(d=1;d<=dm[m];d++){ s=sprintf("%02d%02d%02d", yy%100, m, d); if (s>end) exit; print s }
}' > /tmp/needed.txt
N=0
while read -r d; do
  [ -f "$D/$d.csv" ] && continue
  curl -s -A "tornado-site/1.0 (research)" -m 45 "https://www.spc.noaa.gov/climo/reports/${d}_rpts_torn.csv" -o "$D/$d.csv" && N=$((N+1))
done < /tmp/needed.txt
bash "$BASE/build_page.sh"
echo "NEW_DAYS=$N"
