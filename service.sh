#!/system/bin/sh

# Log file path
LOGFILE=/data/local/tmp/pimax_fan.log

# Fan control node (range: 30–60, values below 30 are invalid, 0 means off)
FAN_NODE="/sys/devices/platform/soc/soc:pimax_soc_pwm_fan/fan"

# Thermal sensor nodes for temperature reference
THERMAL_ZONES=(
    "/sys/class/thermal/thermal_zone4/temp"
    "/sys/class/thermal/thermal_zone15/temp"
)

# Clear previous log
> "$LOGFILE"

# Check if all required nodes exist
for Z in "${THERMAL_ZONES[@]}" "$FAN_NODE"; do
    if [ ! -f "$Z" ]; then
        echo "[!] Missing node: $Z" >> "$LOGFILE"
        exit 1
    fi
done

# Store current fan speed to avoid redundant writes
CURRENT_SPEED=-1
FAN_ON=0            # Track whether the fan is currently on (for hysteresis)
FORCE_MAX_SPEED=0   # Track whether max fan speed is forced due to high temperature

set_fan_speed() {
    temp_avg=$1
    new_speed=0

    # If average temperature >= 95°C, force fan to max (70)
    if [ "$temp_avg" -ge 95000 ]; then
        FORCE_MAX_SPEED=1
    elif [ "$temp_avg" -lt 90000 ]; then
        # Cancel forced max speed when temperature drops below 90°C
        FORCE_MAX_SPEED=0
    fi

    if [ "$FORCE_MAX_SPEED" -eq 1 ]; then
        # Force fan to stay at max speed due to high temperature
        new_speed=70
        FAN_ON=1
    elif [ "$FAN_ON" -eq 1 ]; then
        # Fan is currently on; keep running unless temperature drops below 50°C
        if [ "$temp_avg" -lt 50000 ]; then
            new_speed=0
            FAN_ON=0
        elif [ "$temp_avg" -ge 90000 ]; then
            new_speed=60
        elif [ "$temp_avg" -ge 85000 ]; then
            new_speed=55
        elif [ "$temp_avg" -ge 80000 ]; then
            new_speed=50
        elif [ "$temp_avg" -ge 75000 ]; then
            new_speed=45
        elif [ "$temp_avg" -ge 70000 ]; then
            new_speed=40
        elif [ "$temp_avg" -ge 65000 ]; then
            new_speed=35
        elif [ "$temp_avg" -ge 60000 ]; then
            new_speed=35
        else
            new_speed=$CURRENT_SPEED  # No change
        fi
    else
        # Fan is currently off; turn on only if temperature >= 60°C
        if [ "$temp_avg" -ge 90000 ]; then
            new_speed=60
            FAN_ON=1
        elif [ "$temp_avg" -ge 85000 ]; then
            new_speed=55
            FAN_ON=1
        elif [ "$temp_avg" -ge 80000 ]; then
            new_speed=50
            FAN_ON=1
        elif [ "$temp_avg" -ge 75000 ]; then
            new_speed=45
            FAN_ON=1
        elif [ "$temp_avg" -ge 70000 ]; then
            new_speed=40
            FAN_ON=1
        elif [ "$temp_avg" -ge 65000 ]; then
            new_speed=35
            FAN_ON=1
        elif [ "$temp_avg" -ge 60000 ]; then
            new_speed=35
            FAN_ON=1
        else
            new_speed=0
        fi
    fi

    # Write new fan speed only if it differs from current
    if [ "$new_speed" != "$CURRENT_SPEED" ]; then
        echo "$new_speed" > "$FAN_NODE" 2>> "$LOGFILE"
        if [ $? -ne 0 ]; then
            echo "$(date): Failed to set fan speed to $new_speed" >> "$LOGFILE"
        else
            echo "$(date): Set fan speed to $new_speed" >> "$LOGFILE"
            CURRENT_SPEED=$new_speed
        fi
    fi
}

# Main loop
while true; do
    total=0
    count=0

    for Z in "${THERMAL_ZONES[@]}"; do
        T=$(cat "$Z" 2>/dev/null)
        if echo "$T" | grep -qE '^[0-9]+$'; then
            total=$((total + T))
            count=$((count + 1))
        else
            echo "$(date): Invalid temp read from $Z: $T" >> "$LOGFILE"
        fi
    done

    if [ "$count" -gt 0 ]; then
        avg=$((total / count))
        echo "$(date): Temp avg: $avg" >> "$LOGFILE"
        set_fan_speed "$avg"
    else
        echo "$(date): No valid temperature readings." >> "$LOGFILE"
    fi

    sleep 5
done
