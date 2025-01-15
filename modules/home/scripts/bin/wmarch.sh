#!/usr/bin/env bash

## Kullanım örnekleri:
## Normal çalıştırma
#./vmarch.sh
## Arka planda çalıştırma
#./vmarch.sh --daemon
## Ekransız çalıştırma
#./vmarch.sh --headless
## Özel port ile çalıştırma
#./vmarch.sh --port 2255
## Özel isim ile çalıştırma
#./vmarch.sh --name archvm
## Tüm özellikleri birlikte kullanma
#./vmarch.sh --name archvm --port 2255 --daemon

# Varsayılan değerler
BASE_DIR="/repo/san/arch"
OVMF_CODE="/usr/share/edk2-ovmf/x64/OVMF.4m.fd"
OVMF_VARS_TEMPLATE="/usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd"
ISO_FILE="$BASE_DIR/archlinux-2024.09.01-x86_64.iso"
VARS_FILE="$BASE_DIR/OVMF_VARS.fd"
DISK_FILE="$BASE_DIR/disk.qcow2"
SSH_PORT="2244"
VM_NAME="arch"
USERNAME="kenan"
DISPLAY_MODE="spice" # spice veya none
SPICE_PORT="5930"
DAEMON=false

# Wayland ve Share dizinleri
WAYLAND_SOCKET_DIR="/run/user/1000"
SHARE_DIR="/home/kenan/.share"

# Gerekli paketleri kontrol et
check_dependencies() {
	local packages=("qemu-system-x86" "spice" "spice-vdagent")
	for pkg in "${packages[@]}"; do
		if ! pacman -Qi "$pkg" &>/dev/null; then
			echo "Gerekli paket eksik: $pkg"
			echo "Lütfen yükleyin: sudo pacman -S $pkg"
			exit 1
		fi
	done
}

# Yardım fonksiyonu
show_help() {
	echo "Kullanım: $0 [SEÇENEKLER]"
	echo "Seçenekler:"
	echo "  -n, --name NAME     VM adını ayarla (varsayılan: arch)"
	echo "  -m, --memory SIZE   Bellek boyutunu ayarla (varsayılan: 4G)"
	echo "  -p, --port PORT     SSH portunu ayarla (varsayılan: 2244)"
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
		exit 1
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

# Bağımlılıkları kontrol et
check_dependencies

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
    -monitor unix:/run/user/1000/qemu-monitor.sock,server,nowait"

# Display moduna göre parametreleri ekle
if [ "$DISPLAY_MODE" = "none" ]; then
	QEMU_CMD="$QEMU_CMD -display none -nographic"
else
	# QEMU monitor ve VNC/SPICE desteği
	QEMU_CMD="$QEMU_CMD \
        -device qxl-vga \
        -device virtio-serial-pci \
        -chardev spicevmc,id=vdagent,name=vdagent \
        -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
        -spice unix=on,addr=/run/user/1000/qemu-spice.socket,disable-ticketing=on \
        -monitor unix:/run/user/1000/qemu-monitor.sock,server,nowait"
fi

# Daemon modu için parametre ekle
if [ "$DAEMON" = true ]; then
	QEMU_CMD="$QEMU_CMD -daemonize"
fi

# VM başlatma bilgilerini göster
echo "VM başlatılıyor..."
echo "1. VM'e SSH ile bağlanmak için:"
echo "   ssh -p $SSH_PORT arch"
echo ""
echo "2. SPICE ile bağlanmak için:"
echo "   remote-viewer spice://localhost:$SPICE_PORT"
echo ""
echo "3. VM içinde yapılması gerekenler:"
echo "   a) Wayland socket için:"
echo "      mkdir -p /run/user/1000/"
echo "      mount -t 9p -o trans=virtio,version=9p2000.L hostshare /run/user/1000/"
echo ""
echo "   b) Share klasörü için:"
echo "      mkdir -p /home/kenan/share"
echo "      mount -t 9p -o trans=virtio,version=9p2000.L sharefolder /home/kenan/share"
echo ""
echo "   c) Otomatik mount için /etc/fstab'a ekleyin:"
echo "      hostshare   /run/user/1000    9p  trans=virtio,version=9p2000.L    0   0"
echo "      sharefolder /home/kenan/share 9p  trans=virtio,version=9p2000.L    0   0"
echo ""
echo "   d) SPICE için gerekli paketleri yükleyin:"
echo "      sudo pacman -S spice-vdagent xf86-video-qxl"
echo ""

# Komutu çalıştır
eval $QEMU_CMD
