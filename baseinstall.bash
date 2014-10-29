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

AnyKey()
{
	echo "Press any key when ready or [Ctr]-[C] to cancel."
	read ANYKEY
}

# Important variables
INSTALLDISK="sda"
BOOTPART="1"
SYSTEMPART="2"
LVMGROUP="vg0"
# Well, after setting up a test machine, you might want to do the real thing, and for me
# it is far too easy to forget to change this variable (not sure why, it just is).
echo
echo -n "Are you installing in a VM [Y/n]? "
read INSTALLINGINVM
if [ "$INSTALLINGINVM" = "y" -o "$INSTALLINGINVM" = "Y" -o "$INSTALLINGINVM." = "." ]
then
	INSTALLINGINVM="Y"
else
	INSTALLINGINVM="N"
fi

if [ "$INSTALLINGINVM" = "Y" ]
then
	# VM is assumed to have 14GB VDI.
	# Change if different
	BOOTSIZE="250MB"
	ROOTSIZE="8G"
	SWAPSIZE="1G"
	HOMESIZE="-l +100%FREE"
else
	echo
	echo "We need to specify partition sizes."
	echo "Normally, the boot partition can be small, but you"
	echo "should leave room for upgrades."
	echo "Minimum should be 100MB, but recommend 250MB."
	echo "If you change it DON'T FORGET 'MB' AT END."
	echo
	echo -n "Input number of MB for /boot [250MB]: "
	read BOOTSIZE
	if [ "$BOOTSIZE." = "." ]
	then
		BOOTSIZE="250MB"
	fi
	echo
	echo "Root directory needs enough for programs and system files."
	echo "Default is 40GB (does anyone really use that much?)."
	echo
	echo -n "Input size of / [40G]: "
	read ROOTSIZE
	if [ "$ROOTSIZE." = "." ]
	then
		ROOTSIZE="40G"
	fi
	echo
	echo "Swap size should be at least twice your RAM for"
	echo " hibernation.  4GB RAM is assumed."
	echo
	echo -n "Input size of /swap [8G]: "
	read SWAPSIZE
	if [ "$SWAPSIZE." = "." ]
	then
		SWAPSIZE="8G"
	fi
	echo
	echo "Home size is normally largest on a PC, so"
	echo " assuming rest of drive unless you change it."
	echo " Use --size homesizeG if not."
	echo
	echo -n "Input parameters for /home [-l +100%FREE]: "
	read HOMESIZE
	if [ "$HOMESIZE." = "." ]
	then
		HOMESIZE="-l +100%FREE"
	fi

	echo
	echo "Let's review:"
	echo "/boot : $BOOTSIZE"
	echo "/ :     $ROOTSIZE"
	echo "/swap : $SWAPSIZE"
	echo "and $HOMESIZE for /home"
	echo "If this is not OK, be sure to [Ctr]-[C] now!"
	AnyKey
fi

echo "Set up 2 PRIMARY partitions:"
echo "This script assumes ${BOOTSIZE} for boot partition and"
echo "the rest for LVM partition!"
echo
echo "First primary partition must be BOOTable."
echo "Second primary partition must be type '8E'."
echo
AnyKey

cfdisk "/dev/$INSTALLDISK"

echo "We'll now setup LUKS encryption"
echo "Be sure to put in your encryption password when prompted."
AnyKey

cryptsetup -c aes-xts-plain -y -s 512 luksFormat "/dev/${INSTALLDISK}${SYSTEMPART}"

echo "We now need to decrypt partition just set up and mount it."
echo "Be sure to enter same password you just used to create it."

cryptsetup luksOpen "/dev/${INSTALLDISK}${SYSTEMPART}" "luks${SYSTEMPART}"

echo "Setting up LVM volume group ${LVMGROUP} with ${LVMGROUP}-root, ${LVMGROUP}-swap,"
echo "and ${LVMGROUP}-home containers."
pvcreate "/dev/mapper/luks${SYSTEMPART}"
vgcreate ${LVMGROUP} /dev/mapper/luks${SYSTEMPART}
lvcreate --size ${ROOTSIZE} ${LVMGROUP} --name root
lvcreate --size ${SWAPSIZE} --contiguous y ${LVMGROUP} --name swap
lvcreate ${HOMESIZE} ${LVMGROUP} --name home

echo "Initializing filesystems with ext4 and swap."
# Save off old config if it exists
if [ -e "/dev/${INSTALLDISK}${BOOTPART}/syslinux/syslinux.cfg" ]
then
	cp -v "/dev/${INSTALLDISK}${BOOTPART}/syslinux/syslinux.cfg" /
fi
mkfs.ext4 "/dev/${INSTALLDISK}${BOOTPART}" # the boot partition
mkfs.ext4 /dev/mapper/${LVMGROUP}-root
mkfs.ext4 /dev/mapper/${LVMGROUP}-home
mkswap /dev/mapper/${LVMGROUP}-swap

echo "Mounting the logical volumes to install Arch Linux onto"
echo "them. Watch for errors!"
mount -v /dev/mapper/${LVMGROUP}-root /mnt # /mnt is our system's "/" root   directory
mkdir /mnt/boot
mount -v "/dev/${INSTALLDISK}${BOOTPART}" /mnt/boot
mkdir /mnt/home
mount -v /dev/mapper/${LVMGROUP}-home /mnt/home
swapon /dev/mapper/${LVMGROUP}-swap

echo "Please look for any errors, then press any key to continue."
AnyKey

mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old
wget -O mirrorlist.new 'https://www.archlinux.org/mirrorlist/?country=US&protocol=http&protocol=https&use_mirror_status=on'
sed -e '7,17s/^\#Server/Server/g' mirrorlist.new > /etc/pacman.d/mirrorlist
echo
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
if [ $? -ne 0 ]
then
	echo
	echo "***********************************************"
	echo " ERROR!                                       *"
	echo "A problem occured getting vmconfigure.bash.   *"
	echo "Script will now exit!                         *"
	echo "***********************************************"
	AnyKey
	exit 1
else
	echo "Got vmconfigure.bash script OK."
fi

wget https://github.com/JDCNS/ArchVMInstall/raw/master/installdesktop.zsh
if [ $? -ne 0 ]
then
	echo
	echo "***********************************************"
	echo " WARNING!                                     *"
	echo "A problem occured getting installdesktop.zsh. *"
	echo "Script will continue for base install.        *"
	echo "***********************************************"
	AnyKey
else
	echo "Got installdesktop.zsh script OK."
fi

chmod a+x vmconfigure.bash
chmod a+x installdesktop.zsh
cp -v vmconfigure.bash /mnt
cp -v installdesktop.zsh /mnt
echo
echo "Now getting read to enter chroot environment."
AnyKey
arch-chroot /mnt /vmconfigure.bash "$INSTALLINGINVM" "${INSTALLDISK}${SYSTEMPART}" "$LVMGROUP"
echo
echo "Returned from chroot."
echo
# Copy backup of syslinux.cfg back
if [ -e "/syslinux.cfg" ]
then
	cp -v /syslinux.cfg "/dev/${INSTALLDISK}${BOOTPART}/syslinux/syslinux.cfg.vminstall" /
fi
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

