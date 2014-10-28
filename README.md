ArchVMInstall
=============

Install Arch Linux in VM with encryption by ripping off and modifying commands from http://listx.github.io/post/2013-03-10-installing-arch-and-enabling-system-encryption.html

In short, Linus Arver had some excellent instructions for installing Arch onto a LVM ecrypted filesystem.  However, I wanted a few tweaks, and some of these had to change for installing into a VM.  In addition, I like the idea of a couple of scripts to prevent typos. :)

Arver did all the ground work.  This is just a tweak.  Please see the post listed above.  Three things:

1. He had an older blog at another location. It was by luck that I found this version.  The old one did not work, twice even, and now I know why after going through his updated instructions.  Don't use the old version.  Use the one I've pointed to above.
2. If imitation is the sincerest form of flattery, then I hope this qualifies.  I only "fixed" a couple of things that VirtualBox or I did not like and put it in a runnable form.  I say "fixed" because he obviously did not write his instructions for me (alone, at least) or for running in a VM (especially).
3. This has obviously gone beyond its original intent, and this was not totally un-anticipated.  It obviously makes sense for using the same script that you used to install into a VM to install into the real thing.  Then, what if you want multiple partitions with different things?  So, this is a work in progress mostly, but because it has expanded out to be able to replicate it on real hardware.  Obviously, it is still up to you to find the video drivers and what-not, and you must modify the beginning parameters if they won't work for you.  If you mess it up, it will probably mess up your system, BTW, so there are no guarantees for anything.

Basically, you can kick off the script by booting from the Arch install media and then downloading the first script by doing "wget https://github.com/JDCNS/ArchVMInstall/raw/master/baseinstall.bash", change the permissions to a+x, and then running ./baseinstall.bash.  It will download the other two scripts, but it will only automatically run the second. The third is the optional graphical desktop install for X Windows.  I suggest getting it working before selectiong another.  I'm trying out KDE on this platform, for example, and I install it once I'm satisfied that VirtualBox works correctly using X Windows.
