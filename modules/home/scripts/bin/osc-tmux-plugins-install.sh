#!/usr/bin/env bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ❱❱❱ Tmux Plugin Installer Script
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PLUGIN_DIR="$HOME/.config/tmux/plugins"
TPM_DIR="$PLUGIN_DIR/tpm"

# Plugin listesi
PLUGINS=(
	'tmux-plugins/tpm'
	'tmux-plugins/tmux-sensible'
	'tmux-plugins/tmux-open'
	'kenanpelit/tmux-fzf-url'
	'tmux-plugins/tmux-prefix-highlight'
	'tmux-plugins/tmux-online-status'
	'sainnhe/tmux-fzf'
	'kenanpelit/tmux-ssh-status'
	'lljbash/tmux-update-display'
	'roosta/tmux-fuzzback'
	'joshmedeski/tmux-nerd-font-window-name'
	'vascomfnunes/tmux-kripto'
	'TheSast/tmux-nav-master'
	'omerxx/tmux-sessionx'
	'richin13/tmux-plugin-playerctl'
	'tmux-plugins/tmux-resurrect'
	'tmux-plugins/tmux-continuum'
	'tmux-plugins/tmux-sessionist'
)

# Renkli çıktı
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

check_tmux() {
	if [ -z "$TMUX" ]; then
		echo -e "${RED}❌ Bu script tmux oturumu içinde çalıştırılmalı!${NC}"
		echo -e "${YELLOW}💡 Çözüm: tmux new-session${NC}"
		exit 1
	fi
}

install_plugins() {
	echo -e "${BLUE}🔄 Plugin kurulumu başlıyor...${NC}"

	# Environment setup
	tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$PLUGIN_DIR"

	# Plugin listesini oluştur
	local plugin_string=$(
		IFS=' '
		echo "${PLUGINS[*]}"
	)
	tmux set -g @tpm_plugins "$plugin_string"

	# Her plugin için ayrı ayrı set et
	for plugin in "${PLUGINS[@]}"; do
		tmux set -g @plugin "$plugin"
	done

	echo -e "${GREEN}✅ ${#PLUGINS[@]} plugin tmux'a tanımlandı${NC}"

	# TPM kontrolü
	if [ ! -f "$TPM_DIR/bin/install_plugins" ]; then
		echo -e "${RED}❌ TPM bulunamadı!${NC}"
		return 1
	fi

	# Pluginleri yükle
	echo -e "${BLUE}📦 Pluginler indiriliyor...${NC}"
	"$TPM_DIR/bin/install_plugins"

	# Pluginleri aktif et
	echo -e "${BLUE}🔌 Pluginler aktif ediliyor...${NC}"
	"$TPM_DIR/tpm"

	echo -e "${GREEN}🎉 Plugin kurulumu tamamlandı!${NC}"
	echo -e "${YELLOW}💡 Yeni tmux oturumu açarak değişiklikleri görebilirsiniz.${NC}"
}

# Ana işlem
check_tmux
install_plugins
