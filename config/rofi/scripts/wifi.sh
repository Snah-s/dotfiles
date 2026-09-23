#!/bin/bash

# The same URI NetworkManager uses to detect portals. It has to be http: over
# https the portal can't intercept without breaking the certificate.
# (overridable via env so the redirect branch can be tested without a real portal)
CHECK_URI="${CHECK_URI:-http://ping.archlinux.org/nm-check.txt}"
PORTAL_ITEM="󰖟  Log in to the network"
RESCAN_ITEM="󰑐  Rescan"

# A captive portal intercepts the HTTP and redirects to its login, so we follow
# the redirect to get the real URL instead of guessing the gateway IP.
# -k because portals usually have their own certificate; here we only discover
# the URL, the browser validates on its own afterwards.
portal_url() {
  local url
  url=$(curl -skL -m 5 -o /dev/null -w '%{url_effective}' "$CHECK_URI" 2>/dev/null)
  if [ -z "$url" ] || [ "$url" = "$CHECK_URI" ]; then
    url="http://$(nmcli -g IP4.GATEWAY dev show | grep -m1 .)"
  fi
  printf '%s\n' "$url"
}

open_portal() { xdg-open "$(portal_url)" >/dev/null 2>&1 & }

# Sort by signal (numeric: with a bare -k4 "9" ends up above "100"), drop hidden
# networks and keep a single record per SSID. Without the dedup the same network
# shows up twice when there are several APs or two bands.
filter_networks() { sort -t: -k4,4nr | awk -F: '$2 != "" && !seen[$2]++'; }

# Exact match by field. With grep the SSID went in as a regex, so a name with
# . + [ matched another network or none at all.
security_of() { awk -F: -v s="$1" '$2 == s { print $3; exit }'; }

case "$1" in
portal-url) portal_url; exit ;;
selftest)
  fix=$' :TEKI:WPA2:9\n*:TEKI:WPA2:77\n :Casa+X:WPA2:100\n :Hidden::50\n :DAVID:WPA2:34\n :::80'
  got=$(printf '%s\n' "$fix" | filter_networks | awk -F: '{ printf "%s/%s ", $2, $4 }')
  [ "$got" = "Casa+X/100 TEKI/77 Hidden/50 DAVID/34 " ] ||
    { echo "FAIL order/dedup/hidden: $got"; exit 1; }
  [ "$(printf '%s\n' "$fix" | security_of 'Casa+X')" = "WPA2" ] ||
    { echo "FAIL: SSID with + does not match"; exit 1; }
  [ -z "$(printf '%s\n' "$fix" | security_of 'TEK')" ] ||
    { echo "FAIL: partial SSID match"; exit 1; }
  echo "selftest OK"; exit ;;
esac

# wifi state
state=$(nmcli radio wifi)

if [ "$state" = "disabled" ]; then
  option=$(printf "Turn WiFi on" | rofi -dmenu -p "WiFi off")

  [ "$option" = "Turn WiFi on" ] && nmcli radio wifi on
  exit
fi

# --rescan no skips NM's cache (0.03s instead of 4.5s). NM scans on its own in
# the background; the async rescan below keeps the next open fresh.
networks=$(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list --rescan no | filter_networks)
nmcli dev wifi rescan >/dev/null 2>&1 &

menu=$(echo "$networks" | awk -F: '{
    icon = ($1=="*") ? "󰖩 " : "󰖪 "
    printf "%s%s (%s%%)\n", icon, $2, $4
}')

menu="$RESCAN_ITEM"$'\n'"$menu"

# if the current network requires a web login, offer it at the very top
case "$(nmcli networking connectivity)" in
portal | limited) menu="$PORTAL_ITEM"$'\n'"$menu" ;;
esac

selection=$(echo "$menu" | rofi -dmenu -p "WiFi")

if [ "$selection" = "$PORTAL_ITEM" ]; then
  open_portal
  exit
fi

# blocking scan and start over: re-exec reuses the whole listing path instead of
# duplicating it. NM refuses a rescan right after the previous one, which is
# harmless here — the async rescan of the last open already refreshed the cache.
if [ "$selection" = "$RESCAN_ITEM" ]; then
  nmcli dev wifi rescan >/dev/null 2>&1
  exec "$0"
fi

ssid=$(echo "$selection" | sed 's/^[󰖩󰖪] //; s/ ([0-9]*%)$//')

[ -z "$ssid" ] && exit

security=$(echo "$networks" | security_of "$ssid")

if nmcli -g NAME connection show | grep -qxF "$ssid"; then
  # profile already saved: NM has the key, nothing to ask
  output=$(nmcli connection up id "$ssid" 2>&1)
  ok=$?
elif [ -z "$security" ] || [ "$security" = "--" ]; then
  output=$(nmcli dev wifi connect "$ssid" 2>&1)
  ok=$?
else
  pass=$(rofi -dmenu -password -p "Password")
  [ -z "$pass" ] && exit
  output=$(nmcli dev wifi connect "$ssid" password "$pass" 2>&1)
  ok=$?
fi

if [ "$ok" -ne 0 ]; then
  notify-send -a WiFi -u critical "󰖪  Could not connect" "$ssid — ${output##*: }"
  exit 1
fi

notify-send -a WiFi "󰖩  Connected" "$ssid"

# just connected: if the network wants a web login, open it without you having
# to look up the IP by hand (the 'check' forces the probe, the cached state
# still reports the previous network)
if [ "$(nmcli networking connectivity check)" = "portal" ]; then
  open_portal
fi
