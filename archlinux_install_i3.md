# Archlinux with i3
## Boot
### UEFI
Boot from the Imaged USB in UEFI Mode and before it can auto boot quickly use the Press the `"E"` to edit
the boot sequence to allow for NVIDIA boot or we will get a black screen and won't be able to continue.

Press the `"END"` key to get to the end of the line so we can add something to the boot sequence.

Type:

`nomodeset`

#### Check UEFI booted correctly
Now using your SSH console we need to check we booted with UEFI, type:

`ls /sys/firmware/efi/efivars`

### BIOS
Boot from the Imaged USB in BIOS Mode and before it can auto boot quickly use the Press the `"TAB"` to edit
the boot sequence to allow for NVIDIA boot or we will get a black screen and won't be able to continue.

Press the `"END"` key to get to the end of the line so we can add something to the boot sequence.

Type:

`nomodeset`

### SSH Setup so we can copy/paste
After boot assuming no errors, type:

`passwd`

We have to give the `root` user a password so we can SSH into the install enviroment.

After setting your password we now need to start the SSH service :

`systemctl start sshd.service`

If your using wifi you need to connect to your Wifi Network first:

`wifi-menu`

Type in and look for the `inet` entry that should corrospond with your LAN IP address's to find the IP Address of the Arch Install Computer:

`ip addr`

Use that IP address to SSH into the install enviroment and login with `root` and the password we set earlier.

## Install
### Preperation
First we need to check where connected to the internet:

`ping archlinux.org`

We also have to check the clock is set to your timezones time so update servers don't get confused:

To update the time:

`timedatectl set-ntp true`

Set the timezone accordingly:

`timedatectl set-timezone Australia/Perth`

To check:

`timedatectl status`


### Partitioning
We have to make sure the partition table is set to GPT and find the disk we want to install to:

`lsblk`



#### UEFI
If your using UEFI:

`gdisk /dev/sda`

Now we want to create a GPT partition table (answer "y" for yes):

`o`

Now how much space have we got:

`p`

##### Make esp /boot partition
Create a ESP boot partition (It is recommended to have a ESP partion of 512MiB):

`n`

`1`

`"enter key"` Keep sectors next to each so we dont waist space.`

`+512M`

`ef00`

Print partitions again to check:

`p`

##### Make root partition
Make root partition with 20GB:

`n`

`2`

`"enter key"` Keep sectors next to each so we dont waist space.

`"enter key"` Use remaining space.

`8304`

Write Changes to disk and exit back to install terminal (answer "y" for yes):

`w`

#### LUK's parition encryption
If you want to add encryption for root enter the command below and choose a password:

```
cryptsetup --verbose --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat /dev/sda2
```

Now we need to unlock it so that we can use the partitions that have been created. They can now to be formatted to the appropriate filesystem:

`cryptsetup open --type luks /dev/sda2 cryptroot`

`mkfs.ext4 /dev/mapper/cryptroot`

`mkfs.fat -F32 /dev/sda1`

##### Mount partitions
Now we need to mount them:

`mount -t ext4 /dev/mapper/cryptroot /mnt`

`mkdir -p /mnt/boot`

`mount -t ext4 /dev/sda1 /mnt/boot`



#### BIOS
If your using BIOS:

`fdisk /dev/sda`

#### LUK's parition encryption
If you want to add encryption for root enter the command below and choose a password:

```
cryptsetup --verbose --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat /dev/sda2
```

Now we need to unlock it so that we can use the partitions that have been created. They can now to be formatted to the appropriate filesystem:

`cryptsetup open --type luks /dev/sda2 cryptroot`

`mkfs.ext4 /dev/mapper/cryptroot`

`mkfs.ext4 /dev/sda1`

##### Mount partitions
Now we need to mount them:

`mount -t ext4 /dev/mapper/cryptroot /mnt`

`mkdir -p /mnt/boot`

`mount -t ext4 /dev/sda1 /mnt/boot`

##### Mount the Partitions
We now have to mount the partitions so that we can use them:

`mkfs.ext4 /dev/sda1`

`mkfs.ext4 /dev/sda2`

`mount /dev/sda2 /mnt`

`mkdir /mnt/boot`

`mount /dev/sda1 /mnt/boot`

### Install
#### Select update servers
First we need to edit the mirrorlist to the closest location to get better update speeds:

`nano /etc/pacman.d/mirrorlist`

`"CTRL-W"` and type in `Australia`

Move cursor to the URL and hold `"CTRL-K"` to cut

Move cursor above other address at the top and hold `"CTRL-U"` to paste

Do this until you have at least 3 entrys you have picked and then Install Archlinux system files:

#### Install base system
`pacstrap -i /mnt base base-devel`

Generate the fstab so we can install a boot loader:

`genfstab -U /mnt >> /mnt/etc/fstab`

Check it in case of errors:

`nano /mnt/etc/fstab`

Install `intel-ucode` if you have a Intel CPU:

`pacstrap -i /mnt intel-ucode`

### chroot to finish the install
We need to chroot into the installed system:

`arch-chroot /mnt`

#### Set timezone and language
We need to set the timezone again for the installed system now:

`ln -sf /usr/share/zoneinfo/Australia/Perth /etc/localtime`

Run the hardware clock to set time:

`hwclock --systohc`

Set the localizations:

`nano /etc/locale.gen`

Uncomment `en_AU.UTF-8 UTF-8`

`nano /etc/locale.conf`

type in `LANG=en_AU.UTF-8`

`locale-gen`

#### Hostname
Create the Hostname for the system:

`nano /etc/hostname`

type in `pheoxy-desktop`

`nano /etc/hosts` 

And add your hostname:

`127.0.0.1	pheoxy-desktop.localdomain	pheoxy-desktop`

For example:

```
#
# /etc/hosts: static lookup table for host names
#

