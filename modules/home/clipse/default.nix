# modules/home/clipse/default.nix
# ==============================================================================
# Clipse Clipboard Manager Configuration - Catppuccin Mocha
# ==============================================================================
{ config, pkgs, lib, ... }: 
let
  cfg = config.my.user.clipse;
in
{
  options.my.user.clipse = {
    enable = lib.mkEnableOption "Clipse clipboard manager";
  };

  config = lib.mkIf cfg.enable {
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

    # Ensure log file exists and is writable so the daemon stays up
    home.activation.clipseLog = hmLib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${config.home.homeDirectory}/.local/state/clipse"
      : > "${logPath}"
      chmod 600 "${logPath}"
    '';

    # Remove any stale log in the old location
    home.file.".config/clipse/clipse.log".enable = false;
  };
}
