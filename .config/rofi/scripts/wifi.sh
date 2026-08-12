#!/bin/bash

# El mismo URI que usa NetworkManager para detectar portales. Tiene que ser
# http: sobre https el portal no puede interceptar sin romper el certificado.
# (overridable por env para poder probar la rama del redirect sin un portal real)
CHECK_URI="${CHECK_URI:-http://ping.archlinux.org/nm-check.txt}"
PORTAL_ITEM="󰖟  Iniciar sesión en la red"

# Un portal cautivo intercepta el HTTP y redirige a su login, así que seguimos
# la redirección para sacar la URL real en vez de adivinar la IP del gateway.
# -k porque los portales suelen tener certificado propio; acá solo descubrimos
# la URL, el browser después valida por su cuenta.
portal_url() {
  local url
  url=$(curl -skL -m 5 -o /dev/null -w '%{url_effective}' "$CHECK_URI" 2>/dev/null)
  if [ -z "$url" ] || [ "$url" = "$CHECK_URI" ]; then
    url="http://$(nmcli -g IP4.GATEWAY dev show | grep -m1 .)"
  fi
  printf '%s\n' "$url"
}

abrir_portal() { xdg-open "$(portal_url)" >/dev/null 2>&1 & }

# Ordena por señal (numérico: con -k4 a secas "9" queda arriba de "100"),
# descarta redes ocultas y deja un solo registro por SSID. Sin el dedup la
# misma red aparece dos veces cuando hay varios APs o dos bandas.
filtrar_redes() { sort -t: -k4,4nr | awk -F: '$2 != "" && !visto[$2]++'; }

# Match exacto por campo. Con grep el SSID entraba como regex, así que un
# nombre con . + [ matcheaba otra red o ninguna.
seguridad_de() { awk -F: -v s="$1" '$2 == s { print $3; exit }'; }

case "$1" in
portal-url) portal_url; exit ;;
selftest)
  fix=$' :TEKI:WPA2:9\n*:TEKI:WPA2:77\n :Casa+X:WPA2:100\n :Oculta::50\n :DAVID:WPA2:34\n :::80'
  got=$(printf '%s\n' "$fix" | filtrar_redes | awk -F: '{ printf "%s/%s ", $2, $4 }')
  [ "$got" = "Casa+X/100 TEKI/77 Oculta/50 DAVID/34 " ] ||
    { echo "FALLO orden/dedup/ocultas: $got"; exit 1; }
  [ "$(printf '%s\n' "$fix" | seguridad_de 'Casa+X')" = "WPA2" ] ||
    { echo "FALLO: SSID con + no matchea"; exit 1; }
  [ -z "$(printf '%s\n' "$fix" | seguridad_de 'TEK')" ] ||
    { echo "FALLO: match parcial de SSID"; exit 1; }
  echo "selftest OK"; exit ;;
esac

# estado wifi
estado=$(nmcli radio wifi)

if [ "$estado" = "disabled" ]; then
  opcion=$(printf "Activar WiFi" | rofi -dmenu -p "WiFi apagado")

  [ "$opcion" = "Activar WiFi" ] && nmcli radio wifi on
  exit
fi

# --rescan no lee el cache de NM (0.03s en vez de 4.5s). NM escanea solo en
# background; el rescan async de abajo deja fresca la próxima apertura.
redes=$(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list --rescan no | filtrar_redes)
nmcli dev wifi rescan >/dev/null 2>&1 &

menu=$(echo "$redes" | awk -F: '{
    icon = ($1=="*") ? "󰖩 " : "󰖪 "
    printf "%s%s (%s%%)\n", icon, $2, $4
}')

# si la red actual exige login web, ofrecerlo arriba de todo
case "$(nmcli networking connectivity)" in
portal | limited) menu="$PORTAL_ITEM"$'\n'"$menu" ;;
esac

seleccion=$(echo "$menu" | rofi -dmenu -p "WiFi")

if [ "$seleccion" = "$PORTAL_ITEM" ]; then
  abrir_portal
  exit
fi

ssid=$(echo "$seleccion" | sed 's/^[󰖩󰖪] //; s/ ([0-9]*%)$//')

[ -z "$ssid" ] && exit

seguridad=$(echo "$redes" | seguridad_de "$ssid")

if nmcli -g NAME connection show | grep -qxF "$ssid"; then
  # perfil ya guardado: NM tiene la clave, no hay nada que preguntar
  salida=$(nmcli connection up id "$ssid" 2>&1)
  ok=$?
elif [ -z "$seguridad" ] || [ "$seguridad" = "--" ]; then
  salida=$(nmcli dev wifi connect "$ssid" 2>&1)
  ok=$?
else
  pass=$(rofi -dmenu -password -p "Password")
  [ -z "$pass" ] && exit
  salida=$(nmcli dev wifi connect "$ssid" password "$pass" 2>&1)
  ok=$?
fi

if [ "$ok" -ne 0 ]; then
  notify-send -a WiFi -u critical "󰖪  No se pudo conectar" "$ssid — ${salida##*: }"
  exit 1
fi

notify-send -a WiFi "󰖩  Conectado" "$ssid"

# recién conectado: si la red pide login web, abrirlo sin que tengas que
# averiguar la IP a mano (el 'check' fuerza el sondeo, el estado cacheado
# todavía dice lo de la red anterior)
if [ "$(nmcli networking connectivity check)" = "portal" ]; then
  abrir_portal
fi
