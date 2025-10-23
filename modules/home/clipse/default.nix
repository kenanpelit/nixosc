# modules/home/clipse/default.nix
# ==============================================================================
# Clipse Clipboard Manager Configuration - Catppuccin Mocha
# ==============================================================================
{ config, pkgs, lib, ... }: {

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
    logFile = "clipse.log";
    
    keyBindings = {
      choose = "enter";
      clearSelected = "S";
      down = "down";
      end = "end";
      filter = "/";
      home = "home";
      more = "?";
      nextPage = "right";
      prevPage = "left";
      preview = "t";
      quit = "q";
      remove = "x";
      selectDown = "ctrl+down";
      selectSingle = "s";
      selectUp = "ctrl+up";
      togglePin = "p";
      togglePinned = "tab";
      up = "up";
      yankFilter = "ctrl+s";
    };
    
    imageDisplay = {
      type = "basic";
      scaleX = 9;
      scaleY = 9;
      heightCut = 2;
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

  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    clipse
    wl-clipboard  # Wayland clipboard utilities (required dependency)
  ];

  # =============================================================================
  # Systemd Service (Auto-start listener)
  # =============================================================================
  systemd.user.services.clipse = {
    Unit = {
      Description = "Clipse clipboard manager listener";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.clipse}/bin/clipse -listen";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
