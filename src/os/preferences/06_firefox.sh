#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../../utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "Firefox"

execute "defaults write org.mozilla.firefox AppleEnableSwipeNavigateWithScrolls -bool false" \
    "Disable backswipe"

killall "firefox" &> /dev/null
