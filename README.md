# GOF2 Waydroid Key Mapper

A keyboard-to-touch key mapper for playing **Galaxy on Fire 2 FULL HD Android** on [Waydroid](https://waydro.id) on Linux.

> Made for the GOF2 mod: **Galaxy on Fire 2 FULL HD Android** by [KiritoJPK](https://github.com/KiritoJPK/Galaxy-on-Fire-2-FULL-HD-Android)
>
> 💬 Join the community: [The Kamoo Club | Galaxy on Fire Discord](https://discord.com/invite/N4F4aMQ6XP)

---

## Why does this exist?

Galaxy on Fire 2 has a bug where **pure horizontal and vertical touch swipes are dropped** by the game's dpad — only diagonal swipes register reliably. This affects Waydroid users trying to control the ship with a keyboard, regardless of which key mapper they use (Waydroid Helper, XtMapper, etc.).

This tool works around the bug by **sending a tiny diagonal swipe first** before the intended cardinal direction, tricking the game into accepting the input.

> **This tool only fixes the dpad (movement) control.**
> For all other in-game controls — weapons, boost, menus, etc. — you can use
> [Waydroid Helper](https://github.com/waydroid-helper/waydroid-helper) or any key mapper of your choice.
> This tool does not interfere with them.

---

## How it works

1. Waydroid's `persist.waydroid.fake_touch` property is enabled, which converts mouse input into touch events inside Android.
2. [ydotool](https://github.com/ReimuNotMoe/ydotool) is used to inject mouse drag events at the system level on Wayland.
3. A Python script reads keyboard input via `evdev` and translates WASD / arrow key presses into mouse drag sequences that land on the game's on-screen dpad.
4. For cardinal directions (up/down/left/right), a tiny diagonal swipe is sent first to bypass the game's touch dead zone, then the movement slides to the intended direction.
5. For diagonal directions (e.g. W+D), the swipe goes straight to the target — no trick needed.

---

## Requirements

- Linux with Wayland
- [Waydroid](https://waydro.id) installed and running
- Ubuntu 24.04 LTS or equivalent (Debian-based)
- Internet connection (for downloading dependencies during setup)

> **Calibrated for:**
> - Ubuntu 24.04 LTS, GNOME, Wayland
> - Waydroid resolution: 1920x1032 (taskbar visible, not hidden)
> - US keyboard layout
>
> If your setup differs, you may need to adjust the dpad coordinates in `gof2_keys.py`.
> See [Calibration](#calibration) below.

---

## Installation

```bash
git clone https://github.com/pejal-git/gof2-waydroid-keymapper.git
cd gof2-waydroid-keymapper
chmod +x gof2_setup.sh
./gof2_setup.sh
```

The setup script will:

| Step | What it does |
|------|-------------|
| Ask for confirmation | Nothing runs until you say yes |
| Ask for key preference | Choose WASD, Arrow keys, or both |
| Install apt packages | `python3`, `python3-full`, `python3-evdev`, `git`, `cmake`, `build-essential`, `libevdev-dev`, `libudev-dev`, `scdoc` |
| Build ydotool from source | Cloned to `~/ydotool-src`, installed to `/usr/local/bin` |
| Create Python venv | `~/gof2-env/` |
| Enable Waydroid fake_touch | Sets `persist.waydroid.fake_touch = "*"` |
| Auto-detect keyboard | Falls back to `/dev/input/event3` if not found |
| Write `~/gof2_keys.py` | The key mapper script |
| Write `~/gof2_start.sh` | The launch script |

---

## Usage

Start the key mapper:

```bash
~/gof2_start.sh
```

To stop it, open another terminal and run:

```bash
sudo pkill -f gof2_keys.py && sudo pkill ydotoold
```

### Controls

| Keys | Action |
|------|--------|
| `W` / `↑` | Move up |
| `S` / `↓` | Move down |
| `A` / `←` | Move left |
| `D` / `→` | Move right |
| `W+D` / `↑+→` | Move up-right |
| `W+A` / `↑+←` | Move up-left |
| `S+D` / `↓+→` | Move down-right |
| `S+A` / `↓+←` | Move down-left |

> Keys available depend on your choice during setup (WASD, Arrow keys, or both).

---

## Calibration

If the dpad coordinates don't match your setup, you need to find the correct screen coordinates for your dpad center.

**Step 1** — Start ydotoold:
```bash
sudo /usr/local/bin/ydotoold --socket-path /tmp/.ydotool_socket --socket-perm 0666 &
```

**Step 2** — Move the mouse to find dpad center:
```bash
YDOTOOL_SOCKET=/tmp/.ydotool_socket /usr/local/bin/ydotool mousemove <x> <y>
```

Adjust `x` and `y` until the cursor lands exactly on the game's dpad center. Then update `CX` and `CY` in `~/gof2_keys.py`.

**Step 3** — Tune direction targets if needed by testing swipes:
```bash
YDOTOOL_SOCKET=/tmp/.ydotool_socket /usr/local/bin/ydotool mousemove -a -x <CX> -y <CY>
YDOTOOL_SOCKET=/tmp/.ydotool_socket /usr/local/bin/ydotool click 0x40
YDOTOOL_SOCKET=/tmp/.ydotool_socket /usr/local/bin/ydotool mousemove -a -x <target_x> -y <target_y>
sleep 2
YDOTOOL_SOCKET=/tmp/.ydotool_socket /usr/local/bin/ydotool click 0x80
```

Update the `direction_map` values in `~/gof2_keys.py` accordingly.

---

## Uninstall

To completely remove everything installed by this tool:

```bash
# 1. Remove scripts
rm -f ~/gof2_keys.py ~/gof2_start.sh ~/gof2_setup.sh

# 2. Remove Python venv
rm -rf ~/gof2-env

# 3. Remove ydotool (built from source)
sudo rm -f /usr/local/bin/ydotool /usr/local/bin/ydotoold
sudo rm -f /usr/local/share/man/man1/ydotool.1
sudo rm -f /usr/local/share/man/man8/ydotoold.8
sudo rm -f /usr/lib/systemd/user/ydotoold.service
rm -rf ~/ydotool-src

# 4. Remove ydotool apt package (only if it was installed before this tool)
sudo apt remove ydotool

# 5. Revert Waydroid fake_touch
waydroid prop set persist.waydroid.fake_touch ""

# 6. Optionally remove apt dependencies installed by this tool
sudo apt remove python3-evdev scdoc libevdev-dev libudev-dev
```

---

## Credits

- **[pejal-git](https://github.com/pejal-git)** — Author of this key mapper, discovered the diagonal swipe workaround and built the solution
- **[Claude](https://claude.ai)** (Anthropic) — Co-developed the solution through troubleshooting
- **[FISHLABS Entertainment GmbH](https://www.fishlabs.net)** — Original developer of Galaxy on Fire 2
- **[KiritoJPK](https://github.com/KiritoJPK/Galaxy-on-Fire-2-FULL-HD-Android)** — GOF2 FULL HD Android mod that this tool is made for
- **[Waydroid](https://waydro.id)** — Android container for Linux used to run the game
- **[ydotool](https://github.com/ReimuNotMoe/ydotool)** — Wayland input injection tool used by this key mapper
- **[python-evdev](https://github.com/gvalkov/python-evdev)** — Python library used to read keyboard events

---

## License

MIT License — see [LICENSE](LICENSE) for details.

You are free to use, modify, and distribute this project.
