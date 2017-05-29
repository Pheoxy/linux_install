#!/bin/bash

vmname="windows10_kvm"

if ps -A | grep -q $vmname; then
   echo "$vmname is already running." &
   exit 1

else

# use pulseaudio
#export QEMU_AUDIO_DRV=pa
#export QEMU_PA_SAMPLES=8192
#export QEMU_AUDIO_TIMER_PERIOD=99
#export QEMU_PA_SERVER=/run/user/1000/pulse/native

cp /usr/share/ovmf/x64/ovmf_vars_x64.bin /tmp/ovmf_vars_x64.bin
cp /usr/share/ovmf/x64/ovmf_code_x64.bin /tmp/ovmf_code_x64.bin

qemu-system-x86_64 \
  -name $vmname,process=$vmname \
  -machine type=pc,accel=kvm \
  -cpu host,kvm=off \
  -smp 6,sockets=1,cores=3,threads=2 \
  -enable-kvm \
  -m 8G \
  -mem-prealloc \
  -balloon none \
  -rtc clock=host,base=localtime \
  -vga none \
  -nographic \
  -serial none \
  -parallel none \
  -usb -usbdevice host:05e3:0610 \
  -usb -usbdevice host:05e3:0612 \
  -usb -usbdevice host:046d:c051 \
  -usb -usbdevice host:1532:0202 \
  -usb -usbdevice host:05dc:a81d \
  -usb -usbdevice host:1b1c:0a2b \
  -device vfio-pci,host=02:00.0,multifunction=on \
  -device vfio-pci,host=02:00.1 \
  -device vfio-pci,host=05:00.0 \
  -drive if=pflash,format=raw,readonly,file=/tmp/ovmf_code_x64.bin \
  -drive if=pflash,format=raw,file=/tmp/ovmf_vars_x64.bin \
  -boot order=c \
  -device virtio-scsi-pci,id=scsi \
  -drive id=disk0,if=virtio,cache=none,format=raw,file=/var/lib/libvirt/images/win10.img \
  -drive file=/home/pheoxy/Downloads/virtio-win-0.1.126.iso,id=virtiocd,format=raw,if=none -device ide-cd,bus=ide.1,drive=virtiocd \

   exit 0
fi
