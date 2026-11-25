#!/system/bin/sh
# 巴西 INMET 气象警报（CAP/urn:oid，含强对流/暴雨等级），输出中文摘要
H="$HOME"
UA="dsh-research/1.0 (personal weather research)"
F="$H/inmet.json"
curl -s -A "$UA" -m 45 "https://apiprevmet3.inmet.gov.br/avisos/ativos" -o "$F" || { echo "INMET_FETCH_FAIL"; exit 0; }
[ -s "$F" ] || { echo "INMET_EMPTY"; exit 0; }
tr -d '\n' < "$F" | sed 's/{"id":/\n{"id":/g' > "$H/inmet_lines.txt"
awk '
{
  sev=""; reg=""; ini=""; fim=""
  if (match($0, /"severidade":"[^"]*"/)) { sev=substr($0,RSTART+14,RLENGTH-15) }
  if (match($0, /"regioes":"[^"]*"/))   { reg=substr($0,RSTART+11,RLENGTH-12) }
  if (match($0, /"data_inicio":"[^"]*"/)){ ini=substr($0,RSTART+15,RLENGTH-16) }
  if (match($0, /"data_fim":"[^"]*"/))   { fim=substr($0,RSTART+12,RLENGTH-13) }
  gsub(/T.*/, "", ini); gsub(/T.*/, "", fim)
  if (sev!="") { printf "%s|%s|%s|%s\n", sev, reg, ini, fim }
}' "$H/inmet_lines.txt" > "$H/inmet_parsed.txt"
T=$(wc -l < "$H/inmet_parsed.txt")
RED=$(grep -c 'Grande Perigo' "$H/inmet_parsed.txt")
ORG=$(grep -c '^Perigo|' "$H/inmet_parsed.txt")
YEL=$(grep -c 'Perigo Potencial' "$H/inmet_parsed.txt")
echo "INMET_TOTAL=$T RED=$RED ORANGE=$ORG YELLOW=$YEL"
echo "--- 明细(等级|区域|起|止):"
cat "$H/inmet_parsed.txt"

# 今日红/橙预警 -> 短信文案
TODAY=$(date +%Y-%m-%d)
BR=$(awk -F'|' -v t="$TODAY" '$3==t && ($1=="Grande Perigo" || $1=="Perigo") {
  r=$2; gsub(/Centro-Oeste/,"中西部",r); gsub(/Sudeste/,"东南",r); gsub(/Sul/,"南部",r);
  gsub(/Nordeste/,"东北",r); gsub(/Norte/,"北部",r); gsub(/,/,"/",r);
  if ($1=="Grande Perigo") red=red r " "; else org=org r " " }
END { printf "BR_SMS=【巴西强对流】%s 红:%s 橙:%s\n", t, (red==""?"无":red), (org==""?"无":org) }' "$H/inmet_parsed.txt")
echo "$BR"
