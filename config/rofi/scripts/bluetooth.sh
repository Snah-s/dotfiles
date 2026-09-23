#!/bin/bash
# Bluetooth menu in rofi — sibling of wifi.sh, reachable from settings.sh.
#
# bluetoothctl is the whole backend: it already talks to BlueZ over D-Bus and
# prints stable, greppable lines. No bluez python bindings, no busctl.
#
# Traps:
#   · a controller can be Powered: no because rfkill soft-blocked it
#     (PowerState: off-blocked). `power on` alone fails there, hence the unblock.
#   · `scan on` never returns, so it is always run with --timeout.
#   · device names contain spaces and dots, so a row is parsed back by its LAST
#     field (the MAC), never by regex over the name.

BT=bluetoothctl
SCAN_SECS="${SCAN_SECS:-8}"

# dev_rows <connected macs> <paired macs>   < `bluetoothctl devices`
dev_rows() {
  awk -v c="$1" -v p="$2" '
    BEGIN {
      n = split(c, a, "\n"); for (i = 1; i <= n; i++) if (a[i] != "") con[a[i]] = 1
      n = split(p, b, "\n"); for (i = 1; i <= n; i++) if (b[i] != "") par[b[i]] = 1
    }
    $1 == "Device" {
      mac = $2; name = $0; sub(/^Device [^ ]+ */, "", name)
      if (name == "") name = mac
      icon = con[mac] ? "󰂱" : (par[mac] ? "󰂯" : "󰂰")
      printf "%s  %s  ·  %s\n", icon, name, mac
    }'
}

case "$1" in
selftest)
  got=$(printf 'Device AA:BB:CC:DD:EE:01 Sony WH-1000XM4\nDevice AA:BB:CC:DD:EE:02 OPPO Reno14 F 5G\nDevice AA:BB:CC:DD:EE:03 AA-BB-CC-DD-EE-03\n' |
    dev_rows 'AA:BB:CC:DD:EE:01' $'AA:BB:CC:DD:EE:01\nAA:BB:CC:DD:EE:02')
  want='󰂱  Sony WH-1000XM4  ·  AA:BB:CC:DD:EE:01
󰂯  OPPO Reno14 F 5G  ·  AA:BB:CC:DD:EE:02
󰂰  AA-BB-CC-DD-EE-03  ·  AA:BB:CC:DD:EE:03'
  [ "$got" = "$want" ] || { echo "FAIL rows:"; echo "$got"; exit 1; }
  row='󰂯  OPPO Reno14 F 5G  ·  AA:BB:CC:DD:EE:02'
  [ "${row##* }" = "AA:BB:CC:DD:EE:02" ] || { echo "FAIL mac extraction"; exit 1; }
  echo "selftest OK"; exit ;;
esac

menu() { # menu <prompt> <options> [mesg]
  local args=(-dmenu -i -p "$1")
  [ -n "$3" ] && args+=(-mesg "$3")
  printf '%b\n' "$2" | rofi "${args[@]}"
}

notify() { notify-send -a Bluetooth "$1" "${2:-}"; }

