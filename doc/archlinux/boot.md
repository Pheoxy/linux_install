# Boot
## UEFI
Boot from the Imaged USB in UEFI Mode and before it can auto boot quickly use the Press the `"E"` to edit
the boot sequence to allow for NVIDIA boot or we will get a black screen and won't be able to continue.

Press the `"END"` key to get to the end of the line so we can add something to the boot sequence.

Type:

`nomodeset`

### Check UEFI booted correctly
Now using your SSH console we need to check we booted with UEFI, type:

`ls /sys/firmware/efi/efivars`

## BIOS
Boot from the Imaged USB in BIOS Mode and before it can auto boot quickly use the Press the `"TAB"` to edit
the boot sequence to allow for NVIDIA boot or we will get a black screen and won't be able to continue.

Press the `"END"` key to get to the end of the line so we can add something to the boot sequence.

Type:

`nomodeset`

