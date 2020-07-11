#!/bin/dash
# Kill if already running
if pidof -o %PPID -x "${0##*/}"; then
    exit 1
fi
DAY_THEME="Adapta"
NIGHT_THEME="Adapta-Nokto"
ICONS="Papirus"

# Start loop
while :; do
    # What time is it?
    CURRENT_TIME=$(date +%H%M)
    if [ -n "$NEXT_TIME" ] && [ "$CURRENT_TIME" -lt "$NEXT_TIME" ]; then
        sleep 60
        continue
    fi
    echo ${CURRENT_TIME}
    # Depending on time set THEME_CHOICE & NEXT_TIME
    if [ "$CURRENT_TIME" -ge 0600 ] && [ "$CURRENT_TIME" -lt 1800 ]; then
        THEME_CHOICE=${DAY_THEME}
        NEXT_TIME=1800
    else
        THEME_CHOICE=${NIGHT_THEME}
        NEXT_TIME=0600
    fi
    # Set the chosen theme
    gsettings set org.cinnamon.desktop.interface gtk-theme "$THEME_CHOICE"
    gsettings set org.cinnamon.desktop.interface icon-theme "$ICONS"
    gsettings set org.cinnamon.theme name "$THEME_CHOICE"
    # Sleep
    sleep 60
done
