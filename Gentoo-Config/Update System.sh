# Update System
 emerge --sync
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 env-update && source /etc/profile
 chown root:mail /var/spool/mail/
 chmod 03775 /var/spool/mail/
 eselect pinentry set pinentry-gnome3
 USE+="symlink"
 cat /proc/config.gz | gunzip > /usr/src/linux/mykernel.config
 genkernel --install --lvm --luks --udev --splash --makeopts=-j5 --menuconfig all
 grub2-install --efi-directory=/boot
 grub2-mkconfig -o /boot/grub/grub.cfg
 cp -f /boot/EFI/gentoo/grubx64.efi /boot/EFI/BOOT/bootx64.efi
 emerge --ask virtualbox-guest-additions
 emerge --ask xf86-video-virtualbox
 reboot

