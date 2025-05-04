#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to print success messages
print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to print error messages
print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to print warning messages
print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_status "Starting dotfiles setup script..."

# —————— CONFIGURATION ——————
# Get GitHub username and repository name
read -rp "Enter your GitHub username: " GITHUB_USER
read -rp "Enter repository name (default: dotfiles): " REPO_NAME_INPUT
REPO_NAME="${REPO_NAME_INPUT:-dotfiles}"

# Git alias for dotfiles management
GIT_ALIAS="config"
DOTFILES_DIR="$HOME/.dotfiles"

# Check if .dotfiles directory already exists
if [ -d "$DOTFILES_DIR" ]; then
  print_error "The directory $DOTFILES_DIR already exists. Please remove or rename it before continuing."
  exit 1
fi

# Create ~/.local/bin directory if it doesn't exist
LOCAL_BIN_DIR="$HOME/.local/bin"
if [ ! -d "$LOCAL_BIN_DIR" ]; then
  print_status "Creating directory for custom scripts at $LOCAL_BIN_DIR..."
  mkdir -p "$LOCAL_BIN_DIR"
  print_success "Created $LOCAL_BIN_DIR directory"
fi

# —————— INITIALIZE BARE REPOSITORY ——————
print_status "Creating bare Git repository at $DOTFILES_DIR..."
git init --bare "$DOTFILES_DIR"
print_success "Created bare repository at $DOTFILES_DIR"

# —————— SET UP GIT ALIAS ——————
print_status "Setting up Git alias for dotfiles management..."

# Create a temporary shell script to add the alias
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << EOF
# Function to add text to a file if it doesn't already exist
add_to_file() {
  local file="\$1"
  local text="\$2"
  
  # Check if file exists
  if [ ! -f "\$file" ]; then
    echo "\$text" > "\$file"
    return
  fi
  
  # Check if text already exists in file
  if ! grep -qF "\$text" "\$file"; then
    echo -e "\n\$text" >> "\$file"
  fi
}

# Add alias to .bashrc
add_to_file "$HOME/.bashrc" "# Dotfiles management
alias $GIT_ALIAS='git --git-dir=$DOTFILES_DIR --work-tree=\$HOME'
$GIT_ALIAS config --local status.showUntrackedFiles no"
EOF

# Make the script executable and run it
chmod +x "$TEMP_SCRIPT"
. "$TEMP_SCRIPT"
rm "$TEMP_SCRIPT"

# Load the alias for this session
alias ${GIT_ALIAS}="git --git-dir=${DOTFILES_DIR} --work-tree=${HOME}"
${GIT_ALIAS} config --local status.showUntrackedFiles no

print_success "Git alias '$GIT_ALIAS' configured. You can now use '$GIT_ALIAS' as a replacement for 'git' to manage your dotfiles."

# —————— ADD DOTFILES TO REPOSITORY ——————
print_status "Adding important dotfiles to the repository..."

# List of files to add
DOTFILES=(
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.gitconfig"
  "$HOME/.config/Code/User/settings.json"
  "$HOME/.config/Code/User/keybindings.json"
  "$HOME/.config/Cursor/User/settings.json"
  "$HOME/.config/Cursor/User/keybindings.json"
)

# Add files to git if they exist
for file in "${DOTFILES[@]}"; do
  if [ -f "$file" ]; then
    ${GIT_ALIAS} add "$file"
    relative_path="${file#$HOME/}"
    print_success "Added $relative_path to repository"
  else
    print_warning "File $file not found, skipping"
  fi
done

# —————— COMMIT CHANGES ——————
print_status "Creating initial commit..."
${GIT_ALIAS} commit -m "Initial dotfiles commit"
print_success "Created initial commit"

# —————— GITHUB REPOSITORY SETUP ——————
print_status "GitHub CLI (gh) is not installed. Please manually create a repository on GitHub:"
echo "1. Go to https://github.com/new"
echo "2. Name your repository: $REPO_NAME"
echo "3. Make it public or private according to your preference"
echo "4. Initialize without README, .gitignore, or license files"
echo "5. Click 'Create repository'"
echo ""
echo "After creating the repository, run these commands to push your dotfiles:"
echo ""
echo "  ${GIT_ALIAS} remote add origin git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
echo "  ${GIT_ALIAS} branch -M main"
echo "  ${GIT_ALIAS} push -u origin main"
echo ""

