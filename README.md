<h1 align="center">
   <img src="./.github/assets/logo/nixos-logo.png" width="100px" /> 
   <br>
      Kenan's NixOS Configuration 
   <br>
      <img src="./.github/assets/pallet/pallet-0.png" width="600px" /> <br>

   <div align="center">
      <p></p>
      <div align="center">
         <a href="https://github.com/kenanpelit/nixosc/stargazers">
            <img src="https://img.shields.io/github/stars/kenanpelit/nixosc?color=FABD2F&labelColor=282828&style=for-the-badge&logo=starship&logoColor=FABD2F">
         </a>
         <a href="https://github.com/kenanpelit/nixosc/">
            <img src="https://img.shields.io/github/repo-size/kenanpelit/nixosc?color=B16286&labelColor=282828&style=for-the-badge&logo=github&logoColor=B16286">
         </a>
         <a = href="https://nixos.org">
            <img src="https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=282828&logo=NixOS&logoColor=458588&color=458588">
         </a>
         <a href="https://github.com/kenanpelit/nixosc/blob/main/LICENSE">
            <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=282828&colorB=98971A&logo=unlicense&logoColor=98971A&"/>
         </a>
      </div>
      <br>
   </div>
</h1>

### 🖼️ Gallery

<p align="center">
   <img src="./.github/assets/screenshots/1.png" style="margin-bottom: 10px;"/> <br>
   <img src="./.github/assets/screenshots/hyprlock.png" style="margin-bottom: 10px;" /> <br>
   Screenshots last updated <b>2025-01-14</b>
</p>


# 🗃️ Overview

## 📚 Layout

-   [flake.nix](flake.nix) base of the configuration
-   [hosts](hosts) 🌳 per-host configurations that contain machine specific configurations
    - [hay](hosts/hay/) 💻 Laptop specific configuration
    - [vhay](hosts/vhay/) 🗄️ VM specific configuration
