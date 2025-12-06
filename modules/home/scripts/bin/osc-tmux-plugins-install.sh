#!/usr/bin/env bash

#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TmuxPluginManager - Tmux Plugin Yönetim Aracı
#
# Bu script tmux plugin'lerini yönetmek için tasarlanmış bir araçtır.
# Temel özellikleri:
# - Plugin dizinini otomatik oluşturma
# - Önceden tanımlı plugin'leri kurma/güncelleme
# - TPM (Tmux Plugin Manager) kurulumu
# - Kurulum durumunu renkli loglar ile raporlama
# - Tmux config'i otomatik yeniden yükleme
#
# Desteklenen Pluginler:
# - Oturum yönetimi (resurrect, continuum, sessionist)
# - Pencere yönetimi (window-name, nerd-font-window-name)
# - Sistem bilgisi (net-speed, ssh-status, online-status)
# - Arayüz geliştirmeleri (sensible, prefix-highlight)
# - FZF entegrasyonları (fzf, fzf-url, fuzzback)
# - Medya kontrolü (spotify-info, playerctl)
#
# Kurulum Dizini: ~/.config/tmux/plugins/
#
# License: MIT
#
#######################################

# Tmux plugin dizini
TMUX_PLUGIN_DIR="$HOME/.config/tmux/plugins"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log fonksiyonları
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Plugin dizinini oluştur
mkdir -p "$TMUX_PLUGIN_DIR"

# Plugin listesi
declare -A plugins=(
	["tpm"]="tmux-plugins/tpm"
	["tmux-sensible"]="tmux-plugins/tmux-sensible"
	["tmux-open"]="tmux-plugins/tmux-open"
	["tmux-fzf-url"]="kenanpelit/tmux-fzf-url"
	["tmux-prefix-highlight"]="tmux-plugins/tmux-prefix-highlight"
	["tmux-online-status"]="tmux-plugins/tmux-online-status"
	["tmux-fzf"]="sainnhe/tmux-fzf"
	["tmux-ssh-status"]="kenanpelit/tmux-ssh-status"
	["tmux-update-display"]="lljbash/tmux-update-display"
	["tmux-fuzzback"]="roosta/tmux-fuzzback"
	["tmux-nerd-font-window-name"]="joshmedeski/tmux-nerd-font-window-name"
	["tmux-kripto"]="vascomfnunes/tmux-kripto"
	["tmux-nav-master"]="TheSast/tmux-nav-master"
	["tmux-sessionx"]="omerxx/tmux-sessionx"
	["tmux-plugin-playerctl"]="richin13/tmux-plugin-playerctl"
	["tmux-resurrect"]="tmux-plugins/tmux-resurrect"
	["tmux-continuum"]="tmux-plugins/tmux-continuum"
	["tmux-sessionist"]="tmux-plugins/tmux-sessionist"
	["tmux-thumbs"]="fcsonline/tmux-thumbs"
	["tmux-yank"]="tmux-plugins/tmux-yank"
	#["tmux-pain-control"]="tmux-plugins/tmux-pain-control"
	["tmux-copycat"]="tmux-plugins/tmux-copycat"
)

# Her bir plugin için
for plugin_name in "${!plugins[@]}"; do
	plugin_path="$TMUX_PLUGIN_DIR/$plugin_name"
	plugin_repo="${plugins[$plugin_name]}"

	# Plugin zaten var mı kontrol et
	if [ -d "$plugin_path" ]; then
		log_warn "Plugin $plugin_name zaten mevcut. Güncelleniyor..."
		cd "$plugin_path" || continue
		if git pull; then
			log_info "$plugin_name güncellendi"
		else
			log_error "$plugin_name güncellenemedi"
		fi
	else
		log_info "Plugin $plugin_name yükleniyor..."
		if git clone "https://github.com/$plugin_repo.git" "$plugin_path"; then
			log_info "$plugin_name başarıyla yüklendi"
		else
			log_error "$plugin_name yüklenemedi"
		fi
	fi
done

# TPM'i yükle (eğer yoksa)
TPM_PATH="$TMUX_PLUGIN_DIR/tpm"
if [ ! -d "$TPM_PATH" ]; then
	log_info "TPM yükleniyor..."
	if git clone https://github.com/tmux-plugins/tpm "$TPM_PATH"; then
		log_info "TPM başarıyla yüklendi"
	else
		log_error "TPM yüklenemedi"
	fi
else
	log_warn "TPM zaten mevcut"
fi

# Tmux'u yeniden yükle (eğer çalışıyorsa)
if pgrep tmux >/dev/null; then
	log_info "Tmux oturumları yeniden yükleniyor..."
	tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || log_warn "Tmux config yenilenemedi"
fi

log_info "Kurulum tamamlandı!"
log_info "Tmux'u başlatın ve prefix + I tuşlarına basarak pluginleri başlatın"
