#!/usr/bin/env bash
# ==============================================================================
# Brave Extensions Manuel Kurulum Script'i
# ==============================================================================

# Sadece -u (undefined variable) kontrolü yap, -e (exit on error) kaldır
set -uo pipefail

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
echo -e "${CYAN}"
cat <<"EOF"
╔═══════════════════════════════════════════════════════════╗
║     Brave Browser Extensions Manuel Kurulum              ║
║     Chrome Web Store Entegrasyonu                         ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Extension listesi - ARRAY formatında (ID:Name)
extensions_list=(
	# Çeviri Araçları
	"aapbdbdomjkkjkaonfhkkikfgjllcleb:Google Translate"
	"cofdbpoegempjloogbagkncekinflcnj:DeepL: translate and write with AI"
	"ibplnjkanclpjokhdolnendpplpjiace:Simple Translate"

	# Güvenlik & Gizlilik
	"ddkjiahejlhfcafbddmgiahcphecmpfh:uBlock Origin Lite"
	"pkehgijcmpdhfbdbbnkijodmdjhbjlgp:Privacy Badger"

	# Navigasyon & Prodüktivite
	"gfbliohnnapiefjpjlpjnehglfpaknnc:Surfingkeys"
	"eekailopagacbcdloonjhbiecobagjci:Go Back With Backspace"
	"inglelmldhjcljkomheneakjkpadclhf:Keep Awake"
	"kdejdkdjdoabfihpcjmgjebcpfbhepmh:Copy Link Address"
	"kgfcmiijchdkbknmjnojfngnapkibkdh:Picture-in-Picture Viewer"
	"mbcjcnomlakhkechnbhmfjhnnllpbmlh:Tab Pinner (Keyboard Shortcuts)"
	"llimhhconnjiflfimocjggfjdlmlhblm:Reader Mode"

	# Medya
	"lmjnegcaeklhafolokijcfjliaokphfk:Video DownloadHelper"
	"ponfpcnoihfmfllpaingbgckeeldkhle:Enhancer for YouTube™"

	# Sistem Entegrasyonu
	"gphhapmejobijbbhgpjhcjognlahblep:GNOME Shell integration"

	# Kripto Cüzdanları
	"acmacodkjbdgmoleebolmdjonilkdbch:Rabby Wallet"
	"anokgmphncpekkhclmingpimjmcooifb:Compass Wallet for Sei"
	"bfnaelmomeimhlpmgjnjophhpkkoljpa:Phantom"
	"bhhhlbepdkbapadjdnnojkbgioiodbic:Solflare Wallet"
	"dlcobpjiigpikoobohmabehhmhfoodbb:Ready Wallet (Formerly Argent)"
	"dmkamcknogkgcdfhhbddcghachkejeap:Keplr"
	"enabgbdfcbaehmbigakijjabdpdnimlg:Manta Wallet"
	"nebnhfamliijlghikdgcigoebonmoibm:Leo Wallet"
	"ojggmchlghnjlapmfbnjholfjkiidbch:Venom Wallet"
	"ppbibelpcjmhbdihakflkdcoccbgbkpo:UniSat Wallet"

	# Diğer
	"njbclohenpagagafbmdipcdoogfpnfhp:Ethereum Gas Prices"
)

# Tema extension'ları
theme_extensions_list=(
	"eimadpbcbfnmbkopoojfekhnkhdbieeh:Dark Reader"
	"clngdbkpkpeebahjckkjfobafhncgmne:Stylus"
	"bkkmolkhemgaeaeggcmfbghljjjoofoh:Catppuccin Mocha Theme"
)

# Chrome Web Store base URL
STORE_URL="https://chromewebstore.google.com/detail"

# Extension URL'si oluştur
get_extension_url() {
	local ext_id="$1"
	echo "${STORE_URL}/${ext_id}"
}

# Extension'ı tarayıcıda aç
open_extension() {
	local ext_id="$1"
	local ext_name="$2"
	local url=$(get_extension_url "$ext_id")

	echo -e "${BLUE}📦 Açılıyor:${NC} ${YELLOW}${ext_name}${NC}"
	echo -e "${CYAN}   URL: ${url}${NC}"

	# Brave'i çalıştırmayı dene
	if command -v brave &>/dev/null; then
		brave "$url" >/dev/null 2>&1 &
		sleep 2
	else
		echo -e "${RED}   ⚠️  Brave bulunamadı!${NC}"
		return 1
	fi
}

