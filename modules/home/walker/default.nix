# modules/home/walker/default.nix
#
# Home Manager module for Walker - A fast application launcher for Wayland
#
# Walker is a keyboard-driven application launcher with fuzzy search capabilities,
# designed for modern Wayland compositors. It works together with Elephant backend
# to provide quick access to applications, files, custom menus, and more.
#
# Features:
#   - Fast fuzzy and exact search with configurable algorithms
#   - Multiple providers (applications, files, clipboard, calculator, websearch)
#   - Custom menus with static or dynamic (Lua) content
#   - Themeable UI with GTK4 and CSS support
#   - Flexible keybindings and multi-action support
#   - Page navigation with configurable jump size (v2.7.2+)
#   - Low resource usage and quick startup times
#
# Architecture:
#   Walker (Frontend - GTK4 UI) ←→ Elephant (Backend - Provider engine)
#
# Version Information:
#   - Recommended: v2.7.2+ (from GitHub flake input)
#   - Nixpkgs version: 0.12.21 (outdated, not recommended)
#   - Current detected: Walker 2.7.5, Elephant 2.11.0
#   
#   IMPORTANT: Walker and Elephant versions should match or be close!
#   Version mismatch can cause "unexpected EOF" errors in communication.
#   
#   To fix version mismatch:
#   1. Pin both to same version in flake.nix
#   2. Or use matching flake inputs
#   3. Check: walker --version && elephant --version
#
# Known Issues:
#   - D-Bus service registration can take 15-20 seconds on first launch
#   - Type=dbus causes systemd timeout (fixed with Type=simple + increased timeout)
#   - Walker must wait for Elephant backend to fully initialize
#
# Reliability Improvements (v2):
#   - Elephant uses Restart=always for sleep/resume resilience
#   - Health check timer monitors Elephant every 3 minutes
#   - Automatic restart on any service stoppage
#   - Resource limits prevent runaway processes
#
# Usage:
#   # Automatically enabled when imported in modules/home/default.nix
#   # To disable: programs.walker.enable = false;
#   
#   # To configure:
#   programs.walker = {
#     runAsService = true;  # Run as systemd service (recommended)
#     settings = {
#       force_keyboard_focus = true;
#       theme = "catppuccin";
#       page_jump_size = 10;  # v2.7.2: Page Up/Down navigation
#       providers = {
#         default = ["desktopapplications" "calc" "runner"];
#         prefixes = [
#           { prefix = ">"; provider = "runner"; }
#         ];
#       };
#     };
#   };
#
# References:
#   - Walker (Frontend): https://github.com/abenz1267/walker
#   - Elephant (Backend): https://github.com/abenz1267/elephant
#   - GTK4 Theming: https://docs.gtk.org/gtk4/
#   - Latest Release: https://github.com/abenz1267/walker/releases

{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) 
    mkEnableOption 
    mkOption 
    mkIf 
    types 
    literalExpression
    mdDoc
    mkDefault;
    
  cfg = config.programs.walker;
  
  # TOML format generator for type-safe configuration
  tomlFormat = pkgs.formats.toml { };
  
  # Get elephant package
  elephantPkg = if inputs ? elephant 
                then inputs.elephant.packages.${pkgs.stdenv.hostPlatform.system}.elephant-with-providers
                else throw "Elephant backend is required but not found in flake inputs";
  
