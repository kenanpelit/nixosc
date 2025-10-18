# modules/core/services/default.nix
# ==============================================================================
# System Services & Virtualization Configuration
# ==============================================================================
#
# Module:      modules/core/services
# Purpose:     Unified system services, virtualization, gaming, and containerization
# Author:      Kenan Pelit
# Created:     2025-09-04
# Modified:    2025-10-18
#
# Architecture:
#   Base Services → Desktop Integration → Gaming Stack → Virtualization
#
# Service Categories:
#   1. Base Services       - Core system functionality (GVFS, TRIM, D-Bus)
#   2. Desktop Integration - User experience (Bluetooth, Flatpak, thumbnailer)
#   3. Gaming Stack        - Steam, Gamescope, performance optimizations
#   4. Virtualization      - Podman (containers), Libvirt/QEMU (VMs)
#   5. Hardware Support    - Firmware updates, USB redirection, VFIO
#
# Design Principles:
#   • Single Responsibility - Each service has one clear purpose
#   • Security by Default - Minimal permissions, opt-in features
#   • Performance First - Gaming/RT optimizations where applicable
#   • Maintainability - Clear documentation, no magic configurations
#
# Module Boundaries:
#   ✓ System services configuration    (THIS MODULE)
#   ✓ Virtualization stack              (THIS MODULE)
#   ✓ Gaming stack                      (THIS MODULE)
#   ✓ Desktop integration               (THIS MODULE)
#   ✗ Firewall rules                    (security module)
#   ✗ User-specific packages            (home-manager)
#   ✗ Display server config             (display module)
#   ✗ Hardware-specific settings        (hardware module)
#
# ==============================================================================

{ lib, pkgs, inputs, username, system, ... }:

