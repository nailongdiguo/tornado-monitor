# 部署与排错

## 服务器部署
```bash
sudo bash server/install.sh 你的域名.com 你的服务器IP
```

### 定时任务
```
0 6 1 * *   refresh.sh          # 每月 1 日重绘分布图
*/5 * * * * alerts_update.py    # 每 5 分钟更新 alerts.json
5 * * * *   brief_update.py     # 每小时更新 brief.json
```

### 验证
```bash
curl -I http://127.0.0.1/                    # 200
curl http://127.0.0.1/alerts.json | head      # 有 alerts 数组
curl http://127.0.0.1/brief.json | head       # 有 zh/en
tail -5 /var/log/tornado.log                  # MAP_OK ...
```

## 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| 403 Forbidden | index.html 还没生成 | 等待 refresh.sh 抓完，或手动 `bash /opt/tornado/refresh.sh` |
| 404 index.html | root 目录不对 | 检查 nginx `root /var/www/tornado` |
| 直接访问 IP 是 nginx 欢迎页 | `server_name` 未含该 IP | 在 server_name 里加上 IP |
| alerts.json 为空 | NWS/INMET 无活跃预警 | 正常，等下次 |
| INMET 连接被重置 | 缺少 User-Agent | 用 curl -A 或 urllib 带 header |
| 页面显示“加载中…” | JS 被 nginx 缓存或路径错 | 加 `?v=1` 强制刷新；确认 alerts.js 可访问 |

## 前端注入
`install.sh` 会把 `alerts.js` / `brief.js` 复制到站点目录，但**不会自动改 index.html**。
注入方式（二选一）：
1. 手动在 `index.html` 的 `</body>` 前加：
   ```html
   <script src="alerts.js?v=1"></script>
   <script src="brief.js?v=1"></script>
   ```
2. 或运行 `python3 server/inject.py`（如提供）

> 每次 `refresh.sh` 会重写 index.html，若需要永久生效，应把注入逻辑加到 `build_page.sh` 的输出模板里。
