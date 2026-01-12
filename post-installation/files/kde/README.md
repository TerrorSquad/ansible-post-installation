# KDE Customization Files

Place your KDE configuration files in this directory to have them applied by the playbook.

## Recommended Files to Include

Copy these files from your `~/.config/` directory after setting up KDE to your liking:

- `kdeglobals`: Basic theme settings (colors, fonts, widget style)
- `plasmashellrc`: Plasma panel and desktop layout
- `kwinrc`: Window manager settings and effects
- `kcminputrc`: Mouse and cursor settings
- `kscreenlockerrc`: Lock screen settings
- `plasma-org.kde.plasma.desktop-appletsrc`: Widget specific configuration
- `startkderc`: Startup settings

## How to use

1. Configure KDE on your machine manually.
2. Copy the desired files from `~/.config/` to this directory.
3. Commit them to the repository.
4. Run the playbook to apply them to other machines.
