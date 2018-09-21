#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "./utils.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Brew
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

brew_cleanup() {

    # By default Homebrew does not uninstall older versions
    # of formulas so, in order to remove them, `brew cleanup`
    # needs to be used.
    #
    # https://github.com/Homebrew/brew/blob/496fff643f352b0943095e2b96dbc5e0f565db61/share/doc/homebrew/FAQ.md#how-do-i-uninstall-old-versions-of-a-formula

    execute \
        "brew cleanup" \
        "Homebrew (cleanup)"

    execute \
        "brew cask cleanup" \
        "Homebrew (cask cleanup)"

}

brew_install() {

    declare -r FORMULA_READABLE_NAME="$1"
    declare -r FORMULA="$2"
    declare -r TAP_VALUE="$3"
    declare -r CMD="$4"
    declare -r CMD_ARGUMENTS="$5"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Check if `Homebrew` is installed.

    if ! cmd_exists "brew"; then
        print_error "$FORMULA_READABLE_NAME ('Homebrew' is not installed)"
        return 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If `brew tap` needs to be executed,
    # check if it executed correctly.

    if [ -n "$TAP_VALUE" ]; then
        if ! brew_tap "$TAP_VALUE"; then
            print_error "$FORMULA_READABLE_NAME ('brew tap $TAP_VALUE' failed)"
            return 1
        fi
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Install the specified formula.

    # shellcheck disable=SC2086
    if brew $CMD list "$FORMULA" &> /dev/null; then
        print_success "$FORMULA_READABLE_NAME"
    else
        execute \
            "brew $CMD install $FORMULA $CMD_ARGUMENTS" \
            "$FORMULA_READABLE_NAME"
    fi

}

brew_prefix() {

    local path=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if path="$(brew --prefix 2> /dev/null)"; then
        printf "%s" "$path"
        return 0
    else
        print_error "Homebrew (get prefix)"
        return 1
    fi

}

brew_tap() {
    brew tap "$1" &> /dev/null
}

brew_update() {

    execute \
        "brew update" \
        "Homebrew (update)"

}

