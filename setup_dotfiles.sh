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
print_success "Setup complete! Your dotfiles are now being tracked in a Git repository."
echo ""
echo "You can use '${GIT_ALIAS}' just like you would use 'git' to manage your dotfiles."
echo "For example: '${GIT_ALIAS} status', '${GIT_ALIAS} add', '${GIT_ALIAS} commit', etc."

