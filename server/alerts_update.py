#!/usr/bin/env python3
"""抓取美国 NWS 龙卷预警 + 巴西 INMET 强对流警报 -> /var/www/tornado/alerts.json"""
import json, sys, os, datetime, urllib.request

OUT = sys.argv[1] if len(sys.argv) > 1 else "/var/www/tornado"
UA = {"User-Agent": "tornado-site/1.0 (personal weather research)"}

def get(url, timeout=30):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

alerts = []

# ---------- 美国 NWS 龙卷预警 ----------
try:
    d = json.loads(get("https://api.weather.gov/alerts/active?event=Tornado%20Warning&status=actual"))
    for f in d.get("features", []):
        p = f.get("properties") or {}
        alerts.append({
            "id": f.get("id") or p.get("@id") or "",
            "source": "US",
            "severity": p.get("severity") or "",
            "area": (p.get("areaDesc") or "").replace('"', "'"),
            "start": p.get("onset") or p.get("effective") or "",
            "end": p.get("ends") or p.get("expires") or "",
            "headline": (p.get("headline") or "").replace('"', "'"),
        })
except Exception as e:
    print("US_FAIL", e)

# ---------- 巴西 INMET 强对流 ----------
try:
    d = json.loads(get("https://apiprevmet3.inmet.gov.br/avisos/ativos"))
    today = datetime.date.today().isoformat()
    for a in list(d.get("hoje") or []) + list(d.get("futuro") or []):
        sev = a.get("severidade") or ""
        ini = (a.get("data_inicio") or "")[:10]
        fim = (a.get("data_fim") or "")[:10]
        if sev not in ("Grande Perigo", "Perigo"):
            continue
        if not (ini <= today <= fim):
            continue
        alerts.append({
            "id": "INMET-" + str(a.get("id_aviso") or a.get("id") or ""),
            "source": "BR",
            "severity": sev,
            "area": a.get("regioes") or "",
            "start": ini,
            "end": fim,
            "headline": sev,
        })
except Exception as e:
    print("BR_FAIL", e)

os.makedirs(OUT, exist_ok=True)
tmp = os.path.join(OUT, "alerts.json.tmp")
with open(tmp, "w", encoding="utf-8") as f:
    json.dump({
        "updated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "count": len(alerts),
        "alerts": alerts,
    }, f, ensure_ascii=False)
os.replace(tmp, os.path.join(OUT, "alerts.json"))
print("ALERTS_OK", len(alerts))
