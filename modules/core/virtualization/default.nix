# virtualization.nix
{ config
, pkgs
, username
, ...
}:
{
  # Kullanıcı grupları
  users.users.${username}.extraGroups = [ 
    "libvirtd"
    "kvm"
  ];

  # Sanallaştırma servisleri
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # SPICE agent servisi
  services.spice-vdagentd.enable = true;

  # USB ve SPICE için udev kuralları
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"
    SUBSYSTEM=="vfio", GROUP="libvirtd"
  '';

  # Güvenlik ayarları
  security.wrappers.spice-client-glib-usb-acl-helper.source = 
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}