# —————— INSTRUCTIONS FOR NEW MACHINE ——————
print_status "To clone your dotfiles on a new machine, follow these steps:"
echo ""
echo "1. Clone the bare repository:"
echo "   git clone --bare git@github.com:${GITHUB_USER}/${REPO_NAME}.git \$HOME/.dotfiles"
echo ""
echo "2. Define the alias in your shell:"
echo "   alias ${GIT_ALIAS}='git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME'"
echo ""
echo "3. Checkout the content from the repository to your home directory:"
echo "   ${GIT_ALIAS} checkout"
echo ""
echo "4. Configure the repository to hide untracked files:"
echo "   ${GIT_ALIAS} config --local status.showUntrackedFiles no"
echo ""
echo "Note: If you encounter errors due to existing files, you can either:"
echo "- Back up the conflicting files and then retry the checkout"
echo "- Use '${GIT_ALIAS} checkout -f' to force overwrite (be careful!)"
echo ""
# —————— WARP TERMINAL CONFIGURATION ——————
print_status "Checking for Warp terminal configuration..."

# Only proceed if running on Linux
if [[ "$(uname)" == "Linux" ]]; then
  # Check if Warp is installed
  if command -v warp-terminal &>/dev/null || [ -f "/opt/warpdotdev/warp-terminal/warp" ]; then
    print_status "Warp terminal detected. Setting up as default terminal..."
    
    # Set Warp as the default terminal in GNOME
    if command -v gsettings &>/dev/null; then
      gsettings set org.gnome.desktop.default-applications.terminal exec 'warp-terminal' 2>/dev/null || \
        print_warning "Failed to set Warp as default terminal through gsettings."
      gsettings set org.gnome.desktop.default-applications.terminal exec-arg '' 2>/dev/null || \
        print_warning "Failed to set terminal exec arguments through gsettings."
      print_success "Set Warp as default terminal application in GNOME settings."
    else
      print_warning "gsettings not found. Skipping GNOME terminal configuration."
    fi
    
    # Set up environment variables
    ENVIRONMENT_FILE="/etc/environment"
    WARP_ENV_VARS="# Added by dotfiles setup - Warp terminal configuration
TERMINAL=/usr/bin/warp-terminal
DEFAULT_TERMINAL=/usr/bin/warp-terminal"
    
    if [ -w "$ENVIRONMENT_FILE" ]; then
      # Check if environment variables already exist
      if ! grep -q "TERMINAL=/usr/bin/warp-terminal" "$ENVIRONMENT_FILE"; then
        echo "$WARP_ENV_VARS" | sudo tee -a "$ENVIRONMENT_FILE" >/dev/null || \
          print_warning "Failed to update $ENVIRONMENT_FILE."
        print_success "Added terminal environment variables to $ENVIRONMENT_FILE."
      else
        print_status "Terminal environment variables already exist in $ENVIRONMENT_FILE."
      fi
    else
      print_warning "Cannot write to $ENVIRONMENT_FILE. Please manually add these lines:
$WARP_ENV_VARS"
    fi
    
    # Create Nautilus scripts directory if it doesn't exist
    NAUTILUS_SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts"
    if [ ! -d "$NAUTILUS_SCRIPTS_DIR" ]; then
      mkdir -p "$NAUTILUS_SCRIPTS_DIR"
      print_status "Created Nautilus scripts directory."
    fi
    
    # Create "Open in Warp Terminal" script
    WARP_SCRIPT="$NAUTILUS_SCRIPTS_DIR/Open in Warp Terminal"
    cat > "$WARP_SCRIPT" << 'EOF'
#!/bin/bash

# Get the current selection from Nautilus
for arg in "$@"; do
    # Check if the selected item is a directory
    if [ -d "$arg" ]; then
        # If it's a directory, open Warp terminal in this directory
        /usr/bin/warp-terminal --working-directory="$arg" &
    else
        # If it's a file, open Warp terminal in the parent directory
        parent_dir=$(dirname "$arg")
        /usr/bin/warp-terminal --working-directory="$parent_dir" &
    fi
    # We only process the first selected item
    break
done

