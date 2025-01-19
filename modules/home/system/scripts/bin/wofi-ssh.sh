#!/usr/bin/env bash

#######################################
# ASSH Wofi Launcher v1.0.0
# Author: Kenan Pelit
# License: MIT
#######################################
#
# Bu script ASSH cache'ini kullanarak SSH bağlantılarını
# wofi üzerinden seçip tmux ve byobu ile başlatır.
#
# Bağımlılıklar:
#   - wofi          : Host seçimi için
#   - tmux          : Yerel terminal multiplexer
#   - foot          : Terminal emülatör (değiştirilebilir)
#   - assh          : SSH yapılandırma yönetimi
#   - byobu         : Uzak terminal multiplexer
#
# Kurulum:
#   1. Bu scripti ~/.bin/ altına kopyalayın
#   2. Çalıştırma izni verin: chmod +x ~/.bin/wofi-ssh
#   3. assh-manager.sh -u veya assh-manager.sh --update ile host cache'ini oluşturun
#
# Kullanım:
#   ./wofi-ssh                    : Normal başlatma
#   ./wofi-ssh update            : Host cache'ini günceller (assh-manager.sh -u çalıştırır)
#   ./wofi-ssh alacritty         : Farklı terminal ile başlatma
#
# Özellikler:
#   - ASSH hosts cache'inden host listesi okuma
#   - Wofi ile arama ve filtreleme
#   - Tmux ile yerel oturum yönetimi
#   - Byobu ile uzak oturum yönetimi
#   - XDG Base Directory spesifikasyonuna uyumlu
#   - Host geçmişi tutma ve sıralama
#
#######################################

VERSION="1.0.0"
TERMINAL="${1:-foot}"

# XDG Base Directory paths
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ASSH cache dosyaları
ASSH_CACHE_DIR="$XDG_CACHE_HOME/assh"
ASSH_HOSTS_FILE="$ASSH_CACHE_DIR/hosts"

echo "Debug: Script starting with:" >&2
echo "XDG_CACHE_HOME=$XDG_CACHE_HOME" >&2
echo "ASSH_CACHE_DIR=$ASSH_CACHE_DIR" >&2
echo "ASSH_HOSTS_FILE=$ASSH_HOSTS_FILE" >&2
ASSH_MANAGER="$HOME/.bin/assh-manager.sh"

# Wofi yapılandırması
HISTORY_FILE="$XDG_CACHE_HOME/wofi-ssh-history"
MAX_HISTORY=100
WOFI_CONFIG="$HOME/.config/wofi/configs/ssh"
WOFI_STYLE="$HOME/.config/wofi/styles/ssh.css"

# Fonksiyon: Geçmiş dosyasını temizle
clean_history() {
	[[ -f "$HISTORY_FILE" ]] && {
		sort -u "$HISTORY_FILE" | tail -n "$MAX_HISTORY" >"$HISTORY_FILE.tmp"
		mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
	}
}

# Fonksiyon: Cache'i güncelle
update_cache() {
	if [ -x "$ASSH_MANAGER" ]; then
		echo "Updating SSH hosts cache..."
		$ASSH_MANAGER -u
		echo "Cache update completed."
		exit 0
	else
		echo "Error: assh-manager.sh not found or not executable at $ASSH_MANAGER"
		exit 1
	fi
}

# Fonksiyon: Host listesini al
get_hosts() {
	echo "Debug: Checking file $ASSH_HOSTS_FILE" >&2
	if [ -f "$ASSH_HOSTS_FILE" ]; then
		echo "Debug: File exists, reading content..." >&2
		echo "Debug: Raw content:" >&2
		cat "$ASSH_HOSTS_FILE" >&2

		echo -n "Debug: Total raw lines: " >&2
		wc -l <"$ASSH_HOSTS_FILE" >&2

		echo "Debug: Filtered content:" >&2
		filtered_content=$(grep -v "^$\|^(\|^Add" "$ASSH_HOSTS_FILE")
		echo "$filtered_content" >&2

		echo -n "Debug: Total hosts after filtering: " >&2
		echo "$filtered_content" | wc -l >&2

		# Actual output for wofi
		echo "$filtered_content"
	else
		echo "Debug: File does not exist!" >&2
	fi
}

# Fonksiyon: Tüm host'ları al
get_all_hosts() {
	echo "Debug: Getting all hosts..." >&2
	local all_hosts=$(
		{
			[[ -f "$HISTORY_FILE" ]] && cat "$HISTORY_FILE"
			get_hosts
		} | sort -u
	)

	echo -n "Debug: Total unique hosts for wofi: " >&2
	echo "$all_hosts" | wc -l >&2

	echo "Debug: First 5 hosts from the list:" >&2
	echo "$all_hosts" | head -n 5 >&2

	echo "$all_hosts"
}

# Fonksiyon: Terminal başlatma
launch_terminal() {
	local addr="$1"
	echo "Starting SSH connection to: $addr"

	# Host adından yerel tmux oturum adı oluştur
	local local_session=$(echo "$addr" | sed 's/[^a-zA-Z0-9_-]/_/g')

	# Uzak byobu komutu
	local remote_cmd='byobu has -t kenan || byobu new-session -d -s kenan && byobu a -t kenan'
	local ssh_cmd="ssh ${addr} -t '${remote_cmd}'"

	# Tmux komutlarını oluştur
	local tmux_create="tmux new-session -d -s ${local_session} 2>/dev/null || true"
	local tmux_send="tmux send-keys -t ${local_session} \"${ssh_cmd}\" ENTER"
	local tmux_attach="tmux attach-session -t ${local_session}"

	# Tüm komutları birleştir
	local full_script="${tmux_create}; ${tmux_send}; ${tmux_attach}"

	cd "$HOME"
	$TERMINAL -a SSH --title "SSH" env TERM=xterm-256color bash -c "$full_script"
}

# Argümanları kontrol et
case "$1" in
"update" | "ssh-update")
	update_cache
	;;
esac

# ASSH cache dosyasının varlığını kontrol et
if [ ! -f "$ASSH_HOSTS_FILE" ]; then
	echo "Error: ASSH hosts cache not found at $ASSH_HOSTS_FILE"
	echo "Please run 'assh-manager.sh --update' first"
	exit 1
fi

# Ana program
# Önce geçmişi temizle
clean_history

# Wofi ile host seçimi
all_hosts=$(get_all_hosts)
host_count=$(echo "$all_hosts" | wc -l)
selected_host=$(echo "$all_hosts" | wofi \
	--show dmenu \
	--prompt "SSH hosts ($host_count): " \
	--style "$WOFI_STYLE" \
	--conf "$WOFI_CONFIG")

# Seçilen host varsa
if [ ! -z "$selected_host" ]; then
	# Geçmişe ekle
	echo "$selected_host" >>"$HISTORY_FILE"
	# Bağlantıyı başlat
	launch_terminal "$selected_host"
fi
