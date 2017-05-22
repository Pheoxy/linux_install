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
