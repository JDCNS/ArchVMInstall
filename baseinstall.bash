#!/bin/bash
# Simple script to lead you through Arch VM install using encrypted
# partition with LVM containers.
#
# You can download from the Arch install prompt via "wget https://github.com/JDCNS/ArchVMInstall/raw/master/baseinstall.bash"
#
# Why LVM on LUKS?
# "LVM on LUKS
# "A simple way to realize encrypted swap with suspend-to-disk support is by
# using LVM ontop the encryption layer, so one encrypted partition can
# contain infinite filesystems (root, swap, home, ...). Follow the
# instructions on Dm-crypt/Encrypting an entire system#LVM on LUKS and then
# just configure the required kernel parameters."
#
# ~ https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption#LVM_on_LUKS
#
# IMPORTANT NOTE: I have not at this time tested the suspend-to-disk. This
# is a work in progress!
#
# Much owed to Linus Arver,
# http://listx.github.io/post/2013-03-10-installing-arch-and-enabling-system-encryption.html.
#
# 

# Important variables
# VM is assumed to have 18GB VDI.
# Change if different
BOOTSIZE="250MB"
ROOTSIZE="10G"
SWAPSIZE="2G"

AnyKey()
{
	echo "Press any key when ready or [Ctr]-[C] to cancel."
	read ANYKEY
}

echo "Set up 2 PRIMARY partitions:"
echo "This script assumes ${BOOTSIZE} for boot partition and"
echo "the rest for LVM partition!"
echo
echo "First primary partition must be BOOTable."
echo "Second primary partition must be type '8E'."
echo
AnyKey

cfdisk /dev/sda

echo "We'll now setup LUKS encryption"
echo "Be sure to put in your encryption password when prompted."
AnyKey

cryptsetup -c aes-xts-plain -y -s 512 luksFormat /dev/sda2

echo "We now need to decrypt partition just set up and mount it."
echo "Be sure to enter same password you just used to create it."

cryptsetup luksOpen /dev/sda2 luks

echo "Setting up LVM volume group 'vg0' with 'vg0-root', 'vg0-swap',"
echo "and vg0-home containers."
pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate --size ${ROOTSIZE} vg0 --name root
lvcreate --size ${SWAPSIZE} --contiguous y vg0 --name swap
lvcreate -l +100%FREE vg0 --name home

echo "Initializing filesystems with ext4 and swap."
mkfs.ext4 /dev/sda1 # the boot partition
mkfs.ext4 /dev/mapper/vg0-root
mkfs.ext4 /dev/mapper/vg0-home
mkswap /dev/mapper/vg0-swap

echo "Mounting the logical volumes to install Arch Linux onto"
echo "them. Watch for errors!"
mount -v /dev/mapper/vg0-root /mnt # /mnt is our system's "/" root   directory
mkdir /mnt/boot
mount -v /dev/sda1 /mnt/boot
mkdir /mnt/home
mount -v /dev/mapper/vg0-home /mnt/home
swapon /dev/mapper/vg0-swap

echo "Please look for any errors, then press any key to continue."
AnyKey

echo "You will now inspect the package download mirrors and adjust if"
echo "needed."
echo
AnyKey
nano /etc/pacman.d/mirrorlist

echo "We will now download and install the core packages."
AnyKey
pacstrap -i /mnt base base-devel

echo
echo "Generating the filesystem tables needed for when the system"
echo "first starts. Inspect to be sure all 4 partitions are there:"
echo "1st one is /boot and the 2nd one is our LVM containing /, /home,"
echo "and swap)."
echo
AnyKey
genfstab -U -p /mnt >> /mnt/etc/fstab
nano /mnt/etc/fstab

wget https://github.com/JDCNS/ArchVMInstall/raw/master/vmconfigure.bash
chmod a+x vmconfigure.bash
cp vmconfigure.bash /mnt
arch-chroot /mnt /vmconfigure.bash
echo
echo "The terminal portion of the install has finished."
echo "Next, the computer will reboot into the new installation"
echo "if all went well."
AnyKey

umount /mnt/boot
umount /mnt/home
umount /mnt
swapoff -a
reboot

