#!/usr/bin/env python3
"""生成每日简报（中英双语，美国+巴西）-> /var/www/tornado/brief.json"""
import json, sys, os, datetime, urllib.request, csv, io

OUT = sys.argv[1] if len(sys.argv) > 1 else "/var/www/tornado"
UA = {"User-Agent": "tornado-site/1.0 (personal weather research)"}
ZH_REGION = [("Centro-Oeste", "中西部"), ("Sudeste", "东南部"), ("Sul", "南部"),
             ("Nordeste", "东北部"), ("Norte", "北部")]
ZH_SEV = {"Grande Perigo": "红色警报", "Perigo": "橙色警报"}

def get(url, timeout=35):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

def zh_regions(s):
    for k, v in ZH_REGION:
        s = s.replace(k, v)
    return s.replace(",", "/")

us = {"count": 0, "top": [], "cat": "?", "prob": 0, "watch": 0, "ok": False}
try:
    raw = get("https://www.spc.noaa.gov/climo/reports/yesterday_torn.csv").decode("utf-8", "ignore")
    rows = [r for r in csv.reader(io.StringIO(raw)) if len(r) >= 8 and r[0] != "Time"]
    us["count"] = len(rows)
    cnt = {}
    for r in rows:
        cnt[r[4]] = cnt.get(r[4], 0) + 1
    us["top"] = sorted(cnt.items(), key=lambda x: -x[1])[:3]
    us["ok"] = True
except Exception as e:
    print("US_REPORT_FAIL", e)

try:
    d = json.loads(get("https://www.spc.noaa.gov/products/outlook/day1otlk_cat.lyr.geojson"))
    rank = {"TSTM": 1, "MRGL": 2, "SLGT": 3, "ENH": 4, "MDT": 5, "HIGH": 6}
    best = "TSTM"
    for f in d.get("features", []):
        lab = (f.get("properties") or {}).get("LABEL", "")
        if rank.get(lab, 0) > rank.get(best, 0):
            best = lab
    us["cat"] = best
except Exception as e:
    print("US_CAT_FAIL", e)

try:
    d = json.loads(get("https://www.spc.noaa.gov/products/outlook/day1otlk_torn.lyr.geojson"))
    mx = 0
    for f in d.get("features", []):
        lab = str((f.get("properties") or {}).get("LABEL", ""))
        num = "".join(c for c in lab.split("All Areas")[0] if c.isdigit() or c == ".")
        try:
            mx = max(mx, int(float(num)))
        except Exception:
            pass
    us["prob"] = mx
except Exception as e:
    print("US_PROB_FAIL", e)

try:
    d = json.loads(get("https://api.weather.gov/alerts/active?event=Tornado%20Watch&status=actual"))
    us["watch"] = len(d.get("features", []))
except Exception as e:
    print("US_WATCH_FAIL", e)

br = {"red": [], "org": [], "ok": False, "n": 0}
try:
    d = json.loads(get("https://apiprevmet3.inmet.gov.br/avisos/ativos"))
    today = datetime.date.today().isoformat()
    for a in list(d.get("hoje") or []) + list(d.get("futuro") or []):
        sev = a.get("severidade") or ""
        ini = (a.get("data_inicio") or "")[:10]
        fim = (a.get("data_fim") or "")[:10]
        if sev not in ("Grande Perigo", "Perigo") or not (ini <= today <= fim):
            continue
        br["n"] += 1
        (br["red"] if sev == "Grande Perigo" else br["org"]).append(a.get("regioes") or "")
    br["ok"] = True
except Exception as e:
    print("BR_FAIL", e)

CAT_ZH = {"TSTM": "无强对流风险区", "MRGL": "边缘风险", "SLGT": "一般风险",
          "ENH": "增强风险", "MDT": "中度风险", "HIGH": "高度风险"}
CAT_EN = {"TSTM": "general thunderstorms", "MRGL": "marginal risk", "SLGT": "slight risk",
          "ENH": "enhanced risk", "MDT": "moderate risk", "HIGH": "high risk"}
today_s = datetime.date.today().strftime("%m-%d")

top_zh = "、".join("%s %d 条" % (s, n) for s, n in us["top"]) if us["top"] else "无"
if us["count"] == 0:
    us_txt_zh = "昨日全美无龙卷报告；今日 SPC Day1 展望为%s（%s），龙卷概率 %d%%；当前活跃龙卷观望（Watch）%d 条。" % (
        CAT_ZH.get(us["cat"], us["cat"]), us["cat"], us["prob"], us["watch"])
else:
    us_txt_zh = "昨日全美龙卷报告 %d 条，热点：%s；今日 SPC Day1 展望为%s（%s），龙卷概率 %d%%；活跃龙卷观望 %d 条。" % (
        us["count"], top_zh, CAT_ZH.get(us["cat"], us["cat"]), us["cat"], us["prob"], us["watch"])

def br_txt_zh():
    if br["n"] == 0:
        return "今日无红色或橙色强对流警报。"
    parts = []
    if br["red"]:
        parts.append("红色警报（%s）" % zh_regions("；".join(sorted(set(br["red"])))))
    if br["org"]:
        parts.append("橙色警报（%s）" % zh_regions("；".join(sorted(set(br["org"])))))
    return "今日有 " + "，".join(parts) + "，主要风险为强风、冰雹与短时暴雨。"

zh = "【每日简报 %s】<br><b>🇺🇸 美国</b>：%s<br><b>🇧🇷 巴西</b>：%s<br><span style='color:#8fa3b8;font-size:12px'>数据：NOAA/NWS SPC、INMET；美国为初步报告，正式数据以 NCEI 年鉴为准。每日自动更新。</span>" % (
    today_s, us_txt_zh, br_txt_zh())

top_en = ", ".join("%s %d" % (s, n) for s, n in us["top"]) if us["top"] else "none"
if us["count"] == 0:
    us_txt_en = "No tornado reports yesterday. Today's SPC Day 1 outlook: %s (%d%% tornado probability, %d active watch(es))." % (
        CAT_EN.get(us["cat"], us["cat"]), us["prob"], us["watch"])
else:
    us_txt_en = "%d tornado reports yesterday (top: %s). Today's SPC Day 1 outlook: %s (%d%% tornado probability, %d active watch(es))." % (
        us["count"], top_en, CAT_EN.get(us["cat"], us["cat"]), us["prob"], us["watch"])

br_txt_en = "No red/orange severe weather alerts today." if br["n"] == 0 else (
    "Severe weather alerts active: %d red (Grande Perigo), %d orange (Perigo). Main hazards: strong wind, hail and heavy rain." % (
        len(br["red"]), len(br["org"])))
en = "Daily Brief %s — US: %s Brazil: %s Source: NOAA/NWS SPC, INMET. Preliminary US reports." % (today_s, us_txt_en, br_txt_en)

os.makedirs(OUT, exist_ok=True)
data = {"date": today_s, "updated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "zh": zh, "en": en, "us": us, "br": {"red": len(br["red"]), "org": len(br["org"])}}
tmp = os.path.join(OUT, "brief.json.tmp")
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)
os.replace(tmp, os.path.join(OUT, "brief.json"))
print("BRIEF_OK", us["count"], us["cat"], br["n"])
