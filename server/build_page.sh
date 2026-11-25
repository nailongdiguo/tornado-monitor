#!/bin/bash
# 用 data/<年>/ 下的 SPC 逐日 CSV 生成龙卷风分布图到 /var/www/tornado/index.html
set -e
BASE=/opt/tornado; WWW=/var/www/tornado
Y=$(date +%Y); D="$BASE/data/$Y"; CSV="$BASE/torn_all.csv"; OUT="$WWW/index.html"
mkdir -p "$WWW" "$D"
ls "$D"/*.csv >/dev/null 2>&1 || { echo "NO_DATA"; exit 1; }
awk -F, 'FNR==1{next} NF>=8 && $1!="Time"{fn=FILENAME; sub(/^.*\//,"",fn); sub(/\.csv$/,"",fn); print "20" substr(fn,1,2) "-" substr(fn,3,2) "-" substr(fn,5,2) ","$0}' "$D"/*.csv > "$CSV"
TOTAL=$(wc -l < "$CSV")
DMIN=$(head -1 "$CSV" | cut -d, -f1); DMAX=$(tail -1 "$CSV" | cut -d, -f1)
TODAY=$(date +%Y-%m-%d)
awk '
{ if (index($0,"\"coordinates\"")==0) next
  s=$0; sub(/^.*"coordinates":/,"",s); sub(/\}\]\}[,}]?$/,"",s)
  gsub(/\]\],\[\[/,"|",s); gsub(/\]\]\],\[\[\[/,"|",s)
  n=split(s,segs,"|")
  for(i=1;i<=n;i++){ t=segs[i]; gsub(/[\[\]{}]/," ",t)
    if (t !~ /-?[0-9]/) continue
    m=split(t,nums,","); dl=""; k=0
    for(j=1;j<m;j+=2){ lon=nums[j]+0; lat=nums[j+1]+0
      dl=dl (k==0?"M":"L") sprintf("%.1f,%.1f ",40+(lon+125)*16.9492, 40+(50-lat)*13.3898); k++ }
    if(k>2) print "<path fill=\"#111c2c\" stroke=\"#33475f\" stroke-width=\".7\" d=\"" dl "Z\"/>" } }
' "$BASE/states.json" > "$BASE/state_paths.svgfrag"
awk -F, 'NF>=8 && $8!=""{ lat=$7+0; lon=$8+0
  if(lat<23||lat>50||lon<-126||lon>-65) next
  printf "<circle fill=\"#ff5038\" fill-opacity=\".55\" cx=\"%.1f\" cy=\"%.1f\" r=\"2.4\"/>\n", 40+(lon+125)*16.9492, 40+(50-lat)*13.3898 }' "$CSV" > "$BASE/dots.svgfrag"
SMAX=$(awk -F, 'NF>=8{c[$6]++}END{for(k in c)if(c[k]>m)m=c[k];print m+0}' "$CSV")
MMAX=$(awk -F, 'NF>=8{sub(/-[0-9][0-9]$/,"",$1); c[$1]++}END{for(k in c)if(c[k]>m)m=c[k];print m+0}' "$CSV")
cat > "$OUT" <<HTML
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${Y} 美国龙卷风分布</title><style>
body{background:#0b1220;color:#e6edf3;font-family:-apple-system,sans-serif;margin:0;padding:12px;max-width:1100px;margin:auto}
h2{font-size:19px;margin:6px 0 2px}h3{font-size:15px;margin:18px 0 6px;color:#9fb3c8}
.sub{color:#8fa3b8;font-size:12px;line-height:1.5;margin:0 0 8px}
svg{width:100%;height:auto;display:block;background:#0b1220}
.bar{height:16px;background:#1b2b3f;border-radius:3px;position:relative;margin:3px 0}
.bar i{display:block;height:100%;background:linear-gradient(90deg,#ff5038,#ffb13c);border-radius:3px}
.bar span{position:absolute;left:6px;top:0;font-size:11px;line-height:16px;color:#fff}
.bar b{position:absolute;right:4px;top:0;font-size:11px;line-height:16px;color:#9fb3c8}
</style></head><body>
<h2>${Y} 年美国龙卷风报告分布</h2>
<p class="sub">数据：NOAA/NWS 风暴预测中心（SPC）逐日初步报告｜${DMIN} ~ ${DMAX}（数据截至 ${TODAY}）｜有效记录 ${TOTAL} 条<br>红点＝每条报告位置；越密代表该区域报告越集中（含重复与延迟报告，正式年鉴以 NCEI 为准）<br>每月自动更新</p>
<svg viewBox="0 0 1080 430" xmlns="http://www.w3.org/2000/svg">
HTML
echo '<g stroke-linejoin="round">' >> "$OUT"; cat "$BASE/state_paths.svgfrag" >> "$OUT"
echo '</g><g>' >> "$OUT"; cat "$BASE/dots.svgfrag" >> "$OUT"
echo '</g><text x="40" y="20" fill="#8fa3b8" font-size="11">CONUS 24–50N / 126–66W</text></svg>' >> "$OUT"
echo '<h3>州排名（报告数）</h3>' >> "$OUT"
awk -F, 'NF>=8{c[$6]++}END{for(k in c) printf "%d %s\n", c[k], k}' "$CSV" | sort -rn | head -10 | awk -v max="$SMAX" '{printf "<div class=\"bar\"><i style=\"width:%.1f%%\"></i><span>%s</span><b>%d</b></div>\n", $1/max*100, $2, $1}' >> "$OUT"
echo '<h3>月度分布</h3>' >> "$OUT"
awk -F, 'NF>=8{sub(/-[0-9][0-9]$/,"",$1); c[$1]++}END{for(k in c) printf "%d %s\n", c[k], k}' "$CSV" | sort -k2 | awk -v max="$MMAX" '{printf "<div class=\"bar\"><i style=\"width:%.1f%%\"></i><span>%s</span><b>%d</b></div>\n", $1/max*100, $2, $1}' >> "$OUT"
cat >> "$OUT" <<HTML
<p class="sub" style="margin-top:14px">注：SPC 初步报告未定 EF 等级（F_Scale 多为 UNK），强度需等 NCEI Storm Events 正式核定。</p>
<section id="brief" style="background:#101b2b;border:1px solid #2a3b52;border-left:4px solid #ff5038;border-radius:10px;padding:12px 14px;margin:12px 0">
<div id="brief-h" style="display:flex;justify-content:space-between;align-items:center;cursor:pointer"><b style="font-size:15px;color:#e6edf3">📋 每日简报 / Daily Brief</b><span id="brief-t" style="color:#8fa3b8;font-size:12px">收起 ▴</span></div>
<div id="brief-b" style="margin-top:8px;font-size:13.5px;line-height:1.7;color:#d7e1ec">加载中…</div></section>
<script src="alerts.js?v=1"></script>
<script src="brief.js?v=1"></script>
</body></html>
HTML
echo "MAP_OK TOTAL=$TOTAL RANGE=$DMIN..$DMAX"
