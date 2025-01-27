# modules/home/desktop/rofi/config.nix
# ==============================================================================
# Rofi Appearance and Behavior Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # =============================================================================
  # Main Configuration File
  # =============================================================================
  xdg.configFile."rofi/config.rasi".text = ''
    /* Core Configuration */
    configuration {
      /* Basic Settings */
      modi: "drun,run,window,ssh,filebrowser,keys,recursivebrowser";
      combi-modi: "drun,run,window,ssh,filebrowser";
      lines: 5;
      cycle: false;
      font: "Hack Bold 13";

      /* Display Settings */
      show-icons: true;
      icon-theme: "a-candy-beauty-icon-theme";
      terminal: "kitty";
      drun-display-format: "{icon} {name}";
      location: 0;
      hide-scrollbar: true;
      sidebar-mode: true;

      /* Mode Display Labels */
      display-drun: " Apps ";
      display-run: " Run ";
      display-window: " Window ";
      display-ssh: " SSH ";
      display-filebrowser: " Files ";
      display-keys: " Keys ";
      display-combi: " All ";
      display-recursivebrowser: " Browse ";

      /* Search and Cache Settings */
      sorting-method: "fzf";
      cache-dir: "~/.cache/rofi";
      drun-use-desktop-cache: true;
      drun-reload-desktop-cache: true;
      drun-cache-file: "~/.cache/rofi/drun.cache";
      history: true;
      history-size: 50;
      disable-history: false;

      /* ... diğer ayarlar ... */
      sort: true;
      sorting-method: "fzf";
      drun-use-desktop-cache: true;
      drun-reload-desktop-cache: true;
      disable-history: false;
      show-icons: true;
      window-format: "{w} · {c} · {t}";
      drun-display-format: "{name} [<span weight='light' size='small'><i>({generic})</i></span>]";
      sort-method: "normal";
      pid: "/run/user/1000/rofi.pid";
      preselect-on-match: true;
      drun-match-fields: "name,generic,exec,categories,keywords";
      window-match-fields: "title,class,name,desktop";
      matching: "fuzzy";
      matching-negate-char: '!';

      /* Match Settings */
      levenshtein-sort: true;
      normalize-match: true;
      window-command: "wmctrl -i -R {window}";
      drun-match-fields: "name,generic,exec,categories";
    }
    /* Theme Import */
    @theme "theme"
    /* Element Styles */
    element-text, element-icon, mode-switcher {
      background-color: inherit;
      text-color: inherit;
    }
    /* Window Layout */
    window {
      height: 712px;
      width: 1152px;
      border: 2px;
      border-color: @border-col;
      background-color: @bg-col;
    }
    mainbox {
      background-color: @bg-col;
    }
    /* Input Bar */
    inputbar {
      children: [prompt,entry];
      background-color: @bg-col-light;
      border-radius: 5px;
      padding: 0px;
    }
    prompt {
      background-color: @green;
      padding: 4px;
      text-color: @bg-col-light;
      border-radius: 3px;
      margin: 10px 0px 10px 10px;
    }
    textbox-prompt-colon {
      expand: false;
      str: ":";
    }
    entry {
      padding: 6px;
      margin: 10px 10px 10px 5px;
      text-color: @fg-col;
      background-color: @bg-col;
      border-radius: 3px;
    }
    /* List View */
    listview {
      border: 0px 0px 0px;
      padding: 6px 0px 0px;
      margin: 10px 0px 0px 6px;
      columns: 3;
      background-color: @bg-col;
      cycle: true;
    }
    element {
      padding: 8px;
      margin: 0px 10px 4px 4px;
      background-color: @bg-col;
      text-color: @fg-col;
    }
    element-icon {
      size: 28px;
    }
    element selected {
      background-color: @selected-col;
      text-color: @fg-col2;
      border-radius: 3px;
    }
    /* Mode Switcher */
    mode-switcher {
      spacing: 0;
    }
    button {
      padding: 10px;
      background-color: @bg-col-light;
      text-color: @grey;
      vertical-align: 0.5;
      horizontal-align: 0.5;
    }
    button selected {
      background-color: @bg-col;
      text-color: @green;
    }
  '';
}
