# modules/core/display/default.nix
# ==============================================================================
# AMAÇ (Neden tek dosya?):
# - Masaüstüyle ilgili **dağıtık** ayarları (görüntü, portal, font, ses) tek
#   yerde toplamak; böylece “nerede ne vardı?” araması bitti.
# - GNOME (GDM+Wayland) ve Hyprland’i **yan yana** kullanırken tipik çakışmaları
#   (özellikle XDG portal ve font/emoji sorunları) **baştan önlemek**.
#
# TASARIM İLKELERİ:
# 1) **Hyprland öncelikli portal**: Hyprland oturumunda hyprland portalı aktif,
#    ortak durumlarda GTK portal varsayılan. Böylece `xdg-open` ve ekran paylaşımı
#    gibi çağrılar doğru backend’e gider (Wayland ekran paylaşımı için kritik).
# 2) **Xorg açık ama “uyumluluk için”**: GNOME + Hyprland Wayland’la çalışır;
#    Xorg sadece “bazı uygulamalar” için fallback’tir (NixOS dünyasında olağan).
# 3) **PipeWire merkezi ses yığını**: ALSA/Pulse uyumluluğu PipeWire üzerinden
#    sağlanır; JACK devre dışı (ihtiyaç varsa açarsın). `rtkit` güvenlik modülünde
#    aktif olduğundan gecikme/öncelikler düzgün çalışır.
# 4) **Fontconfig “temkinli”**: Uygulamalara sans/serif seçimini bırakıp,
#    **monospace** ve **emoji** tarafını net şekilde yönetiyoruz. `localConf` yok,
#    çünkü Mako bildirimlerinde emoji’lerle çakışma yaşanmıştı (kanıtlı).
# 5) **Yorumlar canlı belge**: Her bloğun “NEDEN/NASIL” açıklaması var; bakıp
#    hızlıca karar verebilirsin (örn. JACK açma, portal değiştirme vb.)
#
# KAYNAK ÇAKIŞMALARINI ÖNLEME:
# - Hyprland portalı **programs.hyprland.portalPackage** ile verildi; ayrıca
#   `extraPortals`’a eklemedik (çifte kayıt ve rasgele seçim olmasın).
# - GNOME keyring ve libinput burada; PAM/Güvenlik ayarları **security** modülünde.
# - Font env değişkenleri hem sistem hem HM katmanında **aynı** (debug kolaylığı).
#
# SONUÇ:
# - “display + fonts + xdg + audio” üç farklı dosya yerine **tek modül**.
# - `modules/core/default.nix` içinden `./fonts`, `./xdg`, `./audio` import’larını
#   kaldır; **sadece `./display`** kalsın.
#
# Author: Kenan Pelit
# Last merged: 2025-09-03
# ==============================================================================

{ username, inputs, pkgs, lib, ... }:
let
  # Hyprland paketleri (flake input'undan). Neden input?
  # - Sistemdeki hyprland versiyonunu kilitlemek, portal eşleşmesini garanti etmek.
  hyprlandPkg = inputs.hyprland.packages.${pkgs.system}.default;
  hyprPortal  = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
