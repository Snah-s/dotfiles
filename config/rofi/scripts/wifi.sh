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

# Records are IN-USE:SIGNAL:SECURITY:SSID from `nmcli -t -e no`. The SSID goes
# last and is everything after the 3rd colon: a name can contain ":" itself
# ("Casa:5G"), and -e no keeps it raw instead of escaping it as "\:".
SSID_AWK='{ ssid = $0; sub(/^([^:]*:){3}/, "", ssid) }'

# Sort by signal (numeric: with a bare -k2 "9" ends up above "100"), drop hidden
# networks and keep a single record per SSID. Without the dedup the same network
# shows up twice when there are several APs or two bands. The row shown is the
# AP you are connected to, if any (so the connected icon is not lost when another
# AP of the same network is stronger); its place in the list is the strongest one's.
filter_networks() {
  sort -t: -k2,2nr | awk -F: "$SSID_AWK"' ssid != "" {
    if (!(ssid in rec)) { order[++n] = ssid; rec[ssid] = $0 }
    if ($1 == "*") rec[ssid] = $0
  } END { for (i = 1; i <= n; i++) print rec[order[i]] }'
}

# Exact match by field. With grep the SSID went in as a regex, so a name with
# . + [ matched another network or none at all. ENVIRON, not -v: -v would eat
# backslashes in the name.
security_of() { S="$1" awk -F: "$SSID_AWK"' ssid == ENVIRON["S"] { print $3; exit }'; }

case "$1" in
portal-url) portal_url; exit ;;
selftest)
  # TEKI: connected to the weaker AP (77) while a stronger one (90) is visible
  fix=$' :90:WPA2:TEKI\n*:77:WPA2:TEKI\n :100:WPA2:Casa+X\n :50::Hidden\n :34:WPA2:DAVID\n :80::\n :60:WPA3:Casa:5G'
  got=$(printf '%s\n' "$fix" | filter_networks | awk -F: "$SSID_AWK"' { printf "%s%s/%s ", ($1 == "*" ? "*" : ""), ssid, $2 }')
  [ "$got" = "Casa+X/100 *TEKI/77 Casa:5G/60 Hidden/50 DAVID/34 " ] ||
    { echo "FAIL order/dedup/hidden/in-use: $got"; exit 1; }
  [ "$(printf '%s\n' "$fix" | security_of 'Casa+X')" = "WPA2" ] ||
    { echo "FAIL: SSID with + does not match"; exit 1; }
  [ "$(printf '%s\n' "$fix" | security_of 'Casa:5G')" = "WPA3" ] ||
    { echo "FAIL: SSID with : does not match"; exit 1; }
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
networks=$(nmcli -t -e no -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan no | filter_networks)
nmcli dev wifi rescan >/dev/null 2>&1 &

menu=$(echo "$networks" | awk -F: "$SSID_AWK"' {
    icon = ($1=="*") ? "󰖩 " : "󰖪 "
    printf "%s%s (%s%%)\n", icon, ssid, $2
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

if nmcli -e no -g NAME connection show | grep -qxF "$ssid"; then
  # profile already saved: NM has the key, nothing to ask
  output=$(nmcli connection up id "$ssid" 2>&1)
  ok=$?
elif [ -z "$security" ] || [ "$security" = "--" ]; then
  output=$(nmcli dev wifi connect "$ssid" 2>&1)
  ok=$?
else
  pass=$(rofi -dmenu -password -p "Password")
  [ -z "$pass" ] && exit
  # via stdin, not `password "$pass"`: arguments are readable by anyone in `ps`.
  # printf is a builtin, so the key never shows up in a process list.
  output=$(printf '%s\n' "$pass" | nmcli --ask dev wifi connect "$ssid" 2>&1)
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