-   [modules](modules) 🍱 modularized NixOS configurations
    -   [core](modules/core/) ⚙️ Core NixOS configuration
    -   [homes](modules/home/) 🏠 my [Home-Manager](https://github.com/nix-community/home-manager) config
-   [themes](themes/) 🎨 Catppuccin Mocha
-   [wallpapers](wallpapers/) 🌄 wallpapers collection

## 📓 Components
|                             | NixOS + Hyprland                                                                              |
| --------------------------- | :---------------------------------------------------------------------------------------------:
| **Window Manager**          | [Hyprland][Hyprland] |
| **Bar**                     | [Waybar][Waybar] |
| **Application Launcher**    | [rofi][rofi] |
| **Notification Daemon**     | [swaync][swaync] |
| **Terminal Emulator**       | [Kitty][Kitty] + [Wezterm][Wezterm] + [Foot][Foot] |
| **Shell**                   | [zsh][zsh] + [oh-my-zsh][oh-my-zsh] + [p10k][p10k] |
| **Text Editor**             | [Neovim][Neovim] |
| **network management tool** | [iwd][iwd] |
| **System resource monitor** | [Btop][Btop] |
| **File Manager**            | [nemo][nemo] + [yazi][yazi] |
| **Fonts**                   | [Hack Nerd Font][Nerd fonts] + [Maple Mono][Maple Mono] |
| **Color Scheme**            | [Catppuccin Mocha][Catppuccin] |
| **Cursor**                  | [catppuccin-mocha-blue-cursors][catppuccin-cursors] |
| **Icons**                   | [Papirus-Dark][Papirus-Dark] |
| **Lockscreen**              | [Hyprlock][Hyprlock] + [Swaylock-effects][Swaylock-effects] |
| **Image Viewer**            | [qview][qview] |
| **Media Player**            | [mpv][mpv] |
| **Music Player**            | [audacious][audacious] |
| **Screenshot Software**     | [grimblast][grimblast] |
| **Screen Recording**        | [wf-recorder][wf-recorder] |
| **Clipboard**               | [wl-clip-persist][wl-clip-persist] + [CopyQ][CopyQ] |
| **Color Picker**            | [hyprpicker][hyprpicker] |

## 📝 Shell aliases

<details>
<summary>
Utils (EXPAND)
</summary>

- ```c```     $\rightarrow$ ```clear```
- ```cd```    $\rightarrow$ ```z```
- ```tt```    $\rightarrow$ ```gtrash put```
- ```vim```   $\rightarrow$ ```nvim```
- ```cat```   $\rightarrow$ ```bat```
- ```nano```  $\rightarrow$ ```micro```
- ```code```  $\rightarrow$ ```codium```
- ```py```    $\rightarrow$ ```python```
- ```icat```  $\rightarrow$ ```kitten icat```
- ```dsize``` $\rightarrow$ ```du -hs```
- ```pdf```   $\rightarrow$ ```tdf```
- ```open```  $\rightarrow$ ```xdg-open```
- ```space``` $\rightarrow$ ```ncdu```
- ```man```   $\rightarrow$ ```BAT_THEME='default' batman```
- ```l```     $\rightarrow$ ```eza --icons  -a --group-directories-first -1```
- ```ll```    $\rightarrow$ ```eza --icons  -a --group-directories-first -1 --no-user --long```
- ```tree```  $\rightarrow$ ```eza --icons --tree --group-directories-first```
</details>

<details>
<summary>
Nixos (EXPAND)
</summary>

- ```cdnix```      $\rightarrow$ ```cd ~/nixosc && codium ~/nixosc```
- ```ns```         $\rightarrow$ ```nom-shell --run zsh```
- ```nix-test```   $\rightarrow$ ```nh os test```
- ```nix-switch``` $\rightarrow$ ```nh os switch```
- ```nix-update``` $\rightarrow$ ```nh os switch --update```
- ```nix-clean```  $\rightarrow$ ```nh clean all --keep 5```
- ```nix-search``` $\rightarrow$ ```nh search```
</details>

<details>
<summary>
Git (EXPAND)
</summary>

- ```g```     $\rightarrow$ ```lazygit```
- ```gf```    $\rightarrow$ ```onefetch --number-of-file-churns 0 --no-color-palette```
- ```ga```    $\rightarrow$ ```git add```
- ```gaa```   $\rightarrow$ ```git add --all```
- ```gs```    $\rightarrow$ ```git status```
- ```gb```    $\rightarrow$ ```git branch```
- ```gm```    $\rightarrow$ ```git merge```
- ```gd```    $\rightarrow$ ```git diff```
- ```gpl```   $\rightarrow$ ```git pull```
- ```gplo```  $\rightarrow$ ```git pull origin```
- ```gps```   $\rightarrow$ ```git push```
- ```gpso```  $\rightarrow$ ```git push origin```
- ```gpst```  $\rightarrow$ ```git push --follow-tags```
- ```gcl```   $\rightarrow$ ```git clone```
- ```gc```    $\rightarrow$ ```git commit```
- ```gcm```   $\rightarrow$ ```git commit -m```
- ```gcma```  $\rightarrow$ ```git add --all && git commit -m```
- ```gtag```  $\rightarrow$ ```git tag -ma```
- ```gch```   $\rightarrow$ ```git checkout```
- ```gchb```  $\rightarrow$ ```git checkout -b```
- ```glog```  $\rightarrow$ ```git log --oneline --decorate --graph```
- ```glol```  $\rightarrow$ ```git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'```
- ```glola``` $\rightarrow$ ```git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all```
- ```glols``` $\rightarrow$ ```git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat```
  
</details>

## 🛠️ Scripts

All the scripts are located under modules/home/scripts/bin/ and modules/home/scripts/start/. They are automatically generated by generate_nix_bin.sh and generate_nix_start.sh scripts.


## ⌨️ Keybinds

View all keybinds by pressing ```$mainMod F1``` and wallpaper picker by pressing ```$mainMod w```. By default ```$mainMod``` is the ```SUPER``` key. 

<details>
<summary>
Keybindings 
</summary>

##### show keybinds list
- ```$mainMod, F1, exec, show-keybinds```

##### keybindings
- ```$mainMod, Return, exec, wezterm start --always-new-process```
- ```ALT, Return, exec, [float; center] wezterm start --always-new-process```
- ```$mainMod SHIFT, Return, exec, [fullscreen] wezterm start --always-new-process```
- ```$mainMod, B, exec, hyprctl dispatch exec '[workspace 1 silent] floorp'```
- ```$mainMod, Q, killactive,```
- ```$mainMod, F, fullscreen, 0```
- ```$mainMod SHIFT, F, fullscreen, 1```
- ```$mainMod, Space, togglefloating,```
- ```$mainMod, D, exec, rofi -show drun```
- ```$mainMod SHIFT, D, exec, hyprctl dispatch exec '[workspace 4 silent] discord --enable-features=UseOzonePlatform --ozone-platform=wayland'```
- ```$mainMod SHIFT, S, exec, hyprctl dispatch exec '[workspace 5 silent] SoundWireServer'```
- ```$mainMod, Escape, exec, swaylock```
- ```ALT, Escape, exec, hyprlock```
- ```$mainMod SHIFT, Escape, exec, power-menu```
- ```$mainMod, P, pseudo,```
- ```$mainMod, J, togglesplit,```
- ```$mainMod, T, exec, toggle_oppacity```
- ```$mainMod, E, exec, nemo```
- ```$mainMod SHIFT, B, exec, toggle_waybar```
- ```$mainMod, C ,exec, hyprpicker -a```
- ```$mainMod, W,exec, wallpaper-picker```
- ```$mainMod, N, exec, swaync-client -t -sw```
- ```$mainMod SHIFT, W, exec, vm-start```

##### screenshot
- ```$mainMod, Print, exec, grimblast --notify --cursor --freeze save area ~/Pictures/$(date +'%Y-%m-%d-At-%Ih%Mm%Ss').png```
- ```,Print, exec, grimblast --notify --cursor --freeze copy area```

##### switch focus
- ```$mainMod, left, movefocus, l```
- ```$mainMod, right, movefocus, r```
- ```$mainMod, up, movefocus, u```
- ```$mainMod, down, movefocus, d```

##### switch workspace
- ```$mainMod, 1, workspace, 1```
- ```$mainMod, 2, workspace, 2```
- ```$mainMod, 3, workspace, 3```
- ```$mainMod, 4, workspace, 4```
- ```$mainMod, 5, workspace, 5```
- ```$mainMod, 6, workspace, 6```
- ```$mainMod, 7, workspace, 7```
- ```$mainMod, 8, workspace, 8```
- ```$mainMod, 9, workspace, 9```
- ```$mainMod, 0, workspace, 10```

##### same as above, but switch to the workspace
- ```$mainMod SHIFT, 1, movetoworkspacesilent, 1```
- ```$mainMod SHIFT, 2, movetoworkspacesilent, 2```
- ```$mainMod SHIFT, 3, movetoworkspacesilent, 3```
- ```$mainMod SHIFT, 4, movetoworkspacesilent, 4```
- ```$mainMod SHIFT, 5, movetoworkspacesilent, 5```
- ```$mainMod SHIFT, 6, movetoworkspacesilent, 6```
- ```$mainMod SHIFT, 7, movetoworkspacesilent, 7```
- ```$mainMod SHIFT, 8, movetoworkspacesilent, 8```
- ```$mainMod SHIFT, 9, movetoworkspacesilent, 9```
- ```$mainMod SHIFT, 0, movetoworkspacesilent, 10```
- ```$mainMod CTRL, c, movetoworkspace, empty```

##### window control
- ```$mainMod SHIFT, left, movewindow, l```
- ```$mainMod SHIFT, right, movewindow, r```
- ```$mainMod SHIFT, up, movewindow, u```
- ```$mainMod SHIFT, down, movewindow, d```
- ```$mainMod CTRL, left, resizeactive, -80 0```
- ```$mainMod CTRL, right, resizeactive, 80 0```
- ```$mainMod CTRL, up, resizeactive, 0 -80```
- ```$mainMod CTRL, down, resizeactive, 0 80```
- ```$mainMod ALT, left, moveactive,  -80 0```
- ```$mainMod ALT, right, moveactive, 80 0```
- ```$mainMod ALT, up, moveactive, 0 -80```
- ```$mainMod ALT, down, moveactive, 0 80```

##### media and volume controls
- ```,XF86AudioRaiseVolume,exec, pamixer -i 2```
- ```,XF86AudioLowerVolume,exec, pamixer -d 2```
- ```,XF86AudioMute,exec, pamixer -t```
- ```,XF86AudioPlay,exec, playerctl play-pause```
- ```,XF86AudioNext,exec, playerctl next```
- ```,XF86AudioPrev,exec, playerctl previous```
- ```,XF86AudioStop, exec, playerctl stop```
- ```$mainMod, mouse_down, workspace, e-1```
- ```$mainMod, mouse_up, workspace, e+1```

##### laptop brigthness
- ```,XF86MonBrightnessUp, exec, brightnessctl set 5%+```
- ```,XF86MonBrightnessDown, exec, brightnessctl set 5%-```
- ```$mainMod, XF86MonBrightnessUp, exec, brightnessctl set 100%+```
- ```$mainMod, XF86MonBrightnessDown, exec, brightnessctl set 100%-```

##### clipboard manager
- ```$mainMod, V, exec, cliphist list | rofi -dmenu -theme-str 'window {width: 50%;}' | cliphist decode | wl-copy```
</details>

# 🚀 Installation 

> [!CAUTION]
> Applying custom configurations, especially those related to your operating system, can have unexpected consequences and may interfere with your system's normal behavior. While I have tested these configurations on my own setup, there is no guarantee that they will work flawlessly for you.
> **I am not responsible for any issues that may arise from using this configuration.**

> [!NOTE]
> It is highly recommended to review the configuration contents and make necessary modifications to customize it to your needs before attempting the installation.

#### 1. **Install NixOs**

First install nixos using any [graphical ISO image](https://nixos.org/download.html#nixos-iso). 
> [!NOTE]
> Only been tested using the Gnome graphical installer and choosing the ```No desktop``` option durring instalation.

#### 2. **Clone the repo**

```bash
nix-shell -p git
git clone https://github.com/kenanpelit/nixosc
cd nixosc
```

#### 3. **Install script configuration**

Before running the install script, you might need to adjust the `BUILD_CORES` value based on your system's specifications:

- Open `install.sh` and locate the configuration section at the top
- Find or add the `BUILD_CORES` variable:
  ```bash
  BUILD_CORES=4  # Adjust this number based on your system
  ```
  
Recommended values based on RAM:
- 8GB RAM: Use 2-3 cores
- 16GB RAM: Use 4-6 cores
- 32GB+ RAM: Use more cores as needed

> [!IMPORTANT]
> Using too many cores during build can cause the system to run out of RAM and freeze. Adjust this value according to your system's capabilities.
   
The installation script provides various options for customization and management:

```bash
❯ ./install.sh --help
NixOS Installation and Management Script
Version: 2.0.0
Usage:
    install.sh [options]
Options:
    -h, --help              Show this help message
    -v, --version           Show script version
    -s, --silent           Run in silent mode (no confirmations)
    -d, --debug            Run in debug mode
    -a, --auto HOST        Run with default settings for specified host (hay/vhay)
    -u, --update-flake     Update flake.lock
    -m, --update-module    Update specific module
    -b, --backup           Only backup flake.lock
    -r, --restore          Restore from latest backup
    -l, --list-modules     List available modules
    -p, --profile NAME     Specify profile name for nixos-rebuild
    -hc, --health-check    Perform system health check (disabled by default)
    --list-profiles        List all NixOS profiles
    --delete-profile ID    Delete a specific profile by ID

Host Types:
    hay                    Laptop configuration (HAY)
    vhay                   QEMU Virtual Machine configuration (VHAY)

Examples:
    install.sh                      # Normal installation
    install.sh --silent             # Silent installation
    install.sh -a hay              # Automatic laptop setup
    install.sh -m home-manager      # Update home-manager module
    install.sh -p myprofile        # Build with specific profile name
    install.sh -hc                  # Check system health
```

For a basic installation, simply run:
```bash
./install.sh
```

#### 4. **Configure Git**

Before proceeding, update your git configuration in `./modules/home/git/default.nix`:
```nix
programs.git = {
   ...
   userName = "Your Name";
   userEmail = "your.email@example.com";
   ...
};
```
  
#### 5. **Reboot**

After rebooting, the config should be applied, you'll be greeted by hyprlock prompting for your password.

#### 6. **Manual config**

Even though I use home manager, there is still a little bit of manual configuration to do:
- Set Discord theme (in Discord settings under VENCORD > Themes).
- Configure the browser (for now, all browser configuration is done manually).

## 👥 Credits

Special thanks to [Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config) for providing examples and inspiration. The code samples and configuration patterns have been invaluable in creating this setup.

<p align="center"><img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/footers/gray0_ctp_on_line.svg?sanitize=true" /></p>

<!-- end of page, send back to the top -->

<div align="right">
  <a href="#readme">Back to the Top</a>
</div>

<!-- Links -->
[Hyprland]: https://github.com/hyprwm/Hyprland
[Kitty]: https://github.com/kovidgoyal/kitty
[Wezterm]: https://wezfurlong.org/wezterm/index.html
[Foot]: https://codeberg.org/dnkl/foot
[Starship]: https://github.com/starship/starship
[Waybar]: https://github.com/Alexays/Waybar
[rofi]: https://github.com/lbonn/rofi
[Btop]: https://github.com/aristocratos/btop
[nemo]: https://github.com/linuxmint/nemo/
[yazi]: https://github.com/sxyazi/yazi
[zsh]: https://ohmyz.sh/
[oh-my-zsh]: https://ohmyz.sh/
[p10k]: https://github.com/romkatv/powerlevel10k
[Swaylock-effects]: https://github.com/mortie/swaylock-effects
[Hyprlock]: https://github.com/hyprwm/hyprlock
[audacious]: https://audacious-media-player.org/
[mpv]: https://github.com/mpv-player/mpv
[Neovim]: https://github.com/neovim/neovim
[grimblast]: https://github.com/hyprwm/contrib
[qview]: https://interversehq.com/qview/
[swaync]: https://github.com/ErikReider/SwayNotificationCenter
[Nerd fonts]: https://github.com/ryanoasis/nerd-fonts
[Maple Mono]: https://github.com/subframe7536/maple-font
[iwd]: https://git.kernel.org/pub/scm/network/wireless/iwd.git/
[wl-clip-persist]: https://github.com/Linus789/wl-clip-persist
[CopyQ]: https://hluk.github.io/CopyQ/
[wf-recorder]: https://github.com/ammen99/wf-recorder
[hyprpicker]: https://github.com/hyprwm/hyprpicker
[Catppuccin]: https://github.com/catppuccin/catppuccin
[catppuccin-cursors]: https://github.com/catppuccin/cursors
[Papirus-Dark]: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
