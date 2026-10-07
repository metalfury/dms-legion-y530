#!/bin/sh
# Install (or `./install.sh uninstall`) the legion CLI, DMS widget, udev rule
# and battery service. Files are symlinked, so `git pull` updates them.
set -eu
REPO=$(cd "$(dirname "$0")" && pwd)
BIN=$HOME/.local/bin/legion
PLUG=$HOME/.config/DankMaterialShell/plugins/legionFan
UNIT=$HOME/.config/systemd/user/legion-battery.service
RULE=/etc/udev/rules.d/99-legion-y530.rules
SYSFS=/sys/bus/platform/drivers/legion/legion

if [ "${1:-}" = uninstall ]; then
  systemctl --user disable --now legion-battery.service 2>/dev/null || true
  dms ipc call plugins disable legionFan 2>/dev/null || true
  rm -f "$BIN" "$UNIT"
  rm -rf "$PLUG"
  sudo rm -f "$RULE"
  echo "removed"
  exit 0
fi

[ -e "$SYSFS/fan_unlock" ] || echo "warning: $SYSFS/fan_unlock missing - is LenovoLegionLinux with 8JCN fan_unlock loaded?" >&2

mkdir -p "$(dirname "$BIN")" "$(dirname "$PLUG")" "$(dirname "$UNIT")"
ln -sfn "$REPO/bin/legion" "$BIN"
rm -rf "$PLUG"
ln -sfn "$REPO/plugin/legionFan" "$PLUG"
ln -sfn "$REPO/systemd/legion-battery.service" "$UNIT"

sudo install -m 644 "$REPO/udev/99-legion-y530.rules" "$RULE"
if [ -d "$SYSFS" ]; then
  sudo sh -c "cd $SYSFS && chgrp wheel fan_unlock battery_conservation && chmod g+w fan_unlock battery_conservation"
fi

systemctl --user daemon-reload
systemctl --user enable --now legion-battery.service

dms ipc call plugin-scan scan >/dev/null 2>&1 || true
sleep 2
dms ipc call plugins enable legionFan >/dev/null 2>&1 || true
echo "installed - add 'Legion Fan' to the bar in DMS Settings > Dank Bar if it is not there"
