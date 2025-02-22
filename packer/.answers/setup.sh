# show script's output
exec > >(tee -a /dev/tty0) 2>&1

# delete this hack
# otherwise this script will run on the system we newly installed
rm -f /etc/local.d/setup.start
rm -f /etc/runlevels/default/local


# do the system installation
setup-interfaces -a
rc-update add networking boot
passwd -l root
adduser -D -H provision wheel
echo provision:Password1 | chpasswd
printf '\nyes' | setup-sshd
setup-keymap us us
setup-timezone -i Asia/Shanghai
setup-ntp chrony || true
true >/etc/apk/repositories
setup-apkrepos -1 -c
printf 'y' | setup-disk -m sys /dev/sda

#packer/qemu setup
mount /dev/sda3 /mnt

cp /mnt/etc/apk/repositories /etc/apk/repositories


#install guest agent to fetch ip later
apk add -p /mnt qemu-guest-agent doas
echo permit nopass :wheel > /mnt/etc/doas.d/wheel.conf 
# service qemu-guest-agent start
#rc-updated doesnt work with a seprate root so makiing the link by hand
ln -s /mnt/etc/init.d/qemu-guest-agent /etc/runlevels/default/qemu-guest-agent

# reboot