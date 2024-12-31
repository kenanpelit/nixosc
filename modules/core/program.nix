{ pkgs, lib, ... }: {
  programs = {
    # dconf ve zsh ayarları
    dconf.enable = true;
    zsh.enable = true;

    # GnuPG ayarı - SSH desteğini devre dışı bırakıyoruz
    gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
    };

    # Vim ve nano'yu devre dışı bırak
    vim.enable = false;
    nano.enable = false;

    # nix-ld yapılandırması
    nix-ld = {
      enable = true;
      libraries = with pkgs; [];
    };

    # SSH yapılandırması
    ssh = {
      startAgent = true;
      enableAskPassword = false;
      extraConfig = ''
        Host *
          ServerAliveInterval 60
          ServerAliveCountMax 2
          ControlMaster auto
          ControlPath ~/.ssh/controlmasters/%r@%h:%p
          ControlPersist 5m
          ProxyCommand /run/current-system/sw/bin/assh connect --port=%p %h
      '';
    };
  };

  # Çevre değişkenleri
  environment.variables = {
    EDITOR = "nvim";           # Varsayılan editör
    VISUAL = "nvim";           # Varsayılan görsel editör
    ASSH_CONFIG = "~/.ssh/assh.yml"; # ASSH yapılandırma dosyası
  };

  # Sistem genelindeki paketler
  environment.systemPackages = with pkgs; [
    assh                      # Advanced SSH
    openssh                   # SSH istemcisi
  ];

  # Shell aliases
  environment.shellAliases = {
    assh = "/run/current-system/sw/bin/assh"; # ssh komutunu assh ile sarmala
  };

  # SSH dizinlerini oluşturma scripti
  system.activationScripts.sshDirectories = ''
    mkdir -p /home/kenan/.ssh/controlmasters
    chmod 700 /home/kenan/.ssh/controlmasters
    chown kenan:users /home/kenan/.ssh/controlmasters
  '';
}


