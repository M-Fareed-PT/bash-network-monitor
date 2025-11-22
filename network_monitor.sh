#!/bin/bash
# network_monitor_pro.sh — Professional network monitor with CSV logging

# ------------------- CONFIG -------------------
HOSTS=("8.8.8.8" "1.1.1.1" "github.com" "tryhackme.com")
LOGDIR="$HOME/network_logs"
LOGFILE="$LOGDIR/network_status.csv"
INTERVAL=10  # seconds between checks

# Optional alert (configure)
ALERT_EMAIL=""        # your email for alerts
ALERT_DISCORD_WEBHOOK=""  # your webhook URL

# Create log directory
mkdir -p "$LOGDIR"

# Initialize CSV log
if [ ! -f "$LOGFILE" ]; then
    echo "timestamp,host,status,latency_ms" > "$LOGFILE"
fi

echo "🚀 Network Monitor started. Logging to $LOGFILE"

# ------------------- MONITOR LOOP -------------------
while true; do
    TIMESTAMP=$(date -Iseconds)
    for HOST in "${HOSTS[@]}"; do
        PING_RESULT=$(ping -c 1 -W 2 "$HOST" 2>/dev/null)
        if [ $? -eq 0 ]; then
            LATENCY=$(echo "$PING_RESULT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
            STATUS="UP"
        else
            LATENCY=""
            STATUS="DOWN"
        fi

        # Log to CSV
        echo "$TIMESTAMP,$HOST,$STATUS,$LATENCY" >> "$LOGFILE"

        # Optional alert
        if [ "$STATUS" == "DOWN" ]; then
            echo "⚠️ $HOST is DOWN at $TIMESTAMP"
            if [ -n "$ALERT_EMAIL" ]; then
                echo "$HOST is DOWN at $TIMESTAMP" | mail -s "Network Alert" "$ALERT_EMAIL"
            fi
            if [ -n "$ALERT_DISCORD_WEBHOOK" ]; then
                curl -s -H "Content-Type: application/json" \
                    -d "{\"content\":\"⚠️ $HOST is DOWN at $TIMESTAMP\"}" \
                    "$ALERT_DISCORD_WEBHOOK" >/dev/null
            fi
        else
            echo "[+] $HOST is UP (Latency: ${LATENCY} ms)"
        fi
    done
    sleep $INTERVAL
done
