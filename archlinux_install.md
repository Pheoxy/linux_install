# Install ArchLinux using UEFI, NVIDIA and SSH for a Windows 10 Gaming KVM Enviroment

### Requirements
- Motherboard must be IOMMU Compatible and enabled
- SSH Client (Recommended)
- Make sure Host GPU is in Primary PCIE Slot

Download Latest ArchLinux ISO:

<https://www.archlinux.org/download/>

If using Windows use Rufus to image the archlinux.iso with DD Image.


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

`rm /etc/pacman.d/mirrorlist`

https://www.archlinux.org/mirrorlist/

Copy and paste the generated file and uncomment the servers:

`nano /etc/pacman.d/mirrorlist`

Install Archlinux system files:

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

`"CTRL-O"` then `"ENTER"` to save

`"CTRL-X"` to exit nano editor

`nano /etc/locale.conf`

type in `LANG=en_AU.UTF-8`

`"CTRL-O"` then `"ENTER"` to save

`"CTRL-X"` to exit nano editor

`locale-gen`

Create the Hostname for the system:

`nano /etc/hostname`

type in `pheoxy-desktop`

`"CTRL-O"` then `"ENTER"` to save

`"CTRL-X"` to exit nano editor

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

If using broadcom drivers:

`sudo pacman -Sy linux-lts-headers`

`sudo pacman -Sy broadcom-wl-dkms`

`sudo pacman -Sy networkmanager plasma-nm iw wpa_supplicant`

Then enable the service:

`sudo systemctl enable NetworkManager.service`

In case on reboot later still no network you may need to blacklist other broadcom drivers, you can check by:

`lspci -k`

If your Wireless Card has:

`Kernel modules: bcma`

You need to blacklist `bcma`:

`sudo nano /etc/modprobe.d/blacklist.conf`

```
blacklist ssb
blacklist bcma
blacklist b43
blacklist brcmsmac
```

Check again:

`lspci -k`

It should now show and wireless will now be working:

```
Kernel driver in use: wl
Kernel modules: bcma, wl`
```

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


### Rebuild Kernel for boot partition

So that we have a stable kernel we use `linux-lts`:

`mkinitcpio -p linux-lts`


### "root" password security

Give `root` user a password for security and accidents:

`passwd`


### Add your user

Make a user for yourself:

`useradd -m -G wheel -s /bin/bash pheoxy`

Create a password for your user:

`passwd pheoxy`

Give user sudo permissions for updates and to install software:

`EDITOR=nano visudo`

uncomment `%wheel ALL=(ALL) ALL`

`"CTRL-O"` then `"ENTER"` to save

`"CTRL-X"` to exit nano editor


### Install and enable SSHD Server on Installed System


Install and enable it:

`pacman -Sy openssh`

`systemctl enable sshd.service`


### Install Boot loader

Verify EFI varibles are working:

`ls /sys/firmware/efi/efivars`

Setup boot loader so System will boot:

`bootctl --path=/boot install`

Double check IOMMU will work and is enable in UEFI:

`dmesg|grep -e DMAR -e IOMMU`

Find PARTUUID for `root` boot entry:

`blkid -s PARTUUID -o value /dev/sda2`

Make a template, add intel-ucode for microcode updates, add root PARTUUID, add IOMMU:

```
title          Arch Linux
linux          /vmlinuz-linux-lts
initrd         /initramfs-linux-lts.img /intel-ucode.img
options        root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX rw quiet intel_iommu=on
```

Edit boot entry for IOMMU:

`nano /boot/loader/entries/arch.conf`

`Paste or type above template`

`"CTRL-O" then "ENTER" to save`

`"CTRL-X" to exit nano editor`

`bootctl update`

Edit boot loader:

`nano /boot/loader/loader.conf`

`Paste or Type below lines`

`default  arch`

`editor   0`

`"CTRL-O" then "ENTER" to save`

`"CTRL-X" to exit nano editor`

Now we need to exit chroot:

`exit`


### Shutdown to boot into installed system

First we need to turn off the PC:

`poweroff`

Unplug Archlinux USB

Power on your pc and watch boot.



### Login and Final Install Edits


Add optional NVIDIA Dependency otherwise NVIDIA can't find `xorg.conf`:

`sudo pacman -S xorg-server-devel`

Generate xorg.conf:

`sudo nvidia-xconfig`

This should fix some screen tearing:

`sudo nano /etc/X11/xorg.conf.d/20-nvidia.conf`

```
Section "Screen"
    Identifier     "Screen0"
    Option         "metamodes" "nvidia-auto-select +0+0 { ForceFullCompositionPipeline = On }"
    Option         "AllowIndirectGLXProtocol" "off"
    Option         "TripleBuffer" "on"
