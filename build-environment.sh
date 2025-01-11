#!/bin/bash
# Build Alpine Recovery Environment
# By: kodeazmi.id

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Direktori kerja
WORK_DIR="alpine-recovery"
CHROOT_DIR="$WORK_DIR/chroot"

echo -e "${GREEN}[+] Memulai pembuatan Alpine Recovery Environment${NC}"

# Buat direktori kerja
mkdir -p $CHROOT_DIR
cd $WORK_DIR

echo -e "${YELLOW}[*] Downloading Alpine minirootfs...${NC}"
wget https://dl-cdn.alpinelinux.org/alpine/v3.17/releases/x86_64/alpine-minirootfs-3.17.0-x86_64.tar.gz

echo -e "${YELLOW}[*] Extracting minirootfs...${NC}"
tar xzf alpine-minirootfs-*.tar.gz -C $CHROOT_DIR

# Setup repositori
cat > $CHROOT_DIR/etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/v3.17/main
https://dl-cdn.alpinelinux.org/alpine/v3.17/community
EOF

# Copy resolv.conf untuk akses internet dalam chroot
cp /etc/resolv.conf $CHROOT_DIR/etc/resolv.conf

# Buat script untuk dijalankan dalam chroot
cat > $CHROOT_DIR/setup.sh << 'EOF'
#!/bin/sh
# Setup dalam chroot environment

# Update repository
apk update

# Install paket yang diperlukan
apk add --no-cache \
    alpine-base \
    musl \
    busybox \
    openrc \
    ntfs-3g \
    multipath-tools \
    util-linux \
    curl \
    wget

# Setup service
rc-update add local default
rc-update add firstboot default

# Buat direktori untuk script startup
mkdir -p /etc/local.d

# Buat script startup untuk Windows installer
cat > /etc/local.d/windows-install.start << 'EEOF'
#!/bin/sh

# Mount filesystem yang diperlukan
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Setup network
udhcpc -i eth0

# Download dan jalankan script instalasi Windows
curl -o /root/setup.sh https://raw.githubusercontent.com/yourusername/repo/main/setup.sh
chmod +x /root/setup.sh
/root/setup.sh
EEOF

chmod +x /etc/local.d/windows-install.start
EOF

chmod +x $CHROOT_DIR/setup.sh

echo -e "${YELLOW}[*] Entering chroot and setting up environment...${NC}"
# Mount sistem yang diperlukan untuk chroot
mount -t proc none $CHROOT_DIR/proc
mount -t sysfs none $CHROOT_DIR/sys
mount -t devtmpfs none $CHROOT_DIR/dev

# Chroot dan jalankan setup
chroot $CHROOT_DIR /bin/sh /setup.sh

# Unmount
umount $CHROOT_DIR/proc
umount $CHROOT_DIR/sys
umount $CHROOT_DIR/dev

echo -e "${GREEN}[+] Environment setup selesai${NC}"

# Buat ISO (ini perlu tambahan tools dan konfigurasi)
echo -e "${YELLOW}[*] Membuat ISO...${NC}"
# TODO: Tambahkan langkah pembuatan ISO

echo -e "${GREEN}[+] Proses selesai!${NC}"