#!/usr/bin/env bash

## Kullanım örnekleri:
## Normal çalıştırma
#./vmubuntu.sh
## Arka planda çalıştırma
#./vmubuntu.sh --daemon
## Ekransız çalıştırma
#./vmubuntu.sh --headless
## Özel port ile çalıştırma
#./vmubuntu.sh --port 2255
## Özel isim ile çalıştırma
#./vmubuntu.sh --name ubuntuvm
## Tüm özellikleri birlikte kullanma
#./vmubuntu.sh --name ubuntuvm --port 2255 --daemon

# Varsayılan değerler
BASE_DIR="/repo/san/ubuntu"
OVMF_CODE="/usr/share/edk2-ovmf/x64/OVMF.4m.fd"
OVMF_VARS_TEMPLATE="/usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd"
ISO_FILE="$BASE_DIR/ubuntu-24.04.1-desktop-amd64.iso"
VARS_FILE="$BASE_DIR/OVMF_VARS.fd"
DISK_FILE="$BASE_DIR/disk.qcow2"
SSH_PORT="2255"
VM_NAME="ubuntu"
USERNAME="kenan"
DISPLAY_MODE="wayland" # wayland, spice veya none
SPICE_PORT="5930"
DAEMON=false

# Wayland ve Share dizinleri
WAYLAND_SOCKET_DIR="/run/user/1000"
SHARE_DIR="/home/kenan/.share"

# Gerekli paketleri kontrol et
check_dependencies() {
	local packages=("qemu-system-x86" "spice-client-gtk" "spice-vdagent")
	for pkg in "${packages[@]}"; do
		if ! dpkg -l "$pkg" &>/dev/null; then
			echo "Gerekli paket eksik: $pkg"
			echo "Lütfen yükleyin: sudo apt install $pkg"
			exit 1
		fi
	done
}

# Yardım fonksiyonu
show_help() {
	echo "Kullanım: $0 [SEÇENEKLER]"
	echo "Seçenekler:"
	echo "  -n, --name NAME     VM adını ayarla (varsayılan: ubuntu)"
	echo "  -m, --memory SIZE   Bellek boyutunu ayarla (varsayılan: 4G)"
	echo "  -p, --port PORT     SSH portunu ayarla (varsayılan: 2255)"
	echo "  --spice-port PORT   SPICE portunu ayarla (varsayılan: 5930)"
	echo "  -d, --daemon        Arka planda çalıştır"
	echo "  -h, --help          Bu yardım mesajını göster"
	echo "  --headless          Ekransız çalıştır"
	exit 0
}

# Dizinlerin varlığını kontrol et
check_directories() {
	if [ ! -d "$WAYLAND_SOCKET_DIR" ]; then
		echo "Hata: Wayland socket dizini bulunamadı: $WAYLAND_SOCKET_DIR"
		exit 1
	fi

	if [ ! -d "$SHARE_DIR" ]; then
		echo "Hata: Paylaşım dizini bulunamadı: $SHARE_DIR"
		echo "Oluşturuluyor..."
		mkdir -p "$SHARE_DIR"
	fi
}

# Parametreleri işle
while [[ $# -gt 0 ]]; do
	case $1 in
	-n | --name)
		VM_NAME="$2"
		shift 2
		;;
	-m | --memory)
		MEMORY="$2"
		shift 2
		;;
	-p | --port)
		SSH_PORT="$2"
		shift 2
		;;
	--spice-port)
		SPICE_PORT="$2"
		shift 2
		;;
	-d | --daemon)
		DAEMON=true
		shift
		;;
	--headless)
		DISPLAY_MODE="none"
		shift
		;;
	-h | --help)
		show_help
		;;
	*)
		echo "Bilinmeyen seçenek: $1"
		show_help
		;;
	esac
done

# VARS dosyası kontrolü ve oluşturma
if [ ! -f "$VARS_FILE" ]; then
	echo "Yeni VARS dosyası oluşturuluyor..."
	cp "$OVMF_VARS_TEMPLATE" "$VARS_FILE"
fi

# Gerekli dosyaların kontrolü
for file in "$OVMF_CODE" "$VARS_FILE" "$DISK_FILE" "$ISO_FILE"; do
	if [ ! -f "$file" ]; then
		echo "Hata: Dosya bulunamadı: $file"
		exit 1
	fi
done

# Dizinleri kontrol et
check_directories

# Temel QEMU komutunu oluştur
QEMU_CMD="qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -smp 2 \
    -name \"$VM_NAME\" \
    -drive file=\"$OVMF_CODE\",if=pflash,format=raw,readonly=on \
    -drive file=\"$VARS_FILE\",if=pflash,format=raw \
    -drive file=\"$DISK_FILE\",if=virtio \
    -cdrom \"$ISO_FILE\" \
    -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare \
    -fsdev local,security_model=passthrough,id=fsdev0,path=$WAYLAND_SOCKET_DIR \
    -device virtio-9p-pci,id=fs1,fsdev=fsdev1,mount_tag=sharefolder \
    -fsdev local,security_model=passthrough,id=fsdev1,path=$SHARE_DIR \
    -vga std \
    -device virtio-tablet \
    -device virtio-mouse \
    -device virtio-keyboard \
    -monitor unix:/run/user/1000/qemu-monitor.sock,server,nowait"

# Display moduna göre parametreleri ekle
if [ "$DISPLAY_MODE" = "none" ]; then
	QEMU_CMD="$QEMU_CMD -display none -nographic"
elif [ "$DISPLAY_MODE" = "wayland" ]; then
	QEMU_CMD="$QEMU_CMD \
        -display sdl \
        -device virtio-serial-pci \
        -device virtserialport,chardev=spicevmc,name=vdagent \
        -chardev spicevmc,id=spicevmc,debug=0,name=vdagent"
else
	QEMU_CMD="$QEMU_CMD \
        -device qxl-vga \
        -device virtio-serial-pci \
        -chardev spicevmc,id=vdagent,name=vdagent \
        -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
        -spice unix=on,addr=/run/user/1000/qemu-spice.socket,disable-ticketing=on"
fi

# Daemon modu için parametre ekle
if [ "$DAEMON" = true ]; then
	QEMU_CMD="$QEMU_CMD -daemonize"
fi

# VM başlatma bilgilerini göster
echo "VM başlatılıyor..."
echo "1. VM'e SSH ile bağlanmak için:"
echo "   ssh -p $SSH_PORT ubuntu@localhost"
echo ""

if [ "$DISPLAY_MODE" = "spice" ]; then
	echo "2. SPICE ile bağlanmak için:"
	echo "   remote-viewer spice+unix:///run/user/1000/qemu-spice.socket"
	echo ""
fi

echo "3. VM içinde yapılması gerekenler:"
echo "   a) Gerekli paketleri yükleyin:"
echo "      sudo apt update"
echo "      sudo apt install -y qemu-guest-agent spice-vdagent spice-webdavd xdg-desktop-portal-gtk virtio-win"
echo ""
echo "   b) Wayland aktifleştirme:"
echo "      sudo sed -i 's/#WaylandEnable=false/WaylandEnable=true/' /etc/gdm3/custom.conf"
echo ""
echo "   c) Share klasörü için:"
echo "      mkdir -p /home/kenan/share"
echo "      sudo mount -t 9p -o trans=virtio,version=9p2000.L sharefolder /home/kenan/share"
echo ""
echo "   d) Otomatik mount için /etc/fstab'a ekleyin:"
echo "      sharefolder /home/kenan/share 9p trans=virtio,version=9p2000.L 0 0"
echo ""

# Komutu çalıştır
eval $QEMU_CMD
