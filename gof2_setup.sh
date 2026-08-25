#!/bin/bash

# ============================================================================
#  GOF2 Waydroid Key Mapper Setup
# ============================================================================
#
#  This key mapper was made for the GOF2 mod:
#  Galaxy on Fire 2 FULL HD Android by KiritoJPK
#  Source: https://github.com/KiritoJPK/Galaxy-on-Fire-2-FULL-HD-Android
#
#  The Kamoo Club | Galaxy on Fire Discord:
#  https://discord.com/invite/N4F4aMQ6XP
#
# ============================================================================

set -e

echo ""
echo "============================================================"
echo "   GOF2 Waydroid Key Mapper Setup"
echo "============================================================"
echo ""
echo "  This key mapper was made for the GOF2 mod:"
echo "  Galaxy on Fire 2 FULL HD Android by KiritoJPK"
echo "  https://github.com/KiritoJPK/Galaxy-on-Fire-2-FULL-HD-Android"
echo ""
echo "  The Kamoo Club | Galaxy on Fire Discord:"
echo "  https://discord.com/invite/N4F4aMQ6XP"
echo ""
echo "============================================================"
echo ""
echo "  WHAT THIS TOOL DOES:"
echo ""
echo "  This script only fixes the dpad (movement) control for GOF2"
echo "  on Waydroid. It maps keyboard keys to touch drag events on"
echo "  the game's on-screen dpad."
echo ""
echo "  WHY ONLY DPAD?"
echo "  GOF2 has a bug where pure horizontal and vertical touch swipes"
echo "  are dropped by the game. This tool works around it by sending"
echo "  a tiny diagonal swipe first before the intended direction."
echo "  For all other in-game controls (weapons, boost, menu, etc.),"
echo "  you can use Waydroid Helper's Key Mapper or any other tool"
echo "  of your choice — this script does not interfere with them."
echo ""
echo "============================================================"
echo ""
echo "  This script will:"
echo ""
echo "  INSTALL (via apt):"
echo "    - python3, python3-full, python3-evdev"
echo "    - git, cmake, build-essential, libevdev-dev, libudev-dev, scdoc"
echo ""
echo "  BUILD & INSTALL from source:"
echo "    - ydotool (latest) → cloned to ~/ydotool-src"
echo "      binaries installed to /usr/local/bin/ydotool"
echo "                           /usr/local/bin/ydotoold"
echo ""
echo "  CREATE in your home folder:"
echo "    - ~/gof2-env/         Python virtual environment"
echo "    - ~/gof2_keys.py      Key mapper script"
echo "    - ~/gof2_start.sh     Launch script"
echo ""
echo "  MODIFY Waydroid settings:"
echo "    - persist.waydroid.fake_touch = \"*\""
echo "      (makes Waydroid treat mouse input as touch for all apps)"
echo ""
echo "  PERMISSIONS required:"
echo "    - sudo (for apt installs, ydotool install, running key mapper)"
echo "    - /dev/input/event* access (to read keyboard events)"
echo ""
echo "  DOES NOT:"
echo "    - Modify any game files"
echo "    - Send any data anywhere"
echo "    - Run anything at startup automatically"
echo "    - Interfere with other key mappers (Waydroid Helper, etc.)"
echo ""
echo "  CALIBRATION NOTE:"
echo "  The dpad screen coordinates in gof2_keys.py are calibrated for:"
echo "    - Ubuntu 24.04 LTS, GNOME, Wayland"
echo "    - Waydroid resolution: 1920x1032 (taskbar visible, not hidden)"
echo "    - US keyboard layout"
echo ""
echo "  If your setup is different, you may need to adjust the"
echo "  CX, CY and direction_map values in ~/gof2_keys.py."
echo ""
echo "============================================================"
echo ""

# ── Confirmation ──────────────────────────────────────────────────────────────
read -rp "  Proceed with setup? [y/N]: " confirm
echo ""
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "  Setup cancelled."
    exit 0
fi

# ── Key choice ────────────────────────────────────────────────────────────────
echo ""
echo "  Choose your dpad control keys:"
echo "    1) WASD"
echo "    2) Arrow keys"
echo "    3) Both WASD and Arrow keys"
echo ""
read -rp "  Enter choice [1/2/3]: " keychoice
echo ""

case "$keychoice" in
    1) echo "  Using: WASD" ;;
    2) echo "  Using: Arrow keys" ;;
    3) echo "  Using: WASD + Arrow keys" ;;
    *)
        echo "  Invalid choice. Defaulting to WASD."
        keychoice=1
        ;;
esac
echo ""

# ── 1. Check Waydroid ─────────────────────────────────────────────────────────
if ! command -v waydroid &>/dev/null; then
    echo "[ERROR] Waydroid is not installed. Please install it first."
    exit 1
