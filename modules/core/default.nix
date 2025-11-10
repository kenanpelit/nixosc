# modules/core/default.nix
# ==============================================================================
# Core System Configuration - Module Orchestration
# ==============================================================================
#
# Module:      modules/core
# Purpose:     Centralized module import orchestration with dependency ordering
# Author:      Kenan Pelit
# Created:     2025-09-03
# Modified:    2025-10-18
#
# Architecture:
#   Foundation → Build Tools → Display → Network → Security → Services
#        ↓            ↓           ↓         ↓          ↓          ↓
#   Users/System  Nix/Pkgs  Wayland/XDG  NM/VPN  Firewall/Auth  Apps/Virt
#
# Module Dependency Graph:
#   ┌─────────────────────────────────────────────────────────────────┐
#   │                    CORE SYSTEM MODULES                          │
#   └─────────────────────────────────────────────────────────────────┘
#            │
#            ├─► 1. FOUNDATION LAYER (account, system)
#            │   ├─► account   : Users, UIDs, groups, home-manager
#            │   └─► system     : Boot, hardware, thermal, power
#            │
#            ├─► 2. BUILD LAYER (nix, packages)
#            │   ├─► nix        : Nix daemon, GC, cache, overlays
#            │   └─► packages   : System packages, libraries
#            │
#            ├─► 3. DESKTOP LAYER (display)
#            │   └─► display    : Wayland, Hyprland, GDM, fonts, XDG
#            │
#            ├─► 4. NETWORK LAYER (networking)
#            │   └─► networking : NetworkManager, VPN, DNS, TCP tuning
#            │
#            ├─► 5. SECURITY LAYER (security, sops)
#            │   ├─► security   : Firewall, PAM, AppArmor, SSH
#            │   └─► sops       : Secrets management (age, SOPS)
#            │
#            └─► 6. SERVICES LAYER (services)
#                └─► services   : Flatpak, containers, virtualization, gaming
#
# Design Principles - SINGLE AUTHORITY (Critical):
#   ┌────────────────────────────────────────────────────────────────┐
#   │ Each concern has EXACTLY ONE authoritative module              │
#   │ Never duplicate configuration across modules                   │
#   │ Cross-module dependencies declared explicitly                  │
#   └────────────────────────────────────────────────────────────────┘
#
#   Configuration Domain              │ Authoritative Module
#   ──────────────────────────────────┼──────────────────────────────
#   Firewall rules & open ports       │ modules/core/security
#   TCP/IP kernel tuning (sysctl)     │ modules/core/networking
#   Users, UIDs, groups               │ modules/core/account
#   Home-manager configuration        │ modules/core/account
#   Boot loader & kernel              │ modules/core/system
#   Display server & desktop          │ modules/core/display
#   VPN & network management          │ modules/core/networking
#   Containers & virtualization       │ modules/core/services
#   Gaming stack (Steam)              │ modules/core/services
#   Flatpak applications              │ modules/core/services
#   Secrets (passwords, keys)         │ modules/core/sops
#   System packages                   │ modules/core/packages
#   Nix daemon & cache                │ modules/core/nix
#
# CRITICAL: Never Configure These Elsewhere:
#   ✗ DON'T open firewall ports in networking module
#   ✗ DON'T configure TCP sysctl in security module
#   ✗ DON'T define users in system module
#   ✗ DON'T configure Flatpak in display module
#   ✗ DON'T setup VPN in security module
#
# Module Boundaries (What Goes Where):
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/account                                            │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ User definitions (users.users.<name>)                        │
#   │ ✓ UIDs and GIDs                                                 │
#   │ ✓ User groups and permissions                                   │
#   │ ✓ Home-manager integration                                      │
#   │ ✓ User shell configuration                                      │
#   │ ✗ D-Bus services (→ services module)                           │
#   │ ✗ GNOME Keyring daemon (→ services/display module)             │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/system                                             │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ Boot loader (systemd-boot, GRUB)                             │
#   │ ✓ Kernel parameters and modules                                │
#   │ ✓ Hardware configuration                                        │
#   │ ✓ Thermal management (thermald)                                │
#   │ ✓ Power management (TLP, auto-cpufreq)                         │
#   │ ✓ System locale and timezone                                   │
#   │ ✗ Display drivers (→ hardware module)                          │
#   │ ✗ Network configuration (→ networking module)                  │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/nix                                                │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ Nix daemon settings                                           │
#   │ ✓ Garbage collection (auto-GC)                                 │
#   │ ✓ Binary cache configuration                                   │
#   │ ✓ Flakes and experimental features                             │
#   │ ✓ NUR (Nix User Repository) overlay                            │
#   │ ✓ NH (Nix Helper) tool                                         │
#   │ ✗ System packages (→ packages module)                          │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/packages                                           │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ System-wide packages (environment.systemPackages)            │
#   │ ✓ Essential CLI tools                                           │
#   │ ✓ Development libraries                                         │
#   │ ✓ System utilities                                              │
#   │ ✗ User-specific packages (→ home-manager in account)           │
#   │ ✗ Desktop applications (→ home-manager)                        │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/display                                            │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ Wayland compositors (Hyprland)                               │
#   │ ✓ Display manager (GDM)                                        │
#   │ ✓ Desktop environments (GNOME, COSMIC)                         │
#   │ ✓ XDG desktop portals                                          │
#   │ ✓ Font configuration                                            │
#   │ ✓ PipeWire audio stack                                         │
#   │ ✗ GPU drivers (→ hardware module)                              │
#   │ ✗ Window manager config (→ home-manager)                       │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/networking                                         │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ NetworkManager configuration                                 │
#   │ ✓ systemd-resolved (DNS)                                       │
#   │ ✓ VPN clients (Mullvad, WireGuard, OpenVPN)                   │
#   │ ✓ TCP/IP kernel tuning (sysctl)                                │
#   │ ✓ Network interface configuration                              │
#   │ ✗ Firewall rules (→ security module)                           │
#   │ ✗ SSH daemon (→ security module)                               │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/security                                           │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ Firewall configuration (SINGLE AUTHORITY)                    │
#   │ ✓ Open ports (TCP/UDP)                                         │
#   │ ✓ PAM configuration                                             │
#   │ ✓ Polkit rules                                                  │
#   │ ✓ AppArmor profiles                                             │
#   │ ✓ Audit logging                                                 │
#   │ ✓ SSH client configuration                                      │
#   │ ✓ DNS ad-blocking (hBlock)                                     │
#   │ ✗ SSH daemon (technically here, delegated to networking)       │
#   │ ✗ VPN configuration (→ networking module)                      │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/sops                                               │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ SOPS configuration                                            │
#   │ ✓ Age encryption keys                                           │
#   │ ✓ Secret definitions                                            │
#   │ ✓ Secret file paths and permissions                            │
#   │ ✓ Service integration (restartUnits)                           │
#   │ ✗ User secrets (→ home-manager sops)                           │
#   └─────────────────────────────────────────────────────────────────┘
#
#   ┌─────────────────────────────────────────────────────────────────┐
#   │ modules/core/services                                           │
#   ├─────────────────────────────────────────────────────────────────┤
#   │ ✓ Flatpak configuration (nix-flatpak)                          │
#   │ ✓ Container runtime (Podman)                                   │
#   │ ✓ Virtualization (Libvirt/QEMU)                                │
#   │ ✓ Gaming stack (Steam, Gamescope)                              │
#   │ ✓ Core programs (dconf, zsh, nix-ld)                           │
#   │ ✓ D-Bus service registration                                   │
#   │ ✓ GVFS, TRIM, hardware services                                │
#   │ ✗ Firewall ports for services (→ security module)              │
#   │ ✗ User service configuration (→ home-manager)                  │
#   └─────────────────────────────────────────────────────────────────┘
#
# Import Order Rationale:
#   1. Foundation (account, system)
#      - Must come first: defines users, hardware, boot
#      - Other modules may reference user accounts or system config
#   
#   2. Build Tools (nix, packages)
#      - Nix daemon affects package builds
#      - Packages provide tools needed by later modules
#   
#   3. Desktop (display)
#      - Display server needed before network GUI tools
#      - Fonts and portals used by applications
#   
#   4. Network (networking)
#      - Network required for remote services
#      - VPN may be needed before firewall rules
#   
#   5. Security (security, sops)
#      - Firewall last in network stack (after VPN setup)
#      - Secrets needed by services
#   
#   6. Services (services)
#      - Applications and services last (depend on everything)
#      - Can reference users, network, security config
#
# Module Dependencies (External Inputs):
#   ┌────────────────────────────────────────────────────────────────┐
#   │ Module         │ Required Inputs                               │
#   ├────────────────┼───────────────────────────────────────────────┤
#   │ account        │ inputs, username, host                        │
#   │ display        │ inputs.hyprland                               │
#   │ services       │ inputs.nix-flatpak                            │
#   │ sops           │ inputs.sops-nix                               │
#   │ nix            │ inputs (for flake registry)                   │
#   └────────────────────────────────────────────────────────────────┘
#
#   These inputs must be passed via flake.nix:
#     specialArgs = { 
#       inherit inputs username host;
#     };
#
# Common Anti-Patterns to Avoid:
#   ✗ Defining firewall ports in multiple modules
#     → All ports go in security/default.nix
#   
#   ✗ Splitting TCP tuning between networking and system
#     → All sysctl networking in networking/default.nix
#   
#   ✗ Configuring same service in multiple modules
#     → Service configuration goes in services/default.nix
#   
#   ✗ Duplicating user definitions
#     → All users defined in account/default.nix
#   
#   ✗ Mixing system and user packages
#     → System packages in packages/default.nix
#     → User packages in home-manager (account module)
#
# Debugging Module Loading:
#   # Check which modules are loaded:
#   nix eval .#nixosConfigurations.<host>.config.imports --json
#   
#   # Check if specific option is set:
#   nix eval .#nixosConfigurations.<host>.config.networking.firewall.enable
#   
#   # Trace module evaluation:
#   nixos-rebuild build --flake .#<host> --show-trace
#   
#   # Check option definition locations:
#   nixos-option networking.firewall.enable
#
# Best Practices:
#   1. Keep this file minimal - only imports, no configuration
#   2. Maintain consistent import order (dependencies first)
#   3. Document any cross-module dependencies
#   4. Use comments to explain non-obvious ordering
#   5. Review regularly to prevent configuration drift
#   6. Never duplicate configuration across modules
#   7. Follow single authority principle strictly
#
# ==============================================================================

