# modules/core/security/default.nix
# ==============================================================================
# Security Configuration
# ==============================================================================
# This configuration file manages all security-related settings including:
# - Core system security settings
# - GNOME Keyring integration
# - GnuPG configuration
# - Host blocking (hBlock)
#
# Key components:
# - PAM and sudo configuration
# - GNOME Keyring credential storage
# - GnuPG agent and SSH support
# - System-wide ad and malware domain blocking
#
# Author: Kenan Pelit
# ==============================================================================

{ config, lib, pkgs, ... }:
let
 cfg = config.services.hblock;
 updateScript = pkgs.writeShellScript "hblock-update" ''
   # Update ~/.config/hblock/hosts file for each user
   for USER_HOME in /home/*; do
     if [ -d "$USER_HOME" ]; then
       USER=$(basename "$USER_HOME")
       CONFIG_DIR="$USER_HOME/.config/hblock"
       HOSTS_FILE="$CONFIG_DIR/hosts"
       # Create config directory if it doesn't exist
       mkdir -p "$CONFIG_DIR"
       # Add base entries
       echo "# Base entries" > "$HOSTS_FILE"
       echo "localhost 127.0.0.1" >> "$HOSTS_FILE"
       echo "hay 127.0.0.2" >> "$HOSTS_FILE"
       # Add hBlock entries
       echo "# hBlock entries (Updated: $(date))" >> "$HOSTS_FILE"
       ${pkgs.hblock}/bin/hblock -O - | while read DOMAIN; do
         if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(.+)$ ]]; then
           echo "''${BASH_REMATCH[1]} ''${BASH_REMATCH[1]}" >> "$HOSTS_FILE"
         fi
       done
       # Set file ownership
       chown $USER:users "$HOSTS_FILE"
       chmod 644 "$HOSTS_FILE"
     fi
   done
 '';
in
{
 # =============================================================================
 # Core Security Settings
 # =============================================================================
 security = {
   rtkit.enable = true;     # Realtime Kit for audio
   sudo.enable = true;      # Superuser permissions
   
   # PAM Service Configuration
   pam.services = {
     # Screen Locker Integration
     swaylock.enableGnomeKeyring = true;
     hyprlock.enableGnomeKeyring = true;
     login.enableGnomeKeyring = true;
   };
 };

 # =============================================================================
 # GNOME Keyring Configuration
 # =============================================================================
 services.gnome = {
   gnome-keyring.enable = true;  # Secure credential storage
 };

 # =============================================================================
 # GnuPG Configuration
 # =============================================================================
 programs.gnupg = {
   agent = {
     enable = true;
     pinentryPackage = pkgs.pinentry-gnome3;  # GNOME PIN entry interface
     enableSSHSupport = true;                 # SSH key management
   };
 };

 # =============================================================================
 # DBus Integration
 # =============================================================================
 services.dbus = {
   enable = true;
   packages = [ pkgs.gcr ];  # GNOME cryptography services
 };

 # =============================================================================
 # Host Blocking Configuration (hBlock)
 # =============================================================================
 options.services.hblock = {
   enable = lib.mkEnableOption "hBlock service";
 };

 config = lib.mkIf cfg.enable {
   systemd.services.hblock = {
     description = "hBlock - Update user hosts files";
     after = [ "network-online.target" ];
     wants = [ "network-online.target" ];
     serviceConfig = {
       Type = "oneshot";
       ExecStart = updateScript;
       RemainAfterExit = true;
     };
   };

   systemd.timers.hblock = {
     wantedBy = [ "timers.target" ];
     timerConfig = {
       OnCalendar = "daily";
       RandomizedDelaySec = 3600;
       Persistent = true;
     };
   };
 };

 # =============================================================================
 # Environment Configuration
 # =============================================================================
 environment = {
   # Session Variables
   sessionVariables = {
     GCR_PKCS11_MODULE = "${pkgs.gcr}/lib/pkcs11/gcr-pkcs11.so";
     GCR_PROVIDER_PRIORITY = "1";
   };

   # Default Shell Configuration
   etc."skel/.bashrc".text = lib.mkAfter ''
     export HOSTALIASES="$HOME/.config/hblock/hosts"
   '';

   # Required Packages
   systemPackages = with pkgs; [
     hblock
     gcr
   ];
 };
}