in
{
  # =============================================================================
  # WAYLAND COMPOSITOR — HYPRLAND
  # =============================================================================
  # NEDEN: Hyprland modern bir Wayland compositor. GNOME ile birlikte kurulduğunda,
  # portal önceliklerinin doğru yönlenmesi (özellikle ekran paylaşımı ve xdg-open)
  # kritik hale gelir. Burada portal paketi doğrudan Hyprland tarafında tanımlı.
  programs.hyprland = {
    enable = true;
    package = hyprlandPkg;
    portalPackage = hyprPortal;  # HYPRLAND PORTALI BURADA — extraPortals’a da koyma.
  };

  # =============================================================================
  # GÖRÜNTÜ YIĞINI + DM/DE + GİRİŞ CİHAZLARI + KEYRING
  # =============================================================================
  # NEDEN: GNOME (DE) ve GDM (DM) Wayland’da sorunsuz; Xorg uyumluluk için açık.
  # libinput genel giriş cihazı sürücüsü. GNOME Keyring oturum gizli anahtarları
  # için standart (SSH/GPG entegrasyonlarıyla uyumlu).
  services = {
    # Xorg (fallback)
    xserver = {
      enable = true;
      xkb = {
        layout = "tr";        # Tutarlılık için masaüstü ve konsol aynı harita
        variant = "f";        # TR-F
        options = "ctrl:nocaps";  # Caps'i Control yap — kas hafızası için ideal
      };
    };

    # Display Manager (GDM) — Wayland açık
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;       # GNOME + Wayland birincil
      };
      autoLogin.enable = false; # Güvenlik için otomatik giriş kapalı (isteğe bağlı)
    };

    # Masaüstü ortamı: GNOME (Wayland)
    desktopManager.gnome.enable = true;

    # Giriş cihazları (touchpad/klavye/scroll vs.)
    libinput.enable = true;

    # Oturum anahtarlığı/kimlik kasası
    gnome.gnome-keyring.enable = true;

    # -----------------------------------------------------------------------------
    # SES YIĞINI — PIPEWIRE
    # -----------------------------------------------------------------------------
    # NEDEN: PipeWire modern ses/video yöneticisi; PulseAudio/ALSA ile uyumlu.
    # JACK devre dışı (gerektikçe aç), aksi takdirde stüdyo dışı kullanımda
    # karmaşıklık katar. rtkit security modülünde açık → düşük gecikme/öncelik.
    pipewire = {
      enable = true;

      # ALSA katmanı (native + 32-bit)
      alsa.enable = true;
      alsa.support32Bit = true;

      # PulseAudio uyumluluğu
      pulse.enable = true;

      # Stüdyo amaçlı değilse JACK kapalı; DAW kullanıyorsan true yap.
      jack.enable = false;
    };
  };

  # =============================================================================
  # XDG PORTALS — “Doğru Uygulama, Doğru Portal”
  # =============================================================================
  # NEDEN: xdg-desktop-portal, uygulamaların (Flatpak/native) ekran paylaşımı,
  # dosya seçimi, dış link açma gibi işleri “oturuma uygun” arka uçla yapmasını
  # sağlar. Hyprland oturumunda hyprland portalı, diğer durumda GTK varsayılan.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true; # `xdg-open` → portal üzerinden aç (Wayland’da güvenli)

    # Varsayılanlar: hyprland oturumunda "hyprland" portalı devreye girer.
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [ "gtk" "hyprland" ];
    };

    # Hyprland portalını **programs.hyprland.portalPackage** sağlıyor.
    # Buraya sadece GTK portalını ekliyoruz.
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # =============================================================================
  # GNOME WAYLAND SESSION DOSYALARI — LAUNCHER/SESSION TANIMLARI
  # =============================================================================
  # NEDEN: Bazı kurulumlarda GNOME Wayland session dosyalarını açıkça koymak
  # oturum seçicide tutarlılık sağlar (özellikle custom DM/kurulum varyantlarında).
  environment.etc = {
    "wayland-sessions/gnome.desktop".text = ''
      [Desktop Entry]
      Name=GNOME
      Comment=This session logs you into GNOME
      Exec=gnome-session
      Type=Application
      DesktopNames=GNOME
    '';

    "xdg/gnome-session/sessions/gnome.session".text = ''
      [GNOME Session]
      Name=GNOME
      RequiredComponents=org.gnome.Shell;org.gnome.SettingsDaemon.A11ySettings;org.gnome.SettingsDaemon.Color;org.gnome.SettingsDaemon.Datetime;org.gnome.SettingsDaemon.Housekeeping;org.gnome.SettingsDaemon.Keyboard;org.gnome.SettingsDaemon.MediaKeys;org.gnome.SettingsDaemon.Power;org.gnome.SettingsDaemon.PrintNotifications;org.gnome.SettingsDaemon.Rfkill;org.gnome.SettingsDaemon.ScreensaverProxy;org.gnome.SettingsDaemon.Sharing;org.gnome.SettingsDaemon.Smartcard;org.gnome.SettingsDaemon.Sound;org.gnome.SettingsDaemon.UsbProtection;org.gnome.SettingsDaemon.Wacom;org.gnome.SettingsDaemon.XSettings;
    '';
  };

  # =============================================================================
  # FONTLAR (Sistem) — “Önce Monospace & Emoji” Stratejisi
  # =============================================================================
  # NEDEN: Uygulamaların çoğu kendi sans/serif tercihleriyle geliyor. Biz
  # monospace ve emoji’yi garanti altına alıp, geniş kapsayıcı paketlerle
  # (Noto + CJK + Emoji) “her karakter görünsün” hedefliyoruz. Mako testleri
  # maplenf/hack/emoji kombinasyonunun sorunsuz olduğunu doğruladı.
  fonts = {
    packages = with pkgs; [
      # ÇEKİRDEK (Mako ile test edildi)
      maple-mono.NF
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      cascadia-code
      inter
      font-awesome

      # Güvenli genişleme
      source-code-pro
      dejavu_fonts
      noto-fonts-cjk-serif
      noto-fonts-extra
      material-design-icons

      # Modern favoriler
      jetbrains-mono
      ubuntu_font_family
      roboto
      open-sans
    ];

    fontconfig = {
      # Varsayılanlar: monospace ve emoji’yi sağlamlaştır, diğerlerini makul tut.
      defaultFonts = {
        monospace = [
          "Maple Mono NF"
          "Hack Nerd Font Mono"
          "JetBrains Mono"
          "Fira Code"
          "Source Code Pro"
          "Liberation Mono"
          "Noto Color Emoji"
        ];
        emoji = [ "Noto Color Emoji" ];
        serif = [ "Liberation Serif" "Noto Serif" "DejaVu Serif" ];
        sansSerif = [ "Liberation Sans" "Inter" "Noto Sans" "DejaVu Sans" ];
      };

      # Subpixel/LCD filtre — çoğu modern panelde “rgb” en net sonuç verir.
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      # Hinting — “slight” modern ekranlarda güzel denge.
      hinting = {
        enable = true;
        autohint = false;  # Otomatik değil; fontun kendi hint’leri tercih.
        style = "slight";
      };

      antialias = true;

      # ÖNEMLİ: localConf kapalı. Mako emoji rendering’ini bozabiliyor. Eğer
      # XML ile özelleştirme yapman gerekirse, önce Mako testi çalıştır:
      #  $ mako-emoji-test
      # ve değişikliği geri almayı kolaylaştıracak şekilde küçük adımlarla ilerle.
      # localConf = '' ... '';
    };

    enableDefaultPackages = true; # Nixpkgs varsayılan font ekleri
    fontDir.enable = true;        # Font dizinlerinin sisteme linklenmesi
  };

  # =============================================================================
  # SİSTEM ORTAMI — Fontlar için yararlı env değişkenleri
  # =============================================================================
  # NEDEN: Bazı uygulamalar/kitaplıklar explicit env değişkenleri arıyor; debug
  # ve deterministik davranış için sistemde sabitliyoruz. (HM’de de ayna değerler.)
  environment = {
    variables = {
      FONTCONFIG_PATH = "/etc/fonts";                    # Sistem fontconf yolu
      LC_ALL = "en_US.UTF-8";                            # Emoji/çoklu dil güvenliği
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40"; # Render tutarlılığı
      FONTCONFIG_FILE = "/etc/fonts/fonts.conf";         # Ana fontconf
    };

    systemPackages = with pkgs; [
      fontconfig     # fc-list, fc-match vb.
      font-manager   # GUI’yle hızlı göz atma
    ];
  };

  # =============================================================================
  # HOME-MANAGER — Kullanıcı tarafı ayarlar/araçlar
  # =============================================================================
  # NEDEN: Kullanıcı oturumunda font debug/test ve launcherlarda tutarlılık.
  # Rofi’de fontu net veriyoruz; terminali kitty olarak işaretliyoruz.
  home-manager.users.${username} = {
    home.stateVersion = "25.11";

    fonts.fontconfig.enable = true;

    programs.rofi = {
      font = "Hack Nerd Font 13";
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    home.shellAliases = {
      # Hızlı teşhis
      "font-list"        = "fc-list";
      "font-emoji"       = "fc-list | grep -i emoji";
      "font-nerd"        = "fc-list | grep -i 'nerd\\|hack\\|maple'";
      "font-maple"       = "fc-list | grep -i maple";
      "font-reload"      = "fc-cache -f -v";

      # Hızlı görsel testler
      "font-test"        = "echo 'Font Test: Hack Nerd Font with ★ ♪ ● ⚡ ▲ symbols and emoji support'";
      "emoji-test"       = "echo '🎵 📱 💬 🔥 ⭐ 🚀 - Color emoji test'";
      "mako-emoji-test"  = "notify-send 'Emoji Test 🚀' 'Mako notification with emojis: 📱 💬 🔥 ⭐ 🎵'";
      "mako-font-test"   = "notify-send 'Font Test' 'Maple Mono NF with symbols: ★ ♪ ● ⚡ ▲'";
      "mako-icons-test"  = "notify-send 'Icon Test' 'Nerd Font icons:     󰈹 󰍛'";

      # Derin teşhis
      "font-info"        = "fc-match -v";
      "font-debug"       = "fc-match -s monospace | head -5";
      "font-mono"        = "fc-list : family | grep -i mono | sort";
      "font-available"   = "fc-list : family | sort | uniq";
      "font-cache-clean" = "fc-cache -f -r -v";
      "font-render-test" = "echo 'Rendering Test: ABCDabcd1234 ★♪●⚡▲ 🚀📱💬'";
      "font-ligature-test" = "echo 'Ligature Test: -> => != === >= <= && || /* */ //'";
      "font-nerd-icons"  = "echo 'Nerd Icons:     󰈹 󰍛'";
    };

    home.sessionVariables = {
      # Sistemle aynı; debugging kolaylığı
      LC_ALL = "en_US.UTF-8";
      FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      FONTCONFIG_PATH = "/etc/fonts:~/.config/fontconfig";
    };

    home.packages = with pkgs; [
      fontpreview
      gucharmap
    ];
  };
}
