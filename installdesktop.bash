#!/bin/zsh
#
# Part 3 of ArchVMInstall
#
# See https://github.com/JDCNS/ArchVMInstall for details.
#
# you can grab this via: wget https://github.com/JDCNS/ArchVMInstall/raw/master/installdesktop.bash
# If you went through previous script OK, you should have wget
# installed already.
#
# This portion of the install owes a lot to LifeHacker article
# "Build a Killer Customized Arch Linux Installation (and Learn All
# About Linux in the Process)" by Whitson Gordon
#
# Requirements: Working network and base installation, sudo installed
# (assumes you will be logged in as your regular user and not root).

INSTALLINGINVM="Y"

AnyKey()
{
	echo "Press any key when ready or [Ctr]-[C] to cancel."
	read ANYKEY
}

echo "Checking network..."
ping -c3 www.google.com
if [ $? -ne 0 ]
then
	echo "Error pinging Google!"
	echo "Please check network configuration."
	exit 1
fi
echo
echo "Checking for updates."
sudo pacman -Syu
echo
cp ~/.zshrc ~/.zshrc.old
echo "Modifying zsh prompt."
echo >> ~/.zshrc
echo "autoload -U compinit promptinit" >> ~/.zshrc
echo "compinit" >> ~/.zshrc
echo "promptinit" >> ~/.zshrc
echo >> ~/.zshrc
echo "# Setting default theme" >> ~/.zshrc
source ~/.zshrc
echo
echo "Now select a prompt theme. You can change later by editing"
echo "~/.zshrc file."
echo
prompt -l
echo -n "Now select a theme by typing in one of the above names: "
read PTHEME
echo "prompt $PTHEME" >> ~/.zshrc
prompt $PTHEME
echo
echo "Now inspect your .zshrc for errors."
AnyKey
echo
echo "Installing ALSA utils and mixer"
sudo pacman -S alsa-utils
echo
echo "Now need to check mixer."
echo "Unmute Master and PCM channels by highlighting and pressing"
echo "[M] key. Then using up and down arrows, adjust until gain"
echo "is '0' for both."
echo
AnyKey
alsamixer
echo
echo "Now testing left and right speakers..."
speaker-test -c 2 -l 3
echo
echo
echo "Installing X windows."
sudo pacman -S xorg-server xorg-xinit xorg-server-utils
echo
# I know, this seems dumb; that's because it is.
# However, it very often doesn't work the first time.
if [ "${INSTALLINGINVM}" -eq "Y" ]
then
	echo "Reinstalling guest additions for VirtualBox"
	echo "(yes, it's necessary)."
	sudo pacman -S virtualbox-guest-utils
	sudo chmod a+rwx /media
	echo "If you have any shared folders, be sure to modify directory"
	echo "(not file and subdirectory) permissions."
	AnyKey
fi

echo
echo "Installing basic desktop items."
sudo pacman -S xorg-twm xorg-xclock xterm
echo
echo "Preparing to start desktop ..."
sleep 15
startx

