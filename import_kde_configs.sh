#!/bin/bash
set -e

# Configuration
SOURCE_DIR="$HOME/.config"
DEST_DIR="post-installation/files/kde"

# List of KDE configuration files to import
FILES=(
    "kdeglobals"                              # Global settings (colors, fonts, widget style)
    "plasmashellrc"                           # Plasma shell configuration (panels, desktop layout)
    "kwinrc"                                  # Window manager settings (behavior, effects, window rules)
    "kcminputrc"                              # Input device settings (mouse, keyboard, touchpad)
    "kscreenlockerrc"                         # Screen locker settings
    "plasma-org.kde.plasma.desktop-appletsrc" # Widget specific configuration
    "startkderc"                              # Session startup settings
)

setup_directory() {
    if [ ! -d "$DEST_DIR" ]; then
        echo "Creating directory: $DEST_DIR"
        mkdir -p "$DEST_DIR"
    fi
}

copy_files() {
    echo "Importing KDE configuration files..."
    echo "Source: $SOURCE_DIR"
    echo "Destination: $DEST_DIR"
    echo "----------------------------------------"

    local count=0
    for file in "${FILES[@]}"; do
        if [ -f "$SOURCE_DIR/$file" ]; then
            cp "$SOURCE_DIR/$file" "$DEST_DIR/"
            echo "✅ Copied: $file"
            count=$((count + 1))
        else
            echo "⚠️  Skipped (not found): $file"
        fi
    done

    echo "----------------------------------------"
    echo "Import complete. $count files copied."
}

sanitize_kdeglobals() {
    local file="$DEST_DIR/kdeglobals"
    [ ! -f "$file" ] && return

    echo "  - kdeglobals"
    sed -i '/History Items/d' "$file"
    sed -i '/DirSelectDialog Size/d' "$file"
    sed -i '/Splitter State/d' "$file"
    sed -i '/ColorSchemeHash/d' "$file"
    sed -i '/LastUsedCustomAccentColor/d' "$file"
    sed -i '/\[DirSelect Dialog\]/d' "$file"
}

sanitize_kwinrc() {
    local file="$DEST_DIR/kwinrc"
    [ ! -f "$file" ] && return

    echo "  - kwinrc"
    sed -i '/^\[Tiling/,/^\[/ { /^\[Tiling/d; /^\[/!d }' "$file"
    sed -i '/^tiles=/d' "$file"
    sed -i '/^Id_[0-9]/d' "$file"
    sed -i 's/^Scale=[0-9]*/Scale=1/' "$file"
}

sanitize_kcminputrc() {
    local file="$DEST_DIR/kcminputrc"
    [ ! -f "$file" ] && return

    echo "  - kcminputrc"
    sed -i '/^cursorSize=/d' "$file"
}

sanitize_appletsrc() {
    local file="$DEST_DIR/plasma-org.kde.plasma.desktop-appletsrc"
    [ ! -f "$file" ] && return

    echo "  - plasma-org.kde.plasma.desktop-appletsrc"
    # Delete [ScreenMapping] section
    sed -i '/^\[ScreenMapping\]/,/^\[/ { /^\[ScreenMapping\]/d; /^\[/!d }' "$file"
    # Delete [Migration] section
    sed -i '/^\[Migration\]/,/^\[/ { /^\[Migration\]/d; /^\[/!d }' "$file"
    # Remove specific keys
    sed -i '/^activityId=/d' "$file"
    sed -i '/^positions=/d' "$file"
    sed -i '/^ItemGeometries/d' "$file"
    # Reset weather source
    sed -i 's/^source=.*weather.*/source=/' "$file"
}

sanitize_plasmashellrc() {
    local file="$DEST_DIR/plasmashellrc"
    [ ! -f "$file" ] && return

    echo "  - plasmashellrc"
    sed -i '/^\[Updates\]/,/^\[/ { /^\[Updates\]/d; /^\[/!d }' "$file"
    sed -i '/^\[PlasmaViews\]\[Panel 2\]/,/^\[/ { /^\[PlasmaViews\]\[Panel 2\]/d; /^\[/!d }' "$file"
}

sanitize_configs() {
    echo "----------------------------------------"
    echo "🧹 Sanitizing configuration files..."

    sanitize_kdeglobals
    sanitize_kwinrc
    sanitize_kcminputrc
    sanitize_appletsrc
    sanitize_plasmashellrc

    echo "✨ Sanitization complete."
    echo "You can manually add more files by copying them to $DEST_DIR"
}

# Main execution
setup_directory
copy_files
sanitize_configs
