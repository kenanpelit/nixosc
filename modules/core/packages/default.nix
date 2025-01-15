# modules/core/packages/default.nix
# ==============================================================================
# System-wide Package Configuration
# ==============================================================================
{ pkgs, ... }:
let
 # =============================================================================
 # Custom Python Environment
 # =============================================================================
 pythonWithLibtmux = pkgs.python3.withPackages (ps: with ps; [
   ipython
   libtmux
 ]);
in
{
 # =============================================================================
 # System Packages Configuration
 # =============================================================================
 environment.systemPackages = with pkgs; [
   # ---------------------------------------------------------------------------
   # Core System Utilities
   # ---------------------------------------------------------------------------
   home-manager      # User environment management
   catppuccin-grub  # Grub theme
   blueman          # Bluetooth management
   dconf            # GNOME configuration
   dconf-editor     # DConf GUI editor
   libnotify        # Desktop notifications
   poweralertd      # Power management
   xdg-utils        # Desktop integration
   gzip             # Compression utility
   gcc              # C compiler
   gnumake          # Build system
   coreutils        # Essential utilities
   libinput         # Input device handling
   fusuma           # Touchpad gestures
   touchegg         # Multi-touch support

   # ---------------------------------------------------------------------------
   # Terminal and Shell Tools
   # ---------------------------------------------------------------------------
   curl             # Data transfer tool
   wget             # File downloader
   tmux             # Terminal multiplexer
   man-pages        # System documentation
   socat            # Multipurpose relay

   # ---------------------------------------------------------------------------
   # Python Environment
   # ---------------------------------------------------------------------------
   pythonWithLibtmux # Custom Python with iPython and libtmux

   # ---------------------------------------------------------------------------
   # System Monitoring
   # ---------------------------------------------------------------------------
   htop             # Process viewer
   powertop         # Power consumption
   sysstat          # System statistics
   procps           # Process utilities

   # ---------------------------------------------------------------------------
   # Networking Tools
   # ---------------------------------------------------------------------------
   iptables         # Firewall management
   tcpdump          # Network analyzer
   nethogs          # Network monitor
   bind             # DNS tools
   iwd              # Wireless daemon
   impala           # Wireless TUI
   iwgtk            # Wireless GUI
   libnotify        # Desktop notifications
   gawk             # Text processing
   iw               # Wireless tools
   iftop            # Bandwidth monitor
   mtr              # Network diagnostics
   nmap             # Network scanner
   speedtest-cli    # Internet speed test
   iperf            # Network performance
   rsync            # File synchronization

   # ---------------------------------------------------------------------------
   # Security Tools
   # ---------------------------------------------------------------------------
   age              # Encryption tool
   openssl          # SSL/TLS toolkit
   sops             # Secrets management
   hblock           # Ad blocker
   gnupg            # GNU Privacy Guard
   gcr              # GNOME crypto
   gnome-keyring    # Password management
   pinentry-gnome3  # PIN entry dialog

   # ---------------------------------------------------------------------------
   # Development Tools
   # ---------------------------------------------------------------------------
   git              # Version control
   gdb              # Debugger
   nvd              # Nix version diff
   ncdu             # Disk usage analyzer
   du-dust          # Disk usage utility
   cachix           # Binary cache
   nix-output-monitor # Build monitor

   # ---------------------------------------------------------------------------
   # SSH Tools
   # ---------------------------------------------------------------------------
   assh             # SSH config manager
   openssh          # SSH client/server

   # ---------------------------------------------------------------------------
   # Virtualization
   # ---------------------------------------------------------------------------
   virt-manager     # VM manager
   virt-viewer      # VM viewer
   qemu             # Hardware emulator
   spice-gtk        # Remote display
   win-virtio       # Windows drivers
   win-spice        # Windows client
   swtpm            # TPM emulator
   podman           # Container engine

   # ---------------------------------------------------------------------------
   # Power Management
   # ---------------------------------------------------------------------------
   upower           # Power management
   acpi             # ACPI tools
   powertop         # Power monitoring

   # ---------------------------------------------------------------------------
   # Desktop Integration
   # ---------------------------------------------------------------------------
   flatpak          # App distribution
   xdg-desktop-portal # Desktop portal
   xdg-desktop-portal-gtk # GTK portal

   # ---------------------------------------------------------------------------
   # Media Tools
   # ---------------------------------------------------------------------------
   mpc-cli          # MPD client
   rmpc             # Remote MPD
   acl              # Access control

   # ---------------------------------------------------------------------------
   # Remote Access
   # ---------------------------------------------------------------------------
   tigervnc         # VNC client/server
 ];
}
