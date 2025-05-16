#!/bin/bash

GITHUB_EMAIL=""
GITHUB_USERNAME=""
GITHUB_REPO=""

  # --- Personalización de la terminal ---

# Color de fondo de la terminal en formato RGB o hexadecimal(#):
BACKGROUND_COLOR="#000000"

# Nivel de transparencia del fondo de la terminal (0-100):
BACKGROUND_TRANSPARENCY_PERCENT=17

# Tipo y tamaño de fuente para la terminal:
FONT="Liberation Mono 12"

# Color del texto en la terminal en formato RGB o hexadecimal(#):
FOREGROUND_COLOR="rgb(255,255,255)"



# Function to prompt the user for missing variables
check_variables() {
    if [ -z "$GITHUB_EMAIL" ]; then
        read -p "There's no defined email. Please enter one: " GITHUB_EMAIL
	# Update the script file to include the new value
	sed -i.bak -E "s/^(GITHUB_EMAIL=).*/\1\"$GITHUB_EMAIL\"/" "$0"
    fi

    if [ -z "$GITHUB_USERNAME" ]; then
        read -p "There's no defined username. Please enter one: " GITHUB_USERNAME
        # Update the script file to include the new value
        sed -i.bak -E "s/^(GITHUB_USERNAME=).*/\1\"$GITHUB_USERNAME\"/" "$0"
    fi

    if [ -z "$GITHUB_REPO" ]; then
        read -p "There's no defined default Github repository. Please enter one: " GITHUB_REPO
        # Update the script file to include the new value
        sed -i.bak -E "s|^(GITHUB_REPO=).*|\1\"$GITHUB_REPO\"|" "$0"
    fi
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

    echo "set tabsize 4" >> ~/.nanorc
    echo "set tabstospaces" >> ~/.nanorc

    # Apply changes
    source ~/.bashrc
    reset
}

configure_git() {
    git config --global user.name "$GITHUB_USERNAME"
    git config --global user.email "$GITHUB_EMAIL"
    git config --global core.editor "code --wait"
    git config --global init.defaultBranch main
    git config --global color.ui auto
    git config --global pull.rebase false
    git config --global core.autocrlf input
    git config --global core.abbrev 10
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
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone "$GITHUB_REPO" || log_error "Failed to clone repository"
}

# Function to clean SSH
cleanup_ssh() {
    ssh-add -d "$HOME/.ssh/id_ed25519" 2>/dev/null
    rm -f "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519.pub" 2>/dev/null
}


# Function to delete the script itself
self_delete() {
    # Save the path to the script
    local script_path="$0"
    
    # Delete the script
    if rm -f "$script_path"; then
        echo "Script deleted successfully"
    else
        echo "Failed to delete script"
    fi
}

cursor() {
    local URL="https://downloads.cursor.com/production/client/linux/x64/appimage/Cursor-0.46.11-ae378be9dc2f5f1a6a1a220c6e25f9f03c8d4e19.deb.glibc2.25-x86_64.AppImage"
    local DESTINATION="$HOME/Descargas"
    local FILENAME="Cursor.AppImage"
    
    # Create destination directory if it doesn't exist
    mkdir -p "$DESTINATION"
    cd "$DESTINATION" || exit 1
    
    # Download and setup in a subshell with process tracking
    (
        # Download the file
        if ! curl -L "$URL" -o "$FILENAME" > /dev/null 2>&1 ; then
            exit 1
        fi

        chmod +x "$FILENAME"

        # Extract AppImage
        if ! ./"$FILENAME" --appimage-extract >/dev/null 2>&1; then
            exit 1
        fi

        rm "$FILENAME"
        [[ -d cursor-folder ]] && rm -rf cursor-folder
        mv squashfs-root cursor-folder
    ) &
    
    # Store background process PID
    local setup_pid=$!
    
    # Show spinner while waiting for the setup
    show_spinner $setup_pid "Downloading and setting up Cursor..."
    
    # Wait for setup to complete
    wait $setup_pid
    
    if [ $? -eq 0 ]; then
        # Launch Cursor with complete detachment
        nohup "$DESTINATION/cursor-folder/AppRun" >/dev/null 2>&1 & disown
    else
        echo "An error occurred during installation."
        exit 1
    fi
}

set_dark_theme() {
    # Set the dark them for the system
    gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
}

cleanup_folder() {
    
    script_path="/home/camper/Descargas/jarvis.sh"
    script_dir=$(dirname "$script_path")
    script_name=$(basename "$script_path")

    # Delete everything except the script itself
    find /home/camper/Descargas -mindepth 1 ! -name "$script_name"
}


# Main script execution
case "$1" in
    "hello")
    	check_variables
        # Start tasks that don't depend on GitHub credentials in the background
        (set_dark_theme > /dev/null 2>&1 || true; echo "Dark theme set!") &
        (cleanup_folder > /dev/null 2>&1 || true; echo "Main folder cleaned up!") &
        (customize_terminal > /dev/null 2>&1 || true; echo "Terminal aspect improved!") &
        (xdg-settings set default-web-browser google-chrome.desktop || log_error "Failed to set the default browser" || true) &
        
        # Handle Git and SSH setup separately
        if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_EMAIL" ]; then
            # Configure Git
            configure_git
            
            # Handle SSH setup
            SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
            
            # Generate SSH key
            ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$SSH_KEY_PATH" -N "" || { echo "Failed to generate SSH key"; }
            
            if [ $? -eq 0 ]; then
                # Start SSH agent and add key
                eval "$(ssh-agent -s)"
                ssh-add "$SSH_KEY_PATH" || { echo "Failed to add SSH key to agent"; }
                
                # Display public key
                echo -e "\nAdd this public key to GitHub (https://github.com/settings/keys):"
                cat "${SSH_KEY_PATH}.pub"
                
                # Wait for user confirmation
                read -p "Press [Enter] after adding the key to GitHub..."
                
                # Clone repository only if GITHUB_REPO is defined
                if [ -n "$GITHUB_REPO" ]; then
                    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone "$GITHUB_REPO" || echo "Failed to clone repository"
                    echo "Repository cloned successfully"
                fi
                
                echo "SSH setup complete"
            fi
        fi
        
        # Wait for background processes to complete
        wait
        
        echo "Protocolo de bienvenida completado exitosamente"
        ;;

    "cursor")
        cursor
	;;
    "sql")
    	sql
     	;;

    "bye")
        cleanup_ssh 
        cleanup_browsers
        cleanup_folder

        rm ~/.gitconfig
        touch ~/.gitconfig

        # Clear terminal history
        history -c && history -w

        sleep 10 && shutdown now
        self_delete
        ;;
    *)
        echo "Usage: $0 {hello|bye}"
        echo "  hello         - Initial setup"
        echo "  bye           - Cleanup all data and configurations"
	    echo "  cursor        - Download Cursor app, then open it"
        exit 1        
	;;
esac

