#!/bin/bash

# estado wifi
estado=$(nmcli radio wifi)

if [ "$estado" = "disabled" ]; then
  opcion=$(printf "Activar WiFi" | rofi -dmenu -p "WiFi apagado")

  [ "$opcion" = "Activar WiFi" ] && nmcli radio wifi on
  exit
fi

redes=$(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list | sort -r -k4 -t:)

menu=$(echo "$redes" | awk -F: '{
    icon = ($1=="*") ? "󰖩 " : "󰖪 "
    printf "%s%s (%s%%)\n", icon, $2, $4
}')

seleccion=$(echo "$menu" | rofi -dmenu -p "WiFi")

ssid=$(echo "$seleccion" | sed 's/󰖩 //;s/󰖪 //;s/ (.*)//')

[ -z "$ssid" ] && exit

seguridad=$(echo "$redes" | grep ":$ssid:" | awk -F: '{print $3}')

if [ -z "$seguridad" ] || [ "$seguridad" = "--" ]; then
  nmcli dev wifi connect "$ssid"
else
  pass=$(rofi -dmenu -password -p "Password")
  nmcli dev wifi connect "$ssid" password "$pass"
fi
