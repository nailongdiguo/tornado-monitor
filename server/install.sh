#!/bin/bash
# 一键部署：Ubuntu/Debian + nginx + 定时任务
# 用法: sudo bash install.sh [域名] [服务器IP]
set -e
DOMAIN="${1:-example.com}"
IP="${2:-$(curl -s -4 ifconfig.me || true)}"
export DEBIAN_FRONTEND=noninteractive

echo "==> 安装依赖"
apt-get update -y >/dev/null
apt-get install -y nginx curl gawk cron python3 >/dev/null

mkdir -p /opt/tornado /var/www/tornado
SRC="$(cd "$(dirname "$0")" && pwd)"

echo "==> 复制脚本"
cp "$SRC"/build_page.sh "$SRC"/refresh.sh "$SRC"/alerts_update.py "$SRC"/brief_update.py /opt/tornado/
chmod +x /opt/tornado/*.sh /opt/tornado/*.py
cp "$SRC"/../web/alerts.js "$SRC"/../web/brief.js /var/www/tornado/ 2>/dev/null || true

echo "==> 下载美国州界数据"
curl -fsSL -o /opt/tornado/states.json \
  "https://cdn.jsdelivr.net/gh/PublicaMundi/MappingAPI@master/data/geojson/us-states.json"

echo "==> 配置 nginx"
cat > /etc/nginx/sites-available/tornado <<CONF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} ${IP};
    root /var/www/tornado;
    index index.html;
    add_header Cache-Control "no-cache";
}
CONF
ln -sf /etc/nginx/sites-available/tornado /etc/nginx/sites-enabled/tornado
nginx -t && systemctl enable nginx >/dev/null 2>&1 || true
systemctl restart nginx
command -v ufw >/dev/null 2>&1 && ufw allow 80/tcp >/dev/null 2>&1 || true

echo "==> 配置定时任务"
( crontab -l 2>/dev/null | grep -v -e refresh.sh -e alerts_update.py -e brief_update.py
  echo "0 6 1 * * /bin/bash /opt/tornado/refresh.sh >> /var/log/tornado.log 2>&1"
  echo "*/5 * * * * /usr/bin/python3 /opt/tornado/alerts_update.py >> /var/log/tornado_alerts.log 2>&1"
  echo "5 * * * * /usr/bin/python3 /opt/tornado/brief_update.py >> /var/log/tornado_brief.log 2>&1"
) | crontab -

echo "==> 首次生成"
bash /opt/tornado/refresh.sh || true
python3 /opt/tornado/alerts_update.py || true
python3 /opt/tornado/brief_update.py || true

echo "----------------------------------------"
echo "完成： http://${IP}/   或   http://${DOMAIN}/"
echo "日志： tail -f /var/log/tornado.log"
echo "----------------------------------------"
