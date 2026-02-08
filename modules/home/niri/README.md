# Niri (Home-Manager) – DMS odaklı kurulum

Bu klasördeki modül, `my.desktop.niri` altında Niri konfigini üretir ve oturumu `systemd --user` ile yönetir. Amaç: DMS + Niri birleşiminde gözlemlenebilir, restart edilebilir ve runtime override destekli bir yapı.

## Öne çıkanlar

- Niri config’i `xdg.configFile."niri/config.kdl"` ile üretilir.
- Runtime include dosyaları (`dms/*.kdl`) writable gerçek dosya olarak korunur.
- `niri-session.target` altında session servisleri (bootstrap, polkit, DMS, daemons) yönetilir.
- `niri-osc set doctor` include dosyaları için strict kontrol (declared/missing/symlink/writable) verir.

## Açılış akışı

1) DM/TTY oturumu `niri-osc set tty` ile Niri başlatır.
2) Niri açılışında `spawn-at-startup ... niri-osc set env` çalışır:
   - Wayland/Niri env değişkenlerini systemd ve D-Bus activation ortamına taşır.
   - Portal backend’lerini start/restart eder.
   - `niri-session.target` tetikler.
3) `niri-bootstrap.service`:
   - Kısa gecikme (`bootstrapDelaySeconds`, varsayılan `1`) sonrası `niri-osc set init` çağırır.
   - `niri-osc set init` monitor profilini üretir (`~/.config/niri/dms/monitor-auto.kdl`) ve config reload eder.
   - `bootstrapNotifications` açıkken sadece sonuç bildirimi verir (başarı/hata), başlangıç popup’ı göstermez.
4) Uzun yaşayan servisler ayrı unit’lerde yönetilir:
   - `niri-sticky.service`
   - `niriswitcher.service` (opsiyonel)
   - `niri-bt-autoconnect.service` (opsiyonel, one-shot)

## Niri workflow notu

- `niri-osc flow` komutu bu repoda daemon-free bash helper olarak sağlanır (`modules/home/scripts/bin/niri-osc.sh`).
- Bu sayede `niri-osc set here`, `niri-osc drop`, scratchpad/mark kısayolları ek daemon olmadan çalışır.

## Monitor profili (dock/undock)

- Fallback profil `modules/home/niri/monitors.nix` içinde laptop-safe (`eDP-1`) tutulur.
- Runtime’da `niri-osc set init` bağlı output’lara göre `monitor-auto.kdl` üretir:
  - Harici ekran varsa: workspace `1-6` hariciye, `7-9` dahiliye.
  - Harici yoksa: tüm workspace’ler dahili ekrana.
- Bu dosya config’e include edilir ve writable tutulur.

## Runtime include dosyaları

- `~/.config/niri/dms/outputs.kdl`
- `~/.config/niri/dms/monitor-auto.kdl`
- `~/.config/niri/dms/zen.kdl`
- `~/.config/niri/dms/cursor.kdl`

`home.activation` bu dosyaları symlink yerine normal writable dosya olarak zorlar.

## Dosya haritası

- `modules/home/niri/default.nix`: config birleştirme, session servisleri, runtime dosya garantisi.
- `modules/home/niri/settings.nix`: environment, input, layout, animasyon.
- `modules/home/niri/binds.nix`: kategori bazlı keybind blokları.
- `modules/home/niri/rules.nix`: window/layer/privacy kuralları.
- `modules/home/niri/monitors.nix`: fallback monitor/workspace profili.
- `modules/home/dms/settings.nix`: DMS service + plugin sync + resume restart.

## Debug / sorun giderme

- Hızlı tanı: `niri-osc set doctor`
- Ek tanı: `niri-osc set doctor --tree --logs`
- Session target: `systemctl --user status niri-session.target`
- Bootstrap log: `journalctl --user -u niri-bootstrap.service -f`
- DMS log: `journalctl --user -u dms.service -f`

## Kısayol cheatsheet

- DMS keybind UI: `Mod+F1`
- Otomatik çıktı: `~/.config/niri/dms/hotkeys.md`
