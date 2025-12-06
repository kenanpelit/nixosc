#!/usr/bin/env bash
#===============================================================================
#   Original Author: Wenxuan
#    Original Email: wenxuangm@gmail.com
#  Created: 2018-04-06 09:30
#
#   Updated By: Kenan Pelit
#    Email: kenanpelit@gmail.com
#   Update: 2025-04-07 - NixOS ve Zen Browser desteği eklendi
#===============================================================================
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Hata ayıklama log dosyası
LOG_FILE="/tmp/tmux-fzf-url-tmux-debug.log"
echo "$(date): tmux script çalıştı" >"$LOG_FILE"

# $1: option
# $2: default value
tmux_get() {
	local value
	value="$(tmux show -gqv "$1")"
	[ -n "$value" ] && echo "$value" || echo "$2"
}

key="$(tmux_get '@fzf-url-bind' 'u')"
history_limit="$(tmux_get '@fzf-url-history-limit' 'screen')"
extra_filter="$(tmux_get '@fzf-url-extra-filter' '')"
custom_open="$(tmux_get '@fzf-url-open' '')"

# Log yapılandırma bilgileri
echo "Yapılandırma:" >>"$LOG_FILE"
echo "key: $key" >>"$LOG_FILE"
echo "history_limit: $history_limit" >>"$LOG_FILE"
echo "extra_filter: $extra_filter" >>"$LOG_FILE"
echo "custom_open: $custom_open" >>"$LOG_FILE"

# Binding oluştur
BINDING_CMD="$SCRIPT_DIR/fzf-url.sh '$extra_filter' $history_limit '$custom_open'"
echo "Çalıştırılacak komut: $BINDING_CMD" >>"$LOG_FILE"

tmux bind-key "$key" run -b "$BINDING_CMD"
echo "Binding tamamlandı" >>"$LOG_FILE"
