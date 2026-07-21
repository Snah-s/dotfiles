#!/bin/bash

BAT=$(upower -e | grep battery | head -n 1)

if [ -z "$BAT" ]; then
  rofi -e "No se encontró batería"
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
    print "Estado: " state
    print "Carga: " percent
    print "Salud: " health
    if (tempty != "") print "Tiempo restante: " tempty
    if (tfull != "")  print "Tiempo para carga completa: " tfull
    if (rate != "")   print "Consumo/carga: " rate
    if (energy != "") print "Energía actual: " energy
    if (full != "")   print "Carga máxima actual: " full
    if (design != "") print "Carga máxima de diseño: " design
}')

rofi -e "$INFO" -normal-window -theme-str 'window { width: 420px; }'