in
{
  options.programs.walker = {
    # Enable by default when module is imported
    # Can be disabled with: programs.walker.enable = false;
    enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = mdDoc ''
        Whether to enable Walker application launcher.
        
        Enabled by default when the module is imported.
        Set to `false` to disable if needed.
      '';
    };

    runAsService = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = mdDoc ''
        Whether to run Walker and Elephant as systemd user services.
        
        When enabled:
        - Elephant backend runs automatically on login
        - Walker runs as a service with extended timeout for D-Bus registration
        - Services restart automatically on failure, manual stop, or sleep/resume
        - Health check timer monitors Elephant every 3 minutes
        
        Recommended: `true` for best performance and reliability.
        
        Note: Walker's D-Bus registration can take 15-20 seconds on first launch,
        so we use Type=simple with a 2-minute timeout instead of Type=dbus.
        
        Manual control:
```bash
        systemctl --user status elephant walker
        systemctl --user restart elephant walker
        systemctl --user status elephant-healthcheck.timer
```
      '';
    };

    package = mkOption {
      type = types.package;
      # Default to GitHub flake input if available, fallback to nixpkgs
      default = if inputs ? walker 
                then inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default 
                else pkgs.walker;
      defaultText = literalExpression "inputs.walker.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = mdDoc ''
        Walker package to use.
        
        **Recommended**: Use the flake input for latest version (v2.7.2+)
        
        Add to your flake.nix:
```nix
        inputs.walker = {
          url = "github:abenz1267/walker/v2.7.2";
          inputs.nixpkgs.follows = "nixpkgs";
        };
```
        
        **Note**: nixpkgs version (0.12.21) is significantly outdated and
        missing many features. Using the flake input is strongly recommended.
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          # General behavior
          force_keyboard_focus = true;
          theme = "catppuccin";
          page_jump_size = 10;
          
          # Providers
          providers = {
            default = ["desktopapplications" "calc" "runner" "websearch"];
            empty = ["desktopapplications"];
            
            # Prefix shortcuts
            prefixes = [
              { prefix = ">"; provider = "runner"; }
              { prefix = "/"; provider = "files"; }
              { prefix = "="; provider = "calc"; }
              { prefix = "?"; provider = "websearch"; }
              { prefix = ":"; provider = "clipboard"; }
            ];
          };
          
          # Global keybindings
          close = ["Escape"];
          next = ["Down" "ctrl n" "ctrl j"];
          previous = ["Up" "ctrl p" "ctrl k"];
        }
      '';
      description = mdDoc ''
        Configuration written to {file}`$XDG_CONFIG_HOME/walker/config.toml`.
        
        For complete documentation, see the module's comprehensive examples
        or visit: <https://github.com/abenz1267/walker>
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install Walker and Elephant packages
    home.packages = [ 
      cfg.package
      elephantPkg
    ];

    # Elephant provider directory with automatic provider installation
    # Providers MUST be in ~/.config/elephant/providers/ (documented requirement)
    home.file.".config/elephant/providers" = {
      source = "${elephantPkg}/lib/elephant/providers";
      recursive = true;
    };

    # ==========================================================================
    # Elephant Backend Service
    # ==========================================================================
    # Provides search providers (apps, files, clipboard, etc.) to Walker
    # Must start before Walker and remain running
    #
    # Restart Policy:
    #   Uses "always" instead of "on-failure" to ensure the service restarts
    #   even after manual stops or system sleep/resume cycles.
    #
    # Resource Limits:
    #   Memory and CPU quotas prevent runaway resource usage while allowing
    #   the service to restart reliably.
    systemd.user.services.elephant = mkIf cfg.runAsService {
      Unit = {
        Description = "Elephant - Backend provider for Walker";
        Documentation = "https://github.com/abenz1267/elephant";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        
        # Restart limit ayarları Unit bölümünde olmalı
        # 2 dakika içinde 10 kez yeniden başlatma denemesi yapabilir
        StartLimitBurst = 10;
        StartLimitIntervalSec = 120;
      };

      Service = {
        Type = "simple";
        ExecStart = "${elephantPkg}/bin/elephant";
        
        # Agresif yeniden başlatma politikası
        # "always" - servis her durduğunda yeniden başlar (sleep/resume dahil)
        Restart = "always";
        RestartSec = 3;
        
        # Kaynak kullanımını sınırla
        MemoryMax = "500M";
        CPUQuota = "50%";
        
        TimeoutStopSec = 10;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # ==========================================================================
    # Elephant Health Check Timer
    # ==========================================================================
    # Monitors Elephant service health and restarts if not running
    # Runs every 3 minutes to ensure continuous availability
    systemd.user.timers.elephant-healthcheck = mkIf cfg.runAsService {
      Unit = {
        Description = "Periodic health check for Elephant service";
        Documentation = "https://github.com/abenz1267/elephant";
      };

      Timer = {
        # İlk kontrol boot'tan 1 dakika sonra
        OnBootSec = "1min";
        
        # Sonraki kontroller her 3 dakikada bir
        OnUnitActiveSec = "3min";
        
        # Timer'ın kendisi persistent olsun
        Persistent = true;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # ==========================================================================
    # Elephant Health Check Service
    # ==========================================================================
    # Executed by the timer to check and restart Elephant if needed
    systemd.user.services.elephant-healthcheck = mkIf cfg.runAsService {
      Unit = {
        Description = "Health check and restart Elephant if needed";
        Documentation = "https://github.com/abenz1267/elephant";
      };

      Service = {
        Type = "oneshot";
        
        # D-Bus environment'ını ayarla (SSH session için gerekli)
        Environment = [
          "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
        ];
        
        # Elephant'ın çalışıp çalışmadığını kontrol et ve gerekirse yeniden başlat
        # Chroot-safe: systemctl yerine direkt systemd socket kullan
        ExecStart = pkgs.writeShellScript "elephant-healthcheck" ''
          #!${pkgs.bash}/bin/bash
          
          LOG_FILE="$HOME/.local/share/elephant-health.log"
          TIMESTAMP=$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')
          
          # Log dizinini oluştur
          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$LOG_FILE")"
          
          # Elephant process'ini kontrol et
          if ! ${pkgs.procps}/bin/pgrep -u "$USER" -x elephant >/dev/null 2>&1; then
            echo "$TIMESTAMP: Elephant not running, attempting restart..." | \
              ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
            
            # systemd socket üzerinden restart (chroot-safe)
            # /run/user/$UID/systemd/private socket'i kullan
            SYSTEMD_SOCKET="/run/user/$(${pkgs.coreutils}/bin/id -u)/systemd/private"
            
            if [ -S "$SYSTEMD_SOCKET" ]; then
              # busctl ile restart gönder (en güvenilir yöntem)
              if ${pkgs.systemd}/bin/busctl --user call \
                 org.freedesktop.systemd1 \
                 /org/freedesktop/systemd1 \
                 org.freedesktop.systemd1.Manager \
                 StartUnit ss elephant.service replace 2>&1 | \
                 ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"; then
                
                echo "$TIMESTAMP: Start command sent via busctl" | \
                  ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
                
                # Başlatmanın başarılı olup olmadığını kontrol et
                ${pkgs.coreutils}/bin/sleep 10
                if ${pkgs.procps}/bin/pgrep -u "$USER" -x elephant >/dev/null 2>&1; then
                  echo "$TIMESTAMP: Elephant successfully restarted" | \
                    ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
                else
                  echo "$TIMESTAMP: Failed to restart Elephant (process not found after 10s)" | \
                    ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
                fi
              else
                echo "$TIMESTAMP: Failed to send start command via busctl" | \
                  ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
              fi
            else
              echo "$TIMESTAMP: Systemd socket not found at $SYSTEMD_SOCKET" | \
                ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
                
              # Son çare: direkt binary çalıştır
              echo "$TIMESTAMP: Attempting direct binary execution..." | \
                ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
              ${elephantPkg}/bin/elephant &
              ELEPHANT_PID=$!
              echo "$TIMESTAMP: Started Elephant with PID $ELEPHANT_PID" | \
                ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
            fi
          else
            # Elephant çalışıyor, log'a yazmaya gerek yok (sessiz başarı)
            true
          fi
        '';
      };
    };

    # ==========================================================================
    # Walker Frontend Service
    # ==========================================================================
    # GTK4 launcher interface that connects to Elephant backend
    #
    # Service Type Notes:
    #   Originally used Type=dbus for D-Bus activation, but Walker's D-Bus
    #   registration can take 15-20 seconds, causing systemd timeout.
    #   
    #   Solution: Use Type=simple with extended TimeoutStartSec (2 minutes)
    #   to allow Walker time to initialize and register with D-Bus.
    #
    # D-Bus Activation:
    #   Even with Type=simple, D-Bus activation still works via the service
    #   file in ~/.local/share/dbus-1/services/. This allows applications
    #   to launch Walker on-demand via D-Bus while avoiding systemd timeouts.
    systemd.user.services.walker = mkIf cfg.runAsService {
      Unit = {
        Description = "Walker - Application launcher";
        Documentation = "https://github.com/abenz1267/walker";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" "elephant.service" ];
        # Walker REQUIRES Elephant to be running
        Requires = [ "elephant.service" ];
      };

      Service = {
        # Use Type=simple instead of Type=dbus to avoid systemd timeout
        # D-Bus registration can take 15-20 seconds on first launch
        Type = "simple";
        
        # Elephant'ın tamamen hazır olmasını bekle
        # 5 saniye gecikme ekleyerek bağlantı sorunlarını önle
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        
        # Start Walker in GApplication service mode
        # This enables D-Bus activation and single-instance behavior
        ExecStart = "${cfg.package}/bin/walker --gapplication-service";
        
        # Restart policy
        Restart = "on-failure";
        RestartSec = 3;
        
        # Extended timeout to accommodate slow D-Bus registration
        # Walker needs time to:
        #   1. Initialize GTK4 and Vulkan/Mesa
        #   2. Connect to Elephant backend
        #   3. Load providers and register D-Bus service
        TimeoutStartSec = 120;  # 2 minutes (default is 90 seconds)
        TimeoutStopSec = 10;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Generate configuration file
    xdg.configFile."walker/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "walker-config.toml" cfg.settings;
    };

    # ==========================================================================
    # D-Bus Service File
    # ==========================================================================
    # Enables D-Bus activation of Walker (allows other apps to launch Walker)
    # Works independently of systemd service type
    #
    # How it works:
    #   1. Application sends D-Bus message to io.github.abenz1267.walker
    #   2. D-Bus checks this service file and launches Walker if not running
    #   3. Walker registers the bus name and handles the request
    #
    # Note: This is why we can use Type=simple in systemd - D-Bus activation
    # is handled by this service file, not by systemd's Type=dbus mechanism
    xdg.dataFile."dbus-1/services/io.github.abenz1267.walker.service".text = ''
      [D-BUS Service]
      Name=io.github.abenz1267.walker
      Exec=${cfg.package}/bin/walker --gapplication-service
      SystemdService=walker.service
    '';
    
    # Note: Walker uses bus name 'io.github.abenz1267.walker'
    # Legacy bus name 'dev.benz.walker' is no longer used and not needed
    
    # ==========================================================================
    # Usage Instructions
    # ==========================================================================
    # Displayed after home-manager activation to inform user about Walker setup
    home.activation.walkerInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.coreutils}/bin/cat << 'EOF'
      
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Walker Application Launcher
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      
      ${if cfg.runAsService then ''
      ✓ Running as systemd service (recommended)
      ✓ Elephant health check enabled (every 3 minutes)
      
      Service Management:
        systemctl --user status elephant walker
        systemctl --user restart elephant walker
        systemctl --user stop elephant walker
        
        # Health check timer
        systemctl --user status elephant-healthcheck.timer
        systemctl --user list-timers elephant-healthcheck
        
      Launch Walker:
        walker                                    # Standard launch
        nc -U /run/user/$UID/walker/walker.sock  # Fast socket launch
        
      Troubleshooting:
        journalctl --user -u walker -n 50           # View Walker logs
        journalctl --user -u elephant -n 50         # View Elephant logs
        journalctl --user -u elephant-healthcheck   # View health check logs
        cat ~/.local/share/elephant-health.log      # View health check history
        
      Note: First launch may take 15-20 seconds for D-Bus registration.
      This is normal behavior. Subsequent launches will be faster.
      
      Reliability Features:
        • Elephant restarts automatically on stop/failure/sleep
        • Health check monitors Elephant every 3 minutes
        • Resource limits prevent runaway processes
        • Detailed logging for troubleshooting
      '' else ''
      ⚠ Not running as service
      
      Manual Start:
        elephant &      # Start backend first (wait a few seconds)
        walker          # Then start frontend
        
      Recommended: Enable service mode for automatic startup
        programs.walker.runAsService = true;
      ''}
      
      Configuration:
        ~/.config/walker/config.toml              # Main config
        ~/.config/elephant/providers/             # Provider configs
        ~/.config/elephant/menus/                 # Custom menus
        ~/.local/share/elephant-health.log        # Health check log
        
      Documentation:
        Walker:   https://github.com/abenz1267/walker
        Elephant: https://github.com/abenz1267/elephant
        
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      EOF
    '';
  };
}