EndSection
```

Login with the user you created with its password and then type:

`nano ~/.bashrc`

Edit

`PS1='\[\033[38;5;10m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;15m\]:[\W]: \\$ \[$(tput sgr0)\]'`

`"CTRL-O" then "ENTER" to save`

`"CTRL-X" to exit nano editor`

Install screenfetch for fancy login information:

`sudo pacman -Sy screenfetch`

Then we want to add a different one to "root" as well:

`sudo nano /etc/bash.bashrc`
Edit

`PS1='\[\033[38;5;10m\]\u@\h\[$(tput sgr0)\]\[\033[38;5;15m\]:[\W]: \\$ \[$(tput sgr0)\]'`

And add to the bottom

`if [ -f /usr/bin/screenfetch ]; then screenfetch; fi`

`"CTRL-O" then "ENTER" to save`

`"CTRL-X" to exit nano editor`

Install "htop for terminal process information:

`sudo pacman -S htop`

Avoid screen tearing:

`sudo nano /etc/profile.d/kwin.sh`

Add:

`export KWIN_TRIPLE_BUFFER=1`

Install "yaourt" AUR package helper:

`git clone https://aur.archlinux.org/package-query.git`

`cd package-query`

`makepkg -si`

`cd ..`

`git clone https://aur.archlinux.org/yaourt.git`

`cd yaourt`

`makepkg -si`

`cd ..`

`sudo rm -Rv package-query yaourt`

Install Display Manger and Desktop Enviroment:

First we need a Display Manager:

`sudo pacman -S sddm`

`sudo systemctl enable sddm.service`

Then install the Desktop Enviroment:

`sudo pacman -S plasma kde-applications flite`

`all`

`all`

`select libx264`

`select cronie`

`press y to continue`

~~Install a firewall for security:~~

~~`sudo pacman -Sy firewalld`~~

~~`sudo systemctl enable firewalld.service`~~

~~`sudo cp /etc/iptables/empty.rules /etc/iptables/iptables.rules`~~

~~`sudo systemctl enable iptables.service`~~

~~Tell firewalld we are at home and add network interface:~~

~~`sudo firewall-cmd --permanent --zone=home --add-interface=eno1`~~

Now we need to reboot to get into the Desktop Enviroment:

`sudo reboot`

Final software to install:

`sudo pacman -Sy smartmontools filezilla vlc ttf-freefont libva-vdpau-driver cups gtk3-print-backends system-config-printer`

`sudo systemctl enable org.cups.cupsd.service`

`yaourt chrome`

`yaourt tff-google-fonts-git`

`yaourt gpmdp`

`yaourt visual-studio-code`

`yaourt gparted`

`yaourt discord`

`yaourt skype`

`yaourt samsung-unified-driver`

Some annoying kernel drivers:

`yaourt wd719x-firmware`

`yaourt aic94xx-firmware`


## KVM

### Kernel

First we must find the PCI address's of our GPU:

`lspci | grep VGA`

```
01:00.0 VGA compatible controller: NVIDIA Corporation GK208 [GeForce GT 710B] (rev a1)
02:00.0 VGA compatible controller: NVIDIA Corporation GM204 [GeForce GTX 970] (rev a1)
```

`lspci -nn | grep 02:00`

```
02:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM204 [GeForce GTX 970] [10de:13c2] (rev a1)
02:00.1 Audio device [0403]: NVIDIA Corporation GM204 High Definition Audio Controller [10de:0fbb] (rev a1)
```

Now we need to find the wireless card:

`lspci -nn | grep 05:00.0`

```
05:00.0 Network controller [0280]: Broadcom Limited BCM4360 802.11ac Wireless Network Adapter [14e4:43a0] (rev 03)
```

Okay so now I know what address's my PCI Cards are we need to isolate the one we want to use for the Windows Guest:

`sudo nano /etc/modprobe.d/vfio.conf`

```
options vfio-pci ids=10de:13c2,10de:0fbb,14e4:43a0
```

To make sure it does edit:

`sudo nano /etc/mkinitcpio.conf`

Add modules and check for `modconf` is in HOOKS:

```
MODULES="vfio vfio_iommu_type1 vfio_pci vfio_virqfd"
```

```
HOOKS="base udev autodetect modconf block filesystems keyboard fsck"
```

