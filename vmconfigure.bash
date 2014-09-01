#!/bin/bash
#
# Part 2 of ArchVMInstall
#
# See https://github.com/JDCNS/ArchVMInstall for details.
#
# you can grabe this via: wget https://github.com/JDCNS/ArchVMInstall/raw/master/vmconfigure.bash

CONSOLEFONT="default8x16"
TIMEZONE="America/New_York"
INSTALLINGINVM="Y"

AnyKey()
{
	echo "Press any key when ready or [Ctr]-[C] to cancel."
	read ANYKEY
}

echo "Choose and generate locale."
echo "Just choose 'en_US.UTF-8 UTF-8' if you live in the US"
echo "(it will make your life easier)."
AnyKey
nano /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Console fonts are in /usr/share/kbd/consolefonts/
# I tried the "Lat2-Treminus16", and it was too light to see!
echo "Setting default font to default8x16."
setfont ${CONSOLEFONT}
echo "FONT=${CONSOLEFONT}" > /etc/vconsole.conf

echo "Setting timezone."
# Here I had a little difficulty, as /etc/localtime already existed
rm /etc/localtime
ln -s /usr/share/zoneinfo/"${TIMEZONE}" /etc/localtime
hwclock --systohc --utc

echo "Please check output for errors."
AnyKey

echo "Choose your computer's name. Keep it simple, without spaces."
read MYHOSTNAME
echo "$MYHOSTNAME" > /etc/hostname

# VirtualBox changes all of this. I don't think it's needed now
#
# Enable DHCPCD... aka "acquire dynamic ip address from your router/switch".  Be
# sure to choose the right device name (typically eth0 or eth1 (eth2, if you
# have 3 ethernet ports)); you can find out the correct device name with `ip
# link` (look for the device under the first entry, `lo`.). If you choose the
# wrong "eth" number, just go to /etc/systemd/system/multi-user.target.wants/
# and rename the symlink; e.g., rename
# /etc/systemd/system/multi-user.target.wants/dhcpcd@eth0.service to
# /etc/systemd/system/multi-user.target.wants/dhcpcd@eth1.service.

echo "Your network devices:"
ip link
echo
echo "Type in the above device name to use"
echo -n "to enable networking: "
read DEVICENAME
systemctl enable dhcpcd@${DEVICENAME}.service

echo "Inspect package repos. You will want to disable the [testing] repos"
echo "if not already commented out."
AnyKey
nano /etc/pacman.conf

echo "Set up the root user (administrator) password."
passwd

echo "Installing zsh."
pacman -S zsh

echo "Now create your regular user account. You will use this instead"
echo "of the root account normally."
echo
echo -n "Input your regular login name: "
read MYUSERNAME
# Another area that caused grief was vboxsf was missing
useradd -m -g users -G wheel,storage,power,vboxsf -s /bin/zsh ${MYUSERNAME}
echo "Set password for ${MYUSERNAME}"
passwd ${MYUSERNAME}

mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.old
sed "s/^MODULES=\"\"/MODULES=\"ext4\"/" mkinitcpio.conf.old | sed "/^HOOKS=/s/filesystems/encrypt lvm2 filesystems/" > /etc/mkinitcpio.conf

echo "Inspect mkinitcpio."
echo
echo "VERY IMPORTANT: Be sure 'ext4' is inserted into the MODULES"
echo "variable and also 'encrypt' and 'lvm2' is in HOOKS."
AnyKey
nano /etc/mkinitcpio.conf

# Re-generate the linux image to take into account the LVM and encrypt
# flags we added into /etc/mkinitcpio.conf. I say "re-generate" because this
# is our second time doing this (the first time was when we installed the
# linux package with the pacstrap command above).

mkinitcpio -p linux

# There was a mistake in the bootloader section of the instructions,
# as it shouldn't be 'ro', else you will be nagged about root being
# "read-only" at bootup time.
#
# Install boot loader. For now, stick with syslinux. I'm used to GRUB,
# but does it really matter?
#
pacman -S syslinux
syslinux-install_update -i -a -m
BOOTUUID=$(ls -l /dev/disk/by-uuid | grep /sda2 | tr -s " " | cut -d' ' -f9- | cut -d' ' -f1)
echo "APPEND cryptdevice=/dev/disk/by-uuid/${BOOTUUID}:luks root=/dev/mapper/vg0-root resume=/dev/mapper/vg0-swap rw" >> /boot/syslinux/syslinux.cfg
echo
echo "UUID of /dev/sda2 is $BOOTUUID"
echo "Look for this line at the bottom of /boot/syslinux/syslinux.cfg"
echo "and move it under the 'LABEL arch' entries"
echo
AnyKey
nano /boot/syslinux/syslinux.cfg

# This will seem like an odd place to put this, and it is!
# However, this has to be run twice b/c of a bug in the install
if [ "${INSTALLINGINVM}" -eq "Y" ]
	pacman -S virtualbox-guest-utils
fi

echo
echo "Now exiting chroot environment."
exit