{ inputs, nixpkgs, self, username, host, lib, ... }:

{
  # ============================================================================
  # Module Imports (Ordered by Dependency Layer)
  # ============================================================================
  # 
  # CRITICAL: Do not reorder without understanding dependencies
  # Each layer builds upon the previous layer's configuration
  # Reordering may break module evaluation or cause conflicts
  
  imports = [
    # ==========================================================================
    # LAYER 1: FOUNDATION (Users & Hardware)
    # ==========================================================================
    # Defines the base system: who can use it and what hardware it runs on
    # Must be first - other modules may reference users or system config
    
    # ---- User Management ----
    # Defines: users.users.<name>, home-manager integration
    # Provides: User accounts, UIDs, groups, shell configuration
    # Dependencies: None (foundation layer)
    # Used by: All other modules (may reference ${username})
    ./account
    
    # ---- System Configuration ----
    # Defines: Boot, kernel, hardware, thermal, power management
    # Provides: System foundation, hardware support
    # Dependencies: None (foundation layer)
    # Used by: Hardware-specific modules (GPU drivers, etc.)
    ./system

    # ==========================================================================
    # LAYER 2: BUILD TOOLS (Package Management)
    # ==========================================================================
    # Configures how software is built and managed
    # Second priority - affects all package installations
    
    # ---- Nix Daemon & Configuration ----
    # Defines: Nix daemon settings, GC, binary caches, flakes
    # Provides: Build system, package management, overlays
    # Dependencies: None (but affects all builds)
    # Used by: All modules that install packages
    ./nix
    
    # ---- System Packages ----
    # Defines: environment.systemPackages (CLI tools, libraries)
    # Provides: Essential system-wide software
    # Dependencies: nix module (for build system)
    # Used by: Provides tools used by other modules
    ./packages

    # ==========================================================================
    # LAYER 3: DESKTOP ENVIRONMENT (Display & UI)
    # ==========================================================================
    # Sets up the graphical environment
    # Third priority - needed before network GUI tools
    
    # ---- Display Stack ----
    # Defines: Wayland/Hyprland, GDM, fonts, XDG portals, PipeWire
    # Provides: Graphical environment, audio, font rendering
    # Dependencies: inputs.hyprland (flake input)
    # Used by: GUI applications, window managers, desktop apps
    ./display

    # ==========================================================================
    # LAYER 4: NETWORK CONNECTIVITY (Network & VPN)
    # ==========================================================================
    # Establishes network connectivity
    # Fourth priority - needed before security rules
    
    # ---- Network Management ----
    # Defines: NetworkManager, systemd-resolved, VPN, TCP tuning
    # Provides: Network connectivity, DNS resolution, VPN tunnels
    # Dependencies: None (but before security module)
    # Used by: Security module (firewall applies after network up)
    ./networking
    ./sqm           # SQM/CAKE bufferbloat mitigation

    # ==========================================================================
    # LAYER 5: SECURITY & SECRETS (Protection & Authentication)
    # ==========================================================================
    # Applies security policies and manages secrets
    # Fifth priority - protects configured network and services
    
    # ---- Security Policies ----
    # Defines: Firewall (SINGLE AUTHORITY), PAM, AppArmor, SSH, audit
    # Provides: Network security, access control, system hardening
    # Dependencies: networking module (applies rules to network)
    # Used by: Protects all services and network interfaces
    ./security
    
    # ---- Secrets Management ----
    # Defines: SOPS configuration, age keys, secret definitions
    # Provides: Encrypted secrets, key management
    # Dependencies: inputs.sops-nix (flake input)
    # Used by: Services that need passwords, API keys, certificates
    ./sops

    # ==========================================================================
    # LAYER 6: SERVICES & APPLICATIONS (User-Facing Features)
    # ==========================================================================
    # Configures applications and services
    # Last priority - depends on all previous layers
    
    # ---- System Services ----
    # Defines: Flatpak, Podman/Libvirt, Steam/Gamescope, core programs
    # Provides: Application sandboxing, containers, VMs, gaming
    # Dependencies: 
    #   - inputs.nix-flatpak (flake input)
    #   - account module (for user services)
    #   - display module (for GUI apps)
    #   - security module (for firewall ports)
    # Used by: End-user applications and workflows
    ./services
  ];
  
  # ============================================================================
  # Module Loading Verification (Optional Debug)
  # ============================================================================
  # Uncomment to verify module load order during evaluation
  # Useful for debugging module conflicts or dependency issues
  
  # system.activationScripts.moduleLoadOrder = ''
  #   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  #   echo "[CORE] Module loading order:"
  #   echo "  1. account   - Users & home-manager"
  #   echo "  2. system    - Boot & hardware"
  #   echo "  3. nix       - Nix daemon & caches"
  #   echo "  4. packages  - System packages"
  #   echo "  5. display   - Wayland & desktop"
  #   echo "  6. networking- Network & VPN"
  #   echo "  7. security  - Firewall & hardening"
  #   echo "  8. sops      - Secrets management"
  #   echo "  9. services  - Applications & services"
  #   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  # '';
}

