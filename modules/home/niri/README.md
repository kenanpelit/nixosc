# Niri (Home-Manager) – DMS odaklı kurulum

Bu klasördeki modül, `my.desktop.niri` altında Niri konfigini üretir ve Niri oturumunu `systemd --user` ile “gözlemlenebilir / restart edilebilir” hale getirir (DMS ile uyumlu).

## Öne çıkanlar

- Niri config tek bir `programs.niri.config` string’i olarak üretilir (build-time validation için).
- `niri-session.target` ile oturum servisleri yönetilir.
- Portal/ScreenCast/Screenshot için `my.user.xdg-portal.enable = true` (mkDefault) yapılır.
- Kısayollar `hotkey-overlay-title` üzerinden dokümante edilir ve cheatsheet dosyası otomatik üretilir.

## Dosyalar

- `modules/home/niri/default.nix`: Paket seçimi + config birleştirme + systemd user servisleri.
- `modules/home/niri/settings.nix`: Environment, layout, input, animasyonlar.
- `modules/home/niri/binds.nix`: Kategori bazlı keybind blokları (`binds {}` wrapper’ı burada yok).
- `modules/home/niri/rules.nix`: Window/layer rules ve privacy (screencast/screenshot) kuralları.
- `~/.config/niri/dms/hotkeys.md`: `binds.nix` içindeki `hotkey-overlay-title` alanlarından otomatik üretilen cheatsheet.
- `~/.config/niri/dms/workspace-rules.tsv`: `niri-set arrange-windows` için kurallar.

## Seçenekler (özet)

- `my.desktop.niri.package`: Kullanılacak niri paketi.
- `my.desktop.niri.extraConfig`: Üretilen config’in sonuna eklenecek ekstra KDL.
- `my.desktop.niri.extraBinds`: Üretilen `binds {}` bloğunun içine eklenecek ekstra bind satırları.
- `my.desktop.niri.extraRules`: Üretilen window rules sonuna eklenecek ekstra KDL.
- `my.desktop.niri.systemd.enable`: `niri-session.target` ve oturum servislerini aç/kapat.

## Debug / sorun giderme

- Genel hızlı durum: `niri-set doctor`
- Oturum hedefi: `systemctl --user status niri-session.target`
- Niri hazır kapısı: `systemctl --user status niri-ready.service`
- Bootstrap: `systemctl --user status niri-init.service`
- Log takip:
  - `journalctl --user -u niri-ready.service -f`
  - `journalctl --user -u niri-init.service -f`
  - `journalctl --user -u dms.service -f`
  - `journalctl --user -u xdg-desktop-portal.service -f`

## Portal / ekran paylaşımı notları

- `XDG_CURRENT_DESKTOP` değeri `niri` olmalı.
- Gerekirse portalları yeniden başlat:  
  `systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gnome.service xdg-desktop-portal-gtk.service`

## Cheatsheet

- DMS içinden keybind UI: `Mod+F1`
- Dosya çıktısı: `~/.config/niri/dms/hotkeys.md`
