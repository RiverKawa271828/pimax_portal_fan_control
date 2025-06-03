#!/system/bin/sh

SERVICE_PATH="/data/adb/modules/pimax-fan-control-test/service.sh"
LOGFILE="/data/local/tmp/pimax_fan_watchdog.log"

while true; do
    # Check if service.sh is running
    RUNNING=$(pgrep -f "$SERVICE_PATH")

    if [ -z "$RUNNING" ]; then
        echo "$(date): service.sh not running, starting it..." >> "$LOGFILE"
        nohup sh "$SERVICE_PATH" >/dev/null 2>&1 &
    fi

    sleep 10
done
