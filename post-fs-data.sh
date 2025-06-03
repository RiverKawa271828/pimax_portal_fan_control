#!/system/bin/sh

# Module directory
MODDIR="/data/adb/modules/pimax-fan-control-test"

# Start the watchdog script
if [ -f "$MODDIR/watchdog.sh" ]; then
    # Check if the watchdog script is already running
    if ! pgrep -f "$MODDIR/watchdog.sh" > /dev/null; then
        nohup sh "$MODDIR/watchdog.sh" >/dev/null 2>&1 &
    fi
fi
