# modules/nixos/packages/default.nix
# ==============================================================================
# NixOS system package sets and overlays shared across hosts.
# Keep baseline packages and pinned sources defined centrally here.
# Add/remove system packages in this module for consistency.
# ==============================================================================

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # -- Core Utilities --------------------------------------------------------
    coreutils                    # Basic tools (ls, cp, mv, rm)
    procps                       # Process monitoring (ps, top, kill)
    sysstat                      # Performance monitoring (sar, iostat)
    pv                           # Monitor the progress of data through a pipe
    file                         # File type identifier
    acl                          # Access Control Lists support
    lsb-release                  # Distro information
    man-pages                    # System manual pages
    gzip                         # Compression tool
    gnutar                       # Archive tool

    # -- Build Infrastructure --------------------------------------------------
    gcc                          # GNU Compiler Collection
    gnumake                      # Build automation tool
    nodejs                       # JavaScript runtime (often needed for tooling)

    # -- Core Libraries --------------------------------------------------------
    libdrm                       # Direct Rendering Manager (GPU)
    libinput                     # Input device handling
    libinput-gestures            # Gesture mapper for libinput
    libnotify                    # Desktop notifications
    openssl                      # Cryptography library

    # -- System Management -----------------------------------------------------
    home-manager                 # User environment manager
    fwupd                        # Firmware update daemon
    perl                         # Scripting language
    perlPackages.FilePath        # Perl file path module
    dconf                        # GNOME configuration backend
    dconf-editor                 # GUI editor for dconf (TODO: Move to home)

    # -- Security & Secrets ----------------------------------------------------
    sops                         # Secrets management (Mozilla)
    gnupg                        # GPG encryption tool
    gcr                          # GNOME crypto services
    gnome-keyring                # Password and secret manager
    pinentry-gnome3              # Graphical PIN entry for GPG
    iptables                     # Firewall administration
    nftables                     # Modern packet filtering framework
    conntrack-tools              # Connection tracking userspace tools
    hblock                       # Ad-blocking via hosts file

    # -- Network ---------------------------------------------------------------
    networkmanagerapplet         # NetworkManager tray icon (TODO: Move to home)
    iwd                          # Modern wireless daemon
    iw                           # Wireless configuration tool
    bind                         # DNS tools (dig, nslookup)
    openssh                      # SSH client and server
    autossh                      # Auto-restarting SSH
    impala                       # Network utility (if available/needed)
    socat                        # Multipurpose relay (SOcket CAT)
    rsync                        # File synchronization tool

    # -- Virtualization --------------------------------------------------------
    virt-manager                 # VM management GUI
    virt-viewer                  # VM console viewer
    qemu                         # Processor emulator/virtualizer
    spice-gtk                    # SPICE client library
    virtio-win                   # VirtIO drivers for Windows guests
    win-spice                    # SPICE tools for Windows guests
    swtpm                        # TPM emulator for VMs
    podman                       # Daemonless container engine (Docker alternative)

    # -- Power & Hardware ------------------------------------------------------
    upower                       # Power management abstraction
    acpi                         # ACPI client
    powertop                     # Power consumption monitor/tuner
    poweralertd                  # Power alert daemon
    lm_sensors                   # Hardware sensors (temp, fan)
    linuxPackages.turbostat      # Intel Turbo Boost monitoring
    linuxPackages.cpupower       # CPU power management tool
    auto-cpufreq                 # Automatic CPU speed & power optimizer
    ddcutil                      # Monitor control via DDC/CI
    intel-gpu-tools              # Intel GPU tools
    smartmontools                # Disk health monitoring (S.M.A.R.T.)
    nvme-cli                     # NVMe storage management
    dmidecode                    # DMI table decoder
    usbutils                     # USB tools (lsusb)
    android-tools                # Android debugging bridge (adb/fastboot)

    # -- Desktop Integration ---------------------------------------------------
    xdg-utils                    # Desktop integration tools (xdg-open)
    xdg-desktop-portal           # Desktop integration portal
    xdg-desktop-portal-gtk       # GTK portal implementation

    # -- Services --------------------------------------------------------------
    at                           # Job scheduling
    logger                       # Syslog shell interface
  ];
}