fi
echo "[OK] Waydroid found."

# ── 2. Install apt dependencies ───────────────────────────────────────────────
echo "[*] Installing apt dependencies..."
sudo apt install -y \
    python3 \
    python3-full \
    python3-evdev \
    git \
    cmake \
    build-essential \
    libevdev-dev \
    libudev-dev \
    scdoc
echo "[OK] apt dependencies installed."

# ── 3. Python venv ────────────────────────────────────────────────────────────
echo "[*] Setting up Python virtual environment at ~/gof2-env ..."
if [ ! -d "$HOME/gof2-env" ]; then
    python3 -m venv "$HOME/gof2-env" --upgrade-deps
fi
"$HOME/gof2-env/bin/pip" install evdev --quiet
echo "[OK] Python venv ready."

# ── 4. Build and install ydotool ──────────────────────────────────────────────
if [ -f /usr/local/bin/ydotoold ]; then
    echo "[OK] ydotoold already installed at /usr/local/bin, skipping build."
else
    echo "[*] Cloning ydotool source to ~/ydotool-src ..."
    git clone https://github.com/ReimuNotMoe/ydotool.git "$HOME/ydotool-src"
    echo "[*] Building ydotool (this may take a minute)..."
    cd "$HOME/ydotool-src"
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc)
    sudo make install
    cd "$HOME"
    echo "[OK] ydotool installed to /usr/local/bin."
fi

# ── 5. Configure Waydroid fake_touch ──────────────────────────────────────────
echo "[*] Configuring Waydroid fake_touch..."
waydroid prop set persist.waydroid.fake_touch "*"
echo "[OK] persist.waydroid.fake_touch set to \"*\"."

# ── 6. Auto-detect keyboard ───────────────────────────────────────────────────
echo "[*] Detecting keyboard device..."
KEYBOARD=""
for dev in /dev/input/event*; do
    name=$(cat /sys/class/input/$(basename $dev)/device/name 2>/dev/null || echo "")
    if echo "$name" | grep -qi "keyboard\|AT Translated"; then
        KEYBOARD=$dev
        echo "[OK] Keyboard found: $dev ($name)"
        break
    fi
done

if [ -z "$KEYBOARD" ]; then
    echo "[WARN] Could not auto-detect keyboard. Defaulting to /dev/input/event3"
    echo "       Edit KEYBOARD= in ~/gof2_keys.py if movement does not work."
    KEYBOARD="/dev/input/event3"
fi

# ── 7. Build key map based on choice ─────────────────────────────────────────
if [ "$keychoice" == "1" ]; then
    KEY_COMMENT="WASD keys"
    DIRECTION_KEYS_PY="{ecodes.KEY_W, ecodes.KEY_S, ecodes.KEY_A, ecodes.KEY_D}"
    DIRECTION_MAP_PY='    frozenset([ecodes.KEY_W]):                              (True,  53, 271, 38,  230),  # UP
    frozenset([ecodes.KEY_S]):                              (True,  55, 285, 41,  326),  # DOWN
    frozenset([ecodes.KEY_A]):                              (True,  55, 271, 10,  281),  # LEFT
    frozenset([ecodes.KEY_D]):                              (True,  55, 271, 130, 283),  # RIGHT
    frozenset([ecodes.KEY_W, ecodes.KEY_D]):                (False, 0,  0,   130, 200),  # UP-RIGHT
    frozenset([ecodes.KEY_W, ecodes.KEY_A]):                (False, 0,  0,   10,  250),  # UP-LEFT
    frozenset([ecodes.KEY_S, ecodes.KEY_D]):                (False, 0,  0,   130, 366),  # DOWN-RIGHT
    frozenset([ecodes.KEY_S, ecodes.KEY_A]):                (False, 0,  0,   0,   326),  # DOWN-LEFT'

elif [ "$keychoice" == "2" ]; then
    KEY_COMMENT="Arrow keys"
    DIRECTION_KEYS_PY="{ecodes.KEY_UP, ecodes.KEY_DOWN, ecodes.KEY_LEFT, ecodes.KEY_RIGHT}"
    DIRECTION_MAP_PY='    frozenset([ecodes.KEY_UP]):                             (True,  53, 271, 38,  230),  # UP
    frozenset([ecodes.KEY_DOWN]):                           (True,  55, 285, 41,  326),  # DOWN
    frozenset([ecodes.KEY_LEFT]):                           (True,  55, 271, 10,  281),  # LEFT
    frozenset([ecodes.KEY_RIGHT]):                          (True,  55, 271, 130, 283),  # RIGHT
    frozenset([ecodes.KEY_UP,   ecodes.KEY_RIGHT]):         (False, 0,  0,   130, 200),  # UP-RIGHT
    frozenset([ecodes.KEY_UP,   ecodes.KEY_LEFT]):          (False, 0,  0,   10,  250),  # UP-LEFT
    frozenset([ecodes.KEY_DOWN, ecodes.KEY_RIGHT]):         (False, 0,  0,   130, 366),  # DOWN-RIGHT
    frozenset([ecodes.KEY_DOWN, ecodes.KEY_LEFT]):          (False, 0,  0,   0,   326),  # DOWN-LEFT'