# If no arguments are provided, open in the current directory
if [ $# -eq 0 ]; then
    /usr/bin/warp-terminal --working-directory="$PWD" &
fi

exit 0
EOF
    chmod +x "$WARP_SCRIPT"
    print_success "Created Nautilus script for opening Warp Terminal."
    
    # Create directory for app shortcuts if it doesn't exist
    APP_DIR="$HOME/.local/share/applications"
    if [ ! -d "$APP_DIR" ]; then
      mkdir -p "$APP_DIR"
      print_status "Created applications directory."
    fi
    
    # Create script to open parent directory of file
    SCRIPT_DIR="$HOME/.local/bin"
    if [ ! -d "$SCRIPT_DIR" ]; then
      mkdir -p "$SCRIPT_DIR"
      print_status "Created local bin directory."
    fi
    
    PARENT_DIR_SCRIPT="$SCRIPT_DIR/open-warp-parent-dir.sh"
    cat > "$PARENT_DIR_SCRIPT" << 'EOF'
#!/bin/bash

# Check if a file path was provided
if [ -z "$1" ]; then
    echo "No file path provided."
    exit 1
fi

# Get the parent directory of the file
file_path="$1"
parent_dir=$(dirname "$file_path")

# Open Warp Terminal in the parent directory
/usr/bin/warp-terminal --working-directory="$parent_dir"

exit 0
EOF
    chmod +x "$PARENT_DIR_SCRIPT"
    print_success "Created script for opening parent directory in Warp Terminal."
    
    # Create desktop entry for directories
    WARP_FOLDER_DESKTOP="$APP_DIR/warp-open-folder.desktop"
    cat > "$WARP_FOLDER_DESKTOP" << 'EOF'
[Desktop Entry]
Type=Application
Name=Open Folder in Warp Terminal
Comment=Open the selected folder in Warp Terminal
Icon=dev.warp.Warp
Exec=/usr/bin/warp-terminal --working-directory=%f
Terminal=false
Categories=System;TerminalEmulator;
MimeType=inode/directory;
NoDisplay=false
StartupNotify=true
EOF
    print_success "Created desktop entry for opening folders in Warp Terminal."
    
    # Create desktop entry for terminal URL handler
    WARP_TERMINAL_HANDLER="$APP_DIR/warp-terminal-handler.desktop"
    cat > "$WARP_TERMINAL_HANDLER" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Warp Terminal
GenericName=TerminalEmulator
Comment=Open Warp Terminal with terminal:// URLs
Exec=warp-terminal %u
StartupWMClass=dev.warp.Warp
Keywords=shell;prompt;command;commandline;cmd;terminal;
Icon=dev.warp.Warp
Categories=System;TerminalEmulator;
Terminal=false
MimeType=x-scheme-handler/terminal;
NoDisplay=false
EOF
    print_success "Created desktop entry for handling terminal:// URLs."
    
    # Update desktop database
    if command -v update-desktop-database &>/dev/null; then
      update-desktop-database "$APP_DIR" || print_warning "Failed to update desktop database."
      print_success "Updated desktop database."
    fi
    
    # Register Warp as handler for inode/directory and terminal URLs
    if command -v xdg-mime &>/dev/null; then
      xdg-mime default warp-open-folder.desktop inode/directory || \
        print_warning "Failed to set Warp as handler for directories."
      xdg-mime default warp-terminal-handler.desktop x-scheme-handler/terminal || \
        print_warning "Failed to set Warp as handler for terminal:// URLs."
      print_success "Registered Warp as handler for directories and terminal:// URLs."
    else
      print_warning "xdg-mime not found. Skipping MIME type registration."
    fi
    
    print_success "Warp terminal has been set as the default terminal with right-click integration."
    print_status "Note: You may need to log out and log back in for all changes to take effect."
  else
    print_warning "Warp terminal not found. Skipping Warp configuration."
    print_status "To install Warp, visit: https://www.warp.dev/"
  fi
else
  print_status "Not running on Linux. Skipping Warp terminal configuration."
fi

print_success "Setup complete! Your dotfiles are now being tracked in a Git repository."
echo ""
echo "You can use '${GIT_ALIAS}' just like you would use 'git' to manage your dotfiles."
echo "For example: '${GIT_ALIAS} status', '${GIT_ALIAS} add', '${GIT_ALIAS} commit', etc."

####
