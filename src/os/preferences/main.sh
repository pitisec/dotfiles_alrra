#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple_dot "Preferences"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Close any open `System Preferences` panes in order to
# avoid overriding the preferences that are being changed.

./00_close_system_preferences_panes.applescript

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

./01_app_store.sh
./02_chrome.sh
./03_dashboard.sh
./04_dock.sh
./05_finder.sh
./06_firefox.sh
./07_keyboard.sh
./08_language_and_region.sh
./09_maps.sh
./10_photos.sh
./11_safari.sh
./12_terminal.sh
./13_textedit.sh
./14_trackpad.sh
./15_ui_and_ux.sh
