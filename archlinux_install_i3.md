# Archlinux with i3

### Boot

Boot from the Imaged USB in UEFI Mode and and before it can auto boot quickly use the Press the `"E"` to edit
the boot sequence to allow for NVIDIA boot or we will get a black screen and won't be able to continue.

Press the `"END"` key to get to the end of the line so we can add something to the boot sequence.

Type:

`nomodeset`

After boot assuming no errors, type:

`passwd`

We have to give the `root` user a password so we can SSH into the install enviroment.

After setting your password we now need to start the SSH service :

`systemctl start sshd.service`

Type in and look for the `inet` entry that should corrospond with your LAN IP address's to find the IP Address of the Arch Install Computer:

`ip addr`

Use that IP address to SSH into the install enviroment and login with `root` and the password we set earlier.

Now using your SSH console we need to check we booted with UEFI, type:

`ls /sys/firmware/efi/efivars`



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

`gdisk /dev/sda`

Now we want to create a GPT partition table (answer "y" for yes):

`o`

Now how much space have we got:

`p`

Create a ESP boot partition (It is recommended to have a ESP partion of 512MiB):

`n`

`1`

`"enter key"` Keep sectors next to each so we dont waist space.`

`+512M`

`ef00`

Print partitions again to check:

`p`

Make root partition with 20GB:

`n`

`2`

`"enter key"` Keep sectors next to each so we dont waist space.

`+20G`

`8304`

Make home partition with remaining space:

`n`

`3`

`"enter key"` Keep sectors next to each so we dont waist space.

`"enter key"` Use remaining space.

`8302`

Write Changes to disk and exit back to install terminal (answer "y" for yes):

`w`

Now that the partitions have been created they need to be formatted to the appriate filesystem:

`mkfs.fat -F32 /dev/sda1`

`mkfs.ext4 /dev/sda2`

`mkfs.ext4 /dev/sda3`


### Mount the Partitions

We now have to mount the partitions so that we can use them:

`mount /dev/sda2 /mnt`

`mkdir /mnt/boot`

`mount /dev/sda1 /mnt/boot`

`mkdir /mnt/home`

`mount /dev/sda3 /mnt/home`


### Install the base system

First we need to edit the mirrorlist to the closest location to get better update speeds:

`nano /etc/pacman.d/mirrorlist`

`"CTRL-W"` and type in `Australia`

Move cursor to the URL and hold `"CTRL-K"` to cut

Move cursor above other address at the top and hold `"CTRL-U"` to paste

Do this until you have at least 3 entrys you have picked and then Install Archlinux system files:

`pacstrap /mnt base base-devel linux-lts nvidia-lts intel-ucode git`

Generate the fstab so we can install a boot loader:

`genfstab -U /mnt >> /mnt/etc/fstab`

Check it in case of errors:

`nano /mnt/etc/fstab`


### chroot to finish the install

We need to chroot into the installed system:

`arch-chroot /mnt`

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

`"CTRL-O"` then `"ENTER"` to save

`"CTRL-X"` to exit nano editor

Create `SWAP` file:

`dd if=/dev/zero of=/swapfile bs=1M count=1024`

`chmod 600 /swapfile`

`mkswap /swapfile`

`nano /etc/fstab`

Add this to the bottom:

`/swapfile none swap defaults 0 0`


### Setup Network Settings

Choose NetworkManager if using wifi.

#### NetworkManager (WiFi)

First install it.

`sudo pacman -Sy linux-lts-headers`

If using broadcom drivers:

`sudo pacman -Sy broadcom-wl-dkms`

`sudo pacman -Sy networkmanager plasma-nm iw wpa_supplicant`

Then enable the service:

`sudo systemctl enable NetworkManager.service`

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

