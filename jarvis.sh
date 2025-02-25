#!/bin/bash

# Variables Globales
GITHUB_EMAIL=""                      # Ingresa tu email de GitHub
GITHUB_USERNAME=""                   # Ingresa tu usuario de GitHub
GITHUB_REPO=""                       # El link SSH de un repositorio que quieras clonar por defecto
IMAGE_URL=""

# Variables para personalizar la terminal
BACKGROUND_COLOR="rgb(0,0,0)"        # Ingresa el color de fondo que quieres para tu terminal
BACKGROUND_TRANSPARENCY_PERCENT=15   # Ingresa el porcentaje de transparencia para el fondo de la terminal
FONT="Monospace 12"                              # Ingresa el estilo de letra
FOREGROUND_COLOR="rgb(255,255,255)"  # Ingresa el color de la letra


sql() {
    mysql -u campus2023 -pcampus2023
}

# Spinner function that tracks a specific process
show_spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spin='|/-\'
    
    while ps -p $pid >/dev/null 2>&1; do
        for i in $(seq 0 3); do
            printf "\r[%c] %s" "${spin:$i:1}" "$message"
            sleep $delay
        done
    done
    printf "\r[✔] %s\n" "$message"
}

# Function to personalize the terminal
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
    gsettings set $PROFILE_PATH foreground-color "$FOREGROUND_COLOR"
    
    # File and directory colors
    if ! grep -q 'Custom colors for files and directories' ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'
# Custom colors for files and directories
LS_COLORS="di=1;34:ln=1;36:ex=1;32:*.jpg=1;35:*.png=1;35:*.txt=0;37"
export LS_COLORS

# Enable color support
alias ls="ls --color=auto"
alias dir="dir --color=auto"
alias grep="grep --color=auto"
EOF
    fi

    # Add custom prompt colors
    if ! grep -q 'Custom colored prompt' ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'
# Custom colored prompt
RED='\[\033[0;31m\]'
GREEN='\[\033[0;32m\]'
YELLOW='\[\033[0;33m\]'
BLUE='\[\033[0;34m\]'
PURPLE='\[\033[0;35m\]'
CYAN='\[\033[0;36m\]'
RESET='\[\033[0m\]'
PS1="${GREEN}\u${RESET}@${BLUE}\h${RESET}:${PURPLE}\w${RESET}\$ "
EOF
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

# Helper function for error handling
log_error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Helper function for success messages
log_success() {
    echo "SUCCESS: $1"
}


# Function to handle SSH setup
setup_ssh() {
    
    local SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
    
    # Generate SSH key
    ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$SSH_KEY_PATH" -N "" || log_error "Failed to generate SSH key"
    
    # Start SSH agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY_PATH" || log_error "Failed to add SSH key to agent"
    
    # Display public key
    echo -e "\nAdd this public key to GitHub (https://github.com/settings/keys):"
    cat "${SSH_KEY_PATH}.pub"
    
    # Wait for user confirmation
    read -p "Press [Enter] after adding the key to GitHub..."
    
    # Clone repository
    echo "Cloning repository..."
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone "$GITHUB_REPO" || log_error "Failed to clone repository"
    log_success "SSH setup and repository clone complete"
}

# Function to clean SSH
cleanup_ssh() {
    echo "Cleaning up SSH..."
    ssh-add -d "$HOME/.ssh/id_ed25519" 2>/dev/null
    rm -f "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub" 2>/dev/null
    log_success "SSH cleanup complete"
}

set_wallpaper() {

        # Configuration
        DEST_FOLDER="$HOME/Pictures"
        FILENAME="wallpaper.jpg"
        WALLPAPER_PATH="$DEST_FOLDER/$FILENAME"

        # Create wallpapers directory if it doesn't exist
        mkdir -p "$DEST_FOLDER"

        # Download the image with optimized curl command
        echo "Downloading wallpaper..."
        if curl -L \
            -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
            -H "Accept: image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8" \
            -H "Referer: https://uhdpaper.com/" \
            --compressed \
            -o "$WALLPAPER_PATH" \
            "$IMAGE_URL"; then

            # Verify the download was successful
            if [ -f "$WALLPAPER_PATH" ] && [ -s "$WALLPAPER_PATH" ]; then
                echo "Download completed successfully"

                # Set the wallpaper for both light and dark themes
                gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER"
                gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
                gsettings set org.gnome.desktop.background picture-options 'scaled'

                echo "✓ Wallpaper has been set successfully!"
                echo "Location: $WALLPAPER_PATH"
            else
                echo "❌ Error: Download failed or file is empty"
            fi
        else
            echo "❌ Error: Failed to download the image"
        fi
}


# Function to delete the script itself
self_delete() {
    echo "Deleting the script and the folder..."
    
    # Save the path to the script
    local script_path="$0"
    
    # Path to the folder to delete
    local folder_path="/home/camper/Descargas/jarvis"
    
    # Delete the folder and its contents
    if rm -rf "$folder_path"; then
        log_success "Folder deleted successfully"
    else
        log_error "Failed to delete folder"
    fi
    
    # Delete the script
    if rm -f "$script_path"; then
        log_success "Script deleted successfully"
    else
        log_error "Failed to delete script"
    fi
}

