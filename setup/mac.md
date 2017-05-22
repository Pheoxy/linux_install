UEFI

Press "E" to edit boot parameters

Press "END" to go to end and type:

`i915.modeset=0`

Follow install

Add to boot parameters on boot manager:

`i915.modeset=0`

Add to kernel blacklisting:

`sudo nano /etc/modprobe.d/i915.conf`

Add:

`blacklist i915`


Add nouveau to the MODULES array in /etc/mkinitcpio.conf:

`MODULES="... nouveau ..."`

`sudo mkinitcpio -p linux`

After install of xorg:

`sudo nano /etc/X11/xorg.conf.d/20-nouveau.conf`

```
Section "Device"
    Identifier "Nvidia card"
    Driver "nouveau"
EndSection
```

`sudo nano /etc/X11/xorg.conf.d/10-monitor.conf`

```
Section "Monitor"
        Identifier "eDP-1"
        Option "PreferredMode" "1920x1080"
EndSection
```
