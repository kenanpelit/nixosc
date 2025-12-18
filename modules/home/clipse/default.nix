# modules/home/clipse/default.nix
# ==============================================================================
# Home module for Clipse clipboard helper.
# Installs the CLI and manages user config through Home Manager.
# Adjust behaviour here instead of manual config files.
# ==============================================================================

{ config, pkgs, lib, ... }: 
let
  cfg = config.my.user.clipse;
  dag =
    if lib ? hm && lib.hm ? dag
    then lib.hm.dag
    else config.lib.dag;
in
{
  options.my.user.clipse = {
    enable = lib.mkEnableOption "Clipse clipboard manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.clipse ];

    # =============================================================================
    # Configuration Files
    # =============================================================================
    
    # Main config.json
    xdg.configFile."clipse/config.json".text = builtins.toJSON {
      historyFile = "clipboard_history.json";
      maxHistory = 1000;
      allowDuplicates = false;
      themeFile = "custom_theme.json";
      tempDir = "tmp_files";
      logFile = "${config.xdg.stateHome}/clipse/clipse.log";
      
      keyBindings = {
        # Navigation - Vim style
        up = "k";
        down = "j";
        home = "g";          # gg yapmak için 2 kere g
        end = "G";
        
        # Page navigation
        nextPage = "l";      # veya "right"
        prevPage = "h";      # veya "left"
        
        # Selection
        choose = "enter";
        selectSingle = "s";
        selectUp = "ctrl+k"; # veya "K"
        selectDown = "ctrl+j"; # veya "J"
        
        # Actions
        togglePin = "p";
        togglePinned = "tab";
        remove = "d";        # vim'de delete gibi
        clearSelected = "D"; # büyük D - hepsini temizle
        
        # Search/Filter
        filter = "/";        # vim search gibi
        yankFilter = "y";    # vim yank gibi
        
        # Preview & Help
        preview = "t";
        more = "?";
        
        # Exit
        quit = "q";
      };
      
      imageDisplay = {
        type = "basic";
        scaleX = 9;
        scaleY = 9;
        heightCut = 4;
      };
    };

    # Catppuccin Mocha theme
    xdg.configFile."clipse/custom_theme.json".text = builtins.toJSON {
      UseCustom = true;
      
      # Title colors
      TitleFore = "#cdd6f4";        # text
      TitleBack = "#cba6f7";        # mauve
      TitleInfo = "#89b4fa";        # blue
      
      # Normal state
      NormalTitle = "#cdd6f4";      # text
      DimmedTitle = "#6c7086";      # overlay0
      SelectedTitle = "#f5c2e7";    # pink
      
      # Descriptions
      NormalDesc = "#bac2de";       # subtext1
      DimmedDesc = "#6c7086";       # overlay0
      SelectedDesc = "#f5c2e7";     # pink
      
      # Status and indicators
      StatusMsg = "#a6e3a1";        # green
      PinIndicatorColor = "#f9e2af"; # yellow
      
      # Borders
      SelectedBorder = "#89b4fa";   # blue
      SelectedDescBorder = "#89b4fa"; # blue
      
      # Filter bar
      FilteredMatch = "#cdd6f4";    # text
      FilterPrompt = "#a6e3a1";     # green
      FilterInfo = "#89b4fa";       # blue
      FilterText = "#cdd6f4";       # text
      FilterCursor = "#f9e2af";     # yellow
      
      # Help section
      HelpKey = "#9399b2";          # overlay1
      HelpDesc = "#6c7086";         # overlay0
      
      # Page indicators
      PageActiveDot = "#89b4fa";    # blue
      PageInactiveDot = "#6c7086";  # overlay0
      DividerDot = "#89b4fa";       # blue
      
      # Preview
      PreviewedText = "#cdd6f4";    # text
      PreviewBorder = "#89b4fa";    # blue
    };

    # Clipse tries to open `~/.config/clipse/clipse.log` very early (even before
    # reading config in some code paths). We cannot manage this as a `home.file`
    # because the target must be writable and lives outside the Nix store.
    #
    # Instead, create a writable state log and symlink the legacy config-path log
    # to it during activation.
    home.activation.clipseLog = dag.entryAfter [ "writeBoundary" ] ''
      state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
      mkdir -p "$HOME/.config/clipse" "$state_home/clipse"
      touch "$state_home/clipse/clipse.log"
      ln -sf "$state_home/clipse/clipse.log" "$HOME/.config/clipse/clipse.log"
    '';

    # Start the daemon via systemd so it works across sessions (niri + hyprland).
    # It is tied to compositor session targets and won't run under plain TTY.
    systemd.user.services.clipse = {
      Unit = {
        Description = "Clipse clipboard daemon";
        After = [ "dbus.service" "hyprland-session.target" "niri-session.target" ];
        PartOf = [ "hyprland-session.target" "niri-session.target" ];
      };
      Service = {
        ExecStartPre =
          "${pkgs.bash}/bin/bash -lc '"
          + "install -d -m 700 \"${config.xdg.stateHome}/clipse\" && "
          + "touch \"${config.xdg.stateHome}/clipse/clipse.log\""
          + "'";
        ExecStart =
          "${pkgs.bash}/bin/bash -lc '"
          + "for ((i=0;i<300;i++)); do "
          + "  if [[ -n \"${"$"}{WAYLAND_DISPLAY:-}\" && -n \"${"$"}{XDG_RUNTIME_DIR:-}\" && -S \"${"$"}{XDG_RUNTIME_DIR}/${"$"}{WAYLAND_DISPLAY}\" ]]; then break; fi; "
          + "  if [[ -n \"${"$"}{XDG_RUNTIME_DIR:-}\" ]]; then "
          + "    for s in \"${"$"}{XDG_RUNTIME_DIR}\"/wayland-*; do [[ -S \"$s\" ]] || continue; export WAYLAND_DISPLAY=\"$(basename \"$s\")\"; break 2; done; "
          + "  fi; "
          + "  sleep 0.1; "
          + "done; "
          + "${pkgs.clipse}/bin/clipse -listen; "
          + "rc=$?; [[ $rc -eq 0 ]] && rc=1; exit $rc"
          + "'";
        Restart = "on-failure";
        RestartSec = 1;
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "hyprland-session.target" "niri-session.target" ];
      };
    };
  };
}
