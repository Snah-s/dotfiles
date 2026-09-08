#!/bin/bash

BAT=$(upower -e | grep battery | head -n 1)

if [ -z "$BAT" ]; then
  rofi -e "No battery found"
  exit 1
fi

INFO=$(upower -i "$BAT" | awk -F: '
/state/              {gsub(/^[ \t]+/, "", $2); state=$2}
/percentage/         {gsub(/^[ \t]+/, "", $2); percent=$2}
/capacity/           {gsub(/^[ \t]+/, "", $2); health=$2}
/time to empty/      {gsub(/^[ \t]+/, "", $2); tempty=$2}
/time to full/       {gsub(/^[ \t]+/, "", $2); tfull=$2}
/energy-rate/        {gsub(/^[ \t]+/, "", $2); rate=$2}
/energy:/            {gsub(/^[ \t]+/, "", $2); energy=$2}
/energy-full:/       {gsub(/^[ \t]+/, "", $2); full=$2}
/energy-full-design/ {gsub(/^[ \t]+/, "", $2); design=$2}
END {
    print "State: " state
    print "Charge: " percent
    print "Health: " health
    if (tempty != "") print "Time remaining: " tempty
    if (tfull != "")  print "Time to full charge: " tfull
    if (rate != "")   print "Discharge/charge rate: " rate
    if (energy != "") print "Current energy: " energy
    if (full != "")   print "Current max charge: " full
    if (design != "") print "Design max charge: " design
}')

rofi -e "$INFO" -normal-window -theme-str 'window { width: 420px; }'