else
    KEY_COMMENT="WASD + Arrow keys"
    DIRECTION_KEYS_PY="{ecodes.KEY_W, ecodes.KEY_S, ecodes.KEY_A, ecodes.KEY_D, ecodes.KEY_UP, ecodes.KEY_DOWN, ecodes.KEY_LEFT, ecodes.KEY_RIGHT}"
    DIRECTION_MAP_PY='    frozenset([ecodes.KEY_W]):                              (True,  53, 271, 38,  230),  # UP
    frozenset([ecodes.KEY_S]):                              (True,  55, 285, 41,  326),  # DOWN
    frozenset([ecodes.KEY_A]):                              (True,  55, 271, 10,  281),  # LEFT
    frozenset([ecodes.KEY_D]):                              (True,  55, 271, 130, 283),  # RIGHT
    frozenset([ecodes.KEY_W, ecodes.KEY_D]):                (False, 0,  0,   130, 200),  # UP-RIGHT (WASD)
    frozenset([ecodes.KEY_W, ecodes.KEY_A]):                (False, 0,  0,   10,  250),  # UP-LEFT  (WASD)
    frozenset([ecodes.KEY_S, ecodes.KEY_D]):                (False, 0,  0,   130, 366),  # DOWN-RIGHT (WASD)
    frozenset([ecodes.KEY_S, ecodes.KEY_A]):                (False, 0,  0,   0,   326),  # DOWN-LEFT  (WASD)
    frozenset([ecodes.KEY_UP]):                             (True,  53, 271, 38,  230),  # UP
    frozenset([ecodes.KEY_DOWN]):                           (True,  55, 285, 41,  326),  # DOWN
    frozenset([ecodes.KEY_LEFT]):                           (True,  55, 271, 10,  281),  # LEFT
    frozenset([ecodes.KEY_RIGHT]):                          (True,  55, 271, 130, 283),  # RIGHT
    frozenset([ecodes.KEY_UP,   ecodes.KEY_RIGHT]):         (False, 0,  0,   130, 200),  # UP-RIGHT (arrows)
    frozenset([ecodes.KEY_UP,   ecodes.KEY_LEFT]):          (False, 0,  0,   10,  250),  # UP-LEFT  (arrows)
    frozenset([ecodes.KEY_DOWN, ecodes.KEY_RIGHT]):         (False, 0,  0,   130, 366),  # DOWN-RIGHT (arrows)
    frozenset([ecodes.KEY_DOWN, ecodes.KEY_LEFT]):          (False, 0,  0,   0,   326),  # DOWN-LEFT  (arrows)'
fi

# ── 8. Write gof2_keys.py ─────────────────────────────────────────────────────
echo "[*] Writing ~/gof2_keys.py..."
cat > "$HOME/gof2_keys.py" << PYEOF
#!/usr/bin/env python3
#
# GOF2 Waydroid Key Mapper
# Made for: Galaxy on Fire 2 FULL HD Android by KiritoJPK
# https://github.com/KiritoJPK/Galaxy-on-Fire-2-FULL-HD-Android
#
# Calibrated for:
#   Ubuntu 24.04 LTS, GNOME, Wayland
#   Waydroid resolution: 1920x1032 (taskbar visible, not hidden)
#   US keyboard layout
#   Control keys: $KEY_COMMENT
#
import subprocess
import threading
import evdev
from evdev import InputDevice, ecodes

YDOTOOL  = "/usr/local/bin/ydotool"
KEYBOARD = "$KEYBOARD"

# ── Calibration ───────────────────────────────────────────────────────────────
# CX, CY: dpad center in ydotool screen coordinates.
# To find your values run:
#   YDOTOOL_SOCKET=/tmp/.ydotool_socket /usr/local/bin/ydotool mousemove <x> <y>
# and adjust until the cursor lands on the game's dpad center.
CX, CY = 48, 278

# Direction map: frozenset of keys -> (use_diag_trick, diag_x, diag_y, target_x, target_y)
# Cardinal directions need the diagonal trick to bypass the game's touch dead zone.
# Diagonal key combinations go straight to target.
direction_map = {
$DIRECTION_MAP_PY
}
# ─────────────────────────────────────────────────────────────────────────────

DIRECTION_KEYS = $DIRECTION_KEYS_PY