brew_upgrade() {

    execute \
        "brew upgrade" \
        "Homebrew (upgrade)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Xcode
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
agree_with_xcode_licence() {

    # Automatically agree to the terms of the `Xcode` license.
    # https://github.com/alrra/dotfiles/issues/10

    sudo xcodebuild -license accept &> /dev/null
    print_result $? "Agree to the terms of the Xcode licence"

}

are_xcode_command_line_tools_installed() {
    xcode-select --print-path &> /dev/null
}

install_xcode() {

    # If necessary, prompt user to install `Xcode`.

    if ! is_xcode_installed; then
        open "macappstores://itunes.apple.com/en/app/xcode/id497799835"
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until `Xcode` is installed.

    execute \
        "until is_xcode_installed; do \
            sleep 5; \
         done" \
        "Xcode.app"

}

install_xcode_command_line_tools() {

    # If necessary, prompt user to install
    # the `Xcode Command Line Tools`.

    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until the `Xcode Command Line Tools` are installed.

    execute \
        "until are_xcode_command_line_tools_installed; do \
            sleep 5; \
         done" \
        "Xcode Command Line Tools"

}

is_xcode_installed() {
    [ -d "/Applications/Xcode.app" ]
}

set_xcode_developer_directory() {

    # Point the `xcode-select` developer directory to
    # the appropriate directory from within `Xcode.app`.
    #
    # https://github.com/alrra/dotfiles/issues/13

    sudo xcode-select -switch "/Applications/Xcode.app/Contents/Developer" &> /dev/null
    print_result $? "Make 'xcode-select' developer directory point to the appropriate directory from within Xcode.app"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Homebrew
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
get_homebrew_git_config_file_path() {

    local path=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if path="$(brew --repository 2> /dev/null)/.git/config"; then
        printf "%s" "$path"
        return 0
    else
        print_error "Homebrew (get config file path)"
        return 1
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_homebrew() {

    if ! cmd_exists "brew"; then
        printf "\n" | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" &> /dev/null
        #  └─ simulate the ENTER keypress
    fi

    print_result $? "Homebrew"

}

opt_out_of_analytics() {

    local path=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Try to get the path of the `Homebrew` git config file.

    path="$(get_homebrew_git_config_file_path)" \
        || return 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Opt-out of Homebrew's analytics.
    # https://github.com/Homebrew/brew/blob/0c95c60511cc4d85d28f66b58d51d85f8186d941/share/doc/homebrew/Analytics.md#opting-out

    if [ "$(git config --file="$path" --get homebrew.analyticsdisabled)" != "true" ]; then
        git config --file="$path" --replace-all homebrew.analyticsdisabled true &> /dev/null
    fi

    print_result $? "Homebrew (opt-out of analytics)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
change_default_bash() {

    declare -r LOCAL_SHELL_CONFIG_FILE="$HOME/.bash.local"

    local configs=""
    local pathConfig=""

    local newShellPath=""
    local brewPrefix=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Try to get the path of the `Bash`
    # version installed through `Homebrew`.

    brewPrefix="$(brew_prefix)" \
        || return 1

    pathConfig="PATH=\"$brewPrefix/bin:\$PATH\""
    configs="
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$pathConfig

export PATH
"

    newShellPath="$brewPrefix/bin/bash" \

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Add the path of the `Bash` version installed through `Homebrew`
    # to the list of login shells from the `/etc/shells` file.
    #
    # This needs to be done because applications use this file to
    # determine whether a shell is valid (e.g.: `chsh` consults the
    # `/etc/shells` to determine whether an unprivileged user may
    # change the login shell for her own account).
    #
    # http://www.linuxfromscratch.org/blfs/view/7.4/postlfs/etcshells.html

    if ! grep "$newShellPath" < /etc/shells &> /dev/null; then
        execute \
            "printf '%s\n' '$newShellPath' | sudo tee -a /etc/shells" \
            "Bash (add '$newShellPath' in '/etc/shells')" \
        || return 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Set latest version of `Bash` as the default
    # (macOS uses by default an older version of `Bash`).

    chsh -s "$newShellPath" &> /dev/null
    print_result $? "Bash (use latest version)"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If needed, add the necessary configs in the
    # local shell configuration file.

    if ! grep "^$pathConfig" < "$LOCAL_SHELL_CONFIG_FILE" &> /dev/null; then
        execute \
            "printf '%s' '$configs' >> $LOCAL_SHELL_CONFIG_FILE \
                && . $LOCAL_SHELL_CONFIG_FILE" \
            "Bash (update $LOCAL_SHELL_CONFIG_FILE)"
    fi

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# nvm
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
add_nvm_configs() {

    declare -r CONFIGS="
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Node Version Manager

export NVM_DIR=\"$NVM_DIRECTORY\"

[ -f \"\$NVM_DIR/nvm.sh\" ] \\
    && . \"\$NVM_DIR/nvm.sh\"

[ -f \"\$NVM_DIR/bash_completion\" ] \\
    && . \"\$NVM_DIR/bash_completion\"
"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    execute \
        "printf '%s' '$CONFIGS' >> $LOCAL_SHELL_CONFIG_FILE \
            && . $LOCAL_SHELL_CONFIG_FILE" \
        "nvm (update $LOCAL_SHELL_CONFIG_FILE)"

}

install_latest_stable_node() {

    # Install the latest stable version of Node
    # (this will also set it as the default).

    execute \
        ". $LOCAL_SHELL_CONFIG_FILE \
            && nvm install node" \
        "nvm (install latest Node)"
}

install_nvm() {

    # Install `nvm` and add the necessary
    # configs in the local shell config file.

    execute \
        "git clone --quiet $NVM_GIT_REPO_URL $NVM_DIRECTORY" \
        "nvm (install)" \
    && add_nvm_configs

}

update_nvm() {

    execute \
        "cd $NVM_DIRECTORY \
            && git fetch --quiet origin \
            && git checkout --quiet \$(git describe --abbrev=0 --tags) \
            && . $NVM_DIRECTORY/nvm.sh" \
        "nvm (upgrade)"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# npm
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
install_npm_package() {

    execute \
        ". $HOME/.bash.local \
            && npm install --global --silent $2" \
        "$1"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Vim
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
vim_install_plugins() {

    declare -r VUNDLE_DIR="$HOME/.vim/plugins/Vundle.vim"
    declare -r VUNDLE_GIT_REPO_URL="https://github.com/VundleVim/Vundle.vim.git"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Install plugins.

    execute \
        "rm -rf '$VUNDLE_DIR' \
            && git clone --quiet '$VUNDLE_GIT_REPO_URL' '$VUNDLE_DIR' \
            && printf '\n' | vim +PluginInstall +qall" \
        "Install plugins" \
        || return 1

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Install additional things required by some plugins.

    execute \
        ". $HOME/.bash.local \
            && cd $HOME/.vim/plugins/tern_for_vim \
            && npm install" \
        "Install plugins (extra installs for 'tern_for_vim')"

}

vim_update_plugins() {

    execute \
        "vim +PluginUpdate +qall" \
        "Update plugins"

}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    print_in_purple_dot "Installs"


    print_in_purple "Xcode"
    ###############
    install_xcode_command_line_tools
    #install_xcode
    set_xcode_developer_directory
    agree_with_xcode_licence


    print_in_purple "Homebrew"
    ###############
    install_homebrew
    opt_out_of_analytics
    brew_update
    brew_upgrade


    print_in_purple "Bash"
    ###############
    brew_install "Bash" "bash" \
        && change_default_bash
    brew_install "Bash Completion 2" "bash-completion@2"
    brew_install "Watch" "watch"
    brew_install "wGet" "wget"
    brew_install "htop" "htop"
    brew_install "mc" "mc"
    brew_install "ShellCheck" "shellcheck"
    brew_install "fzf" "fzf"


    print_in_purple "nvm"
    ###############
    if [ ! -d "$NVM_DIRECTORY" ]; then
        install_nvm
    else
        update_nvm
    fi
    install_latest_stable_node


    print_in_purple "Browsers"
    ###############
    brew_install "Chrome" "google-chrome" "caskroom/cask" "cask"
    brew_install "Chrome Canary" "google-chrome-canary" "caskroom/versions" "cask"
    brew_install "Firefox" "firefox" "caskroom/cask" "cask"
    brew_install "Flash" "flash-npapi" "caskroom/cask" "cask"


    print_in_purple "Compression Tools"
    ###############
    brew_install "Brotli" "brotli"
    brew_install "Zopfli" "zopfli"


    print_in_purple "Git"
    ###############
    brew_install "Git" "git"
    brew_install "SourceTree" "sourcetree" "caskroom/cask" "cask"


    print_in_purple "GPG"
    ###############
    #brew_install "GPG" "gpg"
    #brew_install "GPG Agent" "gpg-agent"
    #brew_install "Pinentry" "pinentry-mac"


    print_in_purple "Miscellaneous"
    ###############
    brew_install "Android File Transfer" "android-file-transfer" "caskroom/cask" "cask"
    brew_install "Spectacle" "spectacle" "caskroom/cask" "cask"
    brew_install "Unarchiver" "the-unarchiver" "caskroom/cask" "cask"
    brew_install "Docker" "docker" "caskroom/cask" "cask"
    brew_install "Kitematic" "kitematic" "caskroom/cask" "cask"


    print_in_purple "Miscellaneous"
    ###############
    brew_install "Android File Transfer" "android-file-transfer" "caskroom/cask" "cask"
    brew_install "Spectacle" "spectacle" "caskroom/cask" "cask"
    brew_install "Unarchiver" "the-unarchiver" "caskroom/cask" "cask"
    brew_install "Docker" "docker" "caskroom/cask" "cask"
    brew_install "Kitematic" "kitematic" "caskroom/cask" "cask"


    print_in_purple "Editors"
    ###############
    # brew_install "Sublimie3" "sublimie" "caskroom/cask" "cask"
    # brew_install "Atom" "spectacle" "caskroom/cask" "cask"
    # brew_install "Visual Studio Code" "visual-studio-code" "caskroom/cask" "cask"
    # brew_install "InteliJ" "intelij" "caskroom/cask" "cask"
    # brew_install "Eclipse" "intelij" "caskroom/cask" "cask"


    print_in_purple "Node"
    ###############
    if [ -d "$HOME/.nvm" ]; then
        brew_install "Yarn" "yarn" "" "" "--without-node"
    fi
    install_npm_package "npm (update)" "npm"
    install_npm_package "!nstant-markdown-d" "instant-markdown-d"
    install_npm_package "Gulp" "gulp"
    install_npm_package "Bower" "bower"


    print_in_purple "tmux"
    ###############
    brew_install "tmux" "tmux"
    brew_install "tmux (pasteboard)" "reattach-to-user-namespace"


    print_in_purple "Vim"
    ###############
    brew_install "Vim" "vim --with-override-system-vi"
    install_plugins
    update_plugins


    print_in_purple "Web Font Tools"
    ###############
    brew_install "Web Font Tools: TTF/OTF → WOFF (Zopfli)" "sfnt2woff-zopfli" "bramstein/webfonttools"
    brew_install "Web Font Tools: TTF/OTF → WOFF" "sfnt2woff" "bramstein/webfonttools"
    brew_install "Web Font Tools: WOFF2" "woff2" "bramstein/webfonttools"


    print_in_purple "JAVA"
    ###############
    brew_install "Java 1.8" "java8" "caskroom/versions" "cask"
    brew_install "Spring-boot-cli" "springboot" "pivotal/tap" ""


    print_in_purple "Cleanup"
    ###############
    brew_cleanup

}

main
