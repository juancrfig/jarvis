#!/bin/bash

# Variables Globales
GITHUB_EMAIL=""                      # Ingresa tu email de GitHub
GITHUB_USERNAME=""                   # Ingresa tu usuario de GitHub
GITHUB_REPO=""                       # El link SSH de un repositorio que quieras clonar por defecto
IMAGE_URL=""                         # El URL de la imagen para colocar como fondo

# Variables para personalizar la terminal
BACKGROUND_COLOR="rgb(0,0,0)"        # Ingresa el color de fondo que quieres para tu terminal
BACKGROUND_TRANSPARENCY_PERCENT=15   # Ingresa el porcentaje de transparencia para el fondo de la terminal
FONT=""                              # Ingresa el estilo de letra
FOREGROUND_COLOR="rgb(255,255,255)"  # Ingresa el color de la letra


# Función para personalizar la terminal
customize_terminal() {

    PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
    PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"

    # Background color
    gsettings set $PROFILE_PATH background-color "$BACKGROUND_COLOR"

    # Transparency
    gsettings set $PROFILE_PATH use-transparent-background true
    gsettings set $PROFILE_PATH background-transparency-percent $BACKGROUND_TRANSPARENCY_PERCENT

    # Cursor properties
    gsettings set $PROFILE_PATH cursor-shape 'block'
    gsettings set $PROFILE_PATH cursor-blink-mode 'on'

    # Theme and colors
    gsettings set $PROFILE_PATH use-theme-colors false

    # Font settings
    gsettings set $PROFILE_PATH use-system-font false
    gsettings set $PROFILE_PATH font "$FONT"
    gsettings set $PROFILE_PATH foreground-color "$FOREGROUND_COLOR"U    # Get default profile ID
    
    # File and directory colors (creates or modifies .bashrc entries)
    if ! grep -q 'Custom colors for files and directories' ~/.bashrc; then
        echo '
		# Custom colors for files and directories
		LS_COLORS="di=1;34:ln=1;36:ex=1;32:*.jpg=1;35:*.png=1;35:*.txt=0;37"
		export LS_COLORS

		# Enable color support
		alias ls="ls --color=auto"
		alias dir="dir --color=auto"
		alias grep="grep --color=auto"
		' >> ~/.bashrc
    fi

    # Add custom prompt colors
    if ! grep -q 'Custom colored prompt' ~/.bashrc; then
        echo '
		# Custom colored prompt
		RED='\''\[\033[0;31m\]'\''
		GREEN='\''\[\033[0;32m\]'\''
		YELLOW='\''\[\033[0;33m\]'\''
		BLUE='\''\[\033[0;34m\]'\''
		PURPLE='\''\[\033[0;35m\]'\''
		CYAN='\''\[\033[0;36m\]'\''
		RESET='\''\[\033[0m\]'\''
		PS1="${GREEN}\u${RESET}@${BLUE}\h${RESET}:${PURPLE}\w${RESET}\$ "
		' >> ~/.bashrc
    fi

    # Apply changes
    source ~/.bashrc
	reset
    echo "Terminal customization applied!"
}

# Funcion para configurar Git
configure_git() {
    git config --global user.name "$GITHUB_USERNAME"
    git config --global user.email "$GITHUB_EMAIL"
    git config --global core.editor "code --wait"
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global core.abbrev 10
    log_success "Git configuration complete"
}

# Funcion para limpiar VS Code
cleanup_vscode() {

        # Kill VS Code processes
        pkill -f "code" 2>/dev/null

        # Force kill if still running
        if pgrep -f "code" > /dev/null; then
                pkill -9 -f "code"
        fi

    echo "Cleaning VS Code data..."
    local vscode_paths=(
        "$HOME/.config/Code"
        "$HOME/.vscode"
        "$HOME/.config/Code - OSS"
        "$HOME/.local/share/code"
        "$HOME/.local/share/code-oss"
        "$HOME/.cache/code"
        "$HOME/.cache/code-oss"
        "$HOME/.vscode/extensions"
    )
    
    for path in "${vscode_paths[@]}"; do
        rm -rf "$path" 2>/dev/null
    done
    log_success "VS Code cleanup complete"
}

cleanup_browsers() {

    # Ensure both browsers are completely closed
    pkill -f firefox
    pkill -f chrome
    pkill -f chromium
    sleep 2

    # Paths for Firefox cleanup
    firefox_paths=(
        "$HOME/.mozilla/firefox"
        "$HOME/.cache/mozilla/firefox"
        "$HOME/.config/firefox"
        "$HOME/.local/share/firefox"
        "$HOME/.local/share/mozilla"
        "$HOME/.local/state/mozilla"
        "$HOME/.mozilla/firefox/*.default*"
        "$HOME/.mozilla/firefox/*.default-release*"
        "$HOME/.mozilla/firefox/profiles.ini"
        "$HOME/snap/firefox"
        "$HOME/snap/firefox/common/.mozilla"
        "$HOME/snap/firefox/common/.cache/mozilla"
        "$HOME/.var/app/org.mozilla.firefox"
        "$HOME/.var/app/org.mozilla.firefox/.mozilla"
        "$HOME/.var/app/org.mozilla.firefox/.cache"
        "$HOME/.mozilla/firefox/*default*/logins.json"
        "$HOME/.mozilla/firefox/*default*/key*.db"
        "$HOME/.mozilla/firefox/*default*/cookies.sqlite"
    )

    # Paths for Google Chrome cleanup
    chrome_paths=(
        "$HOME/.config/google-chrome"
        "$HOME/.cache/google-chrome"
        "$HOME/.local/share/google-chrome"
        "$HOME/.local/state/google-chrome"
        "$HOME/snap/chromium"
        "$HOME/snap/chromium/common/.cache"
        "$HOME/snap/chromium/common/.config"
        "$HOME/.var/app/com.google.Chrome"
        "$HOME/.var/app/com.google.Chrome/.cache"
        "$HOME/.var/app/com.google.Chrome/.config"
        "$HOME/.config/chromium"
        "$HOME/.cache/chromium"
        "$HOME/.local/share/chromium"
        "$HOME/.local/state/chromium"
    )

    # Combine paths for cleanup
    all_paths=("${firefox_paths[@]}" "${chrome_paths[@]}")

    # Remove all browser-related files
    for path in "${all_paths[@]}"; do
        # Use find to handle wildcards and remove files/directories
        find "${path%/*}" -path "$path" -prune -exec rm -rf {} + 2>/dev/null
    done

    echo "Browser data deletion complete."
}