# Obsidian installation and launch function
obsidian() {
    local URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.7.7/Obsidian-1.7.7.AppImage"
    local DESTINATION="$HOME/Descargas"
    local FILENAME="Obsidian.AppImage"
    
    # Create destination directory if it doesn't exist
    mkdir -p "$DESTINATION"
    cd "$DESTINATION" || exit 1
    
    # Download and setup in a subshell with process tracking
    (
        # Download the file
        if ! curl -L "$URL" -o "$FILENAME" > /dev/null 2>&1 ; then
            echo "Download failed!"
            exit 1
        fi
        
        chmod +x "$FILENAME"
        
        # Extract AppImage
        if ! ./"$FILENAME" --appimage-extract >/dev/null 2>&1; then
            echo "Extraction failed!"
            exit 1
        fi
        
        rm "$FILENAME"
        [[ -d obsidian-folder ]] && rm -rf obsidian-folder
        mv squashfs-root obsidian-folder
    ) &
    
    # Store background process PID
    local setup_pid=$!
    
    # Show spinner while waiting for the setup
    show_spinner $setup_pid "Downloading and setting up Obsidian..."
    
    # Wait for setup to complete
    wait $setup_pid
    
    if [ $? -eq 0 ]; then
        echo "Installation completed. Launching Obsidian..."
        # Launch Obsidian with complete detachment
        nohup "$DESTINATION/obsidian-folder/obsidian" >/dev/null 2>&1 & disown
        echo "Obsidian launched successfully!"
    else
        echo "An error occurred during installation."
        exit 1
    fi
}

setup_nvm() {
    # Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

    # Set up NVM_DIR environment variable
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

    # Load nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    # Check nvm version
    nvm --version
    nvm -v

    # Install the latest version of Node.js
    nvm install node
}

libraries() {

    pip install kivy
    echo "Kivy installed!"

}

set_dark_theme() {

    echo "Setting dark  theme for Ubuntu"

    # Set the dark them for the system
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

    echo "Dark theme has been applied successfully!"
}

cleanup_folder() {
    
    script_path="/home/camper/Descargas/jarvis.sh"
    script_dir=$(dirname "$script_path")
    script_name=$(basename "$script_path")

    # Delete everything except the script itself
    find /home/camper/Descargas -mindepth 1 ! -name "$script_name" ! -name "jarvis-master" ! -name "jarvis" ! -name "menu.py" ! -name "img" ! -name "jarvis-menu.png" ! -name "happy_jarvis.py"  -delete

    echo "All files and folders in $script_dir except $script_name have been deleted."
}

# Main script execution
case "$1" in
    "hello")
        # Start tasks that don't depend on GitHub credentials in the background
        (set_dark_theme > /dev/null 2>&1 || true; echo "Dark theme set!") &
        (cleanup_folder > /dev/null 2>&1 || true; echo "Main folder cleaned up!") &
        (set_wallpaper > /dev/null 2>&1 || true; echo "Wallpaper set!") &
        (customize_terminal > /dev/null 2>&1 || true; echo "Terminal aspect improved!") &
        (cleanup_vscode > /dev/null 2>&1 || true; echo "Visual Studio Code previous configs erased!") &
        (xdg-settings set default-web-browser google-chrome.desktop || log_error "Failed to set the default browser" || true) &
        (setup_nvm > /dev/null 2>&1 || true; echo "Node.js and nvm installed!" ) &
        (libraries > /dev/null 2>&1 || true; echo "Python libraries installed!") &
        
        # Handle Git and SSH setup separately
        if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_EMAIL" ]; then
            # Configure Git
            configure_git
            
            # Handle SSH setup
            SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
            
            # Generate SSH key
            ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$SSH_KEY_PATH" -N "" || { log_error "Failed to generate SSH key"; }
            
            if [ $? -eq 0 ]; then
                # Start SSH agent and add key
                eval "$(ssh-agent -s)"
                ssh-add "$SSH_KEY_PATH" || { log_error "Failed to add SSH key to agent"; }
                
                # Display public key
                echo -e "\nAdd this public key to GitHub (https://github.com/settings/keys):"
                cat "${SSH_KEY_PATH}.pub"
                
                # Wait for user confirmation
                read -p "Press [Enter] after adding the key to GitHub..."
                
                # Clone repository only if GITHUB_REPO is defined
                if [ -n "$GITHUB_REPO" ]; then
                    echo "Cloning repository..."
                    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone "$GITHUB_REPO" || log_error "Failed to clone repository"
                    log_success "Repository cloned successfully"
                else
                    echo "Skipping repository clone: GITHUB_REPO not defined"
                fi
                
                log_success "SSH setup complete"
            fi
        else
            echo "Skipping Git and SSH setup: GitHub credentials not provided"
        fi
        
        # Wait for background processes to complete
        wait
        
        log_success "Protocolo de bienvenida completado exitosamente"
        ;;
    "obsidian")
	obsidian
	;;

    "sql")
    	sql
     	;;

    "bye")
        cleanup_ssh 
        cleanup_discord
        cleanup_vscode
        cleanup_browsers
        cleanup_folder

        rm ~/.gitconfig
        touch ~/.gitconfig

        # Clear terminal history
        history -c && history -w

        log_success "Protocolo de despedida completado exitosamente"
        sleep 10 && shutdown now
        self_delete
        ;;

    "happy")
        pip install selenium &> /dev/null
        pip install undetected-chromedriver &> /dev/null
	    chmod +x happy_jarvis.py
	    echo "Happy mode activated"
	    ./python_scripts/happy_jarvis.py || log_error "Error"
	    echo "Lito a mimir"
	    ;;

    *)
        echo "Usage: $0 {hello|obsidian|bye|review|happy}"
        echo "  hello         - Initial setup (VS Code cleanup, Git config, Firefox default)"
        echo "  obsidian      - Download Obsidian app, then open it"
        echo "  bye           - Cleanup all data and configurations"
        echo "  happy         - Run the Python script (review.py)"
        exit 1        
	;;
esac

