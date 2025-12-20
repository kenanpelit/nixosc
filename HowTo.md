# NixOSC How-To

Hızlı rehber; Snowfall Lib düzenini ve yaygın işleri özetler.

## Yapı & Switch
- Host’u derle/uygula: `sudo nixos-rebuild switch --flake .#hay` (veya `./install.sh install hay`).
- Sadece build: `sudo nixos-rebuild build --flake .#hay`.
- Home Manager yalnız: `home-manager switch --flake .#kenan@hay`.
- Girdi güncelle: `nix flake update` veya `./install.sh update`.
- Kontrol: `nix flake check` (hızlı sentaks/derleme testi).

## Snowfall Lib Ne Sağlıyor?
- `modules/nixos` ve `modules/home` içindeki modülleri otomatik import eder; host dosyasına tek tek eklemen gerekmez.
- `my.*` namespaceni sağlar; örn. `my.host`, `my.firewall`.
- `packages/` ve `overlays/` da otomatik okunur (şu an boş).

## Uygulama Ekle/Kaldır
- Kullanıcı (Home Manager): `modules/home/<app>/default.nix` oluştur; `home.packages = [ pkgs.<pkg> ];` veya `programs.<app>.enable = true;`. Snowfall otomatik dahil eder.
- Sistem: `modules/nixos/packages/` veya yeni bir `modules/nixos/<kategori>/default.nix` içinde `environment.systemPackages = [ ... ];`.
- Kaldırma: İlgili listeden paketi sil; başka referans yoksa rebuild ile gider.

## Servis Açma/Kapama
- Yeni servis modülü: `modules/nixos/<servis>/default.nix` → `services.<servis>.enable = true;`.
- Host’a özel aç/kapa: `systems/<arch>/<host>/default.nix` içinde ayar override et.
- Firewall portları: `my.firewall.allowTransmissionPorts` ve `allowCustomServicePort` bayraklarını yalnızca gerektiği hostta `true` yap.

## Secrets (sops-nix)
- Varsayılan dosya: `secrets/wireless-secrets.enc.yaml` (varsa otomatik bağlanır).
- Yeni secret: `sops -e -i secrets/<file>.enc.yaml` ardından ilgili modülde `sops.secrets.<name>` tanımı ekle.
- Age anahtarı yolu: `~/.config/sops/age/keys.txt` (tmpfiles ile yaratılır).

## Yeni Makine Ekleme
1) Klasörü kopyala: `cp -r systems/x86_64-linux/hay systems/x86_64-linux/<host>`.
2) Hedefte `nixos-generate-config --root /mnt --show-hardware-config > systems/.../<host>/hardware-configuration.nix`.
3) `networking.hostName`, `my.host` rolü (physical/vm) ve gerekirse `display/boot/firewall` bayraklarını güncelle.
4) `./install.sh install <host>` veya `nixos-rebuild switch --flake .#<host>`.

## Overlay/Paket Yazma
- Yeni paket: `packages/<name>/default.nix` (derivasyon); Snowfall otomatik ekler.
- Overlay: `overlays/<name>.nix` ile `self: super: { ... }` tanımla.

## Faydalı Komutlar
- Disk temizliği: `nh clean all` (programs.nh etkin).
- GC: `sudo nix-collect-garbage -d` (nh clean açıkken genelde gerekmez).
- Sistem farkı: `nix store diff-closures /run/current-system ./result`.

## Notlar
- Hem GNOME hem Hyprland açık; ihtiyaç yoksa host bazında birini kapatıp closure’ı küçültebilirsin.
- VMs’de SSH anahtar, `PermitRootLogin=prohibit-password`; fiziksel hostta da benzer sertlik önerilir.