held_keys      = set()
lock           = threading.Lock()
current_thread = None
stop_event     = threading.Event()

def run(cmd):
    subprocess.run(cmd, shell=True)

def do_move(use_diag, diag_x, diag_y, target_x, target_y, stop_evt):
    run(f"{YDOTOOL} mousemove -a -x {CX} -y {CY}")
    run(f"{YDOTOOL} click 0x40")
    if use_diag:
        run(f"{YDOTOOL} mousemove -a -x {diag_x} -y {diag_y}")
    run(f"{YDOTOOL} mousemove -a -x {target_x} -y {target_y}")
    stop_evt.wait()
    run(f"{YDOTOOL} click 0x80")

def restart_movement():
    global current_thread, stop_event
    stop_event.set()
    if current_thread and current_thread.is_alive():
        current_thread.join(timeout=0.5)
    combo      = frozenset(held_keys & DIRECTION_KEYS)
    stop_event = threading.Event()
    if not combo or combo not in direction_map:
        return
    use_diag, diag_x, diag_y, tx, ty = direction_map[combo]
    current_thread = threading.Thread(
        target=do_move,
        args=(use_diag, diag_x, diag_y, tx, ty, stop_event),
        daemon=True
    )
    current_thread.start()

def main():
    dev = InputDevice(KEYBOARD)
    print(f"GOF2 key mapper running on {dev.name}")
    print("$KEY_COMMENT to move, Ctrl+C to stop")
    for event in dev.read_loop():
        if event.type != ecodes.EV_KEY or event.value == 2:
            continue
        code = event.code
        if code not in DIRECTION_KEYS:
            continue
        with lock:
            if event.value == 1:
                held_keys.add(code)
            elif event.value == 0:
                held_keys.discard(code)
            restart_movement()

try:
    main()
except KeyboardInterrupt:
    stop_event.set()
    subprocess.run(f"{YDOTOOL} click 0x80", shell=True)
    print("\nStopped.")
PYEOF
echo "[OK] ~/gof2_keys.py written."

# ── 9. Write gof2_start.sh ────────────────────────────────────────────────────
echo "[*] Writing ~/gof2_start.sh..."
cat > "$HOME/gof2_start.sh" << 'SHEOF'
#!/bin/bash
# GOF2 Waydroid Key Mapper - Launch Script

# Kill any existing ydotoold instance
sudo pkill ydotoold 2>/dev/null
sleep 1

# Start ydotoold with a world-accessible socket
sudo /usr/local/bin/ydotoold --socket-path /tmp/.ydotool_socket --socket-perm 0666 &
sleep 1

# Start the key mapper
sudo YDOTOOL_SOCKET=/tmp/.ydotool_socket ~/gof2-env/bin/python ~/gof2_keys.py
SHEOF
chmod +x "$HOME/gof2_start.sh"
echo "[OK] ~/gof2_start.sh written."

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "   Setup complete!"
echo "============================================================"
echo ""
echo "  Control keys: $KEY_COMMENT"
echo ""
echo "  To start the key mapper:"
echo "    ~/gof2_start.sh"
echo ""
echo "  To stop the key mapper (from another terminal):"
echo "    sudo pkill -f gof2_keys.py && sudo pkill ydotoold"
echo ""
echo "  CALIBRATION:"
echo "  If your dpad coordinates feel off, edit ~/gof2_keys.py"
echo "  and adjust CX, CY and the direction_map target coordinates."
echo ""
echo "============================================================"
echo "   To UNINSTALL / completely remove everything:"
echo "============================================================"
echo ""
echo "  1. Remove scripts:"
echo "       rm -f ~/gof2_keys.py ~/gof2_start.sh ~/gof2_setup.sh"
echo ""
echo "  2. Remove Python venv:"
echo "       rm -rf ~/gof2-env"
echo ""
echo "  3. Remove ydotool (built from source):"
echo "       sudo rm -f /usr/local/bin/ydotool /usr/local/bin/ydotoold"
echo "       sudo rm -f /usr/local/share/man/man1/ydotool.1"
echo "       sudo rm -f /usr/local/share/man/man8/ydotoold.8"
echo "       sudo rm -f /usr/lib/systemd/user/ydotoold.service"
echo "       rm -rf ~/ydotool-src"
echo ""
echo "  4. Remove ydotool apt package (only if installed before this setup):"
echo "       sudo apt remove ydotool"
echo ""
echo "  5. Revert Waydroid fake_touch:"
echo "       waydroid prop set persist.waydroid.fake_touch \"\""
echo ""
echo "  6. Optionally remove apt dependencies installed by this script:"
echo "       sudo apt remove python3-evdev scdoc libevdev-dev libudev-dev"
echo ""
echo "============================================================"
echo ""
