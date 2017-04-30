# Install ArchLinux using UEFI, NVIDIA and SSH for a Windows 10 Gaming KVM Enviroment

### Requirements
- Motherboard must be IOMMU Compatible and enabled
- SSH Client

Download Latest ArchLinux ISO
https://www.archlinux.org/download/

If using Windows use Rufus to image the archlinux.iso with DD Image.


### Boot

Boot from the Imaged USB in UEFI Mode and and before it can auto boot quickly use the Press the "E" to edit
the boot sequence to allow for NVIDIA boot or we will get a black screen and won't be able to continue.

Press the "END" key to get to the end of the line so we can add something to the boot sequence.

Type:
```nomodeset```

After boot assuming no errors, type:
```passwd```

We have to give the "root" user a password so we can SSH into the install enviroment.

After setting your password we now need to start the SSH service :
sshd.service

Type in and look for the "inet" entry that should corrospond with your LAN IP address's to find the IP Address of the Arch Install Computer:
ip addr

Use that IP address to SSH into the install enviroment and login with "root" and the password we set earlier.

Now using your SSH console we need to check we booted with UEFI, type:
ls /sys/firmware/efi/efivars



## Install

### Preperation

First we need to check where connected to the internet.
ping archlinux.org

We also have to check the clock is set to your timezones time so update servers don't get confused.
To update the time:
timedatectl set-ntp true

Set the timezone accordingly:
timedatectl set-timezone Australia/Perth

To check:
timedatectl status


### Partitioning

We have to make sure the partition table is set to GPT and find the disk we want to install to:
lsblk
gdisk /dev/sda

Now we want to create a GPT partition table (answer "y" for yes):
o

Now how much space have we got:
p

Create a ESP boot partition (It is recommended to have a ESP partion of 512MiB):
n
1
"enter key" Keep sectors next to each so we dont waist space.
+512M
ef00

Print partitions again to check:
p

Make root partition with 20GB:
n
2
"enter key" Keep sectors next to each so we dont waist space.
+20G
8304

Make home partition with remaining space:
n
3
"enter key" Keep sectors next to each so we dont waist space.
"enter key" Use remaining space.
8302

Write Changes to disk and exit back to install terminal (answer "y" for yes):
w

Now that the partitions have been created they need to be formatted to the appriate filesystem:
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3


### Mount the Partitions

We now have to mount the partitions so that we can use them:
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda3 /mnt/home


### Install the base system

First we need to edit the mirrorlist to the closest location to get better update speeds:
nano /etc/pacman.d/mirrorlist
"CTRL-W" and type in "Australia"
Move cursor to the URL and hold "CTRL-K" to cut
Move cursor above other address at the top and hold "CTRL-U" to paste

Do this until you have at least 3 entrys you have picked and then:
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor

Install "base-devel" group:
pacstrap /mnt base base-devel linux-lts nvidia-lts intel-ucode git

Generate the fstab so we can install a boot loader:
genfstab -U /mnt >> /mnt/etc/fstab

Check it in case of errors:
nano /mnt/etc/fstab


### chroot to finish the install

We need to chroot into the installed system:
arch-chroot /mnt

We need to set the timezone again for the installed system now:
ln -sf /usr/share/zoneinfo/Australia/Perth /etc/localtime

Run the hardware clock to set time:
hwclock --systohc

Set the localizations:
nano /etc/locale.gen
Uncomment "en_AU.UTF-8 UTF-8"
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor
nano /etc/locale.conf
type in "LANG=en_AU.UTF-8"
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor
locale-gen

Create the Hostname for the system:
nano /etc/hostname
type in "pheoxy-desktop"
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor
nano /etc/hosts
type in underneath the "::1" line "127.0.1.1	pheoxy-desktop.localdomain	pheoxy-desktop"
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor


### Setup Network Settings

Find ethernet interface name:
ls /sys/class/net

Network Configuration:
nano /etc/systemd/network/50-wired.network
Paste or type in
[Match]
Name=eno1

[Network]
DHCP=ipv4

Enable network services:
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service


### Rebuild Kernel for boot partition

So that we have a stable kernel we use linux-lts:
mkinitcpio -p linux-lts


### root password

Give "root" user a password for security and accidents:
passwd


### Add your user

Make a user for yourself:
useradd -m -G wheel -s /bin/bash pheoxy

Create a password for your user:
passwd pheoxy

Give user sudo permissions for updates and to install software:
EDITOR=nano visudo
uncomment "%wheel ALL=(ALL) ALL"
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor


### Install and enable SSHD Server on Installed System


Install and enable it:
pacman -Sy openssh
systemctl enable sshd.service


### Install Boot loader

Verify EFI varibles are working:
ls /sys/firmware/efi/efivars

Setup boot loader so System will boot:
bootctl --path=/boot install

Double check IOMMU will work and is enable in UEFI:
dmesg|grep -e DMAR -e IOMMU

Find PARTUUID for boot entry:
blkid -s PARTUUID -o value /dev/sda2

Make a template, add intel-ucode for microcode updates, add root PARTUUID, add IOMMU:
title          Arch Linux
linux          /vmlinuz-linux-lts
initrd         /initramfs-linux-lts.img /intel-ucode.img
options        root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX rw intel_iommu=on

Edit boot entry for IOMMU:
nano /boot/loader/entries/arch.conf
Paste or type above template
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor
bootctl update

Edit boot loader:
nano /boot/loader/loader.conf
Paste or Type below lines
default  arch
editor   0
"CTRL-O" then "ENTER" to save
"CTRL-X" to exit nano editor

Now we need to exit chroot:
exit


### Shutdown to boot into installed system

First we need to turn off the PC:
poweroff

Unplug Archlinux USB

Power on your pc and watch boot.


### Login and Final Install Edits

Login with the user you created with its password and then type:
nano ~/.bashrc
Edit
PS1='\[\033[38;5;10m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;15m\]:[\W]: \\$ \[$(tput sgr0)\]'

Install screenfetch for fancy login information:
sudo pacman -Sy screenfetch

Then we want to add a different one to "root" as well:
sudo nano /etc/bash.bashrc
Edit
PS1='\[\033[38;5;10m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;15m\]:[\W]: \\$ \[$(tput sgr0)\]'
And add to the bottom
if [ -f /usr/bin/screenfetch ]; then screenfetch; fi

Install "htop for terminal process information:
sudo pacman -S htop

Install "yaourt" AUR package helper:
git clone https://aur.archlinux.org/package-query.git
cd package-query
makepkg -si
cd ..
git clone https://aur.archlinux.org/yaourt.git
cd yaourt
makepkg -si
cd ..
sudo rm -Rv package-query yaourt

Install Display Manger and Desktop Enviroment:

First we need a Display Manager:
sudo pacman -S sddm
sudo systemctl enable sddm.service

Then install the Desktop Enviroment:
sudo pacman -S plasma kde-applications
all
all
select libx264
select cronie
press y to continue

Now we need to reboot to get into the Desktop Enviroment:
sudo reboot

Final software to install:
yaourt chrome
yaourt tff-google-fonts-git
yaourt gpmdp
yaourt visual-studio-code
yaourt gparted


<<<<<<< HEAD
### KVM software install
=======
###### KVM software install
>>>>>>> 01685f832369a52cbe0987fffc8ff46fbea737bf