We also need to get some modules loaded at boot to improve some performance:


`sudo nano /etc/modules-load.d/virtio-pci.conf`

And Paste:

```
# Load virtio-pci.ko at boot
virtio-pci
```

Do this for these modules as well:

`sudo nano /etc/modules-load.d/virtio-net.conf`

```
# Load virtio-net.ko at boot
virtio-net
```

`sudo nano /etc/modules-load.d/virtio-blk.conf`

```
# Load virtio-blk.ko at boot
virtio-blk
```

`sudo nano /etc/modules-load.d/virtio-balloon.conf`

```
# Load virtio-balloon.ko at boot
virtio-balloon
```

`sudo nano /etc/modules-load.d/virtio-ring.conf`

```
# Load virtio-ring.ko at boot
virtio-ring
```

`sudo nano /etc/modules-load.d/virtio.conf`

```
# Load virtio.ko at boot
virtio
```

Because my IUMMO groups stay grouped I need the `ACS override patch`:

Install Patched kernel `linux-vfio-lts` and ~~downgrade `gpupg` until a bug from 2.1.17+ is fixed~~:

~~`sudo pacman -U https://archive.archlinux.org/packages/g/gnupg/gnupg-2.1.16-2-x86_64.pkg.tar.xz`~~

~~Add this to `/etc/pacman.conf` so we won't update it by accident until a fix is provided:~~

~~`sudo nano /etc/pacman.conf`~~

~~`IgnorePkg   = gnupg`~~

Import gpg keys otherwise kernel download will error:

`sudo gpg --recv-keys 79BE3E4300411886`

`sudo gpg --recv-keys 38DBBDC86092693E`

If that fails to import edit `~/.gnupg/dirmngr.conf`:

`sudo nano ~/.gnupg/dirmngr.conf`

Add `keyserver hkp://pgp.mit.edu` to the bottom.

Install kernel:

`yaourt linux-vfio-lts` is flagged out of date so lets update the `pkgbuild`ourselves

`nano`

And then change the `pkgver=4.9.*` with `*` as the kernel version number. Then fix the `sha256sums=` of the patch update to the latest.

Rebuild kernel `linux` and `linux-lts`:

`sudo mkinitcpio -p linux`

`sudo mkinitcpio -p linux-lts`

Now we need to reboot:

`reboot`

And check if it worked:

`lspci -nnk -d 10de:13c2`

`lspci -nnk -d 10de:0fbb`

Check for on both ouputs:

```
Kernel driver in use: vfio-pci
```

Now we need the `pcie_acs_override=downstream` added to the kernel options paremeters and change the kernel to `linux-vfio-lts`:

`nano /boot/loader/entries/arch.conf`

```
title          Arch Linux
linux          /vmlinuz-linux-vfio-lts
initrd         /initramfs-linux-vfio-lts.img /intel-ucode.img
options        root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX rw quiet intel_iommu=on pcie_acs_override=downstream nvidia-drm.modeset=1
```

`"CTRL-O" then "ENTER" to save`

`"CTRL-X" to exit nano editor`

Now we need to reboot to check the IUMMO groups:

`sudo reboot`

Add `blacklist nouveau` to `/etc/modprobe.d/blacklist.conf` if display manager crashes:

`sudo nano /etc/modprobe.d/blacklist.conf`

So we can display Screen Information:

`sudo pacman -Sy xorg-xrandr`


### Software

Now we need to install the software that sets up out Guest OS and optional depencies to get rid of some annoying error logs:

`sudo pacman -Sy qemu libvirt virt-manager dmidecode dnsmasq firewalld`

`yaourt ovmf-git`

Then we need to add the OVMF firmware image path we just downloaded to the bottom of the libvrit config so the software can find it:

`sudo nano /etc/libvirt/qemu.conf`

```
nvram = [
	"/usr/share/ovmf/x64/ovmf_code_x64.bin:/usr/share/ovmf/x64/ovmf_vars_x64.bin"
]
```

Now we need to enable the `libvirtd.service`:

`sudo systemctl enable --now libvirtd`
`sudo systemctl enable virtlogd.socket`

Make the VM then edit the config:

`sudo EDITOR=nano virsh edit win10`

Add `<vendor_id state='on' value='whatever'/>` between:

```
<hyperv>
<vendor_id state='on' value='whatever'/>
</hyperv>
```

And add this directly after `</hyperv>`:

```
<kvm>
<hidden state='on'/>
</kvm>
```
