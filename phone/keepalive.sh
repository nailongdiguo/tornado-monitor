#!/system/bin/sh
# 确保分布图本地服务在跑（每次被规则/手动调用时检查一次）
H="$HOME"
PORT=8097
curl -s -m 2 -o /dev/null "http://127.0.0.1:$PORT/" && { echo "ALREADY_UP"; exit 0; }
nohup sh "$H/srv2.sh" "$H/tornado_map.html" "$PORT" >/dev/null 2>&1 &
sleep 1
code=$(curl -s -m 3 -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/")
echo "STARTED http=$code"
