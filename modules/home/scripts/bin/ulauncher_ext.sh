#!/usr/bin/env bash

# Ulauncher extensions installation script
EXTENSIONS_DIR="$HOME/.local/share/ulauncher/extensions"

# Make sure extensions directory exists
mkdir -p "$EXTENSIONS_DIR"
cd "$EXTENSIONS_DIR"

# Array of extension repositories
declare -a repos=(
	"abhishekmj303/ulauncher-playerctl"
	"adamtillou/ulauncher-aurman-plugin"
	"ahaasler/ulauncher-tmux"
	"brpaz/ulauncher-pwgen"
	"codyfish/ulauncher-mpd"
	"dankni95/ulauncher-playerctl"
	"devkleber/ulauncher-open-link"
	"dhelmr/ulauncher-tldr"
	"floydjohn/ulauncher-chrome-profiles"
	"friday/ulauncher-clipboard"
	"iboyperson/ulauncher-system"
	"kenanpelit/ulauncher-ssh"
	"kleber-swf/ulauncher-firefox-profiles"
	"lighttigerxiv/ulauncher-terminal-runner-extension"
	"manahter/ulauncher-doviz"
	"manahter/ulauncher-ip-analysis"
	"manahter/ulauncher-translate"
	"melianmiko/ulauncher-bluetoothd"
	"nastuzzisamy/ulauncher-custom-scripts"
	"nastuzzisamy/ulauncher-google-search"
	"nastuzzisamy/ulauncher-translate"
	"nastuzzisamy/ulauncher-youtube-search"
	"ncroxas/coingecko-query"
	"rapha149/ulauncher-deepl"
	"rkarami/ulauncher-password-generator"
	"seofernando25/ulauncher-gpt"
	"seon22break/bitcoin-exchange"
	"ulauncher/ulauncher-emoji"
)

# Install each extension
for repo in "${repos[@]}"; do
	echo "Installing $repo..."

	# Extract extension name from repo path
	ext_name="com.github.${repo//\//.}"

	# Remove if exists
	rm -rf "$ext_name"

	# Clone repository
	git clone "https://github.com/$repo" "$ext_name"

	echo "Installed $ext_name"
	echo "----------------------------------------"
done

echo "All extensions installed successfully!"
