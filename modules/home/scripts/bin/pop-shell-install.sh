#!/usr/bin/env bash

# Pop Shell Installation Script for Arch Linux
# Author: Claude
# Description: This script automates the installation of Pop Shell on Arch Linux

# Color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Constants
APPS_DIR="$HOME/.apps"
SHELL_DIR="$APPS_DIR/shell"
EXTENSION_ID="pop-shell@system76.com"
EXTENSION_PATH="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID"
WAYLAND_SESSION=false

# Function to print colored status messages
print_status() {
  echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
  echo -e "${RED}[!]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_not_root() {
  if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    exit 1
  fi
}

# Function to check session type
check_session_type() {
  if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    print_warning "Wayland session detected"
    print_warning "You'll need to log out and log back in for changes to take effect"
    WAYLAND_SESSION=true
  fi
}

# Function to create or check apps directory
setup_apps_directory() {
  print_status "Setting up applications directory..."

  if [ ! -d "$APPS_DIR" ]; then
    mkdir -p "$APPS_DIR" || {
      print_error "Failed to create $APPS_DIR directory"
      exit 1
    }
    print_success "Created $APPS_DIR directory"
  else
    print_success "$APPS_DIR directory already exists"
  fi
}

# Function to install dependencies
install_dependencies() {
  print_status "Checking and installing dependencies..."

  if ! command_exists paru; then
    print_error "paru is not installed. Please install paru first"
    exit 1
  fi

  paru -S --needed --noconfirm git typescript make || {
    print_error "Failed to install dependencies"
    exit 1
  }
  print_success "Dependencies installed successfully"
}

# Function to install Pop Shell
install_pop_shell() {
  print_status "Checking Pop Shell repository..."

  if [ -d "$SHELL_DIR" ]; then
    print_status "Pop Shell repository exists, updating..."
    cd "$SHELL_DIR" || {
      print_error "Failed to enter shell directory"
      exit 1
    }
    git pull || {
      print_error "Failed to update repository"
      exit 1
    }
  else
    print_status "Cloning Pop Shell repository..."
    git clone https://github.com/pop-os/shell.git "$SHELL_DIR" || {
      print_error "Failed to clone repository"
      exit 1
    }
    cd "$SHELL_DIR" || {
      print_error "Failed to enter shell directory"
      exit 1
    }
  fi

  # Clean existing extension if it exists
  if [ -d "$EXTENSION_PATH" ]; then
    print_status "Removing existing extension..."
    rm -rf "$EXTENSION_PATH"
  fi

  # Build and install
  print_status "Building and installing Pop Shell..."
  make install || {
    print_error "Failed to build Pop Shell"
    exit 1
  }
}

# Function to enable the extension
enable_extension() {
  print_status "Enabling Pop Shell extension..."

  if command_exists gnome-extensions; then
    gnome-extensions enable "$EXTENSION_ID" || {
      print_warning "Could not enable extension via command line"
      print_warning "You may need to enable it manually in GNOME Extensions"
    }
  fi

  print_success "Pop Shell installation completed"
}

# Function to configure Pop Shell
configure_pop_shell() {
  print_status "Configuring Pop Shell..."

  # Wait a moment for the extension to be recognized
  sleep 2

  # Configure launcher shortcut (Super+Space)
  gsettings --schemadir ~/.local/share/gnome-shell/extensions/pop-shell@system76.com/schemas \
    set org.gnome.shell.extensions.pop-shell activate-launcher "['<Super>space']" || {
    print_warning "Failed to set launcher shortcut to Super+Space"
  }

  # Disable GNOME overview Super key
  gsettings set org.gnome.mutter overlay-key '' || {
    print_warning "Failed to disable GNOME overview Super key"
  }

  print_success "Pop Shell configured successfully"
}

# Function to provide post-installation instructions
post_install_instructions() {
  echo
  echo "========================================="
  print_success "Installation completed!"
  echo "========================================="
  echo
  if [ "$WAYLAND_SESSION" = true ]; then
    print_warning "Since you're running Wayland, you need to:"
    echo "1. Log out and log back in"
    echo "2. Enable the extension in GNOME Extensions app or via Extensions Manager"
  else
    print_status "To complete installation, either:"
    echo "1. Press Alt+F2, type 'r', and press Enter"
    echo "   OR"
    echo "2. Log out and log back in"
  fi
  echo
  print_status "If the extension isn't working:"
  echo "1. Open Extensions app or Extensions Manager"
  echo "2. Make sure Pop Shell is enabled"
  echo "3. If issues persist, log out and log back in"
  echo "========================================="
}

# Main script execution
main() {
  clear
  echo "========================================="
  echo "     Pop Shell Installation Script"
  echo "========================================="
  echo

  # Check if not running as root
  check_not_root

  # Check session type
  check_session_type

  # Setup ~/.apps directory
  setup_apps_directory

  # Install dependencies
  install_dependencies

  # Install Pop Shell
  install_pop_shell

  # Enable extension
  enable_extension

  # Configure Pop Shell
  configure_pop_shell

  # Show post-installation instructions
  post_install_instructions
}

# Run main function
main