{
  # ============================================================================
  # Module Imports
  # ============================================================================
  # Import nix-flatpak for declarative Flatpak management
  # Provides: managed remotes, packages, and sandbox overrides
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # ============================================================================
  # Base System Services (Layer 1: Core Functionality)
  # ============================================================================
  services = {
    # ==========================================================================
    # File System & Storage Management
    # ==========================================================================
    
    # ---- GVFS (GNOME Virtual File System) ----
    # Provides virtual filesystem support for various protocols
    # Enables: MTP devices, SMB/CIFS shares, Google Drive, archive browsing
    # Used by: File managers (Nautilus, Thunar), GNOME apps
    gvfs.enable = true;

    # ---- SSD TRIM Scheduler ----
    # Periodic TRIM maintains SSD performance and longevity
    # Schedule: Weekly (default systemd timer)
    # Scope: All mounted SSDs with TRIM support
    # Note: Already handled by most modern filesystems (ext4, btrfs, xfs)
    fstrim.enable = true;

    # ==========================================================================
    # Desktop Integration Services (Layer 2: User Experience)
    # ==========================================================================
    
    # ---- D-Bus System Message Bus ----
    # IPC mechanism for system and session services
    # Required by: Most desktop applications, systemd integration
    dbus = {
      enable = true;
      
      # Register GNOME security/crypto services
      # Note: This only registers D-Bus services, NOT the full integration
      # For full GNOME Keyring integration, see security module PAM config
      packages = with pkgs; [
        gcr            # Certificate/key management (crypto UI components)
        gnome-keyring  # Password storage daemon (secrets service)
      ];
    };

    # ---- Bluetooth Management ----
    # Blueman provides system tray integration for Bluetooth
    # Frontend: Graphical applet with device pairing/management
    # Backend: BlueZ daemon (enabled automatically)
    # Usage: Click tray icon to pair/connect devices
    blueman.enable = true;

    # ---- Touch Gesture Support ----
    # Touchegg enables multi-touch gestures on touchpads/touchscreens
    # Examples: Three-finger swipe (workspace switching), pinch-to-zoom
    # Note: Disabled by default (opt-in for touch-enabled devices)
    touchegg.enable = false;

    # ---- File Thumbnail Generator ----
    # Tumbler generates thumbnails for file managers
    # Supports: Images, videos, PDFs, office documents
    # Cache: ~/.cache/thumbnails/
    tumbler.enable = true;

    # ==========================================================================
    # Hardware & Firmware Management
    # ==========================================================================
    
    # ---- Firmware Update Service ----
    # LVFS (Linux Vendor Firmware Service) integration
    # Updates: UEFI/BIOS, device firmware (SSDs, peripherals)
    # Usage: fwupdmgr refresh && fwupdmgr get-updates
    # GUI: GNOME Software or KDE Discover integration available
    fwupd.enable = true;

    # ---- SPICE Guest Agent ----
    # Enables guest-host communication for SPICE protocol
    # Features: Clipboard sharing, display resolution sync, file transfer
    # Note: Only needed on VM guests, not hosts (disabled by default)
    spice-vdagentd.enable = lib.mkDefault false;

    # ==========================================================================
    # Printing Services (Disabled by Default)
    # ==========================================================================
    # CUPS (Common Unix Printing System) and Avahi for printer discovery
    # Enable when needed: services.printing.enable = true;
    
    printing.enable = false;  # CUPS printing daemon
    
    # Avahi provides mDNS/DNS-SD for network printer discovery
    avahi = {
      enable   = false;       # Multicast DNS daemon
      nssmdns4 = false;       # NSS module for .local domain resolution
    };

    # ==========================================================================
    # Flatpak Configuration (Layer 3: Application Sandboxing)
    # ==========================================================================
    # Declarative Flatpak management via nix-flatpak module
    # Philosophy: Wayland-first with X11 fallback for compatibility
    
    flatpak = {
      enable = true;

      # ---- Remote Repositories ----
      # Flathub is the primary Flatpak repository
      # Contains: 2000+ applications (browsers, IDEs, games, media tools)
      remotes = [{
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }];

      # ---- Pre-installed Applications ----
      # System-wide Flatpak apps (available to all users)
      # Note: User-specific apps should be in home-manager config
      packages = [
        "com.github.tchx84.Flatseal"   # Flatpak permissions manager (essential)
        "io.github.everestapi.Olympus" # Celeste game mod manager
      ];

      # ---- Sandbox Configuration ----
      # Global overrides for all Flatpak applications
      # Security vs Compatibility tradeoff
      overrides = {
        global = {
          Context = {
            # Enable Wayland socket (native protocol, better performance/security)
            sockets = [ "wayland" ];
            
            # X11 Compatibility Note:
            # Some apps still require X11 (legacy toolkits, games, proprietary software)
            # To completely disable X11 (breaks compatibility), uncomment:
            # "!sockets" = [ "x11" "fallback-x11" ];
            
            # Current behavior: Wayland-first with X11 fallback
            # Apps will use Wayland if supported, fall back to X11 if not
          };
        };
      };
    };
  };

  # ---- Flatpak Auto-Install Service ----
  # Disable automatic installation on system activation
  # Reason: Prefer manual control via `flatpak update` or nix-flatpak commands
  # Benefits: Faster rebuilds, explicit update control, no surprises
  systemd.services.flatpak-managed-install.enable = false;

  # ============================================================================
  # Core System Programs (Layer 4: Essential Tooling)
  # ============================================================================
  programs = {
    # ==========================================================================
    # Gaming Stack Configuration
    # ==========================================================================
    # Steam + Gamescope for high-performance gaming on Linux
    # Optimizations: Real-time scheduling, VRR, low-latency rendering
    
    # ---- Steam Client ----
    # Valve's gaming platform with Proton compatibility layer
    # Proton: Windows game compatibility via Wine + DXVK
    # Requirements: 32-bit graphics drivers MUST be enabled elsewhere:
    #   hardware.graphics.enable = true;
    #   hardware.graphics.enable32Bit = true;  # Critical for Steam!
    steam = {
      enable = true;
      
      # ---- Network Features ----
      remotePlay.openFirewall      = true;   # UDP 27031-27036, TCP 27036-27037
      dedicatedServer.openFirewall = false;  # Server ports (disable for clients)
      
      # ---- Gamescope Session ----
      # Dedicated Wayland compositor for gaming
      # Benefits: Lower latency, better frame pacing, VRR support
      # Usage: Select "Gamescope Session" from display manager
      gamescopeSession.enable = true;
      
      # ---- Proton Compatibility ----
      # Proton-GE (GloriousEggroll) provides newer Wine/DXVK versions
      # Fixes: Game-specific patches, codec support, performance improvements
      # Install path: ~/.local/share/Steam/compatibilitytools.d/
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    # ---- Gamescope Compositor ----
    # Microcompositor optimized for gaming workloads
    # Features: VRR, HDR (future), frame limiting, upscaling (FSR)
    gamescope = {
      enable = true;
      
      # ---- Real-time Scheduling ----
      # Allow Gamescope to use RT priorities without root
      # Effect: Reduced input latency, smoother frame times
      # Security: Requires CAP_SYS_NICE capability
      capSysNice = true;
      
      # ---- Performance Arguments ----
      args = [
        "--rt"                # Real-time scheduling (needs capSysNice)
        "--expose-wayland"    # Expose Wayland socket to games
        "--adaptive-sync"     # Enable VRR/FreeSync/G-Sync
        "--immediate-flips"   # Reduce latency by skipping frame queue
        "--force-grab-cursor" # Better mouse capture for FPS games
      ];
      
      # Additional useful args (add as needed):
      # "--hdr-enabled"           # HDR support (experimental)
      # "--fsr-upscaling"         # AMD FidelityFX Super Resolution
      # "--framerate-limit 144"   # Cap framerate
      # "--fullscreen"            # Start in fullscreen
    };

    # ==========================================================================
    # Desktop Core Programs
    # ==========================================================================
    
    # ---- DConf Settings Database ----
    # Key-value store for GNOME and GTK application settings
    # Scope: System-wide defaults, user preferences
    # CLI: dconf read/write /org/gnome/...
    dconf.enable = true;

    # ---- Z Shell ----
    # System-wide zsh configuration
    # Note: User-specific configs (oh-my-zsh, plugins) live in home-manager
    # This only enables zsh system-wide and adds it to /etc/shells
    zsh.enable = true;

    # ---- GNOME Keyring Integration ----
    # Uncomment for full PAM/display-manager integration
    # Provides: Automatic keyring unlock on login, SSH key management
    # Note: Already configured in security module PAM settings
    # programs.gnome-keyring.enable = true;

    # ==========================================================================
    # Foreign Binary Support (nix-ld)
    # ==========================================================================
    # Allows running non-Nix binaries (AppImages, precompiled binaries)
    # Mechanism: Dynamic linker wrapper that resolves shared libraries
    # Use cases: Proprietary software, third-party installers
    
    nix-ld = {
      enable = true;
      
      # ---- Shared Library Path ----
      # Add libraries here if foreign binaries complain about missing .so files
      # Common needs: C++ stdlib, compression, graphics libraries
      libraries = with pkgs; [
        # stdenv.cc.cc.lib  # GCC C++ standard library (libstdc++)
        # zlib              # Compression library
        # xorg.libX11       # X11 client library
        # mesa              # OpenGL implementation
        # vulkan-loader     # Vulkan ICD loader
      ];
      
      # Troubleshooting:
      # 1. Run binary with: NIX_LD_DEBUG=1 ./app
      # 2. Check missing libs: ldd ./app
      # 3. Add missing libs to libraries list above
    };
  };

  # ============================================================================
  # System Packages (Layer 5: Host-side Utilities)
  # ============================================================================
  # Convenience tools for virtualization and system management
  # Note: User applications belong in home-manager, not here
  
  environment.systemPackages = with pkgs; [
    # ---- Virtualization Clients ----
    spice-gtk       # SPICE client library (GTK widgets)
    spice-protocol  # SPICE protocol definitions
    virt-viewer     # Virtual machine display client (remote-viewer command)
    
    # Usage Examples:
    # virt-viewer qemu:///system/myvm       # Connect to local VM
    # remote-viewer spice://192.168.1.100   # Connect to remote SPICE
    # virt-manager                          # Graphical VM manager (add if needed)
  ];

  # ============================================================================
  # System Activation Scripts (Optional Diagnostics)
  # ============================================================================
  # Example: Log service versions after system activation
  # Useful for: Debugging, version tracking, audit logs
  
  # system.activationScripts.serviceVersions = ''
  #   echo "[nixos-switch] $(date -Is) Podman: $(${pkgs.podman}/bin/podman --version)"
  #   echo "[nixos-switch] $(date -Is) QEMU: $(${pkgs.qemu}/bin/qemu-system-x86_64 --version | head -1)"
  # '';

  # ============================================================================
  # Virtualization Stack (Layer 6: Containers & VMs)
  # ============================================================================
  virtualisation = {
    # ==========================================================================
    # Podman - Docker-compatible Container Runtime
    # ==========================================================================
    # Rootless container runtime (no root daemon required)
    # Compatible with Docker CLI and docker-compose
    # Architecture: OCI runtime (runc/crun) + CNI networking + Buildah/Skopeo
    
    podman = {
      enable = true;
      
      # ---- Docker Compatibility Layer ----
      # Provides /run/podman/podman.sock compatible with Docker socket
      # Allows: docker CLI, docker-compose, IDE integrations (VS Code, PyCharm)
      # Note: Use `podman` command natively when possible (better features)
      dockerCompat = true;
      
      # ---- DNS Resolution in Containers ----
      # Enable DNS for container networking (required for name resolution)
      # Provides: Container-to-container DNS, internet access from containers
      defaultNetwork.settings.dns_enabled = true;

      # ---- Automatic Cleanup ----
      # Periodic pruning prevents disk space exhaustion
      # Removes: Stopped containers, unused images, dangling volumes
      autoPrune = {
        enable = true;
        flags  = [ "--all" ];  # Remove all unused images (not just dangling)
        dates  = "weekly";     # Systemd timer: every Monday at midnight
      };
      
      # Manual pruning:
      # podman system prune -a --volumes  # Remove everything unused
      # podman image prune                 # Remove unused images only

      # ---- Runtime Dependencies ----
      # Essential tools for container operation
      extraPackages = with pkgs; [
        runc         # OCI runtime (low-level container execution)
        conmon       # Container monitor (PID 1 supervisor, logging)
        skopeo       # Image operations (copy, inspect, delete, sign)
        slirp4netns  # User-mode networking (rootless containers)
      ];
    };

    # ---- Container Registry Configuration ----
    # Configures /etc/containers/registries.conf
    # CRITICAL: Do NOT also write this file via environment.etc (conflict!)
    containers.registries = {
      # Search order for unqualified image names
      # Example: "podman run alpine" searches docker.io then quay.io
      search = [ "docker.io" "quay.io" ];
      
      # Allow insecure registries (HTTP, self-signed certs)
      # Warning: Only use for trusted private registries
      insecure = [ 
        # "registry.internal.company.com"
      ];
      
      # Block specific registries (security policy)
      block = [ 
        # "malicious-registry.com"
      ];
    };

    # ==========================================================================
    # Libvirt / QEMU - Full Virtualization Stack
    # ==========================================================================
    # KVM-based virtual machines with hardware acceleration
    # Supports: x86_64, ARM64, TPM, UEFI, GPU passthrough (VFIO)
    
    libvirtd = {
      enable = true;
      
      # ---- TPM (Trusted Platform Module) Support ----
      # Software TPM emulation for VMs (required for Windows 11)
      # Provides: Secure Boot, BitLocker, Credential Guard
      # Backend: swtpm (software TPM 2.0 implementation)
      qemu.swtpm.enable = true;
      
      # ---- UEFI Firmware ----
      # OVMF (Open Virtual Machine Firmware) for UEFI boot
      # Note: OVMF package must be available in system packages:
      #   environment.systemPackages = [ pkgs.OVMF ];
      # Usage: Select "UEFI" in virt-manager when creating VM
      
      # Additional libvirt options (uncomment as needed):
      # qemu.ovmf.enable = true;           # Enable OVMF support explicitly
      # qemu.runAsRoot = false;            # Run QEMU as libvirt-qemu user
      # onBoot = "ignore";                 # Don't autostart VMs on boot
      # onShutdown = "shutdown";           # Graceful shutdown VMs on host shutdown
    };

    # ---- SPICE USB Redirection ----
    # Enables USB device passthrough to VMs via SPICE protocol
    # Features: Hot-plug USB devices, automatic permission handling
    # Security: Uses polkit for authorization, no raw USB access
    # GUI: Available in virt-viewer/virt-manager "Redirect USB" menu
    spiceUSBRedirection.enable = true;
  };

  # ============================================================================
  # Udev Rules for Virtualization Hardware
  # ============================================================================
  # Device permissions for KVM and VFIO (GPU passthrough)
  # Principle: Least privilege - only grant access to specific devices
  
  services.udev.extraRules = ''
    # --------------------------------------------------------------------------
    # VFIO (Virtual Function I/O) - GPU Passthrough
    # --------------------------------------------------------------------------
    # Allows libvirt to pass through PCIe devices (GPUs) to VMs
    # Usage: Bind GPU to vfio-pci driver before starting VM
    # Guide: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
    SUBSYSTEM=="vfio", GROUP="libvirtd"

    # --------------------------------------------------------------------------
    # KVM & vhost-net - Virtualization Acceleration
    # --------------------------------------------------------------------------
    # /dev/kvm: Hardware virtualization (Intel VT-x / AMD-V)
    # /dev/vhost-net: Kernel-level virtio-net acceleration (faster networking)
    # Group 'kvm': Users in this group can create/manage VMs
    KERNEL=="kvm", GROUP="kvm", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="vhost-net", GROUP="kvm", MODE="0664"

    # --------------------------------------------------------------------------
    # USB Device Passthrough (Example)
    # --------------------------------------------------------------------------
    # Grant specific USB devices to libvirtd for passthrough
    # Security: Avoid blanket USB access (overly broad)
    # Find IDs: lsusb → Bus 001 Device 005: ID 046d:c534 Logitech, Inc.
    
    # Example: Logitech mouse passthrough
    # SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c534", GROUP="libvirtd"
    
    # Example: Yubikey passthrough
    # SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", GROUP="libvirtd"
  '';

  # ============================================================================
  # Security Wrappers (Handled by Modules)
  # ============================================================================
  # Note: SPICE USB wrapper is already configured by spiceUSBRedirection module
  # No manual wrapper configuration needed here
  #
  # What it does:
  # - Installs spice-client-glib-usb-acl-helper with proper capabilities
  # - Configures polkit rules for USB authorization
  # - Allows USB redirection without root privileges
  #
  # Manual configuration (NOT needed, already done by module):
  # security.wrappers.spice-client-glib-usb-acl-helper = {
  #   source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
  #   capabilities = "cap_fowner+ep";
  # };
}

# ==============================================================================
# Best Practices & Usage Guidelines
# ==============================================================================
#
# 1. Gaming Stack:
#    - Verify 32-bit drivers: glxinfo32 | grep "OpenGL renderer"
#    - Test Proton: Steam → Settings → Steam Play → Enable for all titles
#    - Launch in Gamescope: gamescope -W 2560 -H 1440 -r 144 -- %command%
#    - Check performance: mangohud steam (add to launch options)
#
# 2. Flatpak Management:
#    - Search apps: flatpak search <name>
#    - Install user app: flatpak install --user flathub org.app.name
#    - Update all: flatpak update
#    - Manage permissions: flatseal (GUI) or flatpak override (CLI)
#    - Sandbox info: flatpak info --show-permissions org.app.name
#
# 3. Container Usage (Podman):
#    - Run rootless: podman run --rm -it alpine
#    - Docker compat: alias docker=podman (or use dockerCompat)
#    - Compose: podman-compose up -d
#    - System info: podman system info
#    - Network debug: podman network ls && podman network inspect podman
#
# 4. Virtual Machines (Libvirt):
#    - GUI manager: virt-manager
#    - List VMs: virsh list --all
#    - Start VM: virsh start vmname
#    - Connect console: virsh console vmname
#    - TPM check: virsh dumpxml vmname | grep -i tpm
#    - GPU passthrough: https://wiki.archlinux.org/title/PCI_passthrough
#
# 5. SPICE Client:
#    - Connect to VM: virt-viewer qemu:///system/vmname
#    - Remote SPICE: remote-viewer spice://192.168.1.100:5900
#    - USB redirect: View → File → USB device selection
#    - Clipboard: Automatically shared if spice-vdagent running in guest
#
# 6. Firmware Updates:
#    - Check updates: fwupdmgr refresh && fwupdmgr get-updates
#    - Install: fwupdmgr update
#    - Device list: fwupdmgr get-devices
#    - Rollback: fwupdmgr get-history → fwupdmgr rollback <device>
#
# ==============================================================================
# Troubleshooting Guide
# ==============================================================================
#
# Flatpak apps won't start:
#   flatpak run --verbose org.app.name  # Check error messages
#   flatpak repair --user               # Fix broken refs
#   rm -rf ~/.var/app/org.app.name      # Reset app data (nuclear option)
#
# Steam/Proton issues:
#   Check 32-bit drivers: nix-shell -p glxinfo --run "glxinfo32 | grep OpenGL"
#   Enable debug logs: PROTON_LOG=1 %command% in launch options
#   Force Proton version: Right-click game → Properties → Compatibility
#   Proton-GE not showing: Check ~/.local/share/Steam/compatibilitytools.d/
#
# Podman networking broken:
#   podman network ls                    # List networks
#   podman network inspect podman        # Check DNS settings
#   sudo systemctl restart podman        # Restart networking
#   Check firewall: sudo iptables -L -v -n | grep CNI
#
# VM won't start (libvirt):
#   virsh start vmname --console         # Start with console output
#   journalctl -xeu libvirtd             # Check libvirt logs
#   Check permissions: groups | grep libvirtd
#   Verify KVM: ls -l /dev/kvm (should be 0664)
#
# USB redirection not working:
#   Check polkit: polkit-1 --version
#   Verify spice-vdagent: systemctl --user status spice-vdagentd
#   Check USB ownership: lsusb && ls -l /dev/bus/usb/*/*
#   Manual authorization: spice-client-glib-usb-acl-helper --help
#
# VFIO GPU passthrough issues:
#   Check IOMMU: dmesg | grep -i iommu
#   Verify groups: find /sys/kernel/iommu_groups/ -type l
#   Bind GPU: echo "0000:01:00.0" > /sys/bus/pci/drivers/vfio-pci/bind
#   Reset GPU: echo 1 > /sys/bus/pci/devices/0000:01:00.0/reset
#
# ==============================================================================
# Security Considerations
# ==============================================================================
#
# 1. Flatpak Sandboxing:
#    - Review permissions before installing: flatseal or flatpak info
#    - Minimize socket access (prefer Wayland over X11)
#    - Avoid --filesystem=host (grants full filesystem access)
#
# 2. Container Security:
#    - Run rootless when possible: podman run (not sudo podman)
#    - Scan images: podman pull && podman scan <image>
#    - Use official images: docker.io/library/alpine (not random repos)
#    - Keep images updated: podman auto-update (with systemd services)
#
# 3. VM Isolation:
#    - Don't share host filesystem unless necessary
#    - Use virtio-scsi for disk (better isolation than virtio-blk)
#    - Enable SELinux/AppArmor for VMs in production
#    - Audit VM configs: virsh dumpxml vmname | grep security
#
# 4. USB Redirection:
#    - Only redirect trusted devices (malicious USB = BadUSB)
#    - Use polkit to restrict which users can redirect USB
#    - Monitor: journalctl -f | grep usb (watch for unexpected devices)
#
# ==============================================================================

