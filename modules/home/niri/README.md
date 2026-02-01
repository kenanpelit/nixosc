# Niri (Home-Manager) – DMS odaklı kurulum

Bu klasördeki modül, `my.desktop.niri` altında Niri konfigini üretir ve Niri oturumunu `systemd --user` ile “gözlemlenebilir / restart edilebilir” hale getirir (DMS ile uyumlu).

## Öne çıkanlar

- Niri config tek bir `programs.niri.config` string’i olarak üretilir (build-time validation için).
- `niri-session.target` ile oturum servisleri yönetilir.
- Portal/ScreenCast/Screenshot için `my.user.xdg-portal.enable = true` (mkDefault) yapılır.
- Kısayollar `hotkey-overlay-title` üzerinden dokümante edilir ve cheatsheet dosyası otomatik üretilir.

## Açılış akışı (repo)

1) DM/GDM oturumu seçilince `modules/nixos/sessions/default.nix` içindeki Niri entry’si `niri-set tty` çalıştırır.
2) Niri konfigi açılışta `spawn-at-startup ... niri-set env` ile oturum env export akışını tetikler (`modules/home/niri/settings.nix`, `my.desktop.niri.systemd.enable` açıkken).
3) `niri-set env` ( `modules/home/scripts/bin/niri-set.sh` ):
   - `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, `NIRI_SOCKET` tespiti yapar.
   - Kritik değişkenleri `systemd --user` env + D-Bus activation env içine import eder.
   - Portal backend’lerini best-effort başlatır, sonra `xdg-desktop-portal.service`’i restart eder.
   - `clipse -listen` ile clipboard listener’ı (dup’ları engelleyerek) başlatır.
   - Son olarak `systemctl --user start niri-session.target` ile Niri oturum servislerini kaldırır.
4) `niri-session.target` `modules/home/niri/default.nix` içinde tanımlıdır ve `xdg-desktop-autostart.target` ile birlikte oturum servislerini `systemd --user` üzerinden yönetir (izlenebilir/restart edilebilir).

## Niri oturum servisleri (niri-session.target)

- `niri-polkit-agent`: polkit auth pencereleri için `polkit-gnome` agent (`modules/home/niri/default.nix`).
- `niri-ready`: `niri msg version` çalışana kadar bekleyen “IPC hazır” kapısı (`modules/home/niri/default.nix`).
- `niri-bootstrap`: gecikmeli bootstrap → `niri-set init` (+ opsiyonel BT auto-connect) → nsticky/niriusd/niriswitcher daemon’ları (`modules/home/niri/default.nix`).
- `dms.service`: `dms run --session` ile DankMaterialShell (`modules/home/dms/settings.nix`).
- `dms-plugin-sync`: eksik DMS plugin’lerini best-effort indirir (github.com yoksa skip) (`modules/home/dms/settings.nix`).
- `dms-resume-restart`: suspend/resume sonrası DMS restart (Wayland/Qt crash workaround) (`modules/home/dms/settings.nix`).
- `kdeconnectd` + `kdeconnect-indicator`: KDE Connect daemon + tray (`modules/home/connect/default.nix`).
- `fusuma`: touchpad gesture servisi (`modules/home/fusuma/default.nix`).
- `cliphist-watch-{text,image}`: `wl-paste --watch ... | cliphist store` watcher’ları (`modules/home/cliphist/default.nix`).

## Niri’de başlayan diğerleri (graphical-session.target vb.)

- `stasis`: Wayland idle manager (`modules/home/stasis/default.nix`).
- `niri-set init` içindeki `osc-soundctl init`: default ses/mikrofon seviyeleri + son cihaz tercihi (`modules/home/scripts/bin/osc-soundctl.sh`).

## Dosyalar

- `modules/home/niri/default.nix`: Paket seçimi + config birleştirme + systemd user servisleri.
- `modules/home/niri/settings.nix`: Environment, layout, input, animasyonlar.
- `modules/home/niri/binds.nix`: Kategori bazlı keybind blokları (`binds {}` wrapper’ı burada yok).
- `modules/home/niri/rules.nix`: Window/layer rules ve privacy (screencast/screenshot) kuralları.
- `~/.config/niri/dms/hotkeys.md`: `binds.nix` içindeki `hotkey-overlay-title` alanlarından otomatik üretilen cheatsheet.
- `~/.config/niri/dms/workspace-rules.tsv`: `niri-set go` için kurallar.

## Seçenekler (özet)

- `my.desktop.niri.package`: Kullanılacak niri paketi.
- `my.desktop.niri.extraConfig`: Üretilen config’in sonuna eklenecek ekstra KDL.
- `my.desktop.niri.extraBinds`: Üretilen `binds {}` bloğunun içine eklenecek ekstra bind satırları.
- `my.desktop.niri.extraRules`: Üretilen window rules sonuna eklenecek ekstra KDL.
- `my.desktop.niri.systemd.enable`: `niri-session.target` ve oturum servislerini aç/kapat.

## Debug / sorun giderme

- Genel hızlı durum: `niri-set doctor` (`--tree`, `--logs` opsiyonları var)
- Oturum hedefi: `systemctl --user status niri-session.target`
- “Şu an hangileri active?”: `systemctl --user list-dependencies --plain niri-session.target`
- Niri hazır kapısı: `systemctl --user status niri-ready.service`
- Bootstrap: `systemctl --user status niri-bootstrap.service`
- Log takip:
  - `journalctl --user -u niri-ready.service -f`
  - `journalctl --user -u niri-bootstrap.service -f`
  - `journalctl --user -u dms.service -f`
  - `journalctl --user -u xdg-desktop-portal.service -f`

## Portal / ekran paylaşımı notları

- `XDG_CURRENT_DESKTOP` değeri `niri` olmalı.
- Gerekirse portalları yeniden başlat:  
  `systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gnome.service xdg-desktop-portal-gtk.service`

## Cheatsheet

- DMS içinden keybind UI: `Mod+F1`
- Dosya çıktısı: `~/.config/niri/dms/hotkeys.md`