# Ana menü
show_menu() {
	echo ""
	echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
	echo -e "${YELLOW}Kurulum Seçenekleri:${NC}"
	echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
	echo -e "${CYAN}1)${NC} Tüm extension'ları kur (Tema hariç)"
	echo -e "${CYAN}2)${NC} Sadece Güvenlik & Gizlilik extension'larını kur"
	echo -e "${CYAN}3)${NC} Sadece Prodüktivite extension'larını kur"
	echo -e "${CYAN}4)${NC} Sadece Kripto Cüzdanlarını kur"
	echo -e "${CYAN}5)${NC} Tema extension'larını kur"
	echo -e "${CYAN}6)${NC} Tek tek extension seç ve kur"
	echo -e "${CYAN}7)${NC} Extension listesini göster (URL'ler)"
	echo -e "${CYAN}8)${NC} Yüklü extension'ları kontrol et"
	echo -e "${CYAN}9)${NC} Yüklü olmayan extension'ları kur"
	echo -e "${CYAN}0)${NC} Çıkış"
	echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
	echo ""
}

# Tüm extension'ları kur
install_all() {
	echo -e "${MAGENTA}🚀 Tüm extension'lar kurulacak...${NC}"
	echo ""

	local count=0
	local total=${#extensions_list[@]}

	for entry in "${extensions_list[@]}"; do
		((count++)) || true
		IFS=':' read -r ext_id ext_name <<<"$entry"
		echo -e "${GREEN}[${count}/${total}]${NC}"
		open_extension "$ext_id" "$ext_name"
	done

	echo ""
	echo -e "${GREEN}✅ Tüm extension'lar tarayıcıda açıldı!${NC}"
	echo -e "${YELLOW}💡 Her birinde 'Add to Brave' butonuna tıklayın.${NC}"
}

# Güvenlik extension'ları
install_security() {
	echo -e "${MAGENTA}🚀 Güvenlik & Gizlilik Extension'ları kurulacak...${NC}"
	echo ""

	local security_list=(
		"ddkjiahejlhfcafbddmgiahcphecmpfh:uBlock Origin Lite"
		"pkehgijcmpdhfbdbbnkijodmdjhbjlgp:Privacy Badger"
	)

	local count=0
	for entry in "${security_list[@]}"; do
		((count++)) || true
		IFS=':' read -r ext_id ext_name <<<"$entry"
		echo -e "${GREEN}[${count}/${#security_list[@]}]${NC}"
		open_extension "$ext_id" "$ext_name"
	done

	echo ""
	echo -e "${GREEN}✅ Güvenlik extension'ları açıldı!${NC}"
}

# Prodüktivite extension'ları
install_productivity() {
	echo -e "${MAGENTA}🚀 Prodüktivite Extension'ları kurulacak...${NC}"
	echo ""

	local prod_list=(
		"gfbliohnnapiefjpjlpjnehglfpaknnc:Surfingkeys"
		"eekailopagacbcdloonjhbiecobagjci:Go Back With Backspace"
		"inglelmldhjcljkomheneakjkpadclhf:Keep Awake"
		"kdejdkdjdoabfihpcjmgjebcpfbhepmh:Copy Link Address"
		"kgfcmiijchdkbknmjnojfngnapkibkdh:Picture-in-Picture Viewer"
		"mbcjcnomlakhkechnbhmfjhnnllpbmlh:Tab Pinner"
		"llimhhconnjiflfimocjggfjdlmlhblm:Reader Mode"
	)

	local count=0
	for entry in "${prod_list[@]}"; do
		((count++)) || true
		IFS=':' read -r ext_id ext_name <<<"$entry"
		echo -e "${GREEN}[${count}/${#prod_list[@]}]${NC}"
		open_extension "$ext_id" "$ext_name"
	done

	echo ""
	echo -e "${GREEN}✅ Prodüktivite extension'ları açıldı!${NC}"
}

# Kripto extension'ları
install_crypto() {
	echo -e "${MAGENTA}🚀 Kripto Cüzdanları kurulacak...${NC}"
	echo ""

	local crypto_list=(
		"acmacodkjbdgmoleebolmdjonilkdbch:Rabby Wallet"
		"anokgmphncpekkhclmingpimjmcooifb:Compass Wallet for Sei"
		"bfnaelmomeimhlpmgjnjophhpkkoljpa:Phantom"
		"bhhhlbepdkbapadjdnnojkbgioiodbic:Solflare Wallet"
		"dlcobpjiigpikoobohmabehhmhfoodbb:Ready Wallet"
		"dmkamcknogkgcdfhhbddcghachkejeap:Keplr"
		"enabgbdfcbaehmbigakijjabdpdnimlg:Manta Wallet"
		"nebnhfamliijlghikdgcigoebonmoibm:Leo Wallet"
		"ojggmchlghnjlapmfbnjholfjkiidbch:Venom Wallet"
		"ppbibelpcjmhbdihakflkdcoccbgbkpo:UniSat Wallet"
	)

	local count=0
	for entry in "${crypto_list[@]}"; do
		((count++)) || true
		IFS=':' read -r ext_id ext_name <<<"$entry"
		echo -e "${GREEN}[${count}/${#crypto_list[@]}]${NC}"
		open_extension "$ext_id" "$ext_name"
	done

	echo ""
	echo -e "${GREEN}✅ Kripto cüzdanları açıldı!${NC}"
}

# Tema extension'ları
install_themes() {
	echo -e "${MAGENTA}🚀 Tema Extension'ları kurulacak...${NC}"
	echo ""

	local count=0
	for entry in "${theme_extensions_list[@]}"; do
		((count++)) || true
		IFS=':' read -r ext_id ext_name <<<"$entry"
		echo -e "${GREEN}[${count}/${#theme_extensions_list[@]}]${NC}"
		open_extension "$ext_id" "$ext_name"
	done

	echo ""
	echo -e "${GREEN}✅ Tema extension'ları açıldı!${NC}"
}

# Yüklü olmayan extension'ları kur
install_missing() {
	echo -e "${MAGENTA}🔍 Yüklü olmayan extension'lar aranıyor...${NC}"
	echo ""

	local BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser/Default/Extensions"

	if [ ! -d "$BRAVE_DIR" ]; then
		echo -e "${RED}❌ Brave extensions dizini bulunamadı!${NC}"
		return
	fi

	local missing=()

	# Ana extension'ları kontrol et
	for entry in "${extensions_list[@]}"; do
		IFS=':' read -r ext_id ext_name <<<"$entry"
		if [ ! -d "$BRAVE_DIR/$ext_id" ]; then
			missing+=("$entry")
		fi
	done

	# Tema extension'larını kontrol et
	for entry in "${theme_extensions_list[@]}"; do
		IFS=':' read -r ext_id ext_name <<<"$entry"
		if [ ! -d "$BRAVE_DIR/$ext_id" ]; then
			missing+=("$entry")
		fi
	done

	if [ ${#missing[@]} -eq 0 ]; then
		echo -e "${GREEN}✅ Tüm extension'lar zaten yüklü!${NC}"
		return
	fi

	echo -e "${YELLOW}📋 ${#missing[@]} extension yüklü değil:${NC}"
	echo ""

	local count=0
	for entry in "${missing[@]}"; do
		((count++)) || true
		IFS=':' read -r ext_id ext_name <<<"$entry"
		echo -e "${GREEN}[${count}/${#missing[@]}]${NC}"
		open_extension "$ext_id" "$ext_name"
	done

	echo ""
	echo -e "${GREEN}✅ Eksik extension'lar açıldı!${NC}"
}

# Tek tek seçim
install_interactive() {
	echo -e "${MAGENTA}📋 Extension Listesi:${NC}"
	echo ""

	local i=1
	for entry in "${extensions_list[@]}"; do
		IFS=':' read -r ext_id ext_name <<<"$entry"
		printf "${CYAN}%2d)${NC} ${YELLOW}%-50s${NC} ${BLUE}%s${NC}\n" "$i" "$ext_name" "$ext_id"
		((i++)) || true
	done

	echo ""
	echo -e "${GREEN}Kurmak istediğiniz extension'ların numaralarını girin${NC}"
	echo -e "${GREEN}(Virgül ile ayırın, örn: 1,3,5 veya hepsi için 'all'):${NC}"
	read -r selection

	if [[ "$selection" == "all" ]]; then
		install_all
		return
	fi

	IFS=',' read -ra SELECTED <<<"$selection"
	for num in "${SELECTED[@]}"; do
		num=$(echo "$num" | xargs)
		if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#extensions_list[@]}" ]; then
			local idx=$((num - 1))
			local entry="${extensions_list[$idx]}"
			IFS=':' read -r ext_id ext_name <<<"$entry"
			open_extension "$ext_id" "$ext_name"
		else
			echo -e "${RED}❌ Geçersiz seçim: $num${NC}"
		fi
	done

	echo ""
	echo -e "${GREEN}✅ Seçilen extension'lar açıldı!${NC}"
}

# Extension listesini göster
show_list() {
	echo -e "${MAGENTA}📋 Mevcut Extension'lar:${NC}"
	echo ""

	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	printf "${GREEN}%-50s ${YELLOW}%-32s${NC}\n" "İsim" "ID"
	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

	for entry in "${extensions_list[@]}"; do
		IFS=':' read -r ext_id ext_name <<<"$entry"
		printf "%-50s ${BLUE}%-32s${NC}\n" "$ext_name" "$ext_id"
	done

	echo ""
	echo -e "${MAGENTA}🎨 Tema Extension'ları:${NC}"
	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

	for entry in "${theme_extensions_list[@]}"; do
		IFS=':' read -r ext_id ext_name <<<"$entry"
		printf "%-50s ${BLUE}%-32s${NC}\n" "$ext_name" "$ext_id"
	done

	echo ""
}

# Yüklü extension'ları kontrol et
check_installed() {
	echo -e "${MAGENTA}🔍 Yüklü Extension'lar Kontrol Ediliyor...${NC}"
	echo ""

	local BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser/Default/Extensions"

	if [ ! -d "$BRAVE_DIR" ]; then
		echo -e "${RED}❌ Brave extensions dizini bulunamadı!${NC}"
		return
	fi

	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	printf "${GREEN}%-50s ${YELLOW}%-15s ${BLUE}%-32s${NC}\n" "Extension" "Durum" "ID"
	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

	local installed=0
	local total=${#extensions_list[@]}

	for entry in "${extensions_list[@]}"; do
		IFS=':' read -r ext_id ext_name <<<"$entry"
		printf "%-50s " "$ext_name"

		if [ -d "$BRAVE_DIR/$ext_id" ]; then
			local version=$(ls -1 "$BRAVE_DIR/$ext_id" 2>/dev/null | head -n1)
			printf "${GREEN}%-15s${NC} " "✅ v${version}"
			printf "${BLUE}%-32s${NC}\n" "$ext_id"
			((installed++)) || true
		else
			printf "${RED}%-15s${NC} " "❌ Yüklü değil"
			printf "${BLUE}%-32s${NC}\n" "$ext_id"
		fi
	done

	# Tema extension'larını da kontrol et
	echo ""
	echo -e "${MAGENTA}🎨 Tema Extension'ları:${NC}"
	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

	for entry in "${theme_extensions_list[@]}"; do
		IFS=':' read -r ext_id ext_name <<<"$entry"
		printf "%-50s " "$ext_name"

		if [ -d "$BRAVE_DIR/$ext_id" ]; then
			local version=$(ls -1 "$BRAVE_DIR/$ext_id" 2>/dev/null | head -n1)
			printf "${GREEN}%-15s${NC} " "✅ v${version}"
			printf "${BLUE}%-32s${NC}\n" "$ext_id"
		else
			printf "${RED}%-15s${NC} " "❌ Yüklü değil"
			printf "${BLUE}%-32s${NC}\n" "$ext_id"
		fi
	done

	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo ""
	echo -e "${YELLOW}📊 İstatistik: ${GREEN}${installed}${NC}/${total} extension yüklü${NC}"
	echo ""
}

# Brave kontrolü
if ! command -v brave &>/dev/null; then
	echo -e "${RED}❌ Brave tarayıcısı bulunamadı!${NC}"
	echo -e "${YELLOW}Önce Brave'i kurun: home-manager switch${NC}"
	exit 1
fi

# Ana döngü
while true; do
	show_menu
	read -p "Seçiminiz (0-9): " choice

	case $choice in
	1) install_all ;;
	2) install_security ;;
	3) install_productivity ;;
	4) install_crypto ;;
	5) install_themes ;;
	6) install_interactive ;;
	7) show_list ;;
	8) check_installed ;;
	9) install_missing ;;
	0)
		echo -e "${GREEN}👋 Güle güle!${NC}"
		exit 0
		;;
	*)
		echo -e "${RED}❌ Geçersiz seçim!${NC}"
		;;
	esac

	echo ""
	read -p "Devam etmek için Enter'a basın..."
done
