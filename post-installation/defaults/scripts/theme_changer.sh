#!/bin/dash
# Kill if already running
if pidof -o %PPID -x "${0##*/}"; then
    exit 1
fi
DESKTOP_THEME_DAY="Adapta"
DESKTOP_THEME_NIGHT="Adapta-Nokto"
CONTROLS_THEME_DAY="Arc"
CONTROLS_THEME_NIGHT="Arc-Dark"

ICONS="Papirus"
WINDOW_DECORATION_THEME="Cinnazor"

# Start loop
while :; do
    # What time is it?
    CURRENT_TIME=$(date +%H%M)
    if [ -n "$NEXT_TIME" ] && [ "$CURRENT_TIME" -lt "$NEXT_TIME" ]; then
        sleep 60
        continue
    fi
    echo "${CURRENT_TIME}"
    # Depending on the time set CONTROLS_THEME & NEXT_TIME
    if [ "$CURRENT_TIME" -ge 0600 ] && [ "$CURRENT_TIME" -lt 1800 ]; then
        CONTROLS_THEME=${CONTROLS_THEME_DAY}
        DESKTOP_THEME=${DESKTOP_THEME_DAY}
        NEXT_TIME=1800
    else
        CONTROLS_THEME=${CONTROLS_THEME_NIGHT}
        DESKTOP_THEME=${DESKTOP_THEME_NIGHT}
        NEXT_TIME=0600
    fi
    # Set the chosen theme
    gsettings set org.cinnamon.desktop.wm.preferences theme "$WINDOW_DECORATION_THEME"
    gsettings set org.cinnamon.desktop.interface icon-theme "$ICONS"
    gsettings set org.cinnamon.desktop.interface gtk-theme "$CONTROLS_THEME"
    gsettings set org.cinnamon.theme name "$DESKTOP_THEME"
    # Sleep
    sleep 60
done
