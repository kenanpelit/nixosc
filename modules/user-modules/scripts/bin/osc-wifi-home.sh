#!/usr/bin/env bash
# wifi-setup.sh - NetworkManager bağlantılarını oluşturma

# Kullanım: ./wifi-setup.sh Ken_5_Parolası Ken_2_4_Parolası

# Hata kontrolü
if [ $# -ne 2 ]; then
	echo "Hata: İki parola girilmelidir."
	echo "Kullanım: $0 Ken_5_Parolası Ken_2_4_Parolası"
	exit 1
fi

# Parolaları değişkenlere atama
KEN_5_PASSWORD="$1"
KEN_2_4_PASSWORD="$2"

echo "NetworkManager bağlantıları yapılandırılıyor..."

# Mevcut bağlantıları kontrol et ve gerekirse sil
if nmcli connection show "Ken_5" &>/dev/null; then
	echo "Ken_5 bağlantısı zaten var, siliniyor..."
	nmcli connection delete "Ken_5"
fi

if nmcli connection show "Ken_2_4" &>/dev/null; then
	echo "Ken_2_4 bağlantısı zaten var, siliniyor..."
	nmcli connection delete "Ken_2_4"
fi

# Ken_5 bağlantısını oluştur
echo "Ken_5 bağlantısı oluşturuluyor..."
nmcli connection add \
	type wifi \
	con-name "Ken_5" \
	ifname "*" \
	autoconnect yes \
	ssid "Ken_5" \
	wifi.powersave 0 \
	ipv4.method manual \
	ipv4.addresses "192.168.0.100/24" \
	ipv4.gateway "192.168.0.1" \
	ipv4.dns "1.1.1.1" \
	ipv6.method disabled \
	wifi-sec.key-mgmt wpa-psk \
	wifi-sec.psk "$KEN_5_PASSWORD" \
	connection.autoconnect-priority 20

# Ken_2_4 bağlantısını oluştur
echo "Ken_2_4 bağlantısı oluşturuluyor..."
nmcli connection add \
	type wifi \
	con-name "Ken_2_4" \
	ifname "*" \
	autoconnect yes \
	ssid "Ken_2_4" \
	wifi.powersave 0 \
	ipv4.method manual \
	ipv4.addresses "192.168.0.101/24" \
	ipv4.gateway "192.168.0.1" \
	ipv4.dns "1.1.1.1" \
	ipv6.method disabled \
	wifi-sec.key-mgmt wpa-psk \
	wifi-sec.psk "$KEN_2_4_PASSWORD" \
	connection.autoconnect-priority 10

echo "NetworkManager bağlantıları başarıyla yapılandırıldı!"
echo "Ken_5: 192.168.0.100/24 (Öncelik: 20)"
echo "Ken_2_4: 192.168.0.101/24 (Öncelik: 10)"
