#!/bin/bash
Green="\033[32m"
Font="\033[0m"

echo -e "${Green}<--- Updating--->${Font}"
sudo apt-get update && apt-get upgrade -y
apt-get autoremove -y
echo -e "${Green}<--- Complete Update --->${Font}"

echo -e "${Green}<--- Settings OS, Installing Mergerfs --->${Font}"
# OS on USB 3.0
echo xhci_hcd >> /etc/initramfs-tools/modules
echo usbhid >> /etc/initramfs-tools/modules
echo hid >> /etc/initramfs-tools/modules
echo usb_storage >> /etc/initramfs-tools/modules
sudo update-initramfs -u
timedatectl set-timezone Asia/Bangkok
echo -e "vm.swappiness=0" | sudo tee -a /etc/sysctl.conf
sed -i 's|/ ext4 defaults|/ ext4 noatime,errors=remount-ro|' /etc/fstab
sed -i 's|/swap.img|#/swap.img|' /etc/fstab
echo -e "#\x21/bin/sh\\nfstrim -v /" | sudo tee /etc/cron.daily/trim
sudo chmod +x /etc/cron.daily/trim
echo  fs.inotify.max_user_watches=262144  >> /etc/sysctl.conf
sysctl -p
swapoff -a
cd /tmp
wget https://github.com/trapexit/mergerfs/releases/download/2.32.2/mergerfs_2.32.2.ubuntu-focal_amd64.deb
dpkg -i *.deb
rm -rf *.deb
mkdir -p /mnt/disk{1,2}
mkdir -p /mnt/storage
chmod 775 -R /mnt
mkdir -p /mnt/media
mkdir -p /mnt/media/gmedia/{original,foitong,movies,series}
chown -R alief:alief /mnt/media
chmod 775 -R /mnt/media
#mkdir -p /media/gmedia/a_avengers
#chown -R neunghaha28:neunghaha28 /media
#chmod 775 -R /media
echo "LABEL=disk1 /mnt/disk1 ext4 defaults 0 0" >> /etc/fstab
echo "LABEL=disk2 /mnt/disk2 ext4 defaults 0 0" >> /etc/fstab
echo "/mnt/disk*=RW /mnt/storage fuse.mergerfs use_ino,cache.files=auto-full,dropcacheonclose=true,allow_other,func.getattr=newest,category.create=mfs,minfreespace=10G,fsname=mergerfs 0 0" >> /etc/fstab
mount -a
echo -e "${Green}<--- Complete Settings OS --->${Font}"

echo -e "${Green}<--- Installing sanba vsftpd --->${Font}"
sudo apt-get install samba vsftpd nfs-kernel-server -y
echo -e "${Green}<--- Complete sanba vsftpd Install --->${Font}"

echo -e "${Green}<--- Installing Jq --->${Font}"
apt install jq -y
echo -e "${Green}<--- Complete Jq Install --->${Font}"

echo -e "${Green}<--- Installing Rclone --->${Font}"
curl https://rclone.org/install.sh | sudo bash -s beta
echo "user_allow_other" >> /etc/fuse.conf
echo -e "${Green}<--- Complete Rclone Install --->${Font}"

echo -e "${Green}<--- Installing Docker --->${Font}"
cd /tmp
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/test/amd64/containerd.io_1.4.3-1_amd64.deb \
https://download.docker.com/linux/ubuntu/dists/focal/pool/test/amd64/docker-ce-cli_20.10.2~3-0~ubuntu-focal_amd64.deb \
https://download.docker.com/linux/ubuntu/dists/focal/pool/test/amd64/docker-ce-rootless-extras_20.10.2~3-0~ubuntu-focal_amd64.deb \
https://download.docker.com/linux/ubuntu/dists/focal/pool/test/amd64/docker-ce_20.10.2~3-0~ubuntu-focal_amd64.deb
dpkg -i *.deb
rm -rf *.deb
echo -e "${Green}<--- Complete Docker Install --->${Font}"

echo -e "${Green}<--- Installing Docker Compose --->${Font}"
cd /tmp
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.0-rc1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo -e "${Green}<--- Complete Docker Compose Install --->${Font}"

echo -e "${Green}<--- Installing Config, Service, Other... --->${Font}"
cp -pf /etc/samba/smb.conf /etc/samba/smb.conf.bak
rm -rf /etc/samba/smb.conf
cp /mnt/storage/github/homescripts/etc/smb.conf /etc/samba/
cp -pf /etc/vsftpd.conf /etc/vsftpd.conf.bak
rm -rf /etc/vsftpd.conf
cp /mnt/storage/github/homescripts/etc/vsftpd.conf /etc/
echo "/mnt/storage/gmedia  *(ro,sync,fsid=0,insecure,no_subtree_check)" >> /etc/exports
exportfs -a
cp /mnt/storage/github/homescripts/systemd/rclone.service /etc/systemd/system/
cp /mnt/storage/github/homescripts/systemd/gmedia.service /etc/systemd/system/
chown root:root /etc/systemd/system/rclone.service /etc/systemd/system/gmedia.service
systemctl restart vsftpd smbd
systemctl enable --now rclone gmedia
rm -rf /tmp/*
echo -e "${Green}<--- Complete Config, Service, Other... Install --->${Font}"

echo -e "${Green}<--- Installing Container --->${Font}"
docker network create nginx-proxy
docker login --username neunghaha28 --password 3d8a1b76-353c-4d1b-835a-bb6672276ee0
docker-compose -f /mnt/storage/github/homescripts/docker-compose/docker-compose.yml up -d
echo -e "${Green}<--- Complete Container Install --->${Font}"