# `show`/`info` dump 40+ lines: every UUID in full and, for the controller, the
# whole advertising capability table. Keep the fields worth reading, collapse the
# "0x64 (100)" pairs to the decimal and the UUIDs to their profile names.
compact() {
  awk '
    NR == 1 { print; next }
    /^[[:space:]]*UUID:/ {
      sub(/^[[:space:]]*UUID:[[:space:]]*/, ""); sub(/[[:space:]]*\([0-9a-f-]+\)[[:space:]]*$/, "")
      # vendor blobs repeat and say nothing; the profile names are the point
      if ($0 == "Vendor specific" || $0 == "Unknown" || seen[$0]++) next
      uu = uu (uu ? ", " : "") $0; next
    }
    /^[[:space:]]*(Name|Alias|Icon|Powered|Discoverable|Pairable|Discovering|Paired|Trusted|Blocked|Connected|RSSI|TxPower|Battery Percentage):/ {
      sub(/^[[:space:]]+/, "")
      if ($0 ~ /^Name:/) name = substr($0, 7)
      if ($0 ~ /^Alias:/ && substr($0, 8) == name) next   # same as Name, dead line
      if (match($0, /0x[0-9a-fA-F]+ \(/)) {
        v = $0; sub(/.*\(/, "", v); sub(/\).*/, "", v)
        $0 = substr($0, 1, index($0, ":")) " " v
      }
      print; next
    }
    END { if (uu) print "Profiles: " uu }
  '
}

show_text() { rofi -e "$(compact <<<"$1")"; }

prop() { sed -n "s/^[[:space:]]*$1:[[:space:]]*//p" <<<"$2" | head -1; }

powered() { [ "$(prop Powered "$($BT show)")" = "yes" ]; }

power_on() {
  rfkill unblock bluetooth 2>/dev/null   # PowerState: off-blocked
  $BT power on >/dev/null 2>&1 || notify "Could not turn Bluetooth on"
}

devices() {
  dev_rows "$($BT devices Connected | awk '{print $2}')" \
           "$($BT devices Paired    | awk '{print $2}')" < <($BT devices)
}

# blocking scan: bluetoothctl caches what it finds, the next listing shows it
scan() {
  notify "Scanning…" "${SCAN_SECS}s"
  $BT --timeout "$SCAN_SECS" scan on >/dev/null 2>&1
}

act() { # act <verb> <mac> <name>
  local out
  out=$($BT "$1" "$2" 2>&1)
  # bluetoothctl says "Failed to ..." on error and a different success phrase for
  # every verb ("Connection successful", "Device has been removed"), so the
  # failure side is the one worth matching.
  if grep -qiE 'failed|not available|invalid|error' <<<"$out"; then
    notify "$3" "$1 failed — $(grep -iE 'failed|not available|invalid|error' <<<"$out" | head -1)"
  else
    notify "$3" "$1: ok"
  fi
}

menu_device() { # menu_device <mac> <name>
  local mac=$1 name=$2 info sel
  while :; do
    info=$($BT info "$mac")
    [ -n "$info" ] || return 0
    sel=$(menu "$name" \
      "$([ "$(prop Connected "$info")" = yes ] && echo '󰂲  Disconnect' || echo '󰂱  Connect')\n󰂯  Pair\n$([ "$(prop Trusted "$info")" = yes ] && echo '󰩹  Untrust' || echo '󰓾  Trust')\n󰆴  Remove\n󰋼  Info" \
      "$(prop Alias "$info") · paired $(prop Paired "$info") · trusted $(prop Trusted "$info")$(
        # "Battery Percentage: 0x64 (100)" -> the decimal in parentheses
        b=$(prop 'Battery Percentage' "$info" | sed -n 's/.*(\([0-9]*\)).*/\1/p')
        [ -n "$b" ] && printf ' · battery %s%%' "$b"
      )") || return 0
    case "${sel##*  }" in
      Connect)    act connect    "$mac" "$name" ;;
      Disconnect) act disconnect "$mac" "$name" ;;
      Pair)       act pair       "$mac" "$name" ;;
      Trust)      act trust      "$mac" "$name" ;;
      Untrust)    act untrust    "$mac" "$name" ;;
      Remove)     act remove     "$mac" "$name"; return 0 ;;
      Info)       show_text "$info" ;;
      *) return 0 ;;
    esac
  done
}

menu_controller() {
  local info sel
  while :; do
    info=$($BT show)
    sel=$(menu "Controller" \
      "󰂲  Turn Bluetooth off\n󰀄  Discoverable: $(prop Discoverable "$info")\n󰌷  Pairable: $(prop Pairable "$info")\n󰋼  Info" \
      "$(prop Name "$info") · $(sed -n 's/^Controller \([0-9A-F:]*\).*/\1/p' <<<"$info")") || return 0
    case "${sel##*  }" in
      "Turn Bluetooth off") $BT power off >/dev/null 2>&1; return 1 ;;
      "Discoverable: yes")  $BT discoverable off >/dev/null 2>&1 ;;
      "Discoverable: no")   $BT discoverable on  >/dev/null 2>&1 ;;
      "Pairable: yes")      $BT pairable off >/dev/null 2>&1 ;;
      "Pairable: no")       $BT pairable on  >/dev/null 2>&1 ;;
      Info) show_text "$info" ;;
      *) return 0 ;;
    esac
  done
}

[ -n "$($BT list)" ] || { rofi -e "No Bluetooth controller found."; exit 1; }

while :; do
  if ! powered; then
    [ "$(menu "Bluetooth off" "󰂯  Turn Bluetooth on")" ] || exit 0
    power_on
    continue
  fi

  sel=$(menu "Bluetooth" "󰑐  Scan\n󰢻  Controller\n$(devices)" \
    "$($BT devices Connected | sed 's/^Device [^ ]* //' | tr '\n' ' ' | sed 's/^./connected: &/')") || exit 0

  case "${sel##*  }" in
    Scan) scan ;;
    Controller) menu_controller || exit 0 ;;   # powered off from there → close
    *)
      mac=${sel##* }
      [ -n "$mac" ] || exit 0
      name=${sel#*  }; name=${name%  ·  *}
      menu_device "$mac" "$name"
      ;;
  esac
done
