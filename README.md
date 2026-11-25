# 🌪 Tornado Watch — 美国/巴西龙卷风与强对流实时监测

一个开箱即用的龙卷风研究 + 预警系统：**自动抓取 NOAA/NWS 与巴西 INMET 的实时数据**，生成美国龙卷风分布图，并在网页上提供中英双语弹窗预警与每日简报。

> **免责声明 / Disclaimer**：本项目是研究、跟踪与可视化工具，**不是官方预警系统**。美国官方应急预警请以 [NWS](https://www.weather.gov/) 与手机 WEA 警报为准；巴西请以 [INMET](https://portal.inmet.gov.br/) 为准。

---

## ✨ 功能

| 功能 | 说明 |
|---|---|
| 🗺️ 全年分布图 | 抓取 SPC 逐日初步报告，生成美国龙卷风点位分布、州排名、月度柱状图 |
| 📋 每日简报 | 页面常驻卡片（不弹窗），中英双语，含美国 + 巴西，每小时更新 |
| 🚨 实时弹窗 | 页面每 60 秒轮询，出现新预警即弹中英双语卡片（含提示音） |
| 📱 手机端（可选） | DSH/Termux 规则：定时检查 + 短信告警 + 保活本地服务 |
| ⏱️ 全自动 | 服务器 cron：每月重绘图、每 5 分钟查预警、每小时出简报 |

---

## 🏗️ 架构

```
                 ┌─────────────────────────────┐
  NOAA/NWS  ───► │  cron 每 5 分钟              │
  SPC 逐日CSV ─► │  alerts_update.py            │──► alerts.json ──► alerts.js（弹窗）
  INMET     ───► │  brief_update.py（每小时）    │──► brief.json  ──► brief.js（简报卡片）
                 │  refresh.sh（每月 1 日）      │──► index.html  （分布图）
                 └─────────────────────────────┘
                              │  nginx :80
                              ▼
                     浏览器 / 手机

  可选：手机规则（DSH）──tornado_watch.sh──► 短信告警
```

---

## 📁 目录

```
server/   服务器端：抓取、绘图、简报、部署
  install.sh          一键部署（nginx + cron）
  build_page.sh       把逐日 CSV 画成 index.html
  refresh.sh          增量抓当年数据 + 触发绘图
  alerts_update.py    NWS + INMET → alerts.json
  brief_update.py     → brief.json（中英双语简报）
  nginx-tornado.conf  nginx 站点模板
web/      前端
  alerts.js           弹窗预警（含提示音、已读去重、Notification API）
  brief.js            简报卡片（可收起）
phone/    手机端（可选，Android + Termux/DSH）
  tornado_watch.sh    美国龙卷预警检查（去重）
  inmet_alerts.sh     巴西 INMET 强对流解析
  daily_brief.sh      昨日报告 + 今日展望
  alert_and_brief.sh  预警 + 简报合并（供定时规则调用）
  refresh_map.sh      增量更新本地分布图
  keepalive.sh        本地 HTTP 服务保活
docs/     文档
  API.md              数据源接口说明
  DEPLOY.md           部署与排错
```

---

## 🚀 快速开始

### 服务器（Ubuntu / Debian）

```bash
git clone https://github.com/YOUR_NAME/tornado-monitor.git
cd tornado-monitor
sudo bash server/install.sh tornado.yourdomain.com 1.2.3.4
```

脚本会安装 nginx、写入脚本、配置三个 cron 任务，并立即生成首份数据。

访问 `http://<你的IP>/` 即可看到分布图；DNS 生效后 `http://tornado.yourdomain.com/` 也可访问。

### 手机端（可选）

把 `phone/` 下脚本放到 Termux/DSH 的家目录，配置定时规则：

| 脚本 | 建议频率 | 作用 |
|---|---|---|
| `alert_and_brief.sh` | 每 30 分钟 | 检查美国 + 巴西预警、9 点后补发简报 |
| `refresh_map.sh` | 每月 1 次 | 本地分布图增量更新 |
| `keepalive.sh` | 每 15 分钟 | 保活本地 HTTP 服务（127.0.0.1:8097） |

---

## 📊 数据源

| 数据 | 接口 | 说明 |
|---|---|---|
| 龙卷预警 | `https://api.weather.gov/alerts/active?event=Tornado%20Warning&status=actual` | 免 Key，需带 User-Agent |
| 龙卷观望 | 同上，`event=Tornado%20Watch` | |
| 逐日报告 | `https://www.spc.noaa.gov/climo/reports/YYMMDD_rpts_torn.csv` | 每年约 365 个文件 |
| Day1 展望 | `https://www.spc.noaa.gov/products/outlook/day1otlk_cat.lyr.geojson` | 风险等级 |
| 龙卷概率 | `.../day1otlk_torn.lyr.geojson` | 概率区 |
| 巴西强对流 | `https://apiprevmet3.inmet.gov.br/avisos/ativos` | 需带 User-Agent |

详见 [docs/API.md](docs/API.md)。

---

## ⚠️ 已知限制

- 浏览器弹窗**只在页面打开时**生效；锁屏/关闭页面需要 HTTPS + Web Push
- SPC 逐日报告为**初步数据**，未定 EF 等级，正式年鉴以 NCEI 为准
- “报告条数” ≠ “龙卷个数”（同一次龙卷可能多点报告）
- 巴西 INMET 只提供暴雨/强风/冰雹等级，**无龙卷专属预警**；阿根廷 SMN 被 Cloudflare 拦截，暂未接入
- 全球范围内**不存在统一的官方龙卷预警 API**

---

## 📄 License

MIT