# ==============================================================================
# Usage Guidelines & Best Practices
# ==============================================================================
#
# 1. Adding a New Module:
#    ─────────────────────────────────────────────────────────────────────────
#    a) Create module file: modules/core/mymodule/default.nix
#    b) Define clear module boundaries (what it configures)
#    c) Document dependencies (what it needs from other modules)
#    d) Add import in correct dependency layer
#    e) Update module boundary documentation in this file
#    f) Test with: nixos-rebuild build --flake .#<host>
#
#    Example:
#      # modules/core/monitoring/default.nix
#      { config, pkgs, ... }: {
#        # Monitoring configuration (Prometheus, Grafana, etc.)
#        # Dependencies: networking (for ports), security (firewall)
#      }
#      
#      # Add to imports (LAYER 6 - after security):
#      ./monitoring
#
# 2. Modifying Configuration:
#    ─────────────────────────────────────────────────────────────────────────
#    a) Identify the authoritative module (use table above)
#    b) Edit ONLY that module (never duplicate config)
#    c) If config spans modules, choose primary owner
#    d) Document cross-module relationships in comments
#    e) Test thoroughly: nixos-rebuild test --flake .#<host>
#
#    Example (Wrong):
#      # DON'T do this - firewall ports split across modules
#      networking/default.nix:  allowedTCPPorts = [ 22 80 ];
#      security/default.nix:    allowedTCPPorts = [ 443 ];
#    
#    Example (Correct):
#      # All firewall ports in ONE place
#      security/default.nix:    allowedTCPPorts = [ 22 80 443 ];
#
# 3. Resolving Module Conflicts:
#    ─────────────────────────────────────────────────────────────────────────
#    Symptom: "error: The option `X` is defined multiple times"
#    
#    Diagnosis:
#      $ nixos-option <option.path>
#      # Shows all locations where option is defined
#    
#    Resolution:
#      a) Identify which module should own the option
#      b) Remove duplicates from other modules
#      c) Use lib.mkDefault for soft defaults
#      d) Use lib.mkForce to override if necessary
#    
#    Example:
#      # Module A (soft default):
#      networking.firewall.enable = lib.mkDefault true;
#      
#      # Module B (override if needed):
#      networking.firewall.enable = lib.mkForce false;
#
# 4. Checking Module Dependencies:
#    ─────────────────────────────────────────────────────────────────────────
#    # List all imported modules:
#    $ nix eval .#nixosConfigurations.<host>.config.imports --json | jq
#    
#    # Check specific module loaded:
#    $ nix eval .#nixosConfigurations.<host>.config.imports --json \
#      | jq '.[] | select(. | test("security"))'
#    
#    # Trace module evaluation order:
#    $ nixos-rebuild build --flake .#<host> --show-trace 2>&1 \
#      | grep "evaluating module"
#
# 5. Testing Module Changes:
#    ─────────────────────────────────────────────────────────────────────────
#    # Dry run (check for errors):
#    $ nixos-rebuild dry-build --flake .#<host>
#    
#    # Build without activating:
#    $ nixos-rebuild build --flake .#<host>
#    
#    # Test (activate but don't add to bootloader):
#    $ nixos-rebuild test --flake .#<host>
#    
#    # Full switch (activate and add to bootloader):
#    $ nixos-rebuild switch --flake .#<host>
#    
#    # Rollback if broken:
#    $ nixos-rebuild switch --rollback
#
# 6. Debugging Module Issues:
#    ─────────────────────────────────────────────────────────────────────────
#    # Check if option exists:
#    $ nixos-option <option.path>
#    
#    # Show option value:
#    $ nix eval .#nixosConfigurations.<host>.config.<option.path>
#    
#    # Show option with trace:
#    $ nixos-rebuild build --flake .#<host> --show-trace
#    
#    # Check for undefined options:
#    $ nixos-rebuild build --flake .#<host> 2>&1 | grep "error: undefined"
#    
#    # Validate entire config:
#    $ nix flake check
#
# ==============================================================================
# Common Pitfalls & Solutions
# ==============================================================================
#
# Pitfall 1: Circular Dependencies
# ─────────────────────────────────────────────────────────────────────────────
# Problem: Module A needs config from Module B, which needs config from A
# Example: networking needs user from account, account needs network config
# 
# Solution:
#   - Use lib.mkDefault for soft dependencies
#   - Restructure to remove circular reference
#   - Use module arguments ({ config, ... }) to read final values
#
# Pitfall 2: Duplicate Option Definitions
# ─────────────────────────────────────────────────────────────────────────────
# Problem: Same option defined in multiple modules
# Example: firewall ports defined in both security and networking
# 
# Solution:
#   - Follow single authority principle
#   - Remove duplicates, keep one authoritative source
#   - Use lists.concat if must merge from multiple sources
#
# Pitfall 3: Import Order Breaking Evaluation
# ─────────────────────────────────────────────────────────────────────────────
# Problem: Module loaded before its dependencies
# Example: display module before system module (needs hardware config)
# 
# Solution:
#   - Respect dependency layers (1-6 in this file)
#   - Dependencies first, dependents later
#   - Use --show-trace to find evaluation order issues
#
# Pitfall 4: Missing Flake Inputs
# ─────────────────────────────────────────────────────────────────────────────
# Problem: Module needs flake input that wasn't passed
# Example: display module needs inputs.hyprland but not in specialArgs
# 
# Solution:
#   - Ensure flake.nix passes all required inputs:
#     specialArgs = { inherit inputs username host; };
#   - Check module's required inputs (documented in header)
#
# Pitfall 5: Module Scope Confusion
# ─────────────────────────────────────────────────────────────────────────────
# Problem: Unsure which module should own a configuration
# Example: Should D-Bus go in services or display module?
# 
# Solution:
#   - Refer to "Module Boundaries" table above
#   - Choose module closest to primary function
#   - Document choice in module header comments
#
# ==============================================================================
# Advanced Patterns
# ==============================================================================
#
# 1. Conditional Module Loading:
#    ─────────────────────────────────────────────────────────────────────────
#    imports = [
#      ./account
#      ./system
#    ] ++ lib.optionals (host == "gaming-pc") [
#      ./gaming  # Only on gaming systems
#    ];
#
# 2. Module Arguments:
#    ─────────────────────────────────────────────────────────────────────────
#    # Pass custom arguments to modules:
#    imports = [
#      (import ./custom { inherit config; customArg = "value"; })
#    ];
#
# 3. Module Overlays:
#    ─────────────────────────────────────────────────────────────────────────
#    # Override module behavior:
#    imports = [
#      ./security
#      ({ config, ... }: {
#        # Override security module defaults
#        networking.firewall.allowedTCPPorts = 
#          config.networking.firewall.allowedTCPPorts ++ [ 8080 ];
#      })
#    ];
#
# 4. Module Composition:
#    ─────────────────────────────────────────────────────────────────────────
#    # Compose multiple module sets:
#    imports = 
#      (import ./core { inherit inputs username; }) ++  # Core modules
#      (import ./custom { inherit inputs; }) ++         # Custom modules
#      [ ./hardware-configuration.nix ];                # Hardware config
#
# ==============================================================================
# Maintenance Checklist
# ==============================================================================
#
# Monthly Review:
#   □ Check for duplicate configurations across modules
#   □ Verify single authority principle compliance
#   □ Review module boundaries (still make sense?)
#   □ Update documentation for new modules
#   □ Test full rebuild: nixos-rebuild switch --flake .
#
# Before Major Changes:
#   □ Document current module dependencies
#   □ Create backup: nixos-rebuild list-generations
#   □ Test in VM first: nixos-rebuild build-vm --flake .
#   □ Review diff: nix store diff-closures /run/current-system ./result
#
# After Adding New Module:
#   □ Update "Module Boundaries" table above
#   □ Add to dependency graph diagram
#   □ Document required inputs (if any)
#   □ Test module isolation (disable and rebuild)
#   □ Verify no configuration leaks to other modules
#
# ==============================================================================
# Performance Optimization
# ==============================================================================
#
# Module Evaluation Performance:
#   ─────────────────────────────────────────────────────────────────────────
#   # Measure evaluation time:
#   $ time nix eval .#nixosConfigurations.<host>.config.system.build.toplevel
#   
#   # Profile slow evaluations:
#   $ nix eval --profile-json .#nixosConfigurations.<host> > profile.json
#   $ nix store diff-closures --json profile.json
#   
#   # Optimize:
#   - Minimize list operations (use sets where possible)
#   - Cache expensive computations with `let` bindings
#   - Avoid recursive attribute lookups in hot paths
#   - Use lib.mkDefault instead of lib.mkMerge when possible
#
# Build Performance:
#   ─────────────────────────────────────────────────────────────────────────
#   # Parallel builds:
#   nix.settings.max-jobs = lib.mkDefault 8;
#   nix.settings.cores = lib.mkDefault 4;
#   
#   # Build in background:
#   $ nixos-rebuild build --flake .#<host> &
#   
#   # Use binary cache:
#   nix.settings.substituters = [ "https://cache.nixos.org" ];
#
# ==============================================================================
# Security Hardening Checklist
# ==============================================================================
#
# Review Annually (or after CVEs):
#   □ Audit firewall rules (security module)
#     - All open ports still needed?
#     - Any services exposed unnecessarily?
#   
#   □ Review user permissions (account module)
#     - Principle of least privilege enforced?
#     - Unused users disabled?
#   
#   □ Check secrets management (sops module)
#     - Age keys rotated?
#     - Secrets encrypted properly?
#   
#   □ Verify AppArmor profiles (security module)
#     - All services confined?
#     - Profiles up to date?
#   
#   □ Audit system packages (packages module)
#     - Unused packages removed?
#     - All packages from trusted sources?
#   
#   □ Review network configuration (networking module)
#     - DNS secure (DNSSEC, DoT)?
#     - VPN working correctly?
#   
#   □ Check service isolation (services module)
#     - Containers using least privilege?
#     - VMs properly sandboxed?
#
# ==============================================================================
# Migration Guide (Adding/Removing Modules)
# ==============================================================================
#
# Adding a New Module:
#   ─────────────────────────────────────────────────────────────────────────
#   1. Create module structure:
#      $ mkdir -p modules/core/mymodule
#      $ touch modules/core/mymodule/default.nix
#   
#   2. Define module header (copy from existing module):
#      # ==============================================================================
#      # MyModule Configuration
#      # ==============================================================================
#      # Module:      modules/core/mymodule
#      # Purpose:     Brief description
#      # Dependencies: List dependencies here
#   
#   3. Implement configuration:
#      { config, pkgs, lib, ... }: {
#        # Your configuration here
#      }
#   
#   4. Add to imports in correct layer:
#      # In modules/core/default.nix:
#      imports = [
#        # ... existing imports ...
#        ./mymodule  # Add in appropriate layer
#      ];
#   
#   5. Update documentation:
#      - Add to "Module Boundaries" table
#      - Add to dependency graph
#      - Document in module header
#   
#   6. Test thoroughly:
#      $ nixos-rebuild build --flake .#<host>
#      $ nixos-rebuild test --flake .#<host>
#
# Removing a Module:
#   ─────────────────────────────────────────────────────────────────────────
#   1. Identify dependencies:
#      $ grep -r "mymodule" modules/core/
#      # Check if other modules reference it
#   
#   2. Remove or refactor dependencies:
#      - Move config to other modules if needed
#      - Update cross-references
#   
#   3. Remove from imports:
#      # In modules/core/default.nix:
#      # ./mymodule  # Comment out or remove
#   
#   4. Test rebuild:
#      $ nixos-rebuild build --flake .#<host>
#      # Should succeed without the module
#   
#   5. Archive module (don't delete immediately):
#      $ mkdir -p modules/archive
#      $ mv modules/core/mymodule modules/archive/
#   
#   6. Update documentation:
#      - Remove from tables and diagrams
#      - Add removal to changelog
#
# Refactoring Multiple Modules:
#   ─────────────────────────────────────────────────────────────────────────
#   1. Plan refactoring:
#      - Document current state
#      - Define target architecture
#      - Identify breaking changes
#   
#   2. Create migration branch:
#      $ git checkout -b refactor-modules
#   
#   3. Refactor incrementally:
#      - One module at a time
#      - Test after each change
#      - Commit working states
#   
#   4. Test full system:
#      $ nixos-rebuild build-vm --flake .#<host>
#      # Test in VM before production
#   
#   5. Document changes:
#      - Update all diagrams
#      - Update module boundaries
#      - Write migration notes
#   
#   6. Merge and deploy:
#      $ git merge refactor-modules
#      $ nixos-rebuild switch --flake .#<host>
#
# ==============================================================================
# Flake Integration Examples
# ==============================================================================
#
# Example flake.nix structure:
#   ─────────────────────────────────────────────────────────────────────────
#   {
#     inputs = {
#       nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
#       hyprland.url = "github:hyprwm/Hyprland";
#       nix-flatpak.url = "github:gmodena/nix-flatpak";
#       sops-nix.url = "github:Mic92/sops-nix";
#     };
#   
#     outputs = { self, nixpkgs, ... }@inputs: {
#       nixosConfigurations = {
#         myhost = nixpkgs.lib.nixosSystem {
#           system = "x86_64-linux";
#           
#           # Pass inputs to modules
#           specialArgs = {
#             inherit inputs;
#             username = "myuser";
#             host = "myhost";
#           };
#           
#           modules = [
#             # Hardware configuration
#             ./hardware-configuration.nix
#             
#             # Core modules (this file imports all core modules)
#             ./modules/core
#             
#             # Host-specific overrides
#             ./hosts/myhost
#           ];
#         };
#       };
#     };
#   }
#
# Multiple Host Configuration:
#   ─────────────────────────────────────────────────────────────────────────
#   nixosConfigurations = {
#     # Desktop system
#     desktop = nixpkgs.lib.nixosSystem {
#       specialArgs = { 
#         inherit inputs;
#         username = "user";
#         host = "desktop";
#       };
#       modules = [
#         ./hardware/desktop.nix
#         ./modules/core
#         ./hosts/desktop.nix
#       ];
#     };
#     
#     # Laptop system
#     laptop = nixpkgs.lib.nixosSystem {
#       specialArgs = { 
#         inherit inputs;
#         username = "user";
#         host = "laptop";
#       };
#       modules = [
#         ./hardware/laptop.nix
#         ./modules/core
#         ./hosts/laptop.nix
#       ];
#     };
#     
#     # Server system (minimal - no display)
#     server = nixpkgs.lib.nixosSystem {
#       specialArgs = { 
#         inherit inputs;
#         username = "admin";
#         host = "server";
#       };
#       modules = [
#         ./hardware/server.nix
#         # Selective core modules (no display/gaming)
#         ./modules/core/account
#         ./modules/core/system
#         ./modules/core/nix
#         ./modules/core/packages
#         ./modules/core/networking
#         ./modules/core/security
#         ./modules/core/sops
#         # Server-specific modules
#         ./modules/server
#       ];
#     };
#   };
#
# ==============================================================================
# CI/CD Integration
# ==============================================================================
#
# GitHub Actions Example (.github/workflows/build.yml):
#   ─────────────────────────────────────────────────────────────────────────
#   name: Build NixOS Configuration
#   on: [push, pull_request]
#   
#   jobs:
#     build:
#       runs-on: ubuntu-latest
#       steps:
#         - uses: actions/checkout@v3
#         
#         - uses: cachix/install-nix-action@v22
#           with:
#             nix_path: nixpkgs=channel:nixos-unstable
#         
#         - name: Build configuration
#           run: |
#             nix flake check
#             nix build .#nixosConfigurations.myhost.config.system.build.toplevel
#         
#         - name: Check for evaluation errors
#           run: |
#             nix eval .#nixosConfigurations.myhost.config.system.build.toplevel
#
# GitLab CI Example (.gitlab-ci.yml):
#   ─────────────────────────────────────────────────────────────────────────
#   build:
#     image: nixos/nix:latest
#     script:
#       - nix flake check
#       - nix build .#nixosConfigurations.myhost.config.system.build.toplevel
#     only:
#       - main
#       - merge_requests
#
# ==============================================================================
# Disaster Recovery
# ==============================================================================
#
# Backup Strategy:
#   ─────────────────────────────────────────────────────────────────────────
#   # Backup entire configuration:
#   $ tar czf nixos-config-backup-$(date +%Y%m%d).tar.gz \
#       ~/.nixosc/ \
#       /etc/nixos/hardware-configuration.nix \
#       ~/.config/sops/age/keys.txt
#   
#   # Backup secrets separately (encrypted):
#   $ tar czf secrets-backup-$(date +%Y%m%d).tar.gz.age \
#       ~/.nixosc/secrets/ \
#       ~/.config/sops/age/keys.txt
#   $ age -e -r <public-key> secrets-backup-*.tar.gz > secrets-backup-*.tar.gz.age
#
# Recovery Procedure:
#   ─────────────────────────────────────────────────────────────────────────
#   1. Boot from NixOS installer
#   
#   2. Restore configuration:
#      $ mkdir -p ~/.nixosc
#      $ tar xzf nixos-config-backup-*.tar.gz -C /
#   
#   3. Restore secrets:
#      $ age -d -i recovery-key.txt secrets-backup-*.tar.gz.age | tar xz -C /
#   
#   4. Install NixOS:
#      $ nixos-install --flake ~/.nixosc#myhost
#   
#   5. Reboot into new system
#
# Rollback Procedure:
#   ─────────────────────────────────────────────────────────────────────────
#   # List generations:
#   $ nixos-rebuild list-generations
#   
#   # Rollback to previous generation:
#   $ nixos-rebuild switch --rollback
#   
#   # Rollback to specific generation:
#   $ nix-env --switch-generation 42
#   $ nixos-rebuild switch
#   
#   # Boot older generation from bootloader (GRUB/systemd-boot)
#   # Select older generation at boot menu
#
# ==============================================================================
# FAQ & Common Questions
# ==============================================================================
#
# Q: Why is module order important?
# A: Modules can depend on configuration from other modules. For example,
#    the security module needs to know which network interfaces exist (from
#    networking module) to apply firewall rules. Loading security before
#    networking would fail or produce incorrect results.
#
# Q: Can I put all configuration in one file?
# A: Yes, but it's not recommended. Modular organization:
#    - Makes configuration easier to understand
#    - Prevents conflicts (single authority principle)
#    - Allows reuse across multiple systems
#    - Simplifies troubleshooting
#    - Enables selective loading (e.g., server vs desktop)
#
# Q: What if two modules need to configure the same thing?
# A: Follow the single authority principle: choose ONE module as authoritative
#    for that configuration. Document this choice and ensure all related
#    configuration lives in that module. Use comments to reference the
#    authoritative source if needed elsewhere.
#
# Q: How do I debug "option defined multiple times" errors?
# A: Use `nixos-option <option.path>` to see all definition locations.
#    Then remove duplicates, keeping only the authoritative definition.
#    Use lib.mkDefault for soft defaults and lib.mkForce to override.
#
# Q: Can I disable a module without removing it?
# A: Yes, comment out the import:
#    imports = [
#      # ./gaming  # Disabled for server configuration
#    ];
#    Or use conditional loading:
#    imports = lib.optionals (host != "server") [ ./gaming ];
#
# Q: How do I share configuration between multiple hosts?
# A: Use this core module system as the shared base, then create
#    host-specific modules that override or extend the core configuration:
#    - Core modules: ./modules/core (shared)
#    - Host-specific: ./hosts/myhost (overrides)
#
# Q: What's the best way to test module changes?
# A: Progressive testing approach:
#    1. `nixos-rebuild dry-build` - Check for syntax errors
#    2. `nixos-rebuild build` - Build without activating
#    3. `nixos-rebuild build-vm` - Test in VM (safe)
#    4. `nixos-rebuild test` - Activate without bootloader
#    5. `nixos-rebuild switch` - Full activation (can rollback)
#
# Q: How do I migrate from non-modular to modular configuration?
# A: Gradual migration:
#    1. Keep existing configuration.nix
#    2. Extract one concern to a module (e.g., users)
#    3. Import module in configuration.nix
#    4. Test thoroughly
#    5. Repeat for other concerns
#    6. Eventually replace configuration.nix with module imports
#
# Q: What if a module needs information from another module?
# A: Use the `config` argument to access final configuration:
#    { config, ... }: {
#      # Reference another module's config
#      networking.firewall.allowedTCPPorts =
#        if config.services.myservice.enable
#        then [ 8080 ]
#        else [];
#    }
#
# Q: How do I document custom modules?
# A: Follow the header format used in core modules:
#    - Purpose: What does this module do?
#    - Dependencies: What does it need?
#    - Boundaries: What should/shouldn't it configure?
#    - Examples: How to use/test it?
#    Include inline comments for complex logic.
#
# ==============================================================================
# Resources & References
# ==============================================================================
#
# Official Documentation:
#   - NixOS Manual: https://nixos.org/manual/nixos/stable/
#   - Nix Pills: https://nixos.org/guides/nix-pills/
#   - Module System: https://nixos.wiki/wiki/Module
#
# Community Resources:
#   - NixOS Wiki: https://nixos.wiki/
#   - NixOS Discourse: https://discourse.nixos.org/
#   - Reddit: r/NixOS
#
# Example Configurations:
#   - NixOS Examples: https://github.com/NixOS/nixpkgs/tree/master/nixos/modules
#   - Community Configs: https://github.com/topics/nixos-configuration
#
# Tools:
#   - nixos-option: Query option values and definitions
#   - nix flake check: Validate flake configuration
#   - nix eval: Evaluate Nix expressions
#   - nixos-rebuild: Build and activate configurations
#
# ==============================================================================
# Version History
# ==============================================================================
#
# 2025-10-18: Added comprehensive documentation, troubleshooting guide,
#             module boundaries table, dependency graph, best practices
# 2025-09-03: Initial modular structure with 8 core modules
# 2025-08-15: Migration from monolithic configuration.nix
#
# ==============================================================================

