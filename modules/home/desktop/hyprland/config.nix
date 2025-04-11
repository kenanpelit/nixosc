# Hyprland Window Manager Configuration
# modules/home/desktop/hyprland/config.nix
{ config, lib, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      # =====================================================
      # Startup Applications and System Services
      # =====================================================
      exec-once = [
        # Initialize Wayland environment variables for proper system integration
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP"
        # Update DBus environment for Wayland session
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
        # Power management notifications (battery, lid, etc.)
        "poweralertd"
        # Notification center for system-wide notifications
        "swaync"
        # Keep clipboard content persistent across program restarts
        "wl-clip-persist --clipboard both"
        # Store clipboard history using cliphist
        "wl-paste --watch cliphist store"
        # Advanced clipboard manager with searchable history
        "copyq"
        # Set system cursor theme and size
        "hyprctl setcursor catppuccin-mocha-lavender-cursors 24"
        # Initialize wallpaper daemon for dynamic wallpapers
        "swww-daemon"
        # Start wallpaper rotation/management service
        "wallpaper-manager start"
        # Python script runner for custom workspace management
        "pypr"
        # Initialize workspace layout
        "m2w2"
        # Start in service-mode application launcher
        "walker --gapplication-service"
        # Initialize screen locker for security
        "hyprlock"
        # Set initial audio levels - microphone to 5% - speaker volume to 15%
        "osc-audio-init"
        # Hyrsunset set
        "hypr-blue-hyprsunset-manager"

      ];

      # =====================================================
      # Environment Variables - Unified Configuration
      # =====================================================
      env = [
        # -----------------------------------------
        # Wayland Temel Ayarları
        # -----------------------------------------
        "XDG_CURRENT_DESKTOP,Hyprland"          # Masaüstü ortamı
        "XDG_SESSION_TYPE,wayland"              # Oturum tipi
        "XDG_SESSION_DESKTOP,Hyprland"          # Masaüstü oturumu

        # -----------------------------------------
        # Wayland Backend ve Görüntü Ayarları
        # -----------------------------------------
        "GDK_BACKEND,wayland"                   # GTK uygulamaları için
        "SDL_VIDEODRIVER,wayland"               # SDL uygulamaları için
        "CLUTTER_BACKEND,wayland"               # Clutter uygulamaları için
        "OZONE_PLATFORM,wayland"                # Electron uygulamaları için

        # -----------------------------------------
        # Hyprland Özel Ayarları
        # -----------------------------------------
        "HYPRLAND_LOG_WLR,1"                    # WLRoots logging
        "HYPRLAND_NO_RT,1"                      # RT scheduling devre dışı
        "HYPRLAND_NO_SD_NOTIFY,1"               # Systemd bildirimleri devre dışı

        # -----------------------------------------
        # GTK Tema ve Görünüm
        # -----------------------------------------
        "GTK_THEME,catppuccin-mocha-blue-standard" # GTK teması
        "GTK_USE_PORTAL,1"                      # XDG portal kullanımı
        "GTK_APPLICATION_PREFER_DARK_THEME,1"   # Koyu tema tercihi
        "GDK_SCALE,1"                           # HiDPI ölçekleme

        # -----------------------------------------
        # Qt/KDE Tema ve Görünüm
        # -----------------------------------------
        "QT_QPA_PLATFORM,wayland;xcb"           # Wayland öncelikli, XCB fallback
        "QT_QPA_PLATFORMTHEME,gtk3"             # GTK tema entegrasyonu
        "QT_STYLE_OVERRIDE,kvantum"             # Kvantum tema motoru
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"         # Otomatik HiDPI ölçekleme
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1" # Pencere dekorasyonları kapalı

        # -----------------------------------------
        # Firefox Özel Ayarları
        # -----------------------------------------
        "MOZ_ENABLE_WAYLAND,1"                  # Wayland native desteği
        "MOZ_WEBRENDER,1"                       # WebRender grafik motoru
        "MOZ_USE_XINPUT2,1"                     # Xinput2 desteği
        "MOZ_CRASHREPORTER_DISABLE,1"           # Çökme raporlayıcı kapalı

        # -----------------------------------------
        # Font Rendering Ayarları
        # -----------------------------------------
        "FREETYPE_PROPERTIES,truetype:interpreter-version=40"

        # -----------------------------------------
        # Temel Sistem Değişkenleri
        # -----------------------------------------
        "EDITOR,nvim"                           # Varsayılan metin düzenleyici
        "VISUAL,nvim"                           # Varsayılan görsel düzenleyici
        "TERMINAL,kitty"
        "TERM,xterm-kitty"
        "BROWSER,zen"                           # Varsayılan tarayıcı
      ];

      # =====================================================
      # Ecosystem Settings
      # =====================================================
      #ecosystem = {
      #  no_update_news = true;           # Güncelleme bildirimlerini devre dışı bırak
      #};

      # =====================================================
      # Giriş Aygıtları Yapılandırması
      # =====================================================
      input = {
        kb_layout = "tr";                    # Klavye düzeni
        kb_variant = "f";                    # F-klavye varyantı
        kb_options = "ctrl:nocaps";          # Caps Lock -> Ctrl
        repeat_rate = "25";                  # Tuş tekrar hızı
        repeat_delay = "300";                # Tuş tekrar gecikmesi
        sensitivity = "0.70";                # Fare hassasiyeti
        accel_profile = "adaptive";          # İvmelenme profili

        # Touchpad ayarları
        touchpad = {
          natural_scroll = "false";          # Doğal kaydırma
          disable_while_typing = "true";     # Yazarken devre dışı bırak
          tap-to-click = "true";             # Dokunmatik tıklama
          drag_lock = "true";                # Sürükleme kilidi
          scroll_factor = "0.70";            # Kaydırma faktörü
        };

        # Diğer giriş ayarları
        numlock_by_default = "0";            # NumLock varsayılan durumu
        left_handed = "0";                   # Sol el modu
        follow_mouse = "0";                  # Fare odak davranışı
        float_switch_override_focus = "0";   # Yüzen pencere odak geçişi
      };

      # =====================================================
      # Genel Pencere Yöneticisi Ayarları
      # =====================================================
      general = {
        "$mainMod" = "SUPER";                # Ana modifikatör tuşu
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "master";
        allow_tearing = false;
      };

      group = {
        "col.border_active" = "rgba(a855f7ee) rgba(9333eaee) 45deg";
        "col.border_inactive" = "rgba(b4befeaa) rgba(6c7086aa) 45deg";
        "col.border_locked_active" = "rgba(a855f7ee) rgba(9333eaee) 45deg";
        "col.border_locked_inactive" = "rgba(b4befeaa) rgba(6c7086aa) 45deg";
        groupbar = {
          render_titles = false;
          gradients = false;
          font_size = 10;
          "col.active" = "rgba(a855f7ee)";
          "col.inactive" = "rgba(6c7086aa)";
          "col.locked_active" = "rgba(9333eaee)";
          "col.locked_inactive" = "rgba(7aa2f7aa)";
        };
      };

      # =====================================================
      # Çeşitli Ayarlar
      # =====================================================
      misc = {
        # Görünüm ayarları
        disable_hyprland_logo = true;      # Logo gösterimini kapat
        disable_splash_rendering = true;   # Açılış ekranını kapat

        # Güç yönetimi
        mouse_move_enables_dpms = true;    # Fare hareketi ekranı açar
        key_press_enables_dpms = true;     # Tuş basımı ekranı açar
        vrr = 0;                           # VRR/Adaptive sync

        # Pencere davranışları
        focus_on_activate = true;          # Aktif pencereye odaklan
        always_follow_on_dnd = true;       # Sürükle-bırak takibi
        enable_swallow = true;             # Pencere yutma özelliği
        mouse_move_focuses_monitor = true; # Fare monitör odağı
        swallow_regex = "^(kitty)$";       # Yutulacak pencereler
      };

      # =====================================================
      # Yerleşim Yöneticisi Ayarları
      # =====================================================
      dwindle = {
        pseudotile = true;                 # Sahte döşeme
        preserve_split = true;             # Bölme konumunu koru
        special_scale_factor = 0.8;        # Özel ölçekleme faktörü
        force_split = 2;                   # Zorunlu bölme yönü
      };

      master = {
        new_on_top = true;                # Yeni pencereleri üste ekle
        mfact = 0.5;                      # Ana pencere oranı
        orientation = "right";            # Yerleşim yönü
      };

      # =====================================================
      # Kısayol Tuşu Ayarları
      # =====================================================
      binds = {
        pass_mouse_when_bound = true;     # Fare geçişine izin ver
        workspace_back_and_forth = true;  # Çalışma alanı geri-ileri
        allow_workspace_cycles = true;    # Çalışma alanı döngüsü
        workspace_center_on = true;       # Merkeze hizalama
        focus_preferred_method = 0;       # Odak yöntemi
        ignore_group_lock = true;         # Grup kilidini yoksay
      };

      # =====================================================
      # Görsel Efektler ve Dekorasyon
      # =====================================================
      decoration = {
        # Temel görünüm
        rounding = 10;                    # Köşe yuvarlaklığı

        # Opaklık ayarları
        active_opacity = 2.0;             # Aktif pencere opaklığı
        inactive_opacity = 1.0;           # Pasif pencere opaklığı
        fullscreen_opacity = 1.0;         # Tam ekran opaklığı

        # Karartma ayarları
        dim_inactive = true;              # Pasif pencere karartma
        dim_strength = 0.1;               # Karartma şiddeti

        # Bulanıklık ayarları
        blur = {
          enabled = true;                 # Bulanıklık efekti
          size = 6;                       # Bulanıklık boyutu
          passes = 3;                     # Bulanıklık geçişleri
          ignore_opacity = true;          # Opaklığı yoksay
          new_optimizations = true;       # Yeni optimizasyonlar
          xray = false;                   # X-ray efekti
        };

        # Gölge ayarları
        shadow = {
          enabled = true;                 # Gölge efekti
          ignore_window = true;           # Pencere gölgesi
          offset = "0 2";                 # Gölge konumu
          range = 20;                     # Gölge menzili
          render_power = 3;               # Gölge gücü
          color = "rgba(00000055)";       # Gölge rengi
        };
      };

      # =====================================================
      # Animasyon Ayarları
      # =====================================================
      animations = {
        enabled = true;                   # Animasyonları etkinleştir

        # Bezier eğrileri
        bezier = [
          "slow, 0, 0.85, 0.3, 1"
          "winOut, 0.3, -0.3, 0, 1"
          "wind, 0.05, 0.9, 0.1, 1.05"
          "linear, 0.0, 0.0, 1.0, 1.0"
        ];

        # Animasyon tanımları
        animation = [
          "windowsIn, 1, 4, slow, popin"
          "windowsOut, 1, 4, winOut, popin"
          "windowsMove, 1, 4, wind, slide"
          "fade, 1, 5, slow"
          "workspaces, 1, 4, wind"
          "border, 1, 10, linear"
        ];
      };

      # Window Rules Section
      windowrule = [
        "float,class:^(mpv)$"
        "size 19%,class:^(mpv)$"
        "move 1% 77%,class:^(mpv)$"
        "opacity 1.0,class:^(mpv)$"
        "pin,class:^(mpv)$"
        "float,class:^(Vncviewer)$"
        "center,class:^(Vncviewer)$"
        "float,class:^(Viewnior)$"
        "center,class:^(Viewnior)$"
        "size 1200 800,class:^(Viewnior)$"
        "float,class:^(imv)$"
        "center,class:^(imv)$"
        "size 1200 725,class:^(imv)$"
        "tile,class:^(Aseprite)$"
        "float,class:^(audacious)$"
        "pin,class:^(rofi)$"
        "pin,class:^(waypaper)$"
        "tile,class:^(neovide)$"
        "float,class:^(udiskie)$"
        "float,title:^(Transmission)$"
        "float,title:^(Volume Control)$"
        "float,title:^(Firefox — Sharing Indicator)$"
        "move 0 0,title:^(Firefox — Sharing Indicator)$"
        "size 700 450,title:^(Volume Control)$"
        "move 40 55%,title:^(Volume Control)$"
        # Legacy Window Rules
        "float,class:^(scratchpad)$"
        "center,class:^(scratchpad)$"
        "float,class:^(kitty-scratch)$"
        "size 75% 60%,class:^(kitty-scratch)$"
        "center,class:^(kitty-scratch)$"
        "float,class:^(htop)$"
        "size 80% 80%,class:^(htop)$"
        "center,class:^(htop)$"
        "float,class:^(ranger)$"
        "size 75% 60%,class:^(ranger)$"
        "center,class:^(ranger)$"
        "float,class:^(yazi)$"
        "center,class:^(yazi)$"
        "float,class:^(notes)$"
        "size 70% 50%,class:^(notes)$"
        "center,class:^(notes)$"
        "float,class:^(anote)$"
        "center,class:^(anote)$"
        "size 1536 864,class:^(anote)$"
        "animation slide,class:^(anote)$"
        "opacity 0.95 0.95,class:^(anote)$"
        "float,class:^(otpclient)$"
        "size 20%,class:^(otpclient)$"
        "move 79% 40%,class:^(otpclient)$"
        "opacity 1.0 1.0,class:^(otpclient)$"
        "float,class:^(gcr-prompter)$"
        "center,class:^(gcr-prompter)$"
        "pin,class:^(gcr-prompter)$"

        # Workspace Assignments
        #"workspace 1 silent,class:^(Kenp)$"
        "workspace 1,class:^(zen)$"
        "workspace 2 silent,class:^(Tmux)$,title:^(Tmux)$"
        "workspace 2 silent,class:^(TmuxKenp)$"
        "workspace 3 silent,class:^(AI)$"
        "workspace 3,class:^(evince)$"
        "workspace 4 silent,class:^(CompecTA)$"
        "workspace 4 silent,title:^(compecta)$"
        "workspace 4,class:^(Gimp-2.10)$"
        "workspace 4,class:^(Aseprite)$"
        "workspace 5 silent,class:^(Discord)$"
        "workspace 5,class:^(WebCord)$"
        "workspace 5 silent,tile,class:^(discord)$"
        "workspace 5,class:^(Audacious)$"
        "workspace 6 silent,class:^(Kenp)$,title:^(Zen Browser Private Browsing)$"
        "workspace 6 silent,title:^(New Private Tab - Brave)$"
        #"workspace 6 silent,title:^(youtube.com)$"
        "workspace 6 silent,class:^(qemu-system-x86_64)$"
        "workspace 6 silent,class:^(qemu)$"
        "workspace 7 silent,class:^(org.keepassxc.KeePassXC)$"
        "workspace 7 silent,class:^(com.transmissionbt.transmission.*)$"
        "workspace 7 silent,title:^(brave-youtube.com__-Default)$"
        "workspace 8 silent,class:^(Spotify)$"
        "workspace 8 silent,class:^(Brave-browser)$,title:^(Spotify - Web Player).*"
        "workspace 8,class:^(com.obsproject.Studio)$"
        "workspace 9 silent,class:^(Whats)$"
        "workspace 9 silent,title:^(web.whatsapp.com)$ class:^(Brave-browser)$"
        "workspace 9 silent,title:^(web.whatsapp.com)$"

        # Floating Windows
        "float,class:^(clipb)$"
        "float,class:^(dropdown)$"
        "float,class:^(waypaper)$"
        "float,class:^(zenity)$"
        "float,class:^(org.gnome.FileRoller)$"
        "float,class:^(SoundWireServer)$"
        "float,class:^(.sameboy-wrapped)$"
        "float,class:^(file_progress)$"
        "float,class:^(confirm)$"
        "float,class:^(dialog)$"
        "float,class:^(download)$"
        "float,class:^(notification)$"
        "float,class:^(error)$"
        "float,class:^(confirmreset)$"
        "float,title:^(Open File)$"
        "float,title:^(File Upload)$"
        "float,title:^(branchdialog)$"
        "float,title:^(Confirm to replace files)$"
        "float,title:^(File Operation Progress)$"
        "float,title:^(Picture-in-Picture)$"

        # Size and Position Rules
        "size 1920 1080,class:^(yazi)$"
        "size 1536 864,class:^(clipb)$"
        "size 850 500,class:^(zenity)$"
        "size 850 500,class:^(org.gnome.FileRoller)$"
        "size 850 500,title:^(File Upload)$"
        "size 99% 50%,class:^(dropdown)$"
        "move 0.5% 3%,class:^(dropdown)$"
        "center,class:^(clipb)$"
        "center,class:^(zenity)$"
        "center,class:^(org.gnome.FileRoller)$"

        # Animation and Visual Effects
        "animation slide,class:^(clipb)$"
        "opacity 1.0 override 1.0 override,title:^(Picture-in-Picture)$"
        "opacity 1.0 override 1.0 override,title:^(.*imv.*)$"
        "opacity 1.0 override 1.0 override,title:^(.*mpv.*)$"
        "opacity 1.0 override 1.0 override,class:^(mpv)$"
        "opacity 1.0 override 1.0 override,class:^(Aseprite)$"
        "opacity 1.0 override 1.0 override,class:^(Unity)$"
        "opacity 1.0 override 1.0 override,class:^(zen)$"
        "opacity 1.0 override 1.0 override,class:^(evince)$"
        "opacity 0.0 override,class:^(xwaylandvideobridge)$"
        "opacity 1.0 override 1.0 override,class:^(kitty)$"
        "opacity 1.0 override 1.0 override,class:^(foot)$"
        "opacity 1.0 override 1.0 override,class:^(Alacritty)$"

        # Special Behaviors
        "pin,title:^(Picture-in-Picture)$"
        "idleinhibit focus,class:^(mpv)$"
        "idleinhibit fullscreen,class:^(firefox)$"
        "noanim,class:^(xwaylandvideobridge)$"
        "noinitialfocus,class:^(xwaylandvideobridge)$"
        "maxsize 1 1,class:^(xwaylandvideobridge)$"
        "noblur,class:^(xwaylandvideobridge)$"
        "workspace special:dropdown,class:^(dropdown)$"

        # No gaps when only
        "bordersize 0,floating:0,onworkspace:w[t1]"
        "rounding 0,floating:0,onworkspace:w[t1]"
        "bordersize 0,floating:0,onworkspace:w[tg1]"
        "rounding 0,floating:0,onworkspace:w[tg1]"
        "bordersize 0,floating:0,onworkspace:f[1]"
        "rounding 0,floating:0,onworkspace:f[1]"

        # Context Menu Rules
        "opaque,class:^()$,title:^()$"
        "noshadow,class:^()$,title:^()$"
        "noblur,class:^()$,title:^()$"

        # Copyq
        "float,class:^(com.github.hluk.copyq)$"
        "size 25% 80%,class:^(com.github.hluk.copyq)$"
        "move 74% 10%,class:^(com.github.hluk.copyq)$"
        "animation popout,class:^(com.github.hluk.copyq)$"
        "dimaround,class:^(com.github.hluk.copyq)$"

        # VNC
        "workspace 6,class:^(Vncviewer)$,title:^(.*TigerVNC)$"
        "fullscreen,class:^(Vncviewer)$,title:^(.*TigerVNC)$"

        # Pavucontrol
        "float,class:^(org.pulseaudio.pavucontrol)$"
        "size 60% 90%,class:^(org.pulseaudio.pavucontrol)$" 
        "animation popin,class:^(org.pulseaudio.pavucontrol)$"
        "dimaround,class:^(org.pulseaudio.pavucontrol)$"

        # VLC
        "float,class:^(vlc)$"
        "size 800 1250,class:^(vlc)$"
        "move 1700 90,class:^(vlc)$"
        "workspace 6,class:^(vlc)$"
        "pin,class:^(vlc)$"

        # ente
        "float,class:^(io.ente.auth)$"
        "size 400 900,class:^(io.ente.auth)$"
        "center,class:^(io.ente.auth)$"

        # webcord warning dialog
        "float,class:^(WebCord)$,title:^(Warning: Opening link in external app)$"
        "center,class:^(WebCord)$,title:^(Warning: Opening link in external app)$"
        "float,title:^(blob:https://discord.com).*$"
        "center,title:^(blob:https://discord.com).*$"
        "animation popin,title:^(blob:https://discord.com).*$"

        # Meet
        "float,title:^(Meet).*$"
        "size 918 558,title:^(Meet).*$"
        "workspace 4,title:^(Meet).*$"
        "center,title:^(Meet).*$"

        # org.twosheds.iwgtk
        "float,class:^(org.twosheds.iwgtk)$"
        "size 1536 864,class:^(org.twosheds.iwgtk)$"
        "center,class:^(org.twosheds.iwgtk)$"
        "float,class:^(iwgtk)$"
        "size 360 440,class:^(iwgtk)$"
        "center,class:^(iwgtk)$"

        "float,class:^(gcr-prompter)$"
        "center,class:^(gcr-prompter)$"
        "pin,class:^(gcr-prompter)$"
        "animation fade,class:^(gcr-prompter)$"
        "opacity 0.95 0.95,class:^(gcr-prompter)$"
      ];

      # No gaps workspace rules
      workspace = [
        "w[1], gapsout:0, gapsin:0"
        "w[2], gapsout:0, gapsin:0"
      ];

      # Key Bindings
      bind = [
        # show keybinds list
        "$mainMod, F1, exec, rofi-hypr-keybinds"

        # Terminal Emülatörleri
        "$mainMod, Return, exec, kitty"                                                 # Normal mod
        "ALT, Return, exec, [float; center; size 950 650] kitty"                        # Yüzen mod
        "$mainMod SHIFT, Return, exec, [fullscreen] kitty"                              # Tam ekran mod
        #"$mainMod, Return, exec, wezterm"
        #"ALT, Return, exec, [float; center; size 950 650] wezterm"
        #"$mainMod SHIFT, Return, exec, [fullscreen] wezterm"

        # Temel Pencere Yönetimi
        "$mainMod, Q, killactive"                                                     # Pencere kapat
        "ALT, F4, killactive"                                                         # Alternatif kapat
        "$mainMod SHIFT, F, fullscreen, 1"                                            # Sahte tam ekran
        "$mainMod CTRL, F, fullscreen, 0"                                             # Gerçek tam ekran
        "$mainMod, F, exec, toggle_float"                                             # Yüzen mod toggle
        "$mainMod, P, pseudo,"                                                        # Pseudo mod
        "$mainMod, X, togglesplit,"                                                   # Bölme toggle
        "$mainMod, G, togglegroup"                                                    # Grup toggle
        "$mainMod, T, exec, toggle_oppacity"                                          # Opaklık toggle

        # Uygulama Başlatıcılar
        "$mainMod, Space, exec, rofi-launcher || pkill rofi"                          # Rofi
        "ALT, Space, exec, walker"                                                    # Walker
        "$mainMod ALT, Space, exec, ulauncher-toggle"                                 # Ulauncher
        "ALT, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] kitty yazi'"  # Terminal dosya yönetici
        "ALT CTRL, F, exec, hyprctl dispatch exec '[float; center; size 1111 700] nemo'"   # Dosya yönetici

        # Medya ve Ses Kontrolü
        "ALT, A, exec, osc-soundctl switch"                                           # Ses değiştirici
        "ALT, E, exec, hypr-spotify_toggle"                                           # Spotify toggle
        "ALT CTRL, N, exec, spotifycli --next"                                        # Spotify next
        "ALT CTRL, B, exec, spotifycli --prev"                                        # Spotify prev 
        "ALT CTRL, E, exec, mpc-control toggle"                                       # MPC kontrolü
        #"ALT, i, exec, osc-vradio"                                                    # Virgin radio toggle
        "ALT, i, exec, hypr-vlc_toggle"                                               # VLC toggle

        # MPV Yönetimi
        "CTRL ALT, 1, exec, hypr-mpv-manager start"                                   # MPV başlat
        "ALT, 1, exec, hypr-mpv-manager playback"                                     # Oynatma kontrolü
        "ALT, 2, exec, hypr-mpv-manager play-yt"                                      # YouTube oynat
        "ALT, 3, exec, hypr-mpv-manager stick"                                        # Yapıştır
        "ALT, 4, exec, hypr-mpv-manager move"                                         # Taşı
        "ALT, 5, exec, hypr-mpv-manager save-yt"                                      # YouTube kaydet
        "ALT, 6, exec, hypr-mpv-manager wallpaper"                                    # Duvar kağıdı yap

        # Duvar Kağıdı Yönetimi
        "$mainMod, W, exec, wallpaper-manager select"                                 # Duvar kağıdı seç
        "ALT, 0, exec, wallpaper-manager"                                             # Rastgele duvar kağıdı
        "$mainMod SHIFT, W, exec, hyprctl dispatch exec '[float; center; size 925 615] waypaper'" # Waypaper

        # Sistem Araçları
        "ALT, L, exec, hyprlock"                                                     # Ekran kilidi
        "$mainMod, backspace, exec, power-menu"                                      # Güç menüsü
        "$mainMod, C, exec, hyprpicker -a"                                           # Renk seçici
        "$mainMod, N, exec, swaync-client -t -sw"                                    # Bildirim merkezi
        "$mainMod CTRL, Escape, exec, hyprctl dispatch exec '[workspace 12] resources'" # Sistem monitörü

        # Monitör ve Ekran Yönetimi
        "$mainMod, Escape, exec, pypr shift_monitors +1 || hypr-ctl_focusmonitor"    # Monitör değiştir
        "$mainMod, A, exec, hypr-ctl_focusmonitor"                                   # Monitör odakla
        "$mainMod, E, exec, pypr shift_monitors +1"                                  # Monitör kaydır
        "$mainMod SHIFT, B, exec, toggle_waybar"                                     # Waybar toggle

        # Özel Uygulamalar
        "$mainMod SHIFT, D, exec, webcord --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "$mainMod SHIFT, K, exec, hyprctl dispatch exec '[workspace 1 silent] start-zen-kenp'"
        "$mainMod SHIFT, C, exec, hyprctl dispatch exec '[workspace 4 silent] start-zen-compecta'"
        "$mainMod SHIFT, S, exec, hyprctl dispatch exec '[workspace 8 silent] start-spotify'"
        "$mainMod SHIFT, X, exec, hyprctl dispatch exec '[workspace 11 silent] SoundWireServer'"
        "ALT CTRL, W, exec, whatsie -w"
        "ALT, T, exec, start-kkenp"
        "ALT CTRL, C, exec, start-mkenp"
        "$mainMod ALT, RETURN, exec, osc-start-all"

        # Sistem Fonksiyonları
        ",F10, exec, hypr-bluetooth_toggle"                                         # Bluetooth toggle
        "ALT, F12, exec, hypr-mullvad_toggle toggle"                                # VPN toggle
        "ALT, F9, exec, hypr-blue-gammastep-manager toggle"                         # Gammastep
        ",F9, exec, hypr-blue-hyprsunset-manager toggle"                            # Hyprsunset
        "$mainMod, M, exec, anotes"                               # Not yöneticisi
        "$mainMod CTRL, M, exec, anotes -t"                       # Not yöneticisi
        "$mainMod, B, exec, hypr-start-manager tcopyb"                              # Kopyalama yöneticisi

        # Screenshot v1.2.0 Kısayolları
        ",Print, exec, screenshot ri"                  # Print: Bölge Interaktif (düzenleyicide açar)
        "$mainMod SHIFT, Print, exec, screenshot rf"   # Super + Shift + Print: Bölge Dosya (dosyaya kaydeder)
        "CTRL, Print, exec, screenshot rc"             # Ctrl + Print: Bölge Kopyala (panoya kopyalar)
        "$mainMod CTRL, Print, exec, screenshot rec"   # Super + Ctrl + Print: Bölge Düzenle ve Kopyala
        "$mainMod, Print, exec, screenshot si"         # Super + Print: Ekran Interaktif (düzenleyicide açar)
        "SHIFT, Print, exec, screenshot sf"            # Shift + Print: Ekran Dosya (dosyaya kaydeder)
        "CTRL SHIFT, Print, exec, screenshot sc"       # Ctrl + Shift + Print: Ekran Kopyala (panoya kopyalar)
        "$mainMod SHIFT CTRL, Print, exec, screenshot sec" # Super + Shift + Ctrl + Print: Ekran Düzenle ve Kopyala
        "ALT, Print, exec, screenshot wi"              # Alt + Print: Pencere Interaktif (düzenleyicide açar)
        "ALT SHIFT, Print, exec, screenshot wf"        # Alt + Shift + Print: Pencere Dosya (dosyaya kaydeder)
        "ALT CTRL, Print, exec, screenshot wc"         # Alt + Ctrl + Print: Pencere Kopyala (panoya kopyalar)
        "$mainMod ALT, Print, exec, screenshot p"      # Super + Alt + Print: Renk seçer
        "$mainMod ALT CTRL, Print, exec, screenshot o" # Super + Alt + Ctrl + Print: Son ekran görüntüsünü açar

        # switch focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"

        # switch workspace
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"

        # same as above, but switch to the workspace
        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod CTRL, c, movetoworkspace, empty"

        # window control
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, j, movewindow, d"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, l, movewindow, r"

        "$mainMod CTRL, left, resizeactive, -80 0"
        "$mainMod CTRL, right, resizeactive, 80 0"
        "$mainMod CTRL, up, resizeactive, 0 -80"
        "$mainMod CTRL, down, resizeactive, 0 80"
        "$mainMod CTRL, h, resizeactive, -80 0"
        "$mainMod CTRL, j, resizeactive, 0 80"
        "$mainMod CTRL, k, resizeactive, 0 -80"
        "$mainMod CTRL, l, resizeactive, 80 0"

        "$mainMod ALT, left, moveactive,  -80 0"
        "$mainMod ALT, right, moveactive, 80 0"
        "$mainMod ALT, up, moveactive, 0 -80"
        "$mainMod ALT, down, moveactive, 0 80"
        "$mainMod ALT, h, moveactive,  -80 0"
        "$mainMod ALT, j, moveactive, 0 80"
        "$mainMod ALT, k, moveactive, 0 -80"
        "$mainMod ALT, l, moveactive, 80 0"

        # media and volume controls
        ",XF86AudioPlay,exec, playerctl play-pause"
        ",XF86AudioNext,exec, playerctl next"
        ",XF86AudioPrev,exec, playerctl previous"
        ",XF86AudioStop,exec, playerctl stop"

        "$mainMod, mouse_down, workspace, e-1"
        "$mainMod, mouse_up, workspace, e+1"

        # clipboard manager
        "$mainMod, V, exec, copyq toggle"
        "$mainMod CTRL, V, exec, cliphist list | rofi -dmenu -theme-str 'window {width: 50%;} listview {columns: 1;}' | cliphist decode | wl-copy"

        # Ana Pencere Yönetimi
        "$mainMod CTRL, RETURN, layoutmsg, swapwithmaster" # Aktif pencereyi ana pencere ile takas et

        # Temel Çalışma Alanı Navigasyonu
        "ALT, N, workspace, previous"              # Önceki çalışma alanına dön
        "ALT, Tab, workspace, e+1"                 # Bir sonraki çalışma alanına geç
        "ALT CTRL, tab, workspace, e-1"            # Bir önceki çalışma alanına geç

        # Döngüsel Çalışma Alanı Gezinme
        "$mainMod, page_up, exec, hypr-workspace-monitor -wl"   # Sola doğru döngüsel geçiş
        "$mainMod, page_down, exec, hypr-workspace-monitor -wr" # Sağa doğru döngüsel geçiş

        # Pencere Navigasyonu ve Yönetimi
        "$mainMod, Tab, cyclenext"                 # Aynı çalışma alanındaki bir sonraki pencereye geç
        "$mainMod, Tab, bringactivetotop"          # Aktif pencereyi en üste getir
        "$mainMod, Tab, changegroupactive"         # Pencere grubu içinde aktif pencereyi değiştir

        # Pencere Bölme ve Boyutlandırma
        "$mainMod ALT, right, exec, hyprctl dispatch splitratio -0.2"   # Sol bölme oranını azalt
        "$mainMod ALT, left, exec, hyprctl dispatch splitratio +0.2"  # Sağ bölme oranını artır
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };

    # =====================================================
    # Ek Yapılandırma ve Monitor Ayarları
    # =====================================================
    extraConfig = ''
      # Monitor tanımlamaları
      monitor=desc:Dell Inc. DELL UP2716D KRXTR88N909L,2560x1440@59,0x0,1
      monitor=desc:AU Optronics 0x2036,1920x1080@60,320x1440,1

      # Çalışma alanı atamaları
      workspace = 1, monitor:DELL UP2716D KRXTR88N909L,1, default:true
      workspace = 2, monitor:DELL UP2716D KRXTR88N909L,2
      workspace = 3, monitor:DELL UP2716D KRXTR88N909L,3
      workspace = 4, monitor:DELL UP2716D KRXTR88N909L,4
      workspace = 5, monitor:DELL UP2716D KRXTR88N909L,5
      workspace = 6, monitor:DELL UP2716D KRXTR88N909L,6
      workspace = 7, monitor:AU Optronics 0x2036,7, default:true
      workspace = 8, monitor:AU Optronics 0x2036,8
      workspace = 9, monitor:AU Optronics 0x2036,9

      # XWayland ayarları
      xwayland {
        force_zero_scaling = true
      }
    '';
  };
}
