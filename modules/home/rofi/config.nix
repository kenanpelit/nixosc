# modules/home/desktop/rofi/config.nix
# ==============================================================================
# Enhanced Rofi Appearance and Behavior Configuration
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
      modi: "drun,run,window,ssh,filebrowser,keys,combi";
      combi-modi: "drun,run,window";
      lines: 8;
      columns: 3;
      cycle: true;
      font: "Hack Nerd Font Bold 13";

      /* Display Settings */
      show-icons: true;
      icon-theme: "a-candy-beauty-icon-theme";
      terminal: "kitty";
      location: 0;
      hide-scrollbar: true;
      sidebar-mode: true;
      fixed-num-lines: true;

      /* Mode Display Labels with Icons */
      display-drun: "󰀻 Apps";
      display-run: " Run";
      display-window: "󰖯 Windows";
      display-ssh: "󰢹 SSH";
      display-filebrowser: "󰉋 Files";
      display-keys: "󰌌 Keys";
      display-combi: "󰛘 All";

      /* Advanced Search Settings */
      sorting-method: "fzf";
      matching: "fuzzy";
      matching-negate-char: "!";
      levenshtein-sort: true;
      normalize-match: true;
      case-sensitive: false;

      /* Cache and Performance */
      cache-dir: "~/.cache/rofi";
      drun-use-desktop-cache: true;
      drun-reload-desktop-cache: true;
      drun-cache-file: "~/.cache/rofi/drun.cache";
      
      /* History Settings */
      history: true;
      history-size: 100;
      disable-history: false;

      /* Display Formats */
      drun-display-format: "{name} [<span weight='light' size='small'><i>{generic}</i></span>]";
      window-format: "{w} · {c} · {t}";
      
      /* Match Fields */
      drun-match-fields: "name,generic,exec,categories,keywords";
      window-match-fields: "title,class,name,desktop";
      
      /* Window Management */
      window-command: "wmctrl -i -R {window}";
      run-command: "{cmd}";
      ssh-command: "{terminal} -e {ssh-client} {host} [-p {port}]";
      
      /* Behavior */
      sort: true;
      pid: "/run/user/1000/rofi.pid";
      auto-select: false;
      parse-hosts: true;
      parse-known-hosts: true;
      

    }

    /* Theme Import */
    @theme "theme"

    /* Enhanced Element Styles */
    element-text, element-icon, mode-switcher {
      background-color: inherit;
      text-color: inherit;
    }

    /* Main Window Layout */
    window {
      height: 60%;
      width: 50%;
      min-height: 400px;
      min-width: 600px;
      border: 3px;
      border-color: @border-col;
      background-color: @bg-col;
      border-radius: 12px;
      transparency: "real";
    }

    mainbox {
      background-color: @bg-col;
      padding: 8px;
    }

    /* Enhanced Input Bar */
    inputbar {
      children: [prompt, entry, case-indicator];
      background-color: @bg-col-light;
      border-radius: 8px;
      padding: 4px;
      margin: 0px 0px 8px 0px;
    }

    prompt {
      background-color: @green;
      padding: 8px 12px;
      text-color: @bg-col;
      border-radius: 6px;
      margin: 2px;
      font: "Hack Nerd Font Bold 13";
    }



    entry {
      padding: 8px 12px;
      margin: 2px;
      text-color: @fg-col;
      background-color: @bg-col;
      border-radius: 6px;
      placeholder: "Type to search...";
      placeholder-color: @grey;
    }

    case-indicator {
      padding: 8px;
      text-color: @fg-col2;
      background-color: @bg-col-light;
    }

    /* Enhanced List View */
    listview {
      border: 0px;
      padding: 4px;
      margin: 0px;
      columns: 3;
      lines: 8;
      background-color: @bg-col;
      cycle: true;
      dynamic: true;
      scrollbar: false;
      layout: vertical;
      reverse: false;
      fixed-height: true;
      fixed-columns: true;
      spacing: 4px;
    }

    /* Enhanced Elements */
    element {
      padding: 12px;
      margin: 2px;
      background-color: @bg-col;
      text-color: @fg-col;
      border-radius: 8px;
      orientation: horizontal;
      cursor: pointer;
    }

    element-icon {
      size: 32px;
      margin: 0px 8px 0px 0px;
      cursor: inherit;
    }

    element-text {
      cursor: inherit;
      highlight: @highlight;
      vertical-align: 0.5;
    }

    element normal.normal {
      background-color: @bg-col;
      text-color: @fg-col;
    }

    element normal.urgent {
      background-color: @bg-col;
      text-color: @fg-col2;
    }

    element normal.active {
      background-color: @bg-col;
      text-color: @green;
    }

    element selected.normal {
      background-color: @selected-col;
      text-color: @fg-col2;
      border: 2px;
      border-color: @green;
    }

    element selected.urgent {
      background-color: @selected-col;
      text-color: @fg-col2;
      border: 2px;
      border-color: @fg-col2;
    }

    element selected.active {
      background-color: @selected-col;
      text-color: @green;
      border: 2px;
      border-color: @green;
    }

    element alternate.normal {
      background-color: @bg-col;
      text-color: @fg-col;
    }

    element alternate.urgent {
      background-color: @bg-col;
      text-color: @fg-col2;
    }

    element alternate.active {
      background-color: @bg-col;
      text-color: @green;
    }

    /* Enhanced Mode Switcher */
    mode-switcher {
      spacing: 0;
      background-color: @bg-col-light;
      border-radius: 8px;
      margin: 8px 0px 0px 0px;
    }

    button {
      padding: 12px 16px;
      background-color: @bg-col-light;
      text-color: @grey;
      vertical-align: 0.5;
      horizontal-align: 0.5;
      border-radius: 6px;
      margin: 2px;
      cursor: pointer;
    }

    button selected {
      background-color: @green;
      text-color: @bg-col;
      font: "Hack Nerd Font Bold 13";
    }

    /* Scrollbar */
    scrollbar {
      width: 4px;
      border: 0;
      handle-color: @grey;
      handle-width: 4px;
      padding: 0;
      margin: 0px 2px;
    }

    /* Message */
    message {
      padding: 8px;
      border-radius: 8px;
      background-color: @bg-col-light;
      text-color: @fg-col;
    }

    textbox {
      padding: 8px 12px;
      text-color: inherit;
    }

    /* Error */
    error-message {
      padding: 12px;
      border-radius: 8px;
      background-color: @fg-col2;
      text-color: @bg-col;
    }
  '';
}

