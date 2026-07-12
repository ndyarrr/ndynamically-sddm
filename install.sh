#!/usr/bin/env bash

# Setup Colors
C_MAIN='\033[38;2;202;169;224m'
C_ACCENT='\033[38;2;145;177;240m'
C_DIM='\033[38;2;129;122;150m'
C_GREEN='\033[38;2;166;209;137m'
C_YELLOW='\033[38;2;229;200;144m'
C_RED='\033[38;2;231;130;132m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

# Helper functions
header() {
    clear
    echo -e "${C_MAIN}${C_BOLD}"
    echo " ╭──────────────────────────────────────────╮"
    echo " │      󱓞 NDYNAMICALLY SDDM INSTALLER 󱓞     │"
    echo " ╰──────────────────────────────────────────╯"
    echo -e "${C_RESET}"
}

info() {
    echo -e "${C_MAIN}${C_BOLD} ╭─ 󰓅 $1${C_RESET}"
}

substep() {
    echo -e "${C_MAIN}${C_BOLD} │  ${C_DIM}❯ ${C_RESET}$1"
}

success() {
    echo -e "${C_MAIN}${C_BOLD} ╰─ ${C_GREEN}✔ ${C_RESET}$1\n"
}

error() {
    echo -e "${C_MAIN}${C_BOLD} ╰─ ${C_RED}✘ ${C_RESET}$1\n"
}

# Grant execute permission to all parent directories of a path
grant_parent_x() {
    local path="$1"
    while [ "$path" != "/" ] && [ -n "$path" ]; do
        if [ -d "$path" ]; then
            chmod o+x "$path"
        fi
        path="$(dirname "$path")"
    done
}

# Root permission check
if [ "$EUID" -ne 0 ]; then
    header
    error "Please run this installer with sudo: sudo ./install.sh"
    exit 1
fi

header

# Check dependencies
info "Scanning required system dependencies..."
MISSING_DEPS=()

if ! command -v ffmpeg &> /dev/null; then
    MISSING_DEPS+=("ffmpeg")
fi

if ! command -v sddm &> /dev/null && [ ! -d "/usr/share/sddm" ]; then
    MISSING_DEPS+=("sddm")
fi

if ! command -v od &> /dev/null; then
    MISSING_DEPS+=("coreutils (od)")
fi

HAS_SYSTEMD=true
if ! command -v systemctl &> /dev/null; then
    HAS_SYSTEMD=false
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    error "Missing required dependencies: ${MISSING_DEPS[*]}"
    echo -e "Please install the missing packages first."
    echo -e "On Arch Linux  : ${C_BOLD}sudo pacman -S ffmpeg sddm${C_RESET}"
    echo -e "On Debian/Ubuntu: ${C_BOLD}sudo apt install ffmpeg sddm${C_RESET}"
    exit 1
fi
if [ "$HAS_SYSTEMD" = true ]; then
    substep "All dependencies found (ffmpeg, sddm, coreutils, systemd)."
else
    substep "Required dependencies found (ffmpeg, sddm, coreutils). systemd not detected."
fi

# Detect real non-root user
info "Detecting system user..."
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(whoami)"
fi

if [ "$REAL_USER" = "root" ]; then
    substep "${C_YELLOW}Running directly as root user.${C_RESET}"
    REAL_HOME="/root"
else
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    substep "Detected user: ${C_ACCENT}$REAL_USER${C_RESET} (Home: $REAL_HOME)"
fi
DEFAULT_WALLPAPER_DIR="$REAL_HOME/Wallpapers"

# Ask user for custom wallpaper directory
info "Selecting Wallpaper directory..."
echo -e "${C_MAIN}${C_BOLD} │  ${C_DIM}Specify where your video wallpapers (.mp4) are stored.${C_RESET}"
echo -ne "${C_MAIN}${C_BOLD} ╰─ ${C_YELLOW}Directory path [Default: $DEFAULT_WALLPAPER_DIR]: ${C_RESET}"
read -rp "" INPUT_DIR

