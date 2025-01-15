# modules/home/rofi/config.nix
{ pkgs, ... }:
{
  xdg.configFile."rofi/config.rasi".text = ''
    /* Config dosyası */
    configuration {
      modi: "run,drun,window";
      lines: 5;
      cycle: false;
      font: "Hack Bold 13";
      show-icons: true;
      icon-theme: "a-candy-beauty-icon-theme";
      terminal: "kitty";
      drun-display-format: "{icon} {name}";
      location: 0;
      hide-scrollbar: true;
      display-drun: " Apps ";
      display-run: " Run ";
      display-window: " Window ";
      sidebar-mode: true;
      sorting-method: "fzf";
      cache-dir: "~/.cache/rofi";
      drun-use-desktop-cache: true;
      drun-reload-desktop-cache: true;
      drun-cache-file: "~/.cache/rofi/drun.cache";
      history: true;
      history-size: 50;
      disable-history: false;
      levenshtein-sort: true;
      normalize-match: true;
      window-command: "wmctrl -i -R {window}";
      drun-match-fields: "name,generic,exec,categories";
    }

    @theme "theme"

    element-text, element-icon, mode-switcher {
      background-color: inherit;
      text-color: inherit;
    }

    window {
      height: 600px;
      width: 900px;
      border: 2px;
      border-color: @border-col;
      background-color: @bg-col;
    }

    mainbox {
      background-color: @bg-col;
    }

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
