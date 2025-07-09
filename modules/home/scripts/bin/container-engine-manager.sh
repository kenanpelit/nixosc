#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC Container Engine Manager
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Comprehensive container engine management utility for Docker
#                and Podman with cross-migration support
#
#   Features:
#   - Automatic distribution detection
#   - Docker and Podman installation
#   - Migration between Docker and Podman
#   - Complete system cleanup for both engines
#   - Support for Arch, Debian and Fedora based systems
#
#   License: MIT
#
#===============================================================================

# Help function
show_help() {
	echo "Container Engine Manager - v1.0.0"
	echo
	echo "Description:"
	echo "  A script to manage container engines (Docker and Podman) installations,"
	echo "  migrations and system cleanup."
	echo
	echo "Usage:"
	echo "  $0 [COMMAND]"
	echo
	echo "Commands:"
	echo "  podman2docker    Migrate from Podman to Docker (includes cleanup)"
	echo "  docker2podman    Migrate from Docker to Podman (includes cleanup)"
	echo "  clean-podman     Remove Podman and cleanup the system"
	echo "  clean-docker     Remove Docker and cleanup the system"
	echo "  help            Show this help message"
	echo
	echo "Examples:"
	echo "  $0 podman2docker     # Migrate from Podman to Docker"
	echo "  $0 clean-docker      # Remove Docker completely"
	echo
	echo "Note:"
	echo "  This script requires root privileges for installation and cleanup operations."
	echo "  Please make sure to backup your containers and images before migration."
	echo
	exit 1
}

# Dağıtım türünü belirleme
DISTRO=$(grep -i -E '^ID(=|_NAME)=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')

# Paket yöneticisini belirleme
if command -v apt-get &>/dev/null; then
	PKG_MGR="apt-get"
elif command -v dnf &>/dev/null; then
	PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
	PKG_MGR="pacman"
else
	echo "Desteklenmeyen dağıtım. Lütfen el ile kurulum yapın."
	exit 1
fi

# Podman için kapsamlı temizleme
clean_podman() {
	if [ "$DISTRO" == "arch" ]; then
		sudo $PKG_MGR -Rns podman podman-compose
	else
		sudo $PKG_MGR remove -y podman podman-compose
	fi

	# Yapılandırma dosyalarını silme
	sudo rm -rf /etc/containers/
	sudo rm -rf /etc/cni/
	sudo rm -rf /var/lib/containers/
	sudo rm -rf /var/run/containers/
	sudo rm -rf /var/lib/pod/
	sudo rm -rf /var/lib/registries/

	# Veritabanlarını silme
	sudo rm -rf /var/lib/container_share/
	sudo rm -rf /var/lib/containers/storage/
	sudo rm -rf /var/lib/registries/

	# Çakışan paketleri kaldırma
	if [ "$DISTRO" == "arch" ]; then
		sudo pacman -Rns container-selinux || true
		sudo pacman -Rns container-diff || true
		sudo pacman -Rns skopeo || true
		sudo pacman -Scc --noconfirm
	fi

	echo "Podman ve ilgili tüm bileşenler başarıyla kaldırıldı."
}

# Docker için kapsamlı temizleme
clean_docker() {
	if [ "$DISTRO" == "arch" ]; then
		sudo $PKG_MGR -Rns docker docker-compose
	else
		sudo $PKG_MGR remove -y docker docker-compose
	fi

	# Docker yapılandırma dosyalarını silme
	sudo rm -rf /etc/docker/
	sudo rm -rf /var/lib/docker/
	sudo rm -rf /var/run/docker/
	sudo rm -rf ~/.docker/

	# Docker ağ yapılandırmalarını silme
	sudo rm -rf /var/lib/docker/network/
	sudo rm -rf /etc/systemd/system/docker.service.d/

	# Docker grup ve kullanıcı temizliği
	sudo groupdel docker || true

	# Sistem servislerini temizleme
	sudo systemctl stop docker || true
	sudo systemctl disable docker || true
	sudo rm -rf /etc/systemd/system/docker.service
	sudo rm -rf /etc/systemd/system/docker.socket
	sudo systemctl daemon-reload

	# Docker bağımlılıklarını temizleme
	if [ "$DISTRO" == "arch" ]; then
		sudo pacman -Rns docker-cli || true
		sudo pacman -Rns containerd || true
		sudo pacman -Scc --noconfirm
	fi

	echo "Docker ve ilgili tüm bileşenler başarıyla kaldırıldı."
}

# Podman kurulumu
install_podman() {
	if [ "$DISTRO" == "arch" ]; then
		sudo $PKG_MGR -S --noconfirm podman podman-compose
	else
		sudo $PKG_MGR install -y podman podman-compose
	fi
}

# Docker kurulumu
install_docker() {
	if [ "$DISTRO" == "arch" ]; then
		sudo $PKG_MGR -S --noconfirm docker docker-compose
	else
		curl -fsSL https://get.docker.com -o get-docker.sh
		sudo sh get-docker.sh
		sudo $PKG_MGR install -y docker-compose
	fi
}

# Podman'dan Docker'a geçiş
podman2docker() {
	clean_podman
	install_docker
}

# Docker'dan Podman'a geçiş
docker2podman() {
	clean_docker
	install_podman
}

# Kullanım kontrolü
case "$1" in
"podman2docker")
	podman2docker
	;;
"docker2podman")
	docker2podman
	;;
"clean-podman")
	clean_podman
	;;
"clean-docker")
	clean_docker
	;;
"help" | "-h" | "--help" | "")
	show_help
	;;
*)
	echo "Hata: Geçersiz komut '$1'"
	echo "Kullanılabilir komutlar için: $0 help"
	exit 1
	;;
esac
