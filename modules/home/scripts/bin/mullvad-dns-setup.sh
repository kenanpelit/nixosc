#!/usr/bin/env bash

# =================================================================
# Mullvad DNS Installation and Configuration Script
# =================================================================
# Description:
# This script automates the installation and configuration of Mullvad DNS
# on Arch Linux and Ubuntu systems. It sets up secure DNS resolution using
# Mullvad's DNS servers with DNS over TLS support.
#
# Features:
# - Distribution detection (Arch/Ubuntu)
# - Package dependency management
# - Secure DNS configuration with DNS over TLS
# - NetworkManager integration
# - Automatic service configuration
#
# Usage:
# sudo bash mullvad-dns-setup.sh
# =================================================================

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Detect distribution
if [ -f /etc/arch-release ]; then
  DISTRO="arch"
elif [ -f /etc/debian_version ]; then
  DISTRO="ubuntu"
else
  echo "Unsupported distribution. This script only works with Arch Linux and Ubuntu."
  exit 1
fi

# Function to check and install required packages
install_requirements() {
  local packages_to_install=()

  if [ "$DISTRO" = "arch" ]; then
    # Check systemd
    if ! pacman -Qi systemd >/dev/null 2>&1; then
      packages_to_install+=("systemd")
    fi
    # Check networkmanager
    if ! pacman -Qi networkmanager >/dev/null 2>&1; then
      packages_to_install+=("networkmanager")
    fi

    if [ ${#packages_to_install[@]} -eq 0 ]; then
      echo "All required packages are already installed."
    else
      echo "Installing missing packages: ${packages_to_install[*]}"
      pacman -Sy --noconfirm "${packages_to_install[@]}"
    fi

  elif [ "$DISTRO" = "ubuntu" ]; then
    # Check systemd
    if ! dpkg -l | grep -q "^ii.*systemd "; then
      packages_to_install+=("systemd")
    fi
    # Check network-manager
    if ! dpkg -l | grep -q "^ii.*network-manager "; then
      packages_to_install+=("network-manager")
    fi

    if [ ${#packages_to_install[@]} -eq 0 ]; then
      echo "All required packages are already installed."
    else
      echo "Installing missing packages: ${packages_to_install[*]}"
      apt-get update
      apt-get install -y "${packages_to_install[@]}"
    fi
  fi
}

# Function to create resolved.conf
create_resolved_conf() {
  cat >/etc/systemd/resolved.conf <<'EOL'
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation; either version 2.1 of the License, or (at your option)
#  any later version.
#
# Entries in this file show the compile time defaults. Local configuration
# should be created by either modifying this file (or a copy of it placed in
# /etc/ if the original file is shipped in /usr/), or by creating "drop-ins" in
# the /etc/systemd/resolved.conf.d/ directory. The latter is generally
# recommended. Defaults can be restored by simply deleting the main
# configuration file and all drop-ins located in /etc/.
#
# Use 'systemd-analyze cat-config systemd/resolved.conf' to display the full config.
#
# See resolved.conf(5) for details.

[Resolve]
# Some examples of DNS servers which may be used for DNS= and FallbackDNS=:
# Cloudflare: 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
# Google:     8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google
# Quad9:      9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
DNS=194.242.2.4#base.dns.mullvad.net
DNSSEC=no
DNSOverTLS=yes
Domains=~.
EOL
}

# Function to configure NetworkManager
configure_network_manager() {
  local connection_name=$(nmcli -t -f NAME connection show --active | head -n1)
  if [ -n "$connection_name" ]; then
    echo "Configuring active connection: $connection_name"
    nmcli connection modify "$connection_name" ipv4.dns "" ipv6.dns ""
    nmcli connection modify "$connection_name" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes
    nmcli connection down "$connection_name"
    nmcli connection up "$connection_name"
  else
    echo "No active connection found"
    exit 1
  fi
}

# Main installation process
echo "Starting Mullvad DNS installation..."

# Install requirements
echo "Checking and installing required packages..."
install_requirements

# Enable systemd-resolved
echo "Enabling systemd-resolved..."
systemctl enable systemd-resolved
systemctl start systemd-resolved

# Create resolved.conf
echo "Creating resolved.conf..."
create_resolved_conf

# Create symbolic link
echo "Creating symbolic link for resolv.conf..."
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Configure NetworkManager
echo "Configuring NetworkManager..."
configure_network_manager

# Restart services
echo "Restarting services..."
systemctl restart systemd-resolved
systemctl restart NetworkManager

# Verify installation
echo "Verifying DNS settings..."
resolvectl status

echo "Installation complete!"
echo "Please verify the setup by visiting https://mullvad.net/check"
echo "There should be no DNS leaks, and the server listed should contain 'dns' in its name"
echo "If DNS over TLS doesn't work, you can modify /etc/systemd/resolved.conf and change DNSOverTLS=opportunistic"
