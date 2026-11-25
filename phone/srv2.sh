#!/system/bin/sh
PORT="$2"; FILE="$1"
while :; do
  { printf 'HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n' "$(wc -c < "$FILE")"; cat "$FILE"; } | nc -l -p "$PORT" 2>/dev/null
  sleep 0.2
done
