## SSH Setup so we can copy/paste
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
### Preparation
First we need to check where connected to the internet:

`ping -c 3 archlinux.org`

We also have to check the clock is set to your timezones time so update servers don't get confused:

To update the time:

`timedatectl set-ntp true`

Set the timezone accordingly:

`timedatectl set-timezone Australia/Perth`

To check:

`timedatectl status`
