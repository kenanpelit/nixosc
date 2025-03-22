# modules/home/termina/zsh/zsh_tsm.nix
# ==============================================================================
# Transmission CLI Yapılandırması ve Alias'ları
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  programs.zsh = {
    # Script konumu ve completion tanımlamaları
    initExtra = ''
      # Transmission script konumu
      export TSM_SCRIPT="tsm"
      # ZSH Completion için komut açıklamaları
      _tsm_completions() {
          local commands=(
              # Temel komutlar
              "list:Torrent listesini göster"
              "add:Yeni torrent/magnet ekle"
              "info:Torrent detaylarını göster"
              "speed:İndirme/yükleme hızını göster"
              "files:Torrent dosyalarını listele"
              "config:Kimlik bilgilerini yapılandır"
              
              # Arama komutları
              "search:Torrent ara"
              "search-cat:Mevcut kategorileri listele"
              "search-recent:Son 48 saatteki torrentlerde ara"
              
              # Torrent yönetim komutları
              "start:Torrent başlat"
              "stop:Torrent durdur"
              "remove:Torrent sil"
              "purge:Torrent ve dosyaları sil"
              
              # Toplu işlem komutları
              "start-all:Tüm torrentleri başlat"
              "stop-all:Tüm torrentleri durdur"
              "remove-all:Tüm torrentleri sil"
              "purge-all:Tüm torrentleri ve dosyaları sil"
              
              # Gelişmiş özellikler
              "health:Torrent sağlık kontrolü"
              "stats:Detaylı istatistikleri göster"
              "disk:Disk kullanım durumunu kontrol et"
              "tracker:Tracker bilgilerini göster"
              "limit:Hız limiti ayarla"
              "auto-remove:Otomatik tamamlanan torrent silme (daemon)"
              "remove-done:Tamamlanmış torrentleri sil"
              
              # Yeni eklenen özellikler
              "priority:Torrent önceliğini ayarla (high/normal/low)"
              "schedule:Torrent zamanlama (başlama/durma saatleri)"
              "tag:Torrent'e etiket ekle"
              "auto-tag:Torrentleri içeriğe göre otomatik etiketle"
              "list-sort:Torrentleri belirli özelliklere göre sırala"
              "list-filter:Torrentleri belirli kriterlere göre filtrele"
          )
          _describe 'tsm' commands
      }
      compdef _tsm_completions tsm-
    '';
    # Transmission CLI alias'ları
    shellAliases = {
      # Temel komutlar
      tsm = "$TSM_SCRIPT";
      tsm-list = "$TSM_SCRIPT list";
      tsm-add = "$TSM_SCRIPT add";
      tsm-info = "$TSM_SCRIPT info";
      tsm-speed = "$TSM_SCRIPT speed";
      tsm-files = "$TSM_SCRIPT files";
      tsm-config = "$TSM_SCRIPT config";
      
      # Arama komutları
      tsm-search = "$TSM_SCRIPT search";
      tsm-search-cat = "$TSM_SCRIPT search -l";
      tsm-search-recent = "$TSM_SCRIPT search -R";
      
      # Torrent yönetim
      tsm-start = "$TSM_SCRIPT start";
      tsm-stop = "$TSM_SCRIPT stop";
      tsm-remove = "$TSM_SCRIPT remove";
      tsm-purge = "$TSM_SCRIPT purge";
      
      # Toplu işlemler
      tsm-start-all = "$TSM_SCRIPT start all";
      tsm-stop-all = "$TSM_SCRIPT stop all";
      tsm-remove-all = "$TSM_SCRIPT remove all";
      tsm-purge-all = "$TSM_SCRIPT purge all";
      
      # Gelişmiş özellikler
      tsm-health = "$TSM_SCRIPT health";
      tsm-stats = "$TSM_SCRIPT stats";
      tsm-disk = "$TSM_SCRIPT disk-check";
      tsm-tracker = "$TSM_SCRIPT tracker";
      tsm-limit = "$TSM_SCRIPT limit";
      tsm-auto-remove = "$TSM_SCRIPT auto-remove";
      tsm-remove-done = "$TSM_SCRIPT tsm-remove-done";
      
      # Yeni eklenen özellikler
      tsm-priority-high = "$TSM_SCRIPT priority $1 high";
      tsm-priority-normal = "$TSM_SCRIPT priority $1 normal";
      tsm-priority-low = "$TSM_SCRIPT priority $1 low";
      tsm-schedule = "$TSM_SCRIPT schedule";
      tsm-tag = "$TSM_SCRIPT tag";
      tsm-auto-tag = "$TSM_SCRIPT auto-tag";
      tsm-list-sort-name = "$TSM_SCRIPT list --sort-by=name";
      tsm-list-sort-size = "$TSM_SCRIPT list --sort-by=size";
      tsm-list-sort-status = "$TSM_SCRIPT list --sort-by=status";
      tsm-list-sort-progress = "$TSM_SCRIPT list --sort-by=progress";
      tsm-list-filter-size = "$TSM_SCRIPT list --filter=\"size>1GB\"";
      tsm-list-filter-complete = "$TSM_SCRIPT list --filter=\"progress=100\"";
    };
  };
}

