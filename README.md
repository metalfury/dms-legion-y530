# dms-legion-y530

Fan and battery control for the **Lenovo Legion Y530** (81FV, BIOS 8JCN) on Linux, with a
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) bar widget.

The Y530 firmware has no power modes and no fan curve. Its only fan control is
**extreme cooling** (Fn+Q, both fans to ~4000 RPM). This project combines that with
the CPU power profile to give four levels, and adds a software battery charge limit.

| Level | Power profile | Extreme cooling |
|---|---|---|
| Silent | power-saver | off |
| Balanced | balanced | off |
| Performance | performance | off |
| Max | performance | on |

## Requirements

- [LenovoLegionLinux](https://github.com/johnfanv2/LenovoLegionLinux) kernel module with
  `fan_unlock` on 8JCN (from the `y530-fan-unlock` branch until it is merged upstream).
  Loading it with `options legion_laptop enable_platformprofile=0` is recommended on the
  Y530, since the firmware has no power modes.
- `power-profiles-daemon` or `tuned-ppd`
- DankMaterialShell ≥ 1.6 (for the widget)

## Install

```sh
git clone https://github.com/metalfury/dms-legion-y530 ~/src/dms-legion-y530
cd ~/src/dms-legion-y530 && ./install.sh
```

Then add **Legion Fan** to the bar in DMS Settings → Dank Bar. `./install.sh uninstall` removes everything.

## Usage

```sh
legion                    # status
legion set max            # silent | balanced | performance | max
legion cycle              # next level
legion battery 80         # charge limit: 60 | 70 | 80 | 90 | 100 (off)
```

Widget: left click opens levels, fan RPM and charge limit; right click cycles the level.

## How it works

- **Extreme cooling**: `GZFD.WMAA` method 0x0D (`NCMD(0x59, 0x77/0x76)`), state via
  method 0x14 (`FCST & 1`), exposed by LenovoLegionLinux as `fan_unlock`.
- **Charge limit**: the firmware conservation mode stops charging at ~60 %. For higher
  limits `legion-battery.service` turns it on at the limit and off 3 % below it.
- A udev rule lets the `wheel` group write `fan_unlock` and `battery_conservation`.

## License

MIT
