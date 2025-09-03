# modules/core/account/default.nix
# ==============================================================================
# NİYET:
# - Kullanıcı hesabı, gruplar, sudo yetkileri TEK YERDEN yönetilsin.
# - Kullanıcıya bağlı home-manager profili aynı modülde tanımlansın.
# - DBus/Keyring gibi sistem servisleri account’a değil, `services` modülüne ait.
#
# TEK OTORİTE İLKELERİ:
# - users.users / sudo      → BURADA (account)
#
# Author: Kenan Pelit
# Last updated: 2025-09-03
# ==============================================================================

{ pkgs, lib, username, config, inputs, host, ... }:

{
  # ----------------------------------------------------------------------------
  # Modül opsiyonları — İstersen UID’i host’a göre override edebilirsin.
  # ----------------------------------------------------------------------------
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "The primary user account name.";
    };
    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID for the primary user.";
    };
  };

  config = {
    # ==========================================================================
    # Kullanıcı hesabı ve gruplar — TEK otorite
    # ==========================================================================
    users.users.${username} = {
      isNormalUser = true;
      description  = username;
      uid          = config.my.user.uid;
      shell        = pkgs.zsh;

      # NOT: Bu liste, daha önce services/default.nix içinde de ekleniyordu.
      # Artık grupların TEK otoritesi burası; services içindeki extraGroups satırını sil.
      extraGroups = [
        # Sistem / yönetim
        "wheel"            # sudo
        "networkmanager"   # NM izinleri
        "storage"

        # Donanım / I/O
        "input"
        "audio"
        "video"

        # Sanallaştırma
        "libvirtd"
        "kvm"
        "docker"
      ];
    };

    # ==========================================================================
    # Sudo — wheel parolasız (bilinçli tercih)
    # ==========================================================================
    security.sudo.wheelNeedsPassword = false;

    # ==========================================================================
    # Home-Manager — kullanıcı profili
    # ==========================================================================
    # NEDEN BURADA?: Kullanıcıyı tanımladığın yerde HM profilini de bağlamak
    # pratik. HM’nin import ettiği ./modules/home dizini kullanıcı ortamını
    # (rofi, kitty, waybar, vs.) yönetiyor.
    home-manager = {
      useUserPackages      = true;
      useGlobalPkgs        = true;
      backupFileExtension  = "backup";
      extraSpecialArgs     = { inherit inputs username host; };

      users.${username} = {
        # Bu import, senin repo yapına göre: modules/home (iki düzey yukarı).
        # Mevcut yapında zaten buraya işaret ediyor.
        imports = [ ../../home ];
        home = {
          username     = username;
          homeDirectory= "/home/${username}";
          stateVersion = "25.11";
        };
      };
    };

    # ----------------------------------------------------------------------------
    # DİKKAT: DBus/Keyring gibi servisleri account’a koymuyoruz.
    # Bunlar `modules/core/services/default.nix` içinde:
    #   services.dbus.enable = true;
    #   services.dbus.packages = [ pkgs.gcr gnome-keyring ];
    #   (GNOME Keyring enable, display modülünde ya da services’te yönetilebilir)
    # ----------------------------------------------------------------------------
  };
}