# Clean up potential copy-paste clutter (like "Wallpaper Dir: ") or whitespace
INPUT_DIR=$(echo "$INPUT_DIR" | sed 's|^[Ww]allpaper\ *[Dd]ir\ *:\ *||' | xargs)

WALLPAPER_DIR="${INPUT_DIR:-$DEFAULT_WALLPAPER_DIR}"

# Expand tilde ~ to real home path
WALLPAPER_DIR="${WALLPAPER_DIR/#\~/$REAL_HOME}"

# If it is a relative path, convert to absolute path using caller's PWD
if [[ ! "$WALLPAPER_DIR" = /* ]]; then
    # When using sudo, PWD usually points to the caller's working directory
    WALLPAPER_DIR="${PWD}/${WALLPAPER_DIR}"
fi

# Remove trailing slash
WALLPAPER_DIR="${WALLPAPER_DIR%/}"

info "Configuring environment at $WALLPAPER_DIR..."

# Create directory if not exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    substep "Directory does not exist. Creating $WALLPAPER_DIR..."
    mkdir -p "$WALLPAPER_DIR"
    if [ "$REAL_USER" != "root" ] && [[ "$WALLPAPER_DIR" == "$REAL_HOME"* ]]; then
        chown -R "$REAL_USER":"$REAL_USER" "$WALLPAPER_DIR"
    fi
else
    substep "Directory already exists"
fi

# Set directory permissions for sddm access
substep "Granting access permissions to SDDM..."
# Grant execute (+x) on parent directories so sddm can traverse to the folder
grant_parent_x "$WALLPAPER_DIR"
# Grant read (+r) on files inside the folder
chmod -R o+rX "$WALLPAPER_DIR"
success "User environment configured"

# Copy theme files
info "Installing theme files..."
SYSTEM_THEME_DIR="/usr/share/sddm/themes/ndynamically-sddm"

if [ -d "$SYSTEM_THEME_DIR" ]; then
    substep "Removing previous theme installation..."
    rm -rf "$SYSTEM_THEME_DIR"
fi

substep "Copying theme folder to $SYSTEM_THEME_DIR..."
mkdir -p "$SYSTEM_THEME_DIR"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cp -r "$SCRIPT_DIR"/* "$SYSTEM_THEME_DIR/"
rm -f "$SYSTEM_THEME_DIR/install.sh" # Clean up installer inside the theme folder
rm -f "$SYSTEM_THEME_DIR/ndynamically-sddm-sync" # Clean up sync script from theme folder
rm -f "$SYSTEM_THEME_DIR/ndynamically-sddm-watcher" # Clean up watcher script from theme folder

# Install sync script globally
substep "Installing sync script globally to /usr/local/bin/ndynamically-sddm-sync..."
cp "$SCRIPT_DIR/ndynamically-sddm-sync" "/usr/local/bin/ndynamically-sddm-sync"
chmod +x "/usr/local/bin/ndynamically-sddm-sync"

# Install watcher script globally
substep "Installing watcher script globally to /usr/local/bin/ndynamically-sddm-watcher..."
cp "$SCRIPT_DIR/ndynamically-sddm-watcher" "/usr/local/bin/ndynamically-sddm-watcher"
chmod +x "/usr/local/bin/ndynamically-sddm-watcher"

# Template the wallpaper directory path
substep "Configuring Wallpaper path dynamically..."
sed -i "s|@WALLPAPER_DIR@|$WALLPAPER_DIR|g" "$SYSTEM_THEME_DIR/BackgroundVideo.qml"
success "Theme files installed"

# Run color synchronization
/usr/local/bin/ndynamically-sddm-sync "$WALLPAPER_DIR"

# Configure SDDM Theme setting
info "Activating theme in SDDM configuration..."
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="$SDDM_CONF_DIR/theme.conf"

mkdir -p "$SDDM_CONF_DIR"
if [ ! -f "$SDDM_CONF" ]; then
    echo -e "[Theme]\nCurrent=ndynamically-sddm" > "$SDDM_CONF"
else
    # Set Current theme
    if grep -q "^Current=" "$SDDM_CONF"; then
        sed -i "s|^Current=.*|Current=ndynamically-sddm|" "$SDDM_CONF"
    else
        if grep -q "^\[Theme\]" "$SDDM_CONF"; then
            sed -i "/^\[Theme\]/a Current=ndynamically-sddm" "$SDDM_CONF"
        else
            echo -e "\n[Theme]\nCurrent=ndynamically-sddm" >> "$SDDM_CONF"
        fi
    fi
fi
success "SDDM configured to use 'ndynamically-sddm'"

if [ "$HAS_SYSTEMD" = true ]; then
    # Install auto-sync systemd units (watches wallpaper folder for changes)
    info "Setting up auto-sync wallpaper watcher..."

    SYSTEMD_DIR="/etc/systemd/system"

    # Service unit: runs the sync script
    cat > "$SYSTEMD_DIR/ndynamically-sddm-sync.service" << SVCEOF
[Unit]
Description=Sync wallpaper accent colors for ndynamically-sddm
After=network.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/usr/local/bin/ndynamically-sddm-sync
Nice=19
IOSchedulingClass=idle
SVCEOF
    substep "Created ${C_ACCENT}ndynamically-sddm-sync.service${C_RESET}"

    # Path unit: watches wallpaper directory for changes
    cat > "$SYSTEMD_DIR/ndynamically-sddm-sync.path" << PATHEOF
[Unit]
Description=Watch wallpaper directory for ndynamically-sddm accent sync

[Path]
PathChanged=$WALLPAPER_DIR
MakeDirectory=yes

[Install]
WantedBy=multi-user.target
PATHEOF
    substep "Created ${C_ACCENT}ndynamically-sddm-sync.path${C_RESET} -> ${C_DIM}$WALLPAPER_DIR${C_RESET}"

    # Enable and start the path watcher
    systemctl daemon-reload
    systemctl enable --now ndynamically-sddm-sync.path 2>/dev/null
    substep "Watcher ${C_GREEN}enabled and started${C_RESET}"
    success "Auto-sync wallpaper watcher installed"
else
    info "Skipping systemd auto-sync watcher setup (systemd not detected)..."
    substep "You can run ${C_MAIN}ndynamically-sddm-sync${C_RESET} manually to update colors."
    substep "Alternatively, run ${C_MAIN}ndynamically-sddm-watcher${C_RESET} (using inotify-tools) in background."
    success "Non-systemd setup prepared"
fi

echo -e "${C_GREEN}${C_BOLD}🎉 INSTALLATION COMPLETED SUCCESSFULLY!${C_RESET}"
echo -e "${C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e " 󰄬 Tema baru ${C_ACCENT}ndynamically-sddm${C_RESET} telah dipasang."
echo -e " 󰄬 Direktori wallpaper dikonfigurasi ke: ${C_BOLD}$WALLPAPER_DIR${C_RESET}"
echo -e " 󰄬 Letakkan berkas video ${C_YELLOW}.mp4${C_RESET} Anda di dalam folder tersebut."
if [ "$HAS_SYSTEMD" = true ]; then
    echo -e " 󰄬 ${C_GREEN}Auto-sync aktif (systemd)${C_RESET}: warna otomatis diekstrak saat wallpaper baru ditambahkan."
else
    echo -e " 󰄬 ${C_YELLOW}Auto-sync manual / watcher${C_RESET}: Jalankan ${C_BOLD}ndynamically-sddm-watcher${C_RESET} di latar belakang untuk auto-sync."
fi
echo -e " 󰄬 Untuk menguji coba secara lokal:"
echo -e "   ${C_MAIN}sddm-greeter --test-mode --theme $SYSTEM_THEME_DIR${C_RESET}"
echo -e "${C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}\n"