#<ip-address>   <hostname.domain.org>   <hostname>
127.0.0.1       localhost.localdomain   localhost
::1             localhost.localdomain   localhost
127.0.0.1       pheoxy-desktop.localdomain      pheoxy-desktop

# End of file
```

#### Create Swap
Create `SWAP` file:

`dd if=/dev/zero of=/swapfile bs=1M count=1024`

`chmod 600 /swapfile`

`mkswap /swapfile`

`nano /etc/fstab`

Add this to the bottom:

`/swapfile none swap defaults 0 0`

### Setup Network Settings
Choose NetworkManager if using wifi.

##### Broadcom Wifi Card
If using broadcom drivers:

`sudo pacman -Sy broadcom-wl-dkms`

In case on reboot later still no network you may need to blacklist other broadcom drivers, you can check by:

`lspci -k`

If your Wireless Card has:

`Kernel modules: bcma`

You need to blacklist these if using broadcom drivers:

`sudo nano /etc/modprobe.d/blacklist.conf`

```
blacklist ssb
blacklist bcma
blacklist b43
blacklist brcmsmac
```

Reboot and check again:

`lspci -k`

It should now show and wireless will now be working:

```
Kernel driver in use: wl
Kernel modules: bcma, wl`
```

#### NetworkManager (WiFi)
First install it.

`sudo pacman -Sy networkmanager wpa_supplicant`

Then enable the service:

`sudo systemctl enable NetworkManager.service`

#### systemd-network (No WiFi)
Find ethernet interface name:

`ls /sys/class/net`

Network Configuration:

`nano /etc/systemd/network/50-wired.network`

Paste or type in:

```
[Match]
Name=eno1

[Network]
DHCP=ipv4
```

Enable network services:

`systemctl enable systemd-networkd.service`

`systemctl enable systemd-resolved.service`

### Install Boot loader
#### UEFI (systemd-boot)
Use systemd-boot so we don't have to install any extra packages and verify EFI varibles are working:

`ls /sys/firmware/efi/efivars`

If you used encryption we need to add some paremeters to the kernel and a hook to `mkinitcpio.conf` config:

`nano /etc/mkinitcpio.conf`

`HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck"`

Then we need to regenerate the initrams:

`mkinitcpio -p linux`

Setup boot loader so System will boot:

`bootctl --path=/boot install`

Find PARTUUID for `root` boot entry:

`blkid -s PARTUUID -o value /dev/sda2`

Make a template, add `intel-ucode` for microcode updates if you have a intel CPU and add root PARTUUID:

```
title          Arch Linux
linux          /vmlinuz-linux
initrd         /initramfs-linux.img /intel-ucode.img
options        root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX rw quiet
```

If encrypted:

```
title          Arch Linux
linux          /vmlinuz-linux
initrd         /initramfs-linux.img /intel-ucode.img
options cryptdevice=UUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX:cryptroot root=/dev/mapper/cryptroot quiet rw
```

Paste or type above template

`bootctl update`

Edit boot loader:

`nano /boot/loader/loader.conf`

`Paste or Type below lines`

`default  arch`

`editor   0`

#### BIOS
First we need to install `grub`:

`pacman -Sy grub`

If you used encryption we need to add some paremeters to the kernel and a hook to `mkinitcpio.conf` config:

`nano /etc/default/grub`

```
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda2:cryptroot"
```

`nano /etc/mkinitcpio.conf`

`HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck"`

Then we need to regenerate the initrams:

`mkinitcpio -p linux`

Tell grub what hard drive to install to:

`grub-install --target=i386-pc /dev/sda`

Generate the main configuration file:

`grub-mkconfig -o /boot/grub/grub.cfg`

### Security
#### "root" password security

Give `root` user a password for security and accidents:

`passwd`

#### Add your user

Make a user for yourself:

`useradd -m -G wheel -s /bin/bash pheoxy`

Create a password for your user:

`passwd pheoxy`

Give user sudo permissions for updates and to install software:

`EDITOR=nano visudo`

uncomment `%wheel ALL=(ALL) ALL`

### Finished setup
Now we need to exit chroot and boot into our system:

`exit`

`poweroff`

Unplug your Archlinux.iso and turn you computer back on and you should be greeted with a login screen.