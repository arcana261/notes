# handbook https://wiki.gentoo.org/wiki/Handbook:AMD64/Full/Installation
# CHOICE
 # non-EFI
  # boot gentoo minimal install disk (non-EFI)
  :boot gentoo
 # EFI
  # boot gentoo live installation disk (EFI)
  # open Konsole
  sudo bash

# check that we have ethernet up and running
# get eternet name, in this case might be enp0s3
# get ethernet IP address, in this case might be 192.168.56.104
ifconfig
# disable ipv6 on found ethernet
# CHOICE
 # non-EFI
  nano -w /etc/sysctl.conf
  > net.ipv6.conf.eno16777736.disable_ipv6=1
  > net.ipv6.conf.eno16777736.autoconf=0
  > net.ipv6.conf.eno16777736.accept_ra=0 
 # EFI
  nano -w /etc/sysctl.conf
  > net.ipv6.conf.enp0s3.disable_ipv6=1
  > net.ipv6.conf.enp0s3.autoconf=0
  > net.ipv6.conf.enp0s3.accept_ra=0 
  > net.ipv6.conf.enp0s8.disable_ipv6=1
  > net.ipv6.conf.enp0s8.autoconf=0
  > net.ipv6.conf.enp0s8.accept_ra=0 
service sysctl restart
# verify that we have disabled ipv6
ifconfig
# change DNS server for god's sake!
nano -w /etc/resolv.conf
> nameserver 4.2.2.4
> nameserver 8.8.8.8
# check that we have internet
ping -c 4 google.com
# CHOICE
 # non-EFI
  # startup ssh service
  /etc/init.d/sshd restart
  # assign a password so we can ssh (1234 recomended)
  passwd
  # connect using SSH, much easier!
 # EFI
  # startup ssh service
  /etc/init.d/sshd restart
  # assign a password so we can ssh (1234 recomended)
  passwd
# identify disks
lsblk | grep -v "rom\|loop\|airoot"
# identify disk properties
parted /dev/sda print
parted /dev/sdb print

# to remove partitions,
# fdisk /dev/sda
# > d
# > {#partition_number}
# > w

# start lvm
/etc/init.d/lvm restart
/etc/init.d/lvmetad restart
# load modules necessary for encryption
modprobe dm-crypt
modprobe aes
modprobe sha256
# create partitions on /dev/sda
# CHOICE
 # non-EFI
  parted /dev/sda
  > mklabel msdos
  > mkpart primary ext4 1M 200M
  > set 1 boot on
  > mkpart primary linux-swap 200M 2.2G
  > mkpart primary 2.2G 100%
  > set 3 lvm on
  > quit
 # EFI
  parted /dev/sda
  > mklabel gpt
  > mkpart primary 1M 3M
  > name 1 grub
  > set 1 bios_grub on
  > mkpart primary 3M 512M
  > name 2 boot
  > set 2 boot on
  > mkpart primary 512M 100%
  > set 3 lvm on
  > quit
# check created partitions on /dev/sda
lsblk /dev/sda
# create partitions on /dev/sdb
# CHOICE
 # non-EFI
  parted /dev/sdb
  > mklabel msdos
  > mkpart primary 1M 100%
  > set 1 lvm on
  > quit
 # EFI
   parted /dev/sdb
   > mklabel gpt
   > mkpart primary 1M 100%
   > set 1 lvm on
   > quit
# check created partitions on /dev/sdb
lsblk /dev/sdb
# create encrypted partition
# fill random data:
#   dd if=/dev/urandom of=/dev/sdZn bs=1M
# get progress:
#   watch -n5 "kill -USR1 $(pgrep '^dd$')" 
cryptsetup luksFormat /dev/sda3 --debug
cryptsetup luksFormat /dev/sdb1 --debug
# open encrypted partition
cryptsetup luksOpen /dev/sda3 enc1 --debug
cryptsetup luksOpen /dev/sdb1 enc2 --debug
# create PV (Physical Volumes) for LVM
pvcreate /dev/mapper/enc1
pvcreate /dev/mapper/enc2
# identify create PVs
pvdisplay
# to scan for not-displayed PVs use
# pvscan
# create VG (Volume Groups) for LVM
vgcreate vg1 /dev/mapper/enc1
vgcreate vg2 /dev/mapper/enc2
# identify created VGs
vgdisplay
# to scan for not-displayed VGs use
# vgscan
# create logical volumes (LVs)
lvcreate -L 2G -n lv1 vg1
lvcreate -l 100%FREE -n lv2 vg1
lvcreate -l 100%FREE -n lv3 vg2
# alternatively
# lvcreate -L 150M -n lv1 vg0
# identify created LVs
lvdisplay
# create filesystems
# CHOICE
 # non-EFI
  mkswap /dev/sda2
  swapon /dev/sda2
  mkfs.ext4 /dev/sda1
  mkfs.ext4 /dev/vg1/lv1
  mkfs.ext4 /dev/vg2/lv2
 # EFI
  mkswap /dev/vg1/lv1
  swapon /dev/vg1/lv1
  mkfs.vfat /dev/sda2
  mkfs.ext4 /dev/vg1/lv2
  mkfs.ext4 /dev/vg2/lv3
# mount partitions
mount /dev/vg1/lv2 /mnt/gentoo
mkdir -p /mnt/gentoo/{home,boot}
mount /dev/vg2/lv3 /mnt/gentoo/home
# CHOICE
 # non-EFI
  mount /dev/sda1 /mnt/gentoo/boot
 # EFI
  mount /dev/sda2 /mnt/gentoo/boot
# identify that date is correct
date
# download stage3 in /mnt/gentoo
cd /mnt/gentoo
# extract stage3 tarball
tar xvjpf stage3-amd64-20150917.tar.bz2 --xattrs
# copy DNS info to new environment
cp -L /etc/resolv.conf /mnt/gentoo/etc/
# mount necessary filesystems
mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --rbind /run /mnt/gentoo/run
mount --make-rslave /mnt/gentoo/run
# chroot into new environment
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) $PS1"
# install portage
emerge-webrsync
# we can read news about updates in
eselect news list
eselect news read
# list portage profiles
eselect profile list
# select the right profile
eselect profile set 1
# take a look at currently set USE
emerge --info | grep ^USE
# also for more information on USE variables
less /usr/portage/profiles/use.desc
## use can be be set in /etc/portage/make.conf
## USE="-gtk -gnome qt4 kde dvd alsa cdr"
## - removes
## -* removes all
# list available timezone
ls /usr/share/zoneinfo
# select what timezone we want
echo "Iran" > /etc/timezone
# we now update timezone data
emerge --config sys-libs/timezone-data
# check if date is OK
date
# if not OK change it
# date --set "13:30:50"
# select locale we want to use
nano -w /etc/locale.gen
> en_US ISO-8859-1
> en_US.UTF-8 UTF-8
> fa_IR.UTF-8 UTF-8
locale-gen
# verify that locales are installed
locale -a
# we now set system-wide locale setting
eselect locale list
eselect locale set 4
# reload the environment
env-update && source /etc/profile
export PS1="(chroot) $PS1"
# install gentoolkit
emerge app-portage/gentoolkit
# select a kernel from https://wiki.gentoo.org/wiki/Kernel/Overview
#  is gentoo-sources
echo "sys-kernel/gentoo-sources symlink" >> /etc/portage/package.use/gentoo-sources
emerge sys-kernel/gentoo-sources
# see progress of merge inside another terminal
# tail -f /mnt/gentoo/var/log/emerge-fetch.log
# check linux sources installed successfully
ls -l /usr/src/linux
# cpu features https://en.wikipedia.org/wiki/CPUID
# also http://unix.stackexchange.com/questions/43539/what-do-the-flags-in-proc-cpuinfo-mean
  fpu: obboard x87 FPU
  vme: Virtual 8086 mode extensions (such as VIF, VIP, PIV)
  de: Debugging extensions (CR4 bit 3)
  pse: Page Size Extension
  tsc: Time Stamp Counter
  msr: Model specific registers -> kernel
  pae: Physical Address Extension -> kernel (for 32bit kernel)
  mce: Machine Check Exception -> kernel
  cx8: CMPXCHG(compare-and-swap) instruction -> gcc, overriden by cx16
  apic: Onboard Advanced Programmable Interrupt Controller -> kernel
  sep: SYSENTER and SYSEXIT instructions
  mtrr: Memory Type Range Registers -> kernel
  pge: Page Global Enable bit in CR4
  mca: Machine check architecture -> kernel
  cmov: Conditional move and FCMOVE instructions
  pat: Page Attribute Table -> kernel
  pse36: 36-bit page size extensions
  clflush: CLFLUSH instruction (SSE2)
  mmx: MMX Instructions -> gcc -mmmx
  fxsr: FXSAVE, FXRESTORE instructions, CR4 bit 9 -> gcc -mfxsr
  sse: SSE Instructions (a.k.a. Katmai New Instructions) -> gcc -msse
  sse2: SSE2 Instructions -> gcc -msse2
  ht: Hyper-threading -> kernel
  syscall: SYSCALL and SYSRET instructions
  nx: NX bit (used for Exec sheild, etc..) -> kernel
  rdtscp: RDTSCP Instruction
  lm: Long mode -> CPU is AMD64/x86_64
  constant_tsc: TSC ticks at a constant rate
  rep_good: rep microcode works well
  nopl: the NOPL (0f 1f) instructions
  xtopology: cpu topology enum extensions
  nonstop_tsc: TSC does not stop in C states
  pni: Prescott New Instructions-SSE3 -> gcc -msse3
  pclmulqdq: An extended instruction set for block ciphering -> -mpclmul
  ssse3: Supplemental SSE3 Instructions -> gcc -mssse3
  cx16: CMPXCHG16B Instruction -> gcc -mcx16
  sse4_1: SSE4.1 Instructions -> gcc -msse4.1
  sse4_2: SSE4.2 Instructions -> gcc -msse4.2
  movbe: MOVBE Instruction (Big-Endian) -> gcc -mmovbe
  popcnt: POPCNT Instruction -> gcc -mpopcnt
  aes: AES Instruction set -> gcc -maes
  xsave: XSAVE, XRESTOR, XSETBV, XGETBV -> gcc -mxsave
  avx: Advanced Vector Extensions -> gcc -mavx
  rdrand: RDRAND (on-chip random number generator) -> kernel, gcc -mrdrnd
  hypervisor: Running on hypervisor -> System in under virtualization
  lahf_lm: LAHF/SAHF in long mode -> gcc -msahf
  abm: Advanced bit manipulation (lzcnt and popcnt) -> gcc -mabm
# find best CFLAGS in
# https://wiki.gentoo.org/wiki/Safe_CFLAGS
# to see which optimization options are enabled by GCC see output of following command
# gcc -Q -march=native --help=target | egrep '(march|mtune|enabled)' 
# to check optimization flags use --help=optimize
# USE flags for processor include (mmx,sse,sse2,sse3,sse4,ssse3)
# > mmx: cpuinfo "mmx"
# > sse: cpuinfo "sse"
# > sse2: cpuinfo "sse2"
# > sse3: cpuinfo "pni"
# > ssse3: cpuinfo "ssse3"
# > sse4: cpuinfo "sse4_1" "sse4_2"
# other GCC options are -msse, -msse2, -msse3, -mmmx, -m3dnow
# you can use cat /proc/cpuinfo for more information on CPU
nano -w /etc/portage/make.conf
>> disable default USE flags
> CHOST="x86_64-pc-linux-gnu"
> CFLAGS="-march=native -mtune=native -O3 -pipe -fno-stack-protector -fno-strict-aliasing"
> FFLAGS="-march=native -mtune=native -O3 -pipe -fno-stack-protector -fno-strict-aliasing"
> CXXFLAGS="${CFLAGS}"
> FCFLAGS="${FFLAGS}"
> MAKEOPTS="-j9"
# install cpuid to cpuflags
emerge --ask app-portage/cpuid2cpuflags
cpuinfo2cpuflags-x86
>> add result to make.conf, both as CPU_FLAGS_X86 and USE
>> CPU_FLAGS_X86="aes avx mmx mmxext popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
>> USE+="aes avx mmx mmxext popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
# rebuild entire system
env-update && source /etc/profile
export PS1="(chroot) $PS1"
emerge --ask -e @world
hash -r
env-update && source /etc/profile
export PS1="(chroot) $PS1"
etc-update
emerge --depclean
emerge @preserved-rebuild
emerge --depclean
# install list-gentoo-packages
>> copy script to /usr/sbin
>> add +x to script
# disable bindist
# since we don't want anything non-opensource
USE+="-bindist"
emerge --ask --deep --update --newuse @world
emerge --depclean
# install openssl
emerge --ask dev-libs/openssl
echo "dev-lang/python ssl" >> /etc/portage/package.use/python
echo "net-misc/iputils ssl" >> /etc/portage/package.use/iputils
echo "net-misc/openssh ssl" >> /etc/portage/package.use/openssh
echo "net-misc/wget ssl" >> /etc/portage/package.use/wget
emerge --ask --deep --update --newuse @world
emerge --depclean
# enable NLS for localization support in whole system
USE+="nls"
hash -r
env-update && source /etc/profile
export PS1="(chroot) $PS1"
emerge --depclean
# enable linguas
nano -w /etc/portage/make.conf
>> LINGUAS="en_US fa_IR en fa en_GB en-GB fa-IR"
>> L10N="en_US fa_IR en fa en_GB en-GB fa-IR"
emerge --ask --deep --update --newuse @world
emerge --depclean
# enable unicode support
USE+="unicode"
emerge --ask --deep --update --newuse @world
emerge --depclean
# install PAM (Pluggable Authentication Module) cause it's dangerous not to have
>> net-misc/openssh+="pam"
>> sys-apps/kbd+="pam"
>> sys-apps/openrc+="pam"
>> sys-apps/shadow+="pam"
>> sys-apps/util-linux+="pam"
emerge --ask --deep --update --newuse @world
emerge --depclean
# enable "readline" without it, one can not use even "bash" properly
# as the only thing you can do in bash if you mistype is to delete
# backwards pressing backspace, and nothing else.
>> app-shells/bash readline
>> dev-lang/python readline
>> dev-libs/libxml readline
>> sys-devel/bc readline
>> sys-apps/gawk readline
emerge --ask --deep --update --newuse @world
emerge --depclean
# disable static on busybox cause cannot co-exist with PAM
>> sys-apps/busybox+="pam -static"
emerge --ask --deep --update --newuse @world
emerge --depclean
# install systemd
# keep in mind that "-consolekit" should be present
# in all packages, it is incompatible with systemd
# NOTE: add pm-utils to consolekit after installing video card driver
# NOTE: use following to tell why packages are pulled in
# equery depends <package>
# example: equery depends openrc
emerge -C sys-apps/sysvinit
emerge -C sys-fs/eudev
emerge -C virtual/udev
USE+="-consolekit"
>> sys-apps/systemd+="acl nat pam policykit sysv-utils"
>> www-client/w3m+="ssl"
>> sys-apps/dbus+="systemd"
>> sys-auth/consolekit+="policykit pam acl cgroups"
>> dev-libs/glib+="dbus"
>> virtual/udev+="systemd"
>> sys-apps/coreutils+="acl caps xattr"
emerge --ask sys-apps/systemd
emerge -C sys-apps/openrc
emerge -C virtual/service-manager
emerge -C net-misc/netifrc
>> sys-apps/openrc+="-netifrc"
mkdir -p /etc/portage/profile
echo "-*sys-apps/openrc" >> /etc/portage/profile/packages
echo "-*sys-apps/net-tools" >> /etc/portage/profile/packages
emerge --ask --deep --update --newuse @world
emerge --depclean
>> app-admin/cgmanager+="pam"
>> sys-auth/polkit+="pam"
>> sys-libs/libcap+="pam"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> sys-apps/busybox+="systemd"
>> sys-apps/util-linux+="systemd"
>> sys-auth/pambase+="systemd"
>> sys-auth/polkit+="systemd jit"
>> sys-process/procps+="systemd"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> sys-apps/systemd+="cryptsetup"
>> virtual/libudev+="systemd"
>> sys-fs/cryptsetup+="udev"
>> sys-fs/lvm2+="-thin udev readline systemd"
emerge --ask --deep --update --newuse @world
emerge --depclean
 # enable "udev" support to enable device discovery
>> sys-apps/util-linux+="udev"
>> dev-libs/libxml2+="readline"
 # disable tty7 to work better with X
nano -w /etc/systemd/logind.conf
> NAutoVTs=6
> ReserveVT=0
 # enable network service
systemctl enable systemd-networkd.service 
systemctl enable systemd-resolved.service
umount /run
mkdir -p /run/systemd/resolve
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf 
nano -w /etc/systemd/network/50-dhcp.network
> [Match]
> Name=en*
>
> [Network]
> DHCP=yes
 # add nameservers again
 nano -w /etc/resolv.conf
 > nameserver 4.2.2.4
 > nameserver 8.8.8.8
 # enable mtab
ln -sf /proc/self/mounts /etc/mtab
 # enable other services
 # to list unit files issue
 # systemctl list-unit-files
systemctl enable lvm2-lvmetad.service
systemctl enable lvm2-monitor.service
systemctl enable dm-event
systemctl enable blk-availability.service
systemctl enable rsyncd.service
systemctl enable systemd-timesyncd.service
systemctl enable dm-event.socket
systemctl enable lvm2-lvmetad.socket
## systemctl enable sshd.service
## systemctl enable sshd.socket
systemctl enable uuidd.socket
systemctl enable fstrim.timer
# install pciutils
>> sys-apps/pciutils+="dns"
emerge --ask sys-apps/pciutils
# install usbutils
>> dev-libs/libusb+="udev"
>> virtual/libusb+="udev"
emerge --ask sys-apps/usbutils
# install acpitool
# usage: acpitool -e
emerge --ask sys-power/acpitool
# install hwinfo
emerge --ask sys-apps/hwinfo
# install genkernel 
>> sys-kernel/genkernel-next+="cryptsetup"
emerge --ask genkernel-next
 # configure fstab for genkernel
 # use blkid for this UUID=<uuid>
 nano -w /etc/fstab
 > /dev/sda2		/boot	vfat	noatime							  1 2
 > /dev/vg1/lv2	/		ext4	noatime,discard,acl						  0 1
 > /dev/vg1/lv1		none	swap	sw										  0 0
 > /dev/vg2/lv3	/home	ext4	noatime,acl,x-systemd.device-timeout=60s  0 0
 # create empty kernel config
touch /usr/src/linux/empty.config
# compile kernel
# guide http://www.linux.org/threads/the-linux-kernel-series-every-article.6558/
# lspci -vv, lspci -k, lspci -vmk
#  find matching driver (specially usb) via 
#  grep -ir device.*0x2001 /usr/src/linux/drivers/
#  where 0x2001 is the first/second part of device id
#  
#  find device id of PCI devices using lspci -nn
#   PCI id has 3 parts, class, vendor and device
#
#  PCI vendor ids can be found in
#   /usr/src/linux/include/linux/pci_ids.h
#
# dmesg
# CHOICE
 # non-EFI
  genkernel --install --lvm --luks --udev --symlink --makeopts=-j5 --menuconfig all
 # EFI
  genkernel --install --lvm --luks --udev --makeopts=-j5 --menuconfig all
  
NOTE: Virtualbox has DMI
      DMI: innotek GmbH VirtualBox/VirtualBox, BIOS VirtualBox 12/01/2006
NOTE: Virtualbox has EFI v2.31 by EDK IT
NOTE: Virtualbox has ACPI/ACPI 2.0
NOTE: Virtualbox has SMBIOS
NOTE: Virtualbox supports MPS records
NOTE: Virtualbox does not support PCI MMCONFIG
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>> configure base environment
# General Setup
#  (-arcana) Local version - append to kernel release
#  * Automatically append version information to the version string
>>> configure expert linux features
# General Setup
#  * Configure standard kernel features (expert users)
#   * Multiple users, groups and capabilities support || this limits to only "root". not good!
#   [] Enable 16-bit UID system calls
#   * Sysfs syscall support
#   * Enable support for printk
#   [] Enable PC-Speaker support
#   * Enable futex support || required for glibc
# [] Namespace support
>>> we need to export current kernel config for emerge and other software
# General Setup
#  * Kernel .config support
>>> traditional unix IPC isnt bad
# General Setup
#  * System V IPC
>>> some optimizations isnt bad
# General Setup
#  * Optimize very unlikely/likely branches
#  [] Optimize for size
>>> process group scheduling feels nice
# General Setup
#  * Automatic process group scheduling
				>>> namespaces are important
				# General Setup
				#  * Namespaces support
				#   * UTS namespace
				#   * IPC namespace
				#   * PID namespace
>>> configure timers
# General Setup
#  Timers subsystem
#   energy saving?? -> Timer tick handling (Idle dynticks system (tickless idle))
#   performance?? -> Periodic timer ticks (constant rate, no dynticks)
#   * High Resolution Timer Support
>>> shmem is very important functionality
# General Setup
#  * desktop?? -> Use full shmem filesystem
#
### full shmem is not good for embedded small systems
#
>>> enable madvise which is important for performance
# General Setup
#  * Enable madvise/fadvise syscalls
>>> ramdisk is important for boot
# General Setup
#  * Initial RAM filesystem and RAW disk (initramfs/initrd) support
#  * Support initial ramdisks compressed using gzip
#  [] Support initial ramdisks compressed using bzip2
#  [] Support initial ramdisks compressed using LZMA
#  * Support initial ramdisks compressed using XZ
#  [] Support initial ramdisks compressed using LZO
#  [] Support initial ramdisks compressed using LZ4
>>> disable heap randomization, might break things
# General Setup
#  * Disable heap randomization
>>> enable executable support, very important!
# Executable file formats / Emulations
#  * Kernel support for ELF binaries
#  * Kernel support for scripts starting with #!
#  * Kernel support for a.out and ECOFF binaries
>>> CPU is 64 bit: lm: Long mode -> CPU is AMD64/x86_64
# * 64 bit kernel
# Processor type and features
#  * Enable vsyscall emulation
#  Memory Model (Sparse Memory)
#  * Sparse Memory virtual memmap
>>> CPU is multicore
# Processor type and features
#  * Symmetric multi-processing support
#  (4) Maximum number of CPUs
#  * Multi-core scheduler support
>>> CPU is Haswell (4770k) with cpu family = 6 in /proc/cpuinfo
# Processor type and features
#  Processor family (Core 2/newer Xeon
#  Supported processor vendors
#   * Support Intel processors
#   [] Support AMD processors
#   [] Support Centaur processors
>>> CPU gives cpuid
# Processor type and features
#  * /dev/cpu/*/cpuid - CPU informaton support
>>> CPU Instruction: msr: Model specific registers -> kernel  
# Processor type and features
#  * /dev/cpu/*/msr - Model-specific register support
>>> CPU Instruction: mce: Machine Check Exception -> kernel
# Processor type and features
# * Machine Check / overheating reporting
# * Intel MCE features
# [] AMD MCE features 
# [] Machine check injector support
>>> rdrand: RDRAND (on-chip random number generator) -> kernel, gcc -mrdrnd
# Processor type and features
#  * x86 architectural random number generator
# Device Drivers
#  Character devices
#   * Hardware Random Number Generator Core support
#    * VIA HW Random Number Generator support
#    * Timer IOMEM HW Random Number Generator support
>>> we love memory compaction
# Processor type and features
#  * Allow for memory compaction
>>> we love transparent hugepage support for performance
# Processor type and features
#  * Transparent Hugepage Support
#  Transparent Hugepage Support sysfs defaults (always)
>>> seccomp is important security feature
# Processor type and features
#  * Enable seccomp to safely compute untrusted bytecode
>>> set preemption model
# Processor type and features
#  Preemption Model (Voluntary Kernel Preemption (Desktop))
>>> ht: Hyper-threading -> kernel
# Processor type and features
#  * SMT (Hyperthreading) scheduler support
>>> mtrr: Memory Type Range Registers -> kernel
# Processor type and features
#  * MTRR (Memory Type Range Register) support
#  * MTRR cleanup support || good if we want to have X in the future
>>> supervisor mode is important in security
# Processor type and features
#  * Supervisor Mode Access Prevention
>>> recovery from hardware memory errors
# Processor type and features
#  * Enable recovery from hardware memory errors
>>> KSM may come handy
# Processor type and features
#  * Enable KSM for page merging
>>> set timer frequency for desktop performance
# Processor type and features
#  Timer frequency (300 HZ)
>>> pat: Page Attribute Table -> kernel
# Processor type and features
#  * x86 PAT support
>>> AIO is used by many applications including gio (glib)
# General Setup
#  * Enable AIO support
>>> enable Single-depth WCHAN output to increase
>>> scheduling performance
# Processor type and features
#  * Single-depth WCHAN output 
>>> System has PCI
# Bus options
#  * PCI support
#  * Message Signaled Interrupts (MSI and MSI-X)
#  * PCI PRI Support || we consider supporting IOMMU's
#  * PCI PASID Support || we consider supporting IOMMU'ssupport
# General Setup
#  * Enable PCI quirk workarounds
>>> ISA bridge: Intel Corporation 82371SB PIIX3 ISA [Natoma/Triton II]
# Bus options
#  * ISA-style DMA support
>>> System has PCIe
# Bus options
#  * PCI Express Port Bus support
#  * Root Port Advanced Error Reporting support
#  * PCI Express ASPM control
>>> System has one CPU socket
# Bus options
#  [] Interrupts on hypertransport devices 
>>> ASUS Z87 Pro has ACPI 5.0 support
>>> Virtualbox Bridge: Intel Corporation 82371/AB/EB/MB PIIX4 ACPI is ACPI 2.0 Complient
# Power management and ACPI options
#  * ACPI (Advanced Cofiguration and Power Interface) Support
#   [] AC Adapter
#   [] Battery
#   * Processor
#   * Fan
#   [] Processor Aggregator || ACPI 4.0 supports this
#   * Thermal Zone
#   * Power Management Timer Support
#   [] Container and Module Devices || ACPI 5.0 supports this
#   [] ACPI Platform Error Interface (APEI) || ACPI 5.0 supports this
#   [] APEI Generic Hardware Error Source || ACPI 5.0 supports this
#   [] APEI PCIe AER logging/recovering support || ACPI 5.0 supports this
#  CPU Frequency scaling
#   * CPU Frequency scaling
#   * CPU Frequency translation statistics
#   * 'ondemand' cpufreq policy governor
#   * ACPI Processor P-States driver || Intel 4770k supports Enhanced Intel SpeedStep Technology
#   [] Legacy cpb sysfs knob support for AMD CPUs
#   [] Processor Clocking Control interface driver || ACPI 5.0 supports this
#   Default CPUFreq governor (ondemand)
#  [] SFI (Simple Firmware Interface) Support || Only Atom Moorestown platform (handheld device)
#  * Cpuidle Driver for Intel Processors
#  [] Suspend to RAM and standby || we will need standby support!
#  [] Opportunistic sleep || no i really manage sleep manually!
#  [] User space wakeup sources interface || no i really manage sleep manually!
#  [] Enable workqyeye power-efficient mode by default || i really tolerate power efficiency on desktop!
#  Memory power savings
#   [] Intel chipset idle memory power saving driver || I/O Acceleration technology is only available on intel high-end server motherboards
# Device Drivers
#  * Generic Thermal sysfs driver
#   [] ACPI INT340X thermal drivers || available on newer laptops and tablets
>>> PIIX4 south bridge contains DMA channels and thus IOMMU support is needed
# Device Drivers
#  * IOMMU Hardware Support
#   * Support for Intel IOMMU using DMA Remapping Devices
#   * Enable Intel DMA Remapping Devices by default
#  * DMA Engine support
#   <> Intel I/OAT DMA support || my CPU isn't xeon
# Processor type and features
#  * DMA memory allocation support
#  * Enable DMI scanning
#  [] Old AMD GART IOMMU support || im intel
#  [] IBM Calgary IOMMU support || can be checked via dmesg on livedvd
#  [] Should Calgary be enabled by default? || can be checked via dmesg on livedvd
>>> We really have Memory Controller
# Device Drivers
#  * Memory Controller drivers
>>> Intel 4770k Support apic/x2apic (Advanced Programmable Interrupt Controller)
# Device Drivers
#  * IOMMU Hardware Support
#   * Support for Interrupt Remapping
# Processor type and features
#  [] Support x2apic || Intel 4770k comes with x2apic support not available in virtualbox
#  * Reroute for broken boot IRQs
>>> allow LKM
# * Enable loadable module support
#  * Forced module loading
#  * Module unloading
#  * Module versioning support
>>> important general driver options
# Device Drivers
#  Generic Driver Options
#   * Select only drivers that don't need compile-time external firmware
#   * Prevent firmware from being built
>>> we need devtmpfs at /dev
# Device Drivers
#  Generic Driver Options
#   * Maintain a devtmpfs filesystem to mount at /dev
>>> block layer support
# * Enable the block layer
#  * Block layer SG support v4
#  * Block layer SG support v4 helper lib  
#  IO Schedulers
#   [] Deadline I/O scheduler || I'm desktop, useful for DBMS's
#   * CFQ I/O scheduler
>>> block devices support
# Device Drivers
#  * Block devices
#   * RAM block device support
#   <> Packet writing on CD/DVD media || for using cd/dvd writers
>>> Filesystem support
# File systems
#  * The Extended 4 (ext4) filesystem
#  [] Use ext4 for ext2/ext3 file systems || no I won't use ext2/ext3
#  * Ext4 POSIX Access Control Lists
#  * Ext4 Security Labels  
#  * Enable POSIX file locking API || seriosly required for booting!
#  [] Dnotify support || well obsolete but may come handy
#  * Inotify support || this feature might be needed
#  [] Filesystem wide access notification || this feature might be needed
#  CD-ROM/DVD Filesystems
#   M ISO 9660 CDROM file system support
#   * Microsoft Joliet CDROM extensions
#   M UDF file system support
#  DOS/FAT/NT Filesystems
#   M MSDOS fs support
#   M VFAT (Windows-95) fs support
#   M NTFS file system support
#   * NTFS write support
#  * Native Language || without this, mounting vfat is impossible
#   M Codepage 437 (United States, Canada) || without this, mounting vfat is impossible
#   M NLS ISO 8859-1 (Latin 1; Western European Languages) || without this, mounting vfat is impossible
#   M NLS UTF-8 || udisks needs it
>>> enable pseudo filesystems
# File systems
#  Pseudo filesystems
#   * /proc file system support
#   * Sysctl support (/proc/sys)
#   [] Enable /proc page monitoring
#   * sysfs file system support
#   * Tmpfs virtual memory file system support (former shm fs)
#   * Tmpfs POSIX Access Control Lists
>>> enable hwpoison to better tolerate memory corruption errors now that we have procfs support
# Processor type and features
#  * HWPoison pages injector
>>> enable kernel .config now that we have procfs support
# General Setup
#  * Enable access to .config through /proc/config.gz
>>> SWAP support
# General Setup
#  * Support for paging of anonymous memory (swap)
>>> input device support
# Device Drivers
#  Input device support
#   * Generic input layer (needed for keyboard, mouse, ...)
#   M Mouse interface
#   * Provide legacy /dev/psaux device
#   * Event interface || required for xorg to work
#   * Keyboards
#    * AT keyboard
#   * Mice
#    <> PS/2 mouse || no I don't use PS/2!
#    <> Synaptics USB device support || no I don't have touchpad!
#   Hardware I/O ports
#    <> Serial port line discipline || i won't use a serial port!
# Power management and ACPI options
#  * ACPI (Advanced Configuration and Power Interface) Support
#   M Button
			>>> support for LED
			# Device Drivers
			#  * LED Support
			#   M LED Class Support
			#   * LED Trigger support
			#    M LED Timer Trigger
			#    M LED Heartbeat Trigger
			>>> Virtualization Support
			# Bus options
			#  [] PCI Stub driver || we plan to have virtualization support
			# Device Drivers
			#  [] Virtualization drivers
			#  Virtio drivers
			#   <> PCI driver for virtio devices
			#   <> Platform bus driver for memory mapped virtio devices 
			# * Networking support
			# * Virtualization
			#  <> Host kernel accelerator for virtio net
			#  M Kernel-based Virtual Machine
			#   M KVM for Intel processors supports
			# * Networking support
			#  Networking options
			#   TCP/IP networking
			#   * IP: advanced router
			#   * IP: policy routing
			#   * IP: equal cost multipath
>>> SCSI support
# Device Drivers
#  SCSI device support 
#   * SCSI device support
#   * legacy /proc/scsi/ support 
#   [] SCSI low-level drivers || well i didn't find anything useful
#   * SCSI disk support  
#   M SCSI CDROM support
#   * Enable vendor-specific extensions (for SCSI CDROM)  
#   M SCSI generic support
#   * Asynchronous SCSI scanning
#   [] SCSI Device Handlers || well i didn't find anything useful
#   SCSI Transports || well i didn't find anything useful
#   [] SCSI low-level drivers || well i didn't find anything useful
>>> SATA controller: Intel Corporation 82801HM/HEM (ICH8M/ICH8M-E) SATA Controller [AHCI mode]  
>>> kernel driver in use: ahci
# Device Drivers
#  M Serial ATA and Parallel ATA drivers (libata)
#   [] ATA SFF support (for legacy IDE and PATA)
#   M AHCI SATA support
#   [] Verbose ATA error reporting
#   * SATA Port Multiplier support
#   * ATA ACPI Support
>>> USB controller: Intel Corporation 7 Series/C210 Series Chipset Family USB xHCI Host Controller
# Device Drivers
#  * USB support
#   M Support for Host-side USB
#   * USB announce new devices
#   * Enable USB persist by default
#   M xHCI HCD (USB 3.0) support
#   M EHCI HCD (USB 2.0) support
#   * Improved Transaction Translator scheduling
#   M OHCI HCD (USB 1.1) support
#   M OHCI support for PCI-bus USB controllers
#   M UHCI HCD (most Intel and VIA) support
#   M USB Mass Storage support
#   M USB Attached SCSI
# HID support
#  M HID bus support
#  M Generic HID driver
#  * /dev/hidraw raw HID device support
#  Special HID driver
#   >>> deselect all
#   M Keyboard HID devices
#  USB HID support
#   M USB HID transport layer
#   * PID device support
#   * /dev/hiddev raw HID device support
>>> Enable networking support
# Networking support
#  [] Wireless || I'm not using wireless!
#  Networking options
#   * Packet socket || ipv4 won't work without it
#    * Packets: sockets monitoring interface
#   * Unix domain sockets || they are very very important
#   * TCP/IP networking || very obvious that we need it
#   * IP: multicasting
#   [] IP: kernel level autoconfiguration
#    [] IP: DHCP support
#   <> The IPv6 protocol || I won't need IPv6
#   <> IP: IPSec transport mode || I won't need ipsec
#   <> IP: IPSec tunnel mode || I won't need ipsec
#   <> IP: IPSec BEET mode || I won't need ipsec
#   * Large Receive Offload (ipv4/tcp)
#   * NETLINK: mmaped IO || netlink is important
#   * INET: socket monitoring interface
#    * UDP: socket monitoring interface
# General setup
#  * POSIX Message Queues
#  CPU/Task timer and stats accounting
#   * Export task/process statistics through netlink
#   * Enable per-task delay accounting
#  * Namespaces support
#   * Network namespace
>>> Network core driver support, like bridging etc.
# Device Drivers
#  * Network device support
#   * Network core driver support
#    M Bonding driver support
#    M MAC-VLAN support
#    M Virtual eXtensible Local Area Network (VXLAN)
#    M Generic Network Virtualization Encapsulation
#    [] Ethernet team driver support
#     [] Round-robin mode support
#     [] Load-balance mode support
>>> Ethernet controller: Intel Corporation 82540EM Gigabit Ethernet Controller
>>> kernel driver in use: e1000
# Device Drivers
#  * Network device support
#   [] Network core driver support
#   <> USB Network Adapters
#   [] Wireless LAN
#   * Ethernet driver support
#    >> disable all
#    * Intel devices
#    [] Intel (82586/82593/82596) devices
#    M Intel (R) PRO/1000 Gigabit Ethernet support
#   M PHY Device support and infrastructure
>>> enable sound
# Device Drivers
#  * Sound card support
#   * Advanced Linux Sound Architecture
#    [] USB sound devices
#    [] Generic sound devices
#     [] PC-Speaker support (READ HELP!)
#    [] Verbose procfs contents
#    * Support old ALSA API
#    * PCI Sound Devices || mandatory for enabling HD-Audio
#    HD-Audio
#     M HD Audio PCI
#     (2048) Pre-allocated buffer size for HD-audio driver
#     * Support jack plugging notification via input layer
#    M Sequencer support
#    M OSS Mixer API
#    M OSS PCM (digital audio) API
#    * OSS PCM (digital audio) API - Include plugin system
#    * OSS Sequencer API
#    * Sound Proc FS Support
#    * PCM timer interface
>>> configure audio codec
>>> codec should be derived from "lsmod | grep codec"
>>> snd modules could be derived from "lsmod | grep snd"
>>> enabled codecs are 
 snd_hda_codec_idt: 1
 snd_hda_codec_generic: 1: snd_hda_codec_idt
 snd_hda_codec: 4: snd_hda_codec_idt,snd_hda_codec_generic,snd_hda_intel,snd_hda_controller
 snd_hwdep: 3: snd_hda_codec,snd_hda_intel,snd_hda_controller
 snd_pcm: 3: snd_hda_codec,snd_hda_intel,snd_hda_controller
 snd: 17: snd_hwdep,snd_timer,snd_hda_codec_idt,snd_pcm,snd_hda_codec_generic,snd_hda_codec,snd_hda_intel
 >>> snd_hwdep
 # Device Drivers
 #  Sound card support
 #   * Advanced Linux Sound Architecture
 #    HD-Audio
 #     * Build hwdep interface for HD-audio driver
 >>> snd_codec_generic
 # Device Drivers
 #  Sound card support
 #   * Advanced Linux Sound Architecture
 #    HD-Audio
 #     M Enable generic HD-audio codec parser
 >>> snd_hda_codec_idt
 # Device Drivers
 #  Sound card support
 #   * Advanced Linux Sound Architecture
 #    HD-Audio
 #     M Enable IDT/Sigmatel HD-audio codec support
 >>> snd_intel8x0 (for PCM, ICH AC97)
 # Device Drivers
 #  Sound card support
 #   * Advanced Linux Sound Architecture
 #    PCI sound devices
 #     M Intel/SiS/nVidia/AMD/ALi AC97 Controller
>>> Audio device: Intel Corporation 82801FB/FBM/FR/FW/FRW (ICH6 Family) High Definition Audio Controller
>>> kernel driver in use: snd_hda_intel
# --- nothing do to, already enabled by now ---
>>> disable MPS Table, since our CPU is new
# Processor type and features
#  [] Enable MPS table
>>> enable hibernation if necessary
# Power management and ACPI options
#  * Hibernation (aka 'suspend to disk')
>>> enable tty - very important!
# Device Drivers
#  Character devices
#   * Enable TTY
#   * Virtual terminal
#   * Enable character translations in console
#   * Support for console on virtual terminal
#   * Unix98 PTY support
#   * Legacy (BSD) PTY support
>>> enable hardware monitoring
# Device Drivers
#  * Hardware Monitoring support
#   M ACPI 4.0 power meter
#   M Intel Core/Core2/Atom temperature sensor
#   M Intel 5500/5520/X58 temperature sensor
#   M ASUS ATK0110
>>> enable adaptive voltage scaling class support
# Device Drivers
#  * Adaptive Voltage Scaling class support
>>> enable thermal sysfs driver
# Device Drivers
#  * Generic Thermal sysfs driver
#   * Expose thermal sensors as hwmon device
#   M Intel PowerClamp idle injection driver
#   M X86 package temperature thermal driver
#   M ACPI INT340X thermal drivers
#   M Intel PCH Thermal Reporting Driver
>>> enable generic dynamic voltage and frequency scaling (DVFS) support
# Device Drivers
#  * Generic Dynamic Voltage and Frequency Scaling (DVFS) support
#   * DEVFREQ-Event device Support
#   M Simple Ondemand
#   M Userspace
>>> configure some security options
# Security options
#  * Enable access key retention support
#  * Enable register of persistent per-UID keyrings
#  * Enable Intel(R) Trusted Execution Technology (Intel(R) TXT)
>>> enable uevent helper
# Device Drivers
#  Generic Driver Options
#   * Support for event helper
>>> enable EFI support
# Processor type and features
#  * EFI runtime service support 
#  * EFI stub support
# Firmware Drivers
#  EFI (Extensible Firmware Interface) Support
#   M EFI Variable Support via sysfs
# * Enable the block layer
#  Partition types
#   * Advanced partition selection
#   * PC BIOS (MSDOS partition tables) support || we won't be able to mount anything other than gpt, bad for usb devices!
#   * EFI GUID Partition support
# File systems
#  Pseudo filesystems
#   M EFI Variable filesystem
>>> framebuffer support otherwise nothing is visible on boot
# Bus Options
#  [] Mark VGA/VBE/EFI FB as generic system framebuffer
# Device Drivers
#  Graphics support
#   * VGA Arbitration
#   (2) Maximum number of GPUs
#   Frame buffer Devices
#    * Support for frame buffer devices
#    * EFI-based Framebuffer Support 
#    [] VESA VGA graphics support
#    [] Simple framebuffer support
#  Console display driver support
#   * VGA text console
#   * Enable Scrollback Buffer in System RAM
#   * Framebuffer Console support
#   * Map the console to the primary display device
#   [] Support for the Framebuffer Console Decorations
#  * Backlight & LCD device support
#   M Lowlevel LCD controls
#   M Lowlevel Backlight controls
#   M Generic (aka Sharp Corgi) Backlight Driver
>>> enable systemd support
# General setup
#  * Control Group support
#  * open by fhandle syscalls
#  [] Enable deprecated sysfs features to support old userspace tools
#  * Configure standard kernel features (expert users)
#   * Enable eventpoll support
#   * Enable signalfd() system call
#   * Enable timerfd() system call
#   * Enable eventfd() system call || use-space notifications wont work!
# * Networking support
# Device Drivers
#  Generic Driver Options
#   * Maintain a devtmpfs filesystem to mount at /dev
# File systems
#  * Inotify support for userspace
#  * Filesystem wide access notification
#  Pseudo filesystems
#   * /proc file system support
#   * sysfs file system support
# General setup
#  * Namespaces support
#   * Network namespace
# * Enable the block layer
#  * Block layer SG support v4
# Processor type and features
#  * Enable seccomp to safely compute untrusted bytecode
# Networking support
#  Networking options
#   * The IPv6 protocol
#    >> disable all
# Device Drivers
#  Generic Driver Options
#   () path to uevent helper
#   [] Fallback user-helper invocation for firmware loading
#  Character devices
#   * Enable TTY
#   * Unix98 PTY Support
#   * Support multiple instances of devpts
# Firmware Drivers
#  * Export DMI identification via sysfs to userspace
# File systems
#  * Kernel automounter version 4 support (also supports v3)
#  Pseudo filesystems
#   * Tmpfs virtual memory file system support (former shm fs)
#   * Tmpfs POSIX Access Control Lists
#   * Tmpfs extended attributes
>>> enable udev support
# General setup
#  * Configure standard kernel features (expert users)
#   * Enable signalfd() system call
#  [] Enable deprecated sysfs features to support old userspace tools
# Enable the block layer
#  * Block layer SG support v4
# Networking support
#  Networking options
#   * Unix domain sockets
# Device Drivers
#  Generic Driver Options
#   ()  path to uevent helper
#   * Maintain a devtmpfs filesystem to mount at /dev
# <> ATA/ATAPI/MFM/RLL support (DEPRECATED)
# File systems
#  * Inotify support for userspace
#  Pseudo filesystems
#   * /proc file system support
#   * sysfs file system support
>>> enable lvm support
# Device Drivers
#  * Multiple devices driver support (RAID and LVM)
#   * Device mapper support
#   * Crypt target support
#   * Snapshot target
#   * Mirror target
#   * Multipath target
#   * I/O Path Selector based on the number of in-flight I/Os
#   * I/O Path Selector based on the service time
#   * DM uevents
>>> enable dm-crypt support
# * Enable loadable module support
# Device Drivers
#  * Multiple devices driver support (RAID and LVM)
#   * Device mapper support
#   * Crypt target support
# Cryptographic API
#  >>> disable all
#  * Disable run-time self tests
#  * SHA224 and SHA256 digest algorithm
#  * XTS support
#  * AES cipher algorithms
#  * AES cipher algorithms (x86_64)
# General setup
#  * Initial RAM filesystem and RAM disk (initramfs/initrd) support
>>> add AGP graphics support to kernel
# Device Drivers
#  Graphics Support
#   M /dev/agpgart (AGP Support)
#   Direct Rendering Manager
#    M Direct Rendering Manager (XFree86 4.1.0 and higher DRI support)
>>> enable FUSE for ntfs3g
# File systems
#  M FUSE (Filesystem in Userspace) support
>>> enable support for xfce power manager
# Kernel Hacking
#  * Collect kernel timer statistics
>>> disable extra debug
# Kernel Hacking
#  [] Debug preemtible kernel
>>> enable support for razor kraken USB audio controller
# Device Drivers
#  * Sound card support
#   * Advanced Linux Sound Architecture
#    * USB sound devices || snd_usb
#     M USB Audio/MIDI driver || snd_usb_audio
#  * USB support
#   M USB Gadget Support
#    M Audio Gadget
#    M MIDI Gadget
>>> enable wireless support
# Device Drivers
#  * LED Support
#   * LED Class Support || required for LED triggering on WLAN devices
# * Networking support
#  * Wireless
#   * cfg80211 - wireless configuration API
#   [] nl80211 testmode command
#   [] enable developer warnings
#   [] cfg80211 regulatory debugging
#   [] cfg80211 certification onus
#   * enable powersave by default
#   [] cfg80211 DebugFS entries
#   [] use statically compiled regulatory rules database
#   [] cfg80211 wireless extensions compatibility
#   * Generic IEEE 802.11 Networking Stack (mac80211)
#   [] PID controller based rate control algorithm
#   * Minstrel
#   * Minstrel 802.11n support
#   Default rate control algorithm (Minstrel)
#   [] Enable mac80211 mesh networking (pre-802.11s) support
#   * Enable LED triggers
#   [] Export mac80211 internals in DebugFS
#   [] Trace all mac80211 debug messages
#   [] Select mac80211 debugging features   
>>> disable SLIP, we dont use old modem connections
# Device Drivers
#  * Network Device support
#   [] SLIP (serial line) support
>>> D-Link Corp. DWA-160 802.11abgn Xtreme N Dual Band Adapter(rev.B2)
    which is actually Ralink RT5572
	firmware is rt2870.bin
# Device Drivers
#  * Network Device support
#   * Wireless LAN
#    M Ralink driver support
#     M Ralink rt27xx/rt28xx/rt30xx (USB support)
#      [] rt2800usb - Include support for rt33xx devices
#      [] rt2800usb - Include support for rt35xx devices
#      [] rt2800usb - Include support for rt3573 devices
#      [] rt2800usb - Include support for rt53xx devices
#      * rt2800usb - Include support for rt55xx devices
#      * rt2800usb - Include support for unknown (USB) devices
>>> Webcam, Pixart, Imaging, Inc
# Device Drivers
#  M Multimedia Support
#   * Cameras/video grabbers support
#   * Autoselect ancillary drivers (tuners, sensors, i2c, frontends)
#   * Media USB Adapters
#    M GSPCA based webcams
#     M Pixart PAC7311 USB Camera Driver
#     M Pixart PAC7302 USB Camera Driver
#  * USB support
#   M USB Gadget Support
#    M USB Webcam Gadget |||| kernel compile error(?)
>>> CIFS, support for mounting shares via fstab using
>>> mount -t cifs [-o username=xxx,password=xxx] //server/share /mnt/point
# File systems
#  * Network File Systems
#   M CIFS support (advanced network filesystem, SMBFS successor)
#    [] Enable CIFS debugging routines
#    * SMB2 and SMB3 network file system support
>>> USB printer support
# Device Drivers
#  * USB support
#   [] USB Printer support || libusb handles so we have to disable this
#   M USB Gadget Support
#    [] Printer Gadget || libusb handles them so we have to disable this
>>> Enable IA32 Emulation to support crosslibs
>>> Important for compiling glibc later on
# Executable file formats / Emulations
#  * IA32 Emulation
>>> synaptics support
# Device Drivers
#  Input device support
#   * Mice
#    * Synaptics USB device support
>>> better EVDEV support
# Device Drivers
#  Input device support
#   * Mouse interface
#   * Event interface
#   * Keyboards
#    * AT Keyboard
#   * Mice
#    * PS/2 mouse
#      >> disable all extensions
#  * USB support
#   M EHCI HCD (USB 2.0) support
#     * Improved Transaction Translator scheduling
>>> htop support
# General Setup
#  CPU/Task time and stats accounting
#   * Export task/process statistics through netlink
#    * Enable extended accounting over taskstats
#    * Enable per-task storage I/O accounting
>>> enable user namespace support to enable sandboxing
>>> required for chromium to work properly
# General Setup
#  * Namespaces support
#   * User namespace
>>> systemtap support
# General Setup
#  * Kprobes
#  * Kernel->user space relay support (formerly relayfs)
# Kernel hacking
#  Compile-time checks and compiler options
#   * Debug Filesystem
>>> enable memory barriers (important)
# General Setup
#  * Enable membarrier() system call
>>> write-protect kernel data (important)
# Kernel hacking
#  * Write protect kernel read-only data structures
#   [] Testcase for the DEBUG_RODATA feature
#   * Warn on W+X mappings at boot
>>> sys-process/audit support
# General Setup
#  * Auditing support
>>> PPP (for momemmanager support)
# Device Drivers
#  * Network device support
#   M PPP (point-to-point protocol) support
#    M PPP support for async serial ports
#    M PPP support for sync tty ports
#    M PPP Deflate compression
#    M PPP BSD-Compress compression
#    M PPP MPPE compression (encryption)
#    M PPP over Ethernet
>>> virtualization support
# General Setup
#  * Control Group support
#   * Memory Resource Controller for Control Groups
#    * Memory Resource Controller Swap Extension
#    * Memroy Resource Controller Kernel Memory accounting
# Device Drivers
#  * Network device support
#   * Network code driver support
#    M MAC-VLAN support
#     M MAC-VLAN based tap driver   
#    M Universal TUN/TAP device driver support
# * Networking Support
#  Networking Options
#   M 802.1d Ethernet Bridging
#    * IGMP/MDL snooping
>>> docker support
# General Setup
#  * POSIX Message Queues
#  * Control Group Support
#   * Freezer cgroup subsystem
#   * Device controller for cgroups
#   * Cpuset support
#    * Include legacy /proc/<pid> cpuset file
#   * Simple CPU accounting cgroup subsystem
#   * Memory Resource Controller for Control Groups
#    * Memory Resource Controller Swap Extension
#     * Memory Resource Controller Swap Extension enabled by default
#    * Memory Resource Controller Kernel Memory accounting
#   * Enable perf_event per-cpu per-container group (cgroup) monitoring
#   * Group CPU scheduler
#    * Group scheduling for SCHED_OTHER
#     * CPU bandwidth provisioning for FAIR_GROUP_SCHED
#    * Group scheduling for SCHED_RR/FIFO
#   * Block IO controller
#  * Namespaces support
#   * UTS namespace
#   * IPC namespace
#   * PID namespace
#   * Network namespace
# * Networking support
#  * Networking options
#   * 802.1d Ethernet Bridging
#   * Network packet filtering framework (Netfilter)
#    * Advanced netfilter configuration
#     * Bridged IP/ARP packets filtering
#       Core Netfilter Configuration
#        * Netfilter connection tracking support
#         [] Supply CT list _in procfs
#        * Netfilter Xtables support (required for ip_tables)
#         *** Xtables matches ***
#          * "addrtype" address type match support
#          * "conntrack" connection tracking match support
#        [] Netfilter ingress support
#   * IP: Netfilter Configuration
#    * IPv4 connection tracking support (required for NAT)
#     * proc/sysctl compatibility with old connection tracking
#    * IP tables support (required for filtering/masq/NAT)
#     * Packet filtering
#     * IPv4 NAT
#      * MASQUERADE target support
#     * iptables NAT support
#      * MASQUERADE target support
#      * NETMAP target support
#      * REDIRECT target support
#   * 802.1d Ethernet Bridging
#   * QoS and/or fair queueing
#    * Control Group Classifier
#   * Network priority cgroup
#   * Network classid cgroup
# Device Drivers
#  * Multiple devices driver support (RAID and LVM)
#   * Device mapper support
#   * Thin provisioning target
#   * Snapshot target
#  * Network device support
#   * Network core driver support
#   * Virtual ethernet pair device
# Character devices
#  * Enable TTY
#   * Unix98 PTY support
#    * Support multiple instances of devpts
# File systems
#  * Overlay filesystem support
#  * Pseudo filesystems
#   * HugeTLB file system support
# Security Options
#  * Enable access key retention support
#   * Enable register of persistent per-UID keyrings
#   M ENCRYPTED KEYS
#   * Diffie-Hellman operations on retained keys
# General Setup
#  * Control Group Support
#   * HugeTLB Resource Controller for Control Groups
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# install firmwares, specially using wifi
emerge --ask sys-kernel/linux-firmware
# create crypttab file
nano -w /etc/crypttab
> enc2      /dev/sdb1        none         luks,timeout=60s,x-systemd.device-timeout=60s
# assign a root password
passwd
# install cron daemon
emerge --ask sys-process/dcron
systemctl enable dcron
crontab /etc/crontab
# install file-indexing
emerge --ask sys-apps/mlocate
# enable serial consoles, uncomment them
nano -w /etc/inittab
# install filesystem tools
emerge --ask sys-fs/dosfstools
emerge --ask sys-fs/ntfs3g
# change keymaps if necessary
nano -w /etc/conf.d/keymaps
# change hardware clock if necesary
# DUAL BOOT: clock="local" if dual boot with windows
nano -w /etc/conf.d/hwclock
# enable pcre in grep, could be useful!
>> sys-apps/grep+="pcre"
>> dev-libs/libpcre+="jit readline recursion-limit"
emerge --ask --deep --update --newuse @world
emerge --depclean
# CHOICE
 # wifi is needed
 # install wpa_supplicant
 >> dev-lang/swig+="pcre"
 >> net-wireless/wpa_supplicant+="-hs2-0 dbus readline"
 emerge --ask wpa_supplicant
 nano -w /etc/wpa_supplicant/wpa_supplicant.conf
 > ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel
 > update_config=1
 systemctl enable wpa_supplicant@.service
 systemctl enable wpa_supplicant-nl80211@.service
 systemctl enable wpa_supplicant-wired@.service
 systemctl enable wpa_supplicant.service
# install networkmanager
>> net-libs/glib-networking+="ssl"
>> net-libs/libsoup+="ssl"
>> dev-db/sqlite+="readline"
>> net-misc/curl+="ssl"
>> net-misc/networkmanager+="-ppp -modemmanager resolvconf ncurses systemd wext wifi"
  >> if bluetooth is needed, USE+="bluetooth"
  >> if connection sharing is needed, USE+="connection-sharing"
emerge --ask networkmanager
systemctl enable NetworkManager
systemctl disable systemd-networkd.service
systemctl disable systemd-resolved.service
rm -f /etc/resolv.conf
ln -snf /run/resolvconf/interfaces/NetworkManager /etc/resov.conf
# install grub
# CHOICE
 # non-EFI
  # install grub
  emerge sys-boot/grub
  # configure grub
  # root=UUID=<uuid>
  nano -w /etc/default/grub
  > GRUB_CMDLINE_LINUX="dolvm root=/dev/vg1/lv1 init=/usr/lib/systemd/systemd plymouth.enable=0"
  > GRUB_CMDLINE_LINUX_DEFAULT="console=tty1"
  grub2-install /dev/sda
  grub2-mkconfig -o /boot/grub/grub.cfg
 # EFI
  >> sys-boot/grub+="device-mapper grub_platforms_efi-64"
  # install grub
  emerge --ask sys-boot/grub
  emerge --ask sys-boot/os-prober
  etc-update
  # configure grub
  nano -w /etc/default/grub
  > GRUB_CMDLINE_LINUX="crypt_root=/dev/sda3 dolvm root=/dev/vg1/lv2 init=/usr/lib/systemd/systemd plymouth.enable=0"
  > GRUB_CMDLINE_LINUX_DEFAULT="console=tty1"
  mkdir -p /boot/EFI
  grub-install --efi-directory=/boot
  grub-mkconfig -o /boot/grub/grub.cfg
  mkdir -p /boot/EFI/BOOT
  cp /boot/EFI/gentoo/grubx64.efi /boot/EFI/BOOT/bootx64.efi
  # create startup.nsh
  nano -w /boot/startup.nsh
  > FS0:
  > \EFI\gentoo\grubx64.efi
################################
### REBOOT INTO FRESH SYSTEM ###  
################################
# booted? say hooray!!!!

# disable kernel log flooding
 dmesg -n 1
 # view sysctl configured by dmesg
 cat /proc/sys/kernel/printk
 # add printed number to /etc/sysctl
 nano -w /etc/sysctl.conf
 > kernel.printk = 1 4 1 7
# set hostname
hostnamectl set-hostname arcana-gentoo-vm
nmtui
> Set system host name
reboot

# install screen, an important tools for tty
emerge --ask app-misc/screen
# install lsof
emerge --ask sys-process/lsof
# install htop
>> sys-process/htop+="unicode"
emerge --ask sys-process/htop
#### CONFIG_TASK_XACCT
#### CONFIG_TASK_IO_ACCOUNTING
#### sys-process/lsof
# install llvm & clang, many different packages need it!
>> sys-devel/llvm+="clang -video_cards_radeon"
emerge --ask sys-devel/llvm
# install vpdau
>> x11-libs/libvdpau+="dri"
emerge --ask x11-libs/libvdpau
# install libdrm - direct rendering manager
>> x11-libs/libdrm+="libkms -video_cards_amdgpu -video_cards_intel -video_cards_nouveau -video_cards_radeon -video_cards_vmware"
emerge --ask x11-libs/libdrm
# install libva - VAAPI
>> x11-libs/libva+="X drm vdpau -video_cards_dummy -video_cards_intel -video_cards_nouveau"
emerge --ask x11-libs/libva
# install mesa
>> media-libs/mesa+="vaapi vdpau -opencl xvmc openmax osmesa xa classic dri3 egl gallium gbm llvm -video_cards_intel -video_cards_nouveau -video_cards_radeon -video_cards_vmware"
emerge --ask media-libs/mesa
# install libtxc
emerge --ask media-libs/libtxc_dxtn
# install cairo
>> x11-libs/cairo+="opengl"
emerge --ask x11-libs/cairo
>> x11-libs/libva+="opengl"
>> x11-libs/libva-vdpau-driver+="opengl"
emerge --ask --deep --update --newuse @world
emerge --depclean
# install xorg-drivers
# list acquirable from xorg-drivers meta package
INPUT_DEVICES+="evdev synaptics virtualbox keyboard mouse"
VIDEO_CARDS+="virtualbox"
CFLAGS+="-Wno-error=maybe-uninitialized"
FFLAGS+="-Wno-error=maybe-uninitialized"
>> x11-apps/xinit+="systemd"
>> x11-base/xorg-server+="systemd"
>> x11-drivers/xf86-video-virtualbox+="dri"
##>>>>>> ?????????????????????
##>> replace new in /usr/src/linux/include/linux/string.h
##>>>>>> ?????????????????????
emerge xorg-drivers
CFLAGS-="-Wno-error=maybe-uninitialized"
FFLAGS-="-Wno-error=maybe-uninitialized"
# install virtualbox guest additions
>> app-emulation/virtualbox-guest-additions+="X"
emerge --ask app-emulation/virtualbox-guest-additions
eselect opengl set xorg-x11
gpasswd -a root vboxguest
gpasswd -a root vboxsf
systemctl enable virtualbox-guest-additions.service
systemctl restart virtualbox-guest-additions.service
## mount -t vboxsf <shared_folder_name> <mount_point>

# install plymouth 
 >> sys-kernel/genkernel-next+="plymouth"
 >> gnome-base/gdm+="plymouth"
 >> x11-libs/gdk-pixbuf+="X"
 >> x11-libs/cairo+="X"
 >> x11-libs/gtk+ += "X"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 # list available themes
 plymouth-set-default-theme --list
 # install plymouth in genkernel
 nano -w /etc/genkernel.conf
 > SPLASH="no"
 > PLYMOUTH="yes"
 > PLYMOUTH_THEME="solar"
 # regenerate initramfs
 genkernel --install --plymouth --plymouth-theme=solar --udev --lvm --luks initramfs
 # configure grub
 nano -w /etc/default/grub
 > GRUB_CMDLINE_LINUX-="plymouth.enable=0"
 > GRUB_CMDLINE_LINUX_DEFAULT="vga792 quiet splash"
 ##vga=791 splash=silent,theme:default console=tty1 quiet
 > GRUB_GFXMODE=1024x768x24
 > GRUB_GFXPAYLOAD_LINUX=keep
 grub-mkconfig -o /boot/grub/grub.cfg
 reboot
 
# install x11 server
# IMPORTANT: READ THE NEWS ITEMS!
>> x11-base/xorg-server+="-minimal glamor"
emerge --ask x11-base/xorg-server
# CHOICE
 # VirtualBox
  nano -w /etc/X11/xorg.conf
  > # Section "Device"
  > #  Identifier "Virtual Box"
  > #  Driver     "vboxvideo"
  > # EndSection
  > Section "dri"
  >  Mode 0666
  > EndSection
  > Section "Monitor"
  >  Identifier "Virtual Box Monitor"
  >  Option     "PreferredMode"      "1366x768"
  > EndSection
  > Section "Extensions"
  >  Option "Composite" "Enable"
  > EndSection
# install twm
emerge --ask x11-wm/twm
# install xterm
emerge --ask x11-terms/xterm
# install xclock
emerge --ask x11-apps/xclock
# copy evdev configuration
cp /usr/share/X11/xorg.conf.d/10-evdev.conf /etc/X11/xorg.conf.d/
# enable x11 for dbus
>> sys-apps/dbus += "user-session X"
emerge --ask --deep --update --newuse @world
emerge --depclean
# test installed xorg server
startx

# install lightdm
>> sys-apps/accountsservice+="systemd"
emerge --ask x11-misc/lightdm
mkdir -p /var/lib/lightdm-data
# create our own user!
useradd -m -G users,audio,cdrom,floppy,portage,usb,video,wheel -s /bin/bash arcana
gpasswd -a arcana vboxguest
gpasswd -a arcana vboxsf
passwd arcana
systemctl enable accounts-daemon.service
systemctl enable lightdm.service
>> "media-fonts/font-misc-misc"+="X"
>> "media-fonts/liberation-fonts"+="X"
>> "media-libs/freetype"+="X"
>> "x11-libs/pango"+="X"
>> "app-accessibility/at-spi2-core"+="X"
>> "dev-scheme/guile"+="readline"
emerge --ask --deep --update --newuse @world
emerge --depclean

# install gvfs
 # install udisks
 >> sys-fs/udisks+="cryptsetup systemd acl -gptfdisk"
 >> sys-block/parted+="device-mapper readline"
 emerge --ask sys-fs/udisks
 # install gvfs itself
 >> gnome-base/gvfs+="archive cdda fuse mtp systemd udisks"
 emerge --ask gnome-base/gvfs
 systemctl enable udisks2.service
 systemctl restart udisks2.service

# install xfce
 >> media-libs/netpbm+="X jpeg png tiff"
 >> dev-perl/libwww-perl+="ssl"
 >> x11-libs/libwnck+="startup-notification"
 >> xfce-base/libxfce4ui+="startup-notification"
 >> x11-misc/xscreensaver+="opengl"
 >> xfce-base/xfce4-session+="policykit systemd"
 emerge --ask xfce-base/xfce4-session
 emerge --ask xfce-base/xfce4-panel
 nano -w /etc/env.d/99xdg
   >> XDG_DATA_HOME=/usr/share
 env-update
 source /etc/profile
 nano -w /root/.bashrc
   >> source /etc/profile
 >> xfce-base/xfwm4+="dri startup-notification"
 emerge --ask xfce-base/xfwm4
 # install xfce4-settings
 >> xfce-base/xfce4-settings+="libinput"
 emerge --ask xfce-base/xfce4-settings
 emerge --ask xfce-base/xfconf
 # enable lightdm
 systemctl enable lightdm
 # login into xfce
 reboot
 # install xfce-terminal
 emerge x11-terms/xfce4-terminal
 # install thunar
 >> xfce-base/thunar+="exif libnotify pcre udisks"
 >> x11-libs/libcanberra+="udev"
 emerge --ask xfce-base/thunar
 # install xfdesktop
 >> xfce-base/xfdesktop+="libnotify"
 emerge --ask xfce-base/xfdesktop
 reboot
 # install appfinder
 emerge --ask xfce-base/xfce4-appfinder
 reboot
 
# set number of workspaces
>> Settings -> WorkSpaces -> Number Of Workspaces = 4
# configure window manager
>> Settings -> Window Manager -> Focus -> Automatically raise windows when they receive focus
# configure window manager tweaks
>> Settings -> Window Manager Tweaks -> Compositor -> set all to 75%
                                                   -> Show shadows under popup windows
                                     -> Workspaces -> [] Use the mouse wheel on the desktop to switch workspaces
                                     -> Focus -> Activate Focus Stealing Prevention
# configure keyboard
>> Settings -> Keyboard -> Layout -> [] Use system defaults
                                  -> Keyboard Model -> Generic 104 Key PC
								  -> Keyboard Layout -> Persian -> Persian (With Persian Keypad)
								  -> Change Layout Options -> Alt + Shift


# emerge some themes
emerge --ask x11-themes/greybird
emerge --ask x11-themes/clearlooks-phenix 
emerge --ask x11-themes/gnome-themes-standard 
emerge --ask x11-themes/gtk-engines-aurora 
emerge --ask x11-themes/light-themes 
emerge --ask x11-themes/murrine-themes
emerge --ask x11-themes/nimbus 
>> dev-libs/libpcre+="pcre16"
>> app-arch/libarchive+="bzip2"
>> dev-qt/qtcore+="icu systemd"
emerge --ask --deep --update --newuse @world
emerge --depclean
emerge --ask x11-themes/oxygen-molecule
emerge --ask x11-themes/redhat-artwork
emerge --ask x11-themes/shiki-colors
emerge --ask x11-themes/tactile3 
emerge --ask x11-themes/zukini
emerge --ask x11-themes/xfwm4-themes 
# set theme
>> Settings -> Appearance -> Style -> Greybird
                          -> Icons -> Oxygen
>> Settings -> Window Manager -> Greybird
# enable icu
>> dev-db/sqlite+="icu"
>> dev-libs/boost+="icu"
>> dev-libs/libxml2+="icu"
>> media-libs/harfbuzz+="icu"
emerge --ask --deep --update --newuse @world
emerge --ask --deep --update --newuse boost
emerge --depclean
# install gksu, a "run as root" GUI module
>> gnome-base/gvfs+="gnome-keyring"
>> sys-auth/pambase+="gnome-keyring"
>> gnome-base/gnome-keyring+="pam"
>> app-crypt/gcr+="gtk"
>> app-crypt/pinentry+="gtk caps clipboard gnome-keyring"
>> app-crypt/gnupg+="readline"
emerge --ask --deep --update --newuse @world
emerge --depclean
# install taskmanager
>> xfce-extra/xfce4-taskmanager+="gksu"
>> gnome-base/gconf+="policykit"
>> app-admin/sudo+="pam"
emerge --ask xfce-extra/xfce4-taskmanager 
	# install SSH askpass
	emerge ssh-askpass-fullscreen
	nano -w /etc/bash/bashrc
	> alias ssh="setsid -w ssh"
# configure task manager
>> Task Manager -> Settings -> Show memory usage in bytes
# install mount plugin
emerge --ask xfce-extra/xfce4-mount-plugin
# install calendar
emerge --ask app-office/orage 
# install text editor
emerge --ask app-editors/mousepad 
# install archive support
emerge --ask xfce-extra/thunar-archive-plugin
# install volume manager
>> xfce-extra/thunar-volman+="libnotify"
emerge --ask xfce-extra/thunar-volman
# enable auto-mount
>> Settings -> Removable Drives and Media -> Mount removeable drives when hot-plugged
                                          -> Mount removeable drives when inserted
# install pulseaudio, alsa is required for Intel HD to work
>> media-sound/pulseaudio+="X alsa alsa-plugin dbus equalizer gdbm glib systemd"
>> media-plugins/alsa-plugins+="pulseaudio"
emerge --ask media-sound/pulseaudio
>> media-libs/libcanberra+="pulseaudio alsa"
>> media-libs/libsndfile+="alsa"
emerge --ask --deep --update --newuse @world
emerge --depclean
# install ffmpeg
>> media-video/ffmpeg+="X aac alsa amr bluray cdio fribidi gsm libass v4l mp3 openal opengl openssl pulseaudio sdl speex truetype twolame vaapi vdpau vorbis wavpack webp x264 x265 xvid zlib"
>> media-libs/libwebp+="gif tiff"
>> media-libs/libsdl+="X alsa opengl pulseaudio"
>> media-libs/openal+="alsa pulseaudio"
emerge --ask media-video/ffmpeg
>> media-plugins/alsa-plugins+="ffmpeg speex"
>> media-libs/libcanberra+="udev"
>> app-misc/pax-utils+="caps"
>> net-misc/iputils+="caps filecaps"
>> sys-apps/util-linux+="caps"
>> app-arch/libarchive+="acl xattr"
>> app-arch/tar+="acl xattr"
>> net-misc/rsync+="acl"
>> sys-apps/shadow+="acl"
>> sys-fs/ntfs3g+="acl xattr"
>> app-arch/unzip+="unicode"
>> sys-libs/slang+="readline"
>> media-libs/libwebp+="opengl"
>> app-editors/mousepad+="dbus"
>> app-office/orage+="dbus libnotify"
>> www-client/w3m+="X"
>> media-libs/giflib+="X"
>> net-misc/openssh+="X"
>> virtual/ffmpeg+="encode X gsm mp3 sdl speex truetype vaapi vdpau x264"
emerge --ask --deep --update --newuse @world
emerge --ask --deep --update --changed-use @world
emerge --depclean
    # CHOICE: If CUDA
	>> media-libs/opencv+="cuda"
# add user to sudoers
nano -w /etc/sudoers
> arcana ALL=(ALL) ALL
# re-install kernel
genkernel --install --udev --lvm --luks --plymouth --plymouth-theme=solar --makeopts=-j5 --menuconfig all
# re-install grub
grub2-install --efi-directory=/boot
grub2-mkconfig -o /boot/grub/grub.cfg
cp /boot/EFI/gentoo/grubx64.efi /boot/EFI/BOOT/bootx64.efi
# reboot system
reboot
# install gstreamer
>> media-libs/gstreamer+="caps nls orc"
emerge --ask media-libs/gstreamer
>> media-plugins/gst-plugins-meta+="X a52 aac alsa cdda dts dv dvd ffmpeg flac lame libass libvisual mms mp3 mpeg ogg pulseaudio taglib v4l vaapi vcd vorbis wavpack x264"
>> media-libs/libmpeg2+="X sdl"
>> media-video/mjpegtools+="dv quicktime sdl png"
>> media-libs/gst-plugins-good+="nls orc"
>> media-libs/gst-plugins-ugly+="nls orc"
>> media-libs/gst-plugins-bad+="nls orc X opengl vcd"
>> media-libs/gst-plugins-base+="X alsa nls ogg orc pango vorbis"
>> media-plugins/libvisual-plugins+="alsa opengl"
>> media-plugins/gst-plugins-vaapi+="X drm opengl"
>> media-plugins/gst-plugins-v4l2+="udev"
emerge --ask media-plugins/gst-plugins-meta
# install volume deamon
>> xfce-extra/xfce4-volumed-pulse+="libnotify"
emerge --ask xfce-extra/xfce4-volumed-pulse
# install xfce pulseaudio plugin
>> xfce-extra/xfce4-pulseaudio-plugin+="keybinder libnotify"
emerge xfce-extra/xfce4-pulseaudio-plugin
# add volume to panel
>> Right Click On Panel -> Add Items -> PulseAudio plugin
>> Settings -> Session and Startup -> Splash -> Mice
# enable desktop notifications
>> xfce-base/xfce4-settings+="libcanberra libnotify"
emerge --ask --deep --update --newuse @world
emerge --depclean
emerge --ask xfce-extra/xfce4-notifyd
emerge --ask x11-misc/notification-daemon
>> Settings -> Notifications -> Theme -> Greybird
            -> Session and Startup -> Application Autostart -> Notification Daemon
			                                                -> Certification and Key Storage (GNOME Keyring: PKCS#11 Component)
															-> Secret Storage Service (GNOME Keyring: Secret Service)
															-> SSH Key Agent (GNOME Keyring: SSH Agent)
reboot
# install power manager
>> xfce-base/xfce4-session+="upower"
>> xfce-base/xfce4-settings+="upower"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> sys-power/pm-utils+="alsa"
>> xfce-extra/xfce4-power-manager+="networkmanager policykit systemd"
emerge --ask xfce-extra/xfce4-power-manager 
systemctl enable upower
systemctl restart upower
reboot
>> Settings -> Power Manager -> Status notifications
# install fonts
# other useflags already applied before: fontconfig fribidi
# other useflags already applied before: truetype
# other useflags already applied before: tiff
# other useflags to apply "type1 cleartype corefonts iconv icu"
>> media-libs/harfbuzz+="fontconfig"
>> media-video/ffmpeg+="fontconfig iconv"
>> x11-libs/libXfont+="truetype"
>> x11-libs/gdk-pixbuf+="tiff jpeg"
>> app-arch/libarchive+="iconv zlib"
>> net-misc/rsync+="iconv xattr"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> media-fonts/corefonts+="X tahoma"
emerge --ask media-fonts/corefonts
>> media-fonts/dejavu+="X"
emerge --ask media-fonts/dejavu
>> media-fonts/font-bh-ttf+="X"
emerge --ask media-fonts/font-bh-ttf
>> media-fonts/font-bh-type1+="X"
emerge --ask media-fonts/font-bh-type1
>> media-fonts/freefonts+="X"
emerge --ask media-fonts/freefonts
>> media-fonts/ttf-bitstream-vera+="X"
emerge --ask media-fonts/ttf-bitstream-vera
>> media-fonts/unifont+="X"
emerge --ask media-fonts/unifont
>> media-fonts/artwiz-aleczapka-en+="X"
emerge --ask media-fonts/artwiz-aleczapka-en
>> media-fonts/liberation-fonts+="X"
emerge --ask media-fonts/liberation-fonts
# enable some fonts
eselect fontconfig list
eselect fontconfig enable <num>
> 10-autohint.conf
> 10-sub-pixel-rgb.conf
> 20-unhint-small-dejavu-sans-mono.conf
> 20-unhint-small-dejavu-sans.conf
> 20-unhint-small-dejavu-serif.conf
> 25-unhint-nonlatin.conf
> 57-dejavu-sans-mono.conf
> 57-dejavu-sans.conf
> 57-dejavu-serif.conf
> 60-liberation.conf
reboot
>> sys-boot/grub+="truetype"
>> x11-terms/xterm+="truetype"
emerge --ask --deep --update --newuse @world
emerge --depclean
# re-install grub
grub-install --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
cp /boot/EFI/gentoo/grubx64.efi /boot/EFI/BOOT/bootx64.efi
reboot
# install videoplayer
>> dev-libs/libxml2+="python"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> media-sound/mpg123+="pulseaudio alsa sdl"
>> media-video/mplayer+="bidi bluray cddb dts dv faac gif gsm iconv jpeg mad mp3 opengl png pulseaudio sdl speex twolame v4l vcd vdpau xvid xvmc"
emerge --ask media-video/mplayer
>> media-libs/gmtk+="alsa pulseaudio"
>> media-video/gnome-mplayer+="alsa pulseaudio libnotify"
emerge --ask media-video/gnome-mplayer
>> media-libs/libquicktime+="X aac alsa dv ffmpeg opengl x264 jpeg png vorbis"
>> media-sound/alsa-utils+="ncurses"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> media-sound/pulseaudio+="qt4 libsamplerate"
>> dev-python/PyQt4+="dbus X multimedia opengl"
emerge --ask --deep --update --newuse @world
emerge --depclean
systemctl enable canberra-system-bootup.service
systemctl enable canberra-system-shutdown.service
systemctl enable canberra-system-shutdown-reboot.service
>> sys-apps/sed+="acl"
>> sys-devel/gettext+="acl"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> media-plugins/alsa-plugins+="jack libsamplerate"
>> media-plugins/gst-plugins-meta+="oss jack"
>> media-plugins/libvisual-plugins+="jack mplayer"
>> media-sound/mpg123+="jack oss portaudio"
>> media-sound/pulseaudio+="jack"
>> media-video/ffmpeg+="jack theora oss opus"
>> media-video/mplayer+="jack theora oss"
>> media-libs/portaudio+="alsa jack oss"
>> media-sound/jack-audio-connection-kit+="alsa oss pam"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> media-sound/pavucontrol+="nls"
>> dev-cpp/gtkmm+="X"
>> dev-cpp/cairomm+="X"
emerge --ask media-sound/pavucontrol
>> media-sound/paprefs+="nls"
>> media-sound/pulseaudio+="gnome"
emerge --ask media-sound/paprefs
>> xfce-extra/xfce4-mixer+="alsa keybinder oss"
emerge --ask xfce-extra/xfce4-mixer
###
### to test audio, use "speaker-test -t wav -c 2"
###
### to debug pulseaudio, open /etc/pulse/daemon.conf
###  > log-level=debug
###
### to view available alsa devices, use "aplay -L"
###
### to open alsa mixer in terminal, use "alsamixer"
###
# configure gnome-mplayer
reboot
>> Gnome MPlayer -> Edit -> Preferences -> Video Output -> x11
                                        -> Enable Video Hardware Support
# install tumbler
>> sys-apps/systemd+="xkb"
>> x11-libs/libxcb+="xkb"
>> x11-libs/libxkbcommon+="X"
emerge --ask --deep --update --newuse @world
emerge --depclean
reboot
>> xfce-extra/tumbler+="ffmpeg gstreamer jpeg odf pdf raw"
>> app-text/poppler+="cairo"
>> media-libs/libopenraw+="gtk"
emerge --ask xfce-extra/tumbler
reboot
# install cd burn utility
>> dev-libs/libisofs+="acl xattr zlib"
>> dev-libs/libburn+="cdio"
>> app-cdr/xfburn+="udev gstreamer"
emerge --ask app-cdr/xfburn
# install gpicview
emerge --ask x11-misc/xdg-utils
emerge --ask media-gfx/gpicview
# set gpicview as default
>> sudo gpicview
>> Settings (icon) -> Make gpic the default image viewer
reboot
# install bind-tools like nslookup and dig
>> net-dns/bind-tools+="idn readline"
emerge --ask net-dns/bind-tools
# install player control plugin
>> xfce-base/libxfcegui4+="startup-notification"
emerge --ask xfce-extra/xfce4-playercontrol-plugin
# install xfdashboard
>> media-libs/clutter+="X"
>> media-libs/cogl+="gstreamer"
emerge --ask xfce-extra/xfdashboard
>> Session and Startup -> Application Autostart -> Xfdashboard
                                                -> AT-SPI D-Bus Bus
>> Settings Editor -> xfce4-keyboard-shortcuts -> New -> /commands/custom/<Super>q -> String -> xfdashboard
reboot
# install thunar media tags plugin
emerge --ask xfce-extra/thunar-media-tags-plugin
# install thunar shares plugin
emerge --ask xfce-extra/thunar-shares-plugin
# install thunar vcs plugin
>> dev-vcs/git+="gnome-keyring iconv mediawiki pcre"
>> dev-vcs/subversion+="gnome-keyring"
emerge --ask xfce-extra/thunar-vcs-plugin
# install xkb plugin
emerge --ask xfce-extra/xfce4-xkb-plugin
>> Panel -> Items -> Add -> Keyboard Layouts
# install whiskermenu
emerge --ask xfce-extra/xfce4-whiskermenu-plugin
>> Panel -> Items -> Add -> Whisker Menu (remove old app launcher)
# install switch user functionality
emerge --ask xfce-extra/xfswitch-plugin
# install firefox
>> www-client/firefox+="system-cairo system-icu system-jpeg system-libvpx system-sqlite dbus hwaccel jit pulseaudio startup-notification wifi ffmpeg gstreamer system-harfbuzz system-libevent system-cairo"
>> media-libs/libpng+="apng"
>> dev-db/sqlite+="secure-delete"
>> dev-lang/python+="ncurses sqlite"
>> media-libs/libvpx+="postproc"
>> app-text/hunspell+="nls readline"
emerge --ask www-client/firefox
emerge --ask --deep --update --newuse @world
emerge --depclean
# install layman to prove overlay support
>> app-portage/layman+="git subversion"
emerge --ask app-portage/layman
echo "source /var/lib/layman/make.conf" >> /etc/portage/make.conf
layman -L
# install y2kbadbug overlay
layman -a y2kbadbug
# install mugshot
echo "x11-misc/mugshot ~amd64" >> /etc/portage/package.accept_keywords
>> x11-misc/mugshot+="accountsservice pidgin webcam"
>> net-im/pidgin+="dbus gadu idn networkmanager tk meanwhile mxit prediction sasl silc spell"
>> dev-lang/tk+="truetype xscreensaver"
>> net-libs/gupnp+="networkmanager"
>> dev-libs/cyrus-sasl+="pam"
>> net-mail/mailbase+="pam"
emerge --ask x11-misc/mugshot
chown root:mail /var/spool/mail/
chmod 03775 /var/spool/mail/
# configure mugshot
>> whisker -> arcana -> profile picture
                     -> email address
>> media-plugins/gst-plugins-meta+="theora opus"
>> media-libs/gst-plugins-base+="theora"
emerge --ask --deep --update --newuse @world
emerge --depclean
reboot
# install thunderbird
>> mail-client/thunderbird+="crypt dbus ffmpeg gstreamer jit pulseaudio startup-notification system-cairo system-harfbuzz system-jpeg system-libevent system-libvpx system-sqlite lightning system-icu mozdom"
emerge --ask mail-client/thunderbird
# set default to mailto, run as non-root
xdg-mime default thunderbird.desktop x-scheme-handler/mailto
>> add earlybird to launcher
# install some firefox addons
> FoxyProxy Standard
> DownThemAll
> 1-Click Youtube Video Downloader (search youtube)
> Download YouTube Videos as MP4
# run as non-root
xdg-mime default firefox.desktop x-scheme-handler/http
xdg-mime default firefox.desktop x-scheme-handler/https
xdg-mime default firefox.desktop text/html
xdg-mime default firefox.desktop application/x-mswinurl
# install network manager applet
emerge --ask gnome-extra/nm-applet
reboot
# install vim
>> app-editors/vim+="X acl cscope gpm vim-pager"
emerge --ask app-editors/vim
# change default editor to vi
eselect editor list
 >> eselect editor set <num>
 /usr/bin/vi
eselect vi list
 >> eselect vi set <num>
env-update && source /etc/profile
# install gedit
>> app-editors/gedit+="spell"
emerge --ask app-editors/gedit
xdg-mime default gedit.desktop text/plain
>> gedit -> Preferences -> Font & Colors -> Cobalt
# install samba
 >> net-fs/samba+="acl aio client fam pam quota systemd winbind"
 >> sys-libs/ntdb+="python"
 >> sys-libs/tevent+="python"
 >> sys-libs/tdb+="python"
 emerge --ask net-fs/samba
 >> gnoma-base/gvfs+="samba"
 >> media-video/ffmpeg+="samba librtmp jpeg2k lzma ssh quvi"
 >> media-video/mplayer+="rtmp samba live jpeg2k rtc nut mng dga pvr nas ftp"
 >> net-libs/libsoup+="samba"
 >> net-misc/curl+="samba"
 >> net-nds/openldap+="samba"
 >> dev-lang/lua+="readline"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 >> app-editors/nano+="justify ncurses"
 emerge --ask app-editors/nano
 reboot
 # create public folder for samba
 mkdir -p /home/samba
 mkdir -p /home/samba/public
 chmod -R o+rw /home/samba/public
 chmod -R g+s /home/samba
 setfacl -Rm o:rwX,d:o:rwX /home/samba/public
 cp /etc/samba/smb.conf.default /etc/samba/smb.conf
 nano -w /etc/samba/smb.conf
 > [global]
 > workgroup = WORKGROUP
 > server string = arcana-gentoo-vm
 > security = user
 > guest ok = yes
 > map to guest = Bad User
 > [public]
 > comment = Public Files
 > browseable = yes
 > public = yes
 > create mode = 0766
 > guest ok = yes
 > path = /home/samba/public
 > writable = yes
 nano -w /etc/nsswitch.conf
 > hosts: files dns wins
 systemctl enable nmbd.service
 systemctl enable smbd.service
 systemctl enable winbindd.service
 systemctl enable smbd.socket
 reboot
# install cups
 >> net-print/cups+="X acl dbus pam systemd usb"
 >> media-fonts/urw-fonts+="X"
 >> app-text/ghostscript-gpl+="X dbus djvu idn tiff"
 >> app-text/poppler+="cxx tiff"
 >> net-print/cups-filters+="dbus jpeg png tiff"
 >> app-text/djvu+="jpeg tiff"
 emerge --ask net-print/cups
 >> app-text/ghostscript-gpl+="cups"
 >> dev-qt/qtgui+="dbus evdev jpeg mng nas tiff cups"
 >> net-fs/samba+="cups"
 >> x11-libs/gtk+ += "cups"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 >> app-text/evince+="djvu dvi gnome-keyring gstreamer nsplugin t1lib tiff xps"
 >> app-text/libgxps+="jpeg tiff"
 >> app-text/texlive-core+="X tk"
 >> media-libs/t1lib+="X"
 >> dev-libs/zziplib+="sdl"
 >> media-libs/tiff+="zlib"
 emerge --ask app-text/evince
 systemctl enable cups.path
 systemctl enable cups-browsed.service
 systemctl enable cups.service
 systemctl enable cups-lpd.socket
 systemctl enable cups.socket
 gpasswd -a arcana lp
 gpasswd -a arcana lpadmin
 gpasswd -a root lp
 gpasswd -a root lpadmin
 reboot
 >> net-print/gutenprint+="cups foomaticdb ppds readline"
 emerge --ask net-print/gutenprint
 # set in make.conf
 # this sets use flags for sane-backends
 # since use flags for sane-backends is
 # a hell of use flags, it is more efficient
 # to set it like this
 >> SANE_BACKENDS="hp"
 >> media-gfx/sane-backends+="systemd usb v4l"
 emerge --ask media-gfx/sane-backends 
 >> x11-libs/gtk+ += "colord"
 >> x11-misc/colord+="scanner systemd"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 # install hplip
 >> net-print/hplip+="X fax hpcups hpijs libnotify policykit scanner snmp"
 >> dev-python/pillow+="tiff jpeg truetype"
 >> net-analyzer/net-snmp+="X"
 >> media-gfx/xsane+="jpeg png tiff"
 emerge --ask ne-print/hplip
 # install printer
 hp-setup
   # open cups
   # http://localhost:631
 # install xsane for scanner support
 # might be already installed
 # install cup-winows
 emerge --ask net-print/cups-windows
 ###
 ### To add windows shared printer:
 ### smb://user:pass@workgroup/server/PrinterName
 ###
 ### Note that "Space" in printer name should be manually
 ### replaced with %20
 ###
 # install gtklp
 emerge --ask net-print/gtklp
# enable some more use flags
>> app-text/poppler+="png"
>> media-libs/freetype+="png harfbuzz"
>> media-libs/jbig2dec+="png"
>> media-video/ffmpegthumbnailer+="gtk jpeg png"
>> sys-libs/slang+="png"
>> app-text/djvu+="jpeg tiff"
>> dev-python/pillow+="jpeg2k"
>> media-libs/lcms+="jpeg tiff"
>> media-libs/libv4l+="jpeg"
>> media-libs/netpbm+="jpeg2k"
>> media-libs/tiff+="jpeg"
>> x11-libs/gdk-pixbuf+="jpeg2k"
>> x11-misc/xscreensaver+="jpeg pam xinerama"
>> dev-qt/qtgui+="xinerama"
>> media-libs/libsdl+="xinerama"
>> media-video/mplayer+="xinerama"
>> x11-libs/gtk+ += "xinerama"
>> app-misc/screen+="pam"
>> sys-process/psmisc+="X"
>> sys-apps/groff+="X"
>> www-client/w3m+="X"
>> dev-libs/libunique+="dbus"
>> media-libs/cogl+="gstreamer"
>> media-libs/libcanberra+="gstreamer"
>> dev-qt/qtmultimedia+="alsa"
>> net-nds/openldap+="icu"
>> app-editors/vim-core+="acl"
>> net-fs/cifs-utils+="caps"
>> net-libs/libproxy+="networkmanager"
>> media-libs/jasper+="jpeg opengl"
emerge --ask --deep --update --newuse @world
emerge --ask --deep --update --changed-use @world
emerge --depclean
>> virtual/ffmpeg+="opus theora jpeg2k"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> sys-libs/zlib+="minizip"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> dev-libs/libdbusmenu+="gtk3"
emerge --ask dev-libs/libdbusmenu
# Install ProxyChains
 emerge --ask net-misc/proxychains
 vim /etc/proxychains.conf
 > socks5	127.0.0.1	8082
# install telegram messenger
 >> app-portage/layman+="mercurial"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 # install rindeal overlay
 layman -a rindeal
 >> net-im/telegram-desktop+="proxy"
 >> dev-qt/qt-telegram-static+="libproxy systemd"
 emerge --ask net-im/telegram-desktop
# more config in gedit
 GEdit -> Preferences -> Display line numbers
                      -> Highlight current line
                      -> Highligt matching brackets
# add user to group plugdev
gpasswd -a arcana plugdev
gpasswd -a root plugdev
# Install Java (Oracle)
# prerequisite: please update the system
 nano -w /etc/portage/make.conf
 > ACCEPT_LICENSE="Oracle-BCLA-JavaSE"
 env-update && source /etc/profile
 proxychains emerge --ask dev-java/oracle-jdk-bin
 # manually download jdk-8u77-linux-x64.tar.gz
 # using a proxy connection
 cp /home/arcana/Downloads/jdk-8u77-linux-x64.tar.gz /usr/portage/distfiles
 chown root:root /usr/portage/distfiles/jdk-8u77-linux-x64.tar.gz
 chmod 777 /usr/portage/distfiles/jdk-8u77-linux-x64.tar.gz
 proxychains emerge --ask dev-java/oracle-jdk-bin
# Install Java (Open JDK)
 >> media-libs/freetype+="infinality"
 >> media-fonts/croscorefonts+="X"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 echo "dev-java/icedtea ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask dev-java/icedtea-bin
 >> dev-java/icedtea+="alsa cups gtk infinality nsplugin nss pulseaudio source sunec webstart"
 >> dev-java/icedtea-web+="javascript nsplugin tagsoup"
 emerge --ask dev-java/icedtea
 emerge -C dev-java/icedtea-bin

# Install VLC Media Player
 >> media-video/vlc+="X a52 alsa bidi bluray cdda cddb dbus dts dvd faad flac fontconfig jack jpeg libass libnotify libtar libtiger modplug mp3 mpeg mtp musepack ogg opengl opus png postproc projectm pulseaudio -qt4 qt5 samba sdl sdl-image sftp skins speex svg taglib theora tremor truetype twolame udev v4l vaapi vcdx vdpau vorbis vpx wma-fixed x264 x265 xml xv matroska kate"
 media-libs/sdl-image+="gif jpeg png tiff"
 dev-libs/libtar+="zlib"
 emerge --ask media-video/vlc
 >> VLC -> Tools -> Preferences -> Video -> Output -> X11 video output (XCB)
# Install Evolution Data Server
 >> gnome-extra/evolution-data-server+="gnome-online-accounts gtk weather ldap"
 >> dev-lang/ruby+="readline ncurses ssl"
 >> net-misc/modemmanager+="policykit"
 >> net-im/telepathy-mission-control+="networkmanager"
 >> net-libs/webkit-gtk+="gnome-keyring spell nsplugin"
 >> app-crypt/libsecret+="crypt"
 >> dev-libs/libgdata+="gnome-online-accounts"
 emerge --ask gnome-extra/evolution-data-server
# Install PostgreSQL
 >> dev-db/postgresql+="pam nls readline ssl threads server"
 emerge --ask dev-db/postgresql
 emerge --config dev-db/postgresql:9.5
 systemctl enable postgresql-9.5.service
 systemctl restart postgresql-9.5.service
 # test postgres
 sudo -u postgres psql -d template1
# enable some services
 systemctl enable pwcheck.service
 systemctl enable samba.service
 systemctl enable smbd.service
 systemctl enable snmpd.service
 systemctl enable saslauthd.service
 systemctl enable slapd.service
 systemctl enable snmptrapd.service
 systemctl enable udisks2.service
 systemctl restart pwcheck.service
 systemctl restart samba.service
 systemctl restart smbd.service
 systemctl restart snmpd.service
 systemctl restart saslauthd.service
 systemctl restart slapd.service
 systemctl restart snmptrapd.service
 systemctl restart udisks2.service
# upgrade some packages
 >> net-nds/openldap+="crypt sasl slp ssl"
 >> virtual/ffmpeg+="threads"
 >> net-misc/curl+="threads"
 >> net-libs/libgadu+="threads" 
 >> sci-libs/fftw+="threads"
 >> media-libs/libvisual+="threads"
 >> media-gfx/sane-backends+="threads"
 >> dev-libs/elfutils+="threads"
 >> dev-libs/boehm-gc+="threads"
 >> dev-lang/tk+="threads"
 >> dev-lang/tcl+="threads"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
# select active java VM
 eselect java-vm list
 # eselect java-vm set system <num>
 >> select latest icedtea version
# install libreoffice
 >> app-office/libreoffice+="-branding cups dbus eds google gstreamer gtk java libreoffice_extensions_nlpsolver libreoffice_extensions_wiki-publisher odk postgres quickstarter vlc gnome"
 >> dev-db/postgresql+="kerberos"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 >> media-fonts/libertine+="X"
 >> net-libs/neon+="nls libproxy ssl zlib"
 >> dev-libs/redland+="postgres sqlite"
 emerge --ask app-office/libreoffice
 # add persian language
 LibreOffice -> Tools -> Options -> Language Settings -> Languages -> * Complex Text Layout (CTL) -> Persian
 # install persian fonts
 >> media-fonts/farsi-fonts+="X"
 emerge --ask media-fonts/farsi-fonts
 # enable persian fonts
 eselect fontconfig list
 eselect fontconfig enable <num>
 > 65-fonts-persian.conf
# install file-roller
 emerge --ask app-arch/file-roller
 >> app-arch/p7zip+="pch rar"
 emerge --ask app-arch/p7zip
 emerge --ask app-arch/unace
 emerge --ask app-arch/arj
 emerge --ask app-arch/cpio
 >> app-arch/dpkg+="bzip2 zlib"
 emerge --ask app-arch/dpkg
 >> app-cdr/cdrtools+="acl caps"
 emerge --ask app-cdr/cdrtools
 emerge --ask app-arch/zip
 emerge --ask app-arch/unzip
 emerge --ask app-arch/lha
 emerge --ask app-arch/lzop
 emerge --ask app-arch/unrar
 >> sys-libs/db+="java"
 >> app-arch/rpm+="acl caps"
 emerge --ask app-arch/rpm
 emerge --ask app-arch/zoo
# install more fonts
 >> media-fonts/source-pro+="X"
 emerge --ask media-fonts/source-pro
 >> media-fonts/ubuntu-font-family+="X"
 emerge --ask media-fonts/ubuntu-font-family
 # enable fonts
 eselect fontconfig list
 eselect fontconfig enable <num>
 > 63-source-pro.conf
 # IF TRASH DOES NOT WORK: enable trash
 # CHECK VIA "gvfs-trash <somefile>"
 # AND "gvfs-ls trash://"
  mkdir -p /home/.Trash
  chown root:wheel /home/.Trash
  chmod o=rw,g=rw /home/.Trash
  chmod g+s /home/.Trash
  setfacl -Rm g::rwX,d:g::rwX,o:rwX,d:o:rwX /home/.Trash
  ln -s /home/.Trash /usr/share/Trash
 # upgrade gvfs
 >> gnome-base/gvfs+="bluray gnome-online-accounts google gphoto2 gtk nfs"
 >> dev-libs/libgdata+="crypt"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 # install strace utility
 >> dev-util/strace+="aio"
 emerge --ask dev-util/strace
 # download persian fonts from yasdl or p30download. etc.
 # extract downloaded RAR file
 mkdir -p ~/.fonts
 cp -r ~/Downloads/..../* ~/.fonts
# install transmission bit torrent client
 >> dev-qt/qtnetwork+="libproxy networkmanager ssl"
 >> dev-qt/linguist-tools+="qml"
 >> dev-qt/qtdeclarative+="localstorage xml"
 >> net-p2p/transmission+="qt5 systemd"
 >> dev-qt/qtsql+="postgres"
 emerge --ask net-p2p/transmission
 systemctl enable transmission-daemon.service
 systemctl restart transmission-daemon.service
# configure transmission
 -> Transmission -> Edit -> Preferences -> Network -> * Pick a random port every time transmission is started
# enable some services
 systemctl enable slpd.service
 systemctl enable gpm.service
 systemctl enable nullmailer.service
 systemctl restart slpd.service
 systemctl restart gpm.service
 systemctl restart nullmailer.service
# install chromium
 >> www-client/chromium+="cups gnome-keyring hangouts proprietary-codecs pulseaudio system-ffmpeg hidpi hotwording"
 >> media-sound/sox+="alsa amr ao encode flac id3tag mad ogg opus png pulseaudio twolame wavpack"
 >> app-accessibility/espeak+="pulseaudio"
 >> app-accessibility/speech-dispatcher+="ao alsa pulseaudio"
 emerge --ask www-client/chromium
 >>>> right click on firefox icon in xfce bottom panel
 >>>>, click on properties, add chromium
 >>> execute chrome, set as default browser
 emerge --ask dev-python/Babel
 >> app-accessibility/speech-tools+="X nas"
 echo "app-accessibility/fesitval-freebsoft-utils ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask app-accessibility/festival-freebsoft-utils
 xdg-mime default chromium-browser-chromium.desktop x-scheme-handler/http
 xdg-mime default chromium-browser-chromium.desktop x-scheme-handler/https
 xdg-mime default chromium-browser-chromium.desktop text/html
 xdg-mime default chromium-browser-chromium.desktop application/x-mswinurl
 #####
 #### To try text-to-speech,
 #### echo "Gentoo can speak" | festival --tts
 ####
 #####
# install more fonts
>> media-gfx/fontforge+="X cairo gif gtk jpeg png readline svg tiff"
>> media-fonts/arphicfonts+="X"
emerge --ask media-fonts/arphicfonts
>> media-fonts/dejavu+="fontforge"
>> media-fonts/liberation-fonts+="fontforge"
>> media-fonts/unifont+="fontforge"
>> media-libs/freetype+="fontforge"
>> media-libs/gd+="png fontconfig jpeg tiff truetype webp xpm zlib"
>> dev-perl/GD+="png animgif gif jpeg truetype xpm"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> media-fonts/bitstream-cyberbit+="X"
emerge --ask media-fonts/bitstream-cyberbit
>> media-fonts/droid+="X"
emerge --ask media-fonts/droid
>> media-fonts/ipamonafont+="X"
emerge --ask media-fonts/ipamonafont
>> media-fonts/ja-ipafonts
emerge --ask media-fonts/ja-ipafonts
>> media-fonts/takao-fonts+="X"
emerge --ask media-fonts/takao-fonts
>> media-fonts/wqy-microhei+="X"
emerge --ask media-fonts/wqy-microhei
>> media-fonts/wqy-zenhei+="X"
emerge --ask media-fonts/wqy-zenhei
eselect fontconfig list
eselect fontconfig enable <num>
>> 41-ttf-arphic-ukai.conf
>> 64-ttf-arphic-uming.conf
>> 59-google-droid-sans-mono.conf
>> 59-google-droid-sans.conf
>> 59-google-droid-serif.conf
>> 66-ja-ipafonts.conf
>> 66-takao-fonts.conf
>> 44-wqy-zenhei.conf
# enable chrome as default
 -> Settings -> Preferred Applications -> Interner -> Web Browser -> Chromium
# install avahi
>> net-dns/avahi+="dbus gtk utils"
emerge --ask net-dns/avahi
systemctl enable avahi-daemon.service
systemctl enable avahi-dnsconfd.service
systemctl restart avahi-daemon.service
systemctl restart avahi-dnsconfd.service
nano -w /etc/nsswitch.conf
>> hosts: files mdns4_minimal wins dns mdns4
# install mono
>> dev-lang/mono+="nls"
>> dev-dotnet/libgdiplus+="cairo"
>> www-client/links+="unicode X bzip2 gpm jpeg ssl tiff zlib lzma"
emerge --ask dev-lang/mono
>> net-dns/avahi+="mono"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> www-client/w3m+="X nls ssl unicode gpm gtk"
emerge --ask www-client/w3m
# install banshee
>> media-sound/banshee+="aac bpm cdda daap encode mtp udev youtube karma"
>> media-fonts/canterell+="X"
>> gnome-base/gnome-vfs+="acl samba ssl"
>> gnome-base/gnome-settings-daemon+="networkmanager policykit"
### NOTE: "emerge -l" might also help
emerge --ask dev-dotnet/gdk-sharp
emerge --ask dev-dotnet/gnome-sharp
emerge --ask media-sound/banshee
emerge --ask dev-dotnet/glib-sharp
emerge --ask dev-dotnet/gtk-sharp
emerge --ask dev-dotnet/pango-sharp
>> media-plugins/gst-plugins-meta+="http modplug xvid"
emerge --ask --deep --update --newuse @world
emerge --depclean
emerge --deselect dev-lang/mono
emerge --depclean
# configure banshee
Banshee -> Edit -> Preferences -> Extensions -> * Youtube
                                             -> * Library watcher
                               -> Source Specific -> Music -> * Copy files to media folder when  importing
                                                  -> Videos -> * Copy files to media folder when importing
                               -> General -> * Sync metadata between library and files
                                          -> * Sync ratings between library and files
        -> View -> Equalizer -> * Enabled 
                             -> Party
                -> * Show Cover Art
# install disk utility
>> sys-apps/gnome-disk-utility+="fat systemd"
emerge --ask sys-apps/gnome-disk-utility
# install gdm
>> gnome-base/gdm+="audit accessibility xinerama"
>> gnome-base/gnome-control-center+="colord cups gnome-online-accounts networkmanager v4l"
>> net-misc/networkmanager+="modemmanager ppp"
>> net-dialup/ppp+="dhcp gtk pam ipv6"
>> media-libs/clutter-gtk+="X gtk"
>> media-libs/clutter-gst+="X udev"
>> dev-libs/liblouis+="python"
>> media-libs/mesa+="gles2"
>> app-accessibility/brltty+="python X gpm iconv icu java ncurses usb"
>> media-libs/clutter+="egl"
>> media-libs/cogl+="gles2"
>> app-accessibility/speech-dispatcher+="python"
>> dev-python/pycurl+="ssl"
>> x11-apps/xdpyinfo+="dga xinerama"
>> dev-lang/spidermonkey+="system-icu icu jit"
>> net-wireless/bluez+="udev cups extra-tools readline systemd"
>> media-libs/grilo+="gtk playlist"
>> gnome-extra/zenity+="libnotify webkit"
>> sys-auth/consolekit+="pm-utils"
>> app-i18n/ibus+="gconf gtk"
>> app-admin/system-config-printer+="gnome-keyring policykit"
>> x11-apps/mesa-progs+="egl gles2"
>> gnome-base/gnome-session+="systemd"
>> dev-libs/gmime+="mono"
>> media-libs/clutter+="gtk"
emerge --ask --deep --update --newuse @world
emerge --depclean
emerge --ask gnome-base/gdm
 # configure ibus
 layman -a sunrise
 >> dev-libs/libotf+="X"
 >> app-i18n/ibus-m17n+="nls gtk"
 emerge --ask app-i18n/ibus-m17n
 emerge --ask app-i18n/ibus-qt
 emerge --ask app-i18n/ibus-table
 echo "app-i18n/ibus-table-latin ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask app-i18n/ibus-table-latin
 # setup ibus
 ibus-setup
  -> Input Methods -> Add -> English (US)
                          -> Persian
  -> Advanced -> * Use system keyboard layout
 # configure startups
 -> Session and Startup -> Application Autostart -> Gnome Settings Daemon
                                                 -> Orca screen reader
                                                 -> GSettings Data Conversion
                        -> Advanced -> * Launch GNOME services on startup
                       
# add more gdm compatibility
>> sys-boot/plymouth+="gdm"
>> x11-misc/xscreensaver+="gdm"
>> x11-themes/redhat-artwork+="gdm"
>> xfce-extra/xfswitch-plugin+="gdm"
emerge --ask --deep --update --newuse @world
emerge --depclean
systemctl disable lightdm.service
systemctl enable gdm.service
systemctl enable auditd.service
systemctl enable brltty.service
systemctl enable ModemManager.service
emerge --ask media-gfx/argyllcms
# reboot system
reboot
# install imagemagick
>> media-gfx/imagemagick+="X corefonts djvu fftw fontconfig graphviz hdri jbig jpeg jpeg2k lzma bzip2 pango png postscript q64 raw svg tiff truetype webp wmf xml zlib"
>> media-gfx/exiv2+="nls png webready xmp"
>> media-gfx/ufraw+="gtk"
>> media-libs/libwmf+="X expat xml"
>> media-gfx/graphviz+="cairo nls X gdk-pixbuf gtk java pdf postscript qt4 svg"
emerge --ask media-gfx/imagemagick
# install inkscape
>> media-gfx/inkscape+="cdr dbus dia exif imagemagick inkjar jpeg lcms nls postscript spell visio wpg"
>> media-gfx/imagemagick+="cxx"
emerge --ask media-gfx/inkscape
# configure default proxy server in firefox
 -> Firefox -> FoxyProxy -> Add Proxy
# upgrade system
>> app-text/libgxps+="lcms"
>> dev-python/pillow+="lcms zlib webp"
>> media-gfx/imagemagick+="lcms"
>> media-gfx/xsane+="lcms"
>> media-libs/libmng+="lcms"
>> media-gfx/sane-backends+="gphoto2 avahi"
>> dev-libs/elfutils+="threads lzma bzip2"
>> net-dns/libidn+="java"
>> net-print/cups+="java"
>> sys-devel/gettext+="java"
>> dev-libs/cyrus-sasl+="java"
>> dev-libs/protobuf+="java"
>> dev-vcs/subversion+="java"
>> media-libs/libbluray+="java"
>> media-libs/libjpeg-turbo+="java"
>> dev-java/icedtea+="javascript"
>> dev-qt/qtmultimedia+="alsa"
>> media-libs/libao+="alsa pulseaudio"
>> media-libs/cogl+="gstreamer"
>> media-libs/libgphoto2+="exif jpeg"
>> media-libs/tiff+="lzma"
>> sys-apps/kmod+="lzma zlib"
>> sys-apps/systemd+="lzma"
>> dev-libs/libxml2+="lzma"
>> gnome-extra/libgsf+="gtk bzip2"
>> media-libs/freetype+="bzip2"
>> media-video/ffmpeg+="bzip2"
>> net-analyzer/net-snmp+="bzip2 ssl zlib"
>> x11-libs/libXfont+="bzip2"
>> app-arch/zip+="bzip2"
>> app-arch/unzip+="bzip2"
>> app-crypt/gnupg+="bzip2"
>> dev-db/postgresql+="zlib xml uuid"
>> dev-libs/libpcre+="zlib"
>> dev-libs/openssl+="zlib"
>> media-libs/lcms+="zlib"
>> media-libs/netpbm+="xml zlib"
>> net-libs/gnutls+="zlib"
>> net-libs/libssh+="zlib"
>> net-libs/libssh2+="zlib"
>> net-misc/wget+="zlib"
>> sys-apps/file+="zlib"
>> sys-apps/man-db+="zlib"
>> sys-apps/pciutils+="zlib"
>> sys-devel/binutils+="zlib"
>> sys-libs/binutils-libs+="zlib"
>> sys-libs/cracklib+="zlib"
>> sys-libs/slang+="zlib"
>> dev-qt/qtcore+="iconv ssl"
>> dev-libs/libpwquality+="pam"
>> gnome-extra/libgsf+="gtk"
>> media-libs/gst-plugins-bad+="gtk"
>> media-libs/libquicktime+="gtk"
>> media-plugins/libvisual-plugins+="gtk"
>> media-sound/pulseaudio+="gtk"
>> media-video/mjpegtools+="gtk"
>> net-libs/gssdp+="gtk"
>> net-print/gutenprint+="gtk"
>> net-ndns/openldap+="gtk"
>> sys-auth/polkit+="gtk"
>> x11-misc/xdg-user-dirs+="gtk"
>> x11-themes/nimbus+="gtk"
>> app-text/ghostscript-gpl+="gtk"
>> dev-libs/gjs+="gtk"
>> dev-libs/libdbusmenu+="gtk"
>> dev-vcs/git+="gtk"
>> dev-qt/qtgui+="gtkstyle"
>> dev-qt/qtwidgets+="gtkstyle"
>> net-fs/samba+="avahi"
emerge --ask --deep --update --newuse @world
emerge --depclean
# change Qt style
 -> Settings -> Qt Configuration -> Appearance -> GUI Style -> GTK+
# reboot system
reboot
# apply more upgrades to system
>> net-fs/cifs-utils+="acl"
>> www-client/chromium+="gtk3"
>> x11-themes/light-themes+="gtk3"
>> app-editors/mousepad+="gtk3"
>> app-office/libreoffice+="gtk3"
>> net-dns/avahi+="gtk3"
>> app-office/orage+="berkdb"
>> dev-lang/perl+="berkdb gdbm"
>> dev-lang/python+="berkdb gdbm"
>> dev-lang/ruby+="berkdb"
>> dev-libs/apr-util+="berkdb gdbm postgres ldap nss odbc sqlite openssl"
>> dev-libs/cyrus-sasl+="berkdb sqlite postgres"
>> dev-libs/redland+="berkdb"
>> dev-vcs/subversion+="berkdb"
>> gnome-extra/evolution-data-server+="berkdb"
>> net-nds/openldap+="berkdb"
>> sys-apps/iproute2+="berkdb"
>> sys-apps/man-db+="berkdb gdbm"
>> sys-libs/gdbm+="berkdb"
>> sys-libs/pam+="berkdb"
>> app-doc/doxygen+="clang doc dot doxysearch latex qt5 sqlite"
>> dev-util/systemtap+="sqlite"
>> media-libs/libsndfile+="sqlite"
emerge --ask --deep --update --newuse @world
emerge --depclean
# even more upgrades to system
>> dev-libs/gobject-introspection+="cairo doctool"
>> app-text/poppler+="cjk curl nss qt4 qt5"
>> dev-libs/glib+="systemtap utils xattr"
>> sys-apps/portage+="xattr"
>> sys-apps/shadow+="xattr"
>> sys-devel/patch+="xattr"
emerge --ask --deep --update --newuse @world
emerge --depclean
>> dev-util/gtk-doc+="doc highlight vim"
emerge --ask dev-util/gtk-doc
# reboot system
reboot
# install gimp
>> media-gfx/gimp+="alsa bzip2 curl dbus exif jpeg jpeg2k lcms mng pdf png postscript python smp svg tiff udev webkit wmf xpm"
>> media-libs/gegl+="cairo ffmpeg jpeg jpeg2k png raw sdl svg"
emerge --ask media-gfx/gimp
# install nautilus
>> gnome-base/nautilus+="exif introspection previewer sendto tracker xmp"
>> media-libs/libmediaart+="gtk"
>> app-misc/tracker+="cue exif -ffmpeg firefox-bookmarks flac gif gsf gstreamer gtk mp3 networkmanager pdf playlist thunderbird xmp xps rss upower"
>> gnome-extra/sushi+="office"
emerge --ask gnome-base/nautilus
>> x11-themes/redhat-artwork+="nautilus"
>> app-arch/file-roller+="nautilus"
>> app-text/evince+="nautilus"
emerge --ask --deep --update --newuse @world
emerge --depclean
# set nautilus as default
 -> Settings -> Preferred Applications -> Utilities -> File Manager -> Nautilus
# some upgrades to system
>> dev-scheme/guile+="networking"
>> media-libs/netpbm+="svga jbig"
>> media-libs/openal+="gui jack utils"
>> media-libs/tiff+="jbig"
emerge --ask --deep --update --newuse @world
emerge --depclean
# configure startup programs
 -> Settings -> Session and Startup -> Application Autostart -> * Files
# reboot system
reboot
# install nautilus utilities
 emerge --ask gnome-extra/nautilus-actions
 emerge --ask gnome-extra/nautilus-share
 gpasswd -a arcana samba
 gpasswd -a root samba
 emerge --ask gnome-extra/gnome-directory-thumbnailer
# install more gnome tools
 >> gnome-extra/gnome-system-monitor+="X systemd"
 emerge --ask gnome-extra/gnome-system-monitor
 emerge --ask gnome-extra/gnome-calculator
 emerge --ask gnome-extra/gnome-calendar
 >> dev-libs/folks+="eds telepathy tracker utils"
 >> gnome-extra/gnome-contacts+="v4l"
 >> gnome-extra/evolution-data-server+="vala"
 emerge --ask gnome-extra/gnome-contacts
 emerge --ask gnome-extra/gnome-clocks
 emerge --ask gnome-extra/gnome-characters
 echo "gnome-extra/gnome-color-chooser ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask gnome-extra/gnome-color-chooser
 emerge --ask gnome-extra/gnome-color-manager
 emerge --ask gnome-extra/gnome-power-manager
# configure clocks
 -> Clocks -> New -> Tehran
# install more gnome tools
 >> net-misc/gnome-online-miners+="flickr"
 >> media-plugins/grilo-plugins+="gnome-online-accounts subtitles tracker dvd flickr vimeo youtube daap freebox"
 emerge --ask gnome-extra/gnome-documents
 echo "gnome-extra/gnome-do ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask gnome-extra/gnome-do
 >> gnome-extra/gnome-do-plugins+="banshee"
 echo "gnome-extra/gnome-do-plugins ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask gnome-extra/gnome-do-plugins
 emerge --ask gnome-extra/gnome-logs
 emerge --ask gnome-extra/polkit-gnome
 emerge --ask gnome-extra/gnome-tweak-tool
 emerge --ask gnome-extra/gnome-weather
 emerge --ask gnome-extra/gnome-web-photo
 >> dev-python/rdflib+="berkdb redland sqlite"
 >> gnome-extra/zeitgeist+="datahub fts nls downloads-monitor icu plugins telepathy"
 >> gnome-extra/zeitgeist-datasources+="chromium firefox mono telepathy thunderbird vim"
 >> dev-libs/redland-bindings+="python"
 >> app-editors/vim+="python"
 >> dev-util/monodevelop+="git subversion"
 emerge --ask gnome-extra/gnome-activity-journal
 >> dev-libs/folks+="zeitgeist"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 emerge --ask gnome-extra/gnome-utils
 >> app-admin/packagekit-base+="cron networkmanager nsplugin systemd command-not-found"
 >> app-admin/packagekit+="gtk"
 echo "app-admin/packagekit-base ~amd64" >> /etc/portage/package.accept_keywords
 echo "gnome-extra/gnome-software ~amd64" >> /etc/portage/package.accept_keywords
 ###
 # to fix compile error, temporarily declare method as static:
 #  nano -w /usr/include/libappstream-glib/as-app.h
 #  > "static" ... as_app_has_compulsory_for_desktop
 ###
 emerge --ask gnome-extra/gnome-software
 ###
 # to fix compile error, temporarily declare method as static:
 #  nano -w /usr/include/libappstream-glib/as-app.h
 #  < "static" ... as_app_has_compulsory_for_desktop
 ###
 emerge --ask gnome-extra/gnome-user-docs
 emerge --ask gnome-extra/gnome-search-tool
 emerge --ask gnome-extra/gpointing-device-settings 
 echo "app-admin/packagekit-gtk ~amd64" >> /etc/portage/package.accept_keywords
 echo "gnome-extra/gnome-packagekit ~amd64" >> /etc/portage/package.accept_keywords
 >> gnome-extra/gnome-pacakgekit+="systemd udev"
 emerge --ask gnome-extra/gnome-packagekit
 emerge --ask gnome-extra/office-runner
 >> gnome-extra/gnome-commander+="chm doc exif gsf pdf taglib"
 emerge --ask gnome-extra/gnome-commander
 emerge --ask gnome-extra/activity-log-manager
 mkdir -p /usr/share/gnome-dictionary
 chmod g=rw,o=rw /usr/share/gnome-dictionary
 chown root:wheel /usr/share/gnome-dictionary
 chmod g+s /usr/share/gnome-dictionary
 sefacl -Rm g::rwX,d:g::rwX,o:rwX,d:o:rwX /usr/share/gnome-dictionary
 emerge --ask gnome-extra/gnome-getting-started-docs
# add gnome software to system startup
 Settings -> Session and startup -> Application Autostart -> GNOME Software
# install yet more gnome tools
 mkdir -p /usr/share/gnome-do
 chmod g=rw,o=rw /usr/share/gnome-do
 chown root:wheel /usr/share/gnome-do
 chmod g+s /usr/share/gnome-do
 sefacl -Rm g::rwX,d:g::rwX,o:rwX,d:o:rwX /usr/share/gnome-dictionary
 emerge --ask gnome-extra/gconf-editor
 >> media-libs/celt+="ogg"
 >> app-emulation/spice+="sasl"
 >> sys-firmware/ipxe+="qemu efi iso usb undi lkrn"
 >> app-emulation/qemu+="xattr vte vnc virtfs vhost-net uuid usb threads systemtap ssh spice snappy seccomp sdl sasl pulseaudio png opengl nfs ncurses lzo jpeg gtk filecaps fdt curl caps bzip2 bluetooth alsa aio"
 >> sys-fs/mtools+="X"
 >> app-emulation/libvirt+="audit avahi fuse lvm nfs parted policykit sasl systemd"
 >> net-libs/gtk-vnc+="pulseaudio sasl"
 >> net-misc/spice-gtk+="gtk3 dbus gstreamer lz4 policykit -pulseaudio sasl"
 >> net-nds/rpcbind+="systemd"
 >> net-fs/nfs-utils+="caps"
 nano -w /etc/portage/make.conf
 > QEMU_SOFTMMU_TARGETS="x86_64 i386"
 > QEMU_USER_TARGETS="x86_64 i386"
 emerge --ask gnome-extra/gnome-boxes
 gpasswd -a arcana kvm
 gpasswd -a root kvm
 vim /etc/modules-load.d/kvm-intel.conf
 > kvm-intel
 systemctl enable libvirt-guests.service
 systemctl enable libvirtd.service
 systemctl enable rpcbind.service
 systemctl enable virtlockd.service
 systemctl enable virtlogd.service
# reboot
 reboot
# continue configuring system for gnome
 udevadm trigger -c add /dev/kvm
 >> dev-libs/libgit2+="threads ssh"
 >> dev-libs/libgit2-glib+="ssh"
 emerge --ask gnome-extra/gnome-builder
 emerge --ask gnome-extra/gtkhtml
 >> gnome-extra/gucharmap+="cjk"
 emerge --ask gnome-extra/gucharmap
 >> app-office/mdbtools+="odbc"
 >> gnome-extra/libgda+="berkdb gnome-keyring gtk ldap postgres json mdb"
 emerge --ask gnome-extra/libgda
 emerge --ask gnome-extra/gnome-integration-spotify
 emerge --ask gnome-extra/libgsf
 emerge --ask gnome-extra/mousetweaks
 emerge --ask gnome-extra/zeitgeist-explorer
 emerge --ask gnome-extra/yelp
 emerge --ask gnome-extra/yelp-xsl
 emerge --ask gnome-extra/zenity
 >> gnome-extra/synapse+="plugins"
 emerge --ask gnome-extra/synapse
 emerge --ask gnome-extra/sushi
 >> x11-libs/libcryptui+="libnotify"
 emerge --ask gnome-extra/seahorse-nautilus
 emerge --ask gnome-extra/nautilus-sendto
 emerge --ask gnome-extra/nautilus-tracker-tags
 emerge --ask gnome-extra/docky
 >> gnome-extra/eiciel+="xattr"
 emerge --ask gnome-extra/eiciel
 >> mail-filter/bogofilter+="berkdb sqlite"
 >> mail-client/evolution+="bogofilter weather crypt highlight ldap spell ssl"
 >> app-text/highlight+="qt4"
 emerge --ask gnome-extra/evolution-ews
# add evolution to list of mail client
 XFCE Bottom Panel -> Right click on Mail -> Properties -> Add -> Evolution
# continue installing gnome
 emerge --ask x11-terms/gnome-terminal
 -> Settings -> Preferred Applications -> Utilities -> Terminal Emulator -> GNOME Terminal
# configure gnome terminal
 -> GNOME Terminal -> Edit -> Preferences -> Profiles -> Edit -> [] Use colors from system theme
                                                              -> Built-in schemas -> White on Black
# continue installing gnome
 emerge --ask gnome-extra/assogiate 
 echo "gnome-extra/cameramonitor ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask gnome-extra/cameramonitor
 echo "gnome-extra/avant-window-navigator ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask gnome-extra/avant-window-navigator
 >> gnome-extra/avant-window-navigator-extras+="gconf gstreamer webkit"
 echo "gnome-extra/avant-window-navigator-extras ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask gnome-extra/avant-window-navigator-extras
 >> gnome-extra/cjs+="cairo gtk"
 emerge --ask gnome-extra/cjs
 emerge --ask gnome-extra/gnome-dvb-daemon
 echo "gnome-extra/chrome-gnome-shell ~amd64" >> /etc/portage/package.accept_keywords
 emerge --ask gnome-extra/gnome-shell-frippery
 emerge --ask gnome-extra/gnome-shell-extensions
 emerge --ask gnome-extra/gnome-shell-extensions-topicons 
 emerge --ask gnome-base/gnome-common
 >> gnome-base/gnome-core-libs+="cups"
 emerge --ask gnome-base/gnome-core-libs
 >> gnome-base/gnome-core-apps+="cups"
 >> net-voip/telepathy-gabble+="plugins"
 >> app-crypt/seahorse+="ldap"
 >> media-video/totem+="nautilus zeitgeist"
 >> media-gfx/eog+="lcms tiff xmp"
 >> app-cdr/brasero+="mp3 nautilus playlist tracker"
 >> net-im/telepathy-connection-managers+="irc xmpp gadu icq meanwhile msn sip sipe steam yahoo"
 >> net-im/empathy+="gnome-online-accounts spell"
 >> x11-plugins/pidgin-sipe+="telepathy openssl"
 emerge --ask gnome-base/gnome-core-apps
 >> gnome-base/gnome-extra-apps+="-share"
 >> media-libs/libraw+="lcms jpeg jpeg2k"
 >> net-misc/whois+="nls iconv idn"
 >> net-libs/libpcap+="dbus"
 >> net-misc/vino+="crypt gnome-keyring jpeg ssl zlib"
 >> www-client/epiphany+="nss"
 >> media-libs/gegl+="v4l lcms webp"
 >> media-sound/sound-juicer="flac vorbis"
 >> net-misc/vinagre+="rdp spice"
 >> media-plugins/grilo-plugins+="upnp-av"
 >> virtual/libgudev+="introspection"
 >> dev-libs/libgudev+="introspection"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 emerge --ask gnome-base/gnome-extra-apps
 gpasswd -a arcana games
 gpasswd -a root games
# reboot
 reboot
# continue configuring gnome
 -> Games -> Mines -> Preferences -> Appearance -> Select Colorful theme
 emerge --ask gnome-base/dconf
 emerge --ask gnome-base/dconf-editor
 emerge --ask gnome-base/gconf
 emerge --ask gnome-base/gnome-session
 emerge --ask gnome-base/gnome-mime-data
 emerge --ask gnome-base/gsettings-desktop-schemas
 emerge --ask gnome-base/gnome-settings-daemon
 emerge --ask gnome-base/gnome-vfs
 emerge --ask gnome-base/gnome-menus
 emerge --ask gnome-base/gnome-shell
 >> gnome-base/gnome-light+="gnome-shell cups"
 emerge --ask gnome-base/gnome-desktop
 emerge --ask gnome-base/gnome-control-center
 >> gnome-base/gnome+="bluetooth cdr classic extras accessibility cups"
 emerge --ask gnome-base/gnome
# some configurations are necessary
 touch /usr/share/recently-used.xbel
 chown root:wheel /usr/share/recently-used.xbel
 chmod g=rw,o=rw /usr/share/recently-used.xbel
 chmod g+s /usr/share/recently-used.xbel
 setfacl -Rm g::rwX,d:g::rwX,o:rwX,d:o:rwX
 chown root:wheel /usr/share
 chmod g+s /usr/share
 setfacl -m g:wheel:rwX,d:g:wheel:rwX /usr/share
 chown -R root:wheel /usr/share/docky
 chmod -R g=rw,o=rw /usr/share/docky
 chmod -R g+s /usr/share/docy
 setfacl -Rm g::rwX,d:g::rwX,o:rwX,d:o:rwX /usr/share/docky
# change default video sink of gstreamer
 -> gconf editor -> system -> gstreamer -> 0.10 -> default -> videosink -> ximagesink
# upgrade system to use gnome environment 
 >> app-office/mdbtools+="gnome"
 >> gnome-base/nautilus+="gnome"
 >> media-gfx/inkscape+="gnome"
 >> media-gfx/ufraw+="gnome"
 >> media-libs/libcanberra+="gnome"
 >> media-video/ffmpegthumbnailer+="gnome"
 >> media-video/gnome-mplayer+="gnome"
 >> media-video/vlc+="gnome"
 >> net-im/empathy+="gnome"
 >> net-libs/gnome-online-accounts+="gnome"
 >> net-libs/libproxy+="mono gnome perl python spidermonkey webkit"
 >> sys-apps/gnome-disk-utility+="gnome"
 >> virtual/notification-daemon+="gnome"
 >> www-client/chromium+="gnome"
 >> x11-libs/libdesktop-agnostic+="gnome"
 >> x11-themes/greybird+="gnome"
 >> app-text/evince+="gnome"
 >> media-gfx/gimp+="gnome"
 >> net-dns/libidn+="mono"
 >> app-misc/tracker+="nautilus upnp-av"
 >> gnome-extra/gnome-dvb-daemon+="-totem"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
# reboot
# LOGIN INTO NEW GNOME SYSTEM!
# HOOORAYYYYYYYYYYYYY!
 reboot 
# set default image viewer to eog(eye of gnome)
# NOTE that there are 2 image viewers, try both of them!
# you will be successful
Settings -> Details -> Default Applications -> Photos -> Image Viewer
                                            -> Web -> Chromium
                                            -> Music -> Banshee Media Player
                                            -> Video -> VLC media player
                    -> Removeabe Media -> Software -> Ask what to do
# Use EOG to assign a backgound wallpaper to gnome!
 -> Open Picture -> Right Click -> Set as Wallpaper
# fix shotwell
 mkdir -p /usr/share/shotwell
 chown -R root:wheel /usr/share/shotwell
 chmod -R g=rw,o=rw /usr/share/shotwell
 chmod -R g+s /usr/share/shotwell
 setfacl -Rm g::rwX,d:g::rwX,o:rwX,d:o:rwX /usr/share/shotwell
# setup gnome online accounts
 -> Settings -> Online Accounts -> Add Account -> Google
                                               -> Other -> Yahoo
             -> Region & Language -> Input Sources -> Add -> English (US)
                                                          -> Persian (with Persian keypad)
             -> Privacy -> Location Services -> On
             -> Date & Time -> Time Zone -> Tehran, Iran
                            -> Time Format -> AM/PM
             -> Users -> Change Profile Picture
# start docky
 -> Docky -> Settings -> * Start when user logs in
# reboot
 reboot
# configure gnome-do
 -> gnome-do -> Preferences -> Keyboard -> Summon Do -> "<Super>d"
# configure synapse
 -> synapse -> Preferences -> General -> Startup on logon
# configure tweaks
 -> Tweak Tool -> Extensions -> * Removeable drive menu
                             -> * Topicons
                             -> * Applications Menu
                             -> * Places status indicator
               -> Window -> * Maximize
                         -> * Minimize
# install geany
>> dev-util/geany+="gtk3 vte"
emerge --ask dev-util/geany
# install glade
emerge --ask dev-util/glade
>> dev-libs/libgweather+="glade"
>> dev-libs/libpeas+="glade jit"
>> gnome-base/libgnomecanvas+="glade"
>> x11-libs/gtksourceview+="glade"
>> x11-libs/libdesktop-agnostic+="glade"
emerge --ask --deep --update --newuse @world
emerge --depclean
# install qt goodies
>> dev-qt/designer+="declarative webkit"
>> sys-libs/libunwind+="lzma"
>> dev-qt/qtprintsupport+="cups -gles2"
>> dev-qt/qtwebkit+="jit geolocation gstreamer -multimedia opengl orientation printsupport qml webchannel webp"
>> dev-qt/qtpositioning+="geoclue qml"
>> dev-qt/qtwebchannel+="qml"
>> dev-qt/qtsensors+="qml"
>> app-misc/geoclue+="geonames gps gtk hostip networkmanager"
>> sci-geosciences/gpsd+="X bluetooth dbus ncurses ntp systemd python"
>> net-misc/ntp+="threads caps readline samba snmp ssl"
emerge --ask dev-qt/designer
emerge --ask --deep --update --newuse @world
emerge --depclean
## IF QT DESIGNER LINK BROKEN
# fix qt designer link
> rm -f /usr/bin/designer
> ln -s /usr/lib64/qt5/bin/designer /usr/bin/designer
# install python requests module
emerge --ask dev-python/requests
# continue installing qt goodies
>> dev-qt/qt-creator+="android autotools baremetal clang cmake cvs git ios python qbs subversion systemd webkit winrt"
>> dev-libs/botan+="threads bzip2 gmp ssl zlib"
>> dev-vcs/cvs+="nls crypt pam"
>> dev-qt/qtscript+="jit scripttools"
>> sys-devel/gdb+="client nls server expat lzma"
emerge --ask dev-qt/qt-creator
emerge --ask --deep --update --newuse @world
emerge --depclean
# configure Qt Creator
 -> Qt Creator -> Help -> About Plugins -> Beautifier
                                        -> FakeVim
                                        -> AutotoolsProjectManager
                                        -> ModelEditor
# install pgadmin
>> x11-libs/wxGTK+="X gstreamer libnotify opengl sdl tiff webkit"
emerge --ask dev-db/pgadmin3
# configure pgadmin
 -> PgAdmin3 -> Add Server -> localhost
# unmerge some un-needed tools
 emerge -C x11-terms/xfce4-terminal
 emerge -C x11-terms/xterm
 emerge --depclean
 emerge -C app-editors/mousepad
 emerge -C app-office/orage
 emerge -C xfce-extra/xfce4-taskmanager
 emerge --depclean
 >> mail-mta/nullmailer+="ssl"
 emerge --ask app-admin/sudo
 emerge -C xfce-base/xfce4-app
# install codeblocks
 >> dev-util/codeblocks+="contrib pch"
 >> x11-libs/wxGTK=="gnome odbc pch"
 echo "dev-util/codeblocks ~amd64" >> /erc/portage/package.accept_keywords
 >> gnome-base/libgnomeprint+="cups"
 emerge --ask dev-util/codeblocks
# run codeblocks, set GNU GCC as default compiler
 -> Code Blocks
# install MC, a tool for terminal
 >> app-misc/mc+="X edit gpm nls samba sftp slang spell xdg"
 emerge --ask app-misc/mc
# unmerge some un-needed tools
 emerge -C xfce-extra/thunar-vcs-plugin
 emerge -C xfce-extra/thunar-shares-plugin
 emerge -C xfce-extra/thunar-media-tags-plugin
 emerge -C xfce-extra/thunar-archive-plugin
 emerge -C xfce-extra/thunar-volman
 emerge -C media-gfx/gpicview
 emerge -C xfce-extra/xfce4-playercontrol-plugin
 emerge -C xfce-extra/tumbler
 emerge -C xfce-extra/xfce4-xkb-plugin
 emerge -C xfce-extra/xfswitch-plugin
 emerge -C app-cdr/xfburn
 emerge --depclean
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 emerge -C xfce-extra/xfce4-mount-plugin
 emerge -C xfce-extra/xfce4-pulseaudio-plugin
 emerge -C xfce-extra/xfce4-volumed-pulse
 emerge -C xfce-extra/xfce4-power-manager
 emerge -C xfce-extra/xfce4-mixer
 emerge -C xfce-extra/xfce4-whiskermenu-plugin
 emerge -C xfce-extra/xfdashboard
 emerge -C xfce-base/xfce4-settings
 emerge -C xfce-base/xfdesktop
 emerge -C xfce-base/xfce4-panel
 emerge -C xfce-base/xfce4-session
 emerge -C xfce-extra/xfce4-notifyd
 emerge -C xfce-base/thunar
 emerge -C xfce-base/xfce4-appfinder
 emerge -C xfce-base/xfwm4
 emerge -C xfce-base/libxfce4ui
 emerge -C xfce-base/garcon
 emerge -C xfce-base/exo
 emerge -C xfce-base/xfconf
 emerge -C x11-themes/xfwm4-themes
 emerge --depclean
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 emerge -C x11-misc/lightdm
 emerge -C x11-misc/lightdm-gtk-greeter
 emerge --depclean
 emerge --ask --deep --update --newuse @world
 emerge --depclean
# reboot system
 reboot
# upgrade system
 >> dev-libs/newt+="gpm"
 >> sys-libs/ncurses+="gpm"
 >> net-misc/freerdp+="X alsa cups ffmpeg gstreamer jpeg pulseaudio usb xinerama"
 >> app-accessibility/brltty+="bluetooth"
 >> app-office/libreoffice+="bluetooth"
 >> dev-libs/folks+="bluetooth"
 >> gnome-extra/nm-applet+="bluetooth modemmanager"
 >> media-sound/pulseaudio+="bluetooth ssl"
 >> net-analyzer/netcat6+="bluetooth"
 >> net-libs/libpcap+="bluetooth"
 >> net-misc/networkmanager+="bluetooth"
 >> sys-libs/slang+="cjk"
 >> app-text/texlive-core+="cjk xetex"
 >> dev-java/icedtea+="cjk"
 >> dev-perl/Spreadsheet-ParseExcel+="unicode cjk"
 >> media-gfx/sam2p+="gif"
 >> dev-texlive/texlive-xetex+="X"
 >> app-text/texlive+="extra X cjk graphics epspdf context humanities png truetype xml science tex4ht texi2html"
 >> media-fonts/sazanami+="X"
 >> media-fonts/baekmuk-fonts+="unicode X"
 >> media-fonts/lohit-fonts+="X"
 >> media-fonts/lklug+="X"
 >> dev-libs/ptexenc+="iconv"
 >> dev-tex/tex4ht+="java"
 >> app-text/dvipng+="truetype"
 >> dev-tex/dot2texi+="pgf pstricks"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
# install geany plugins
 >> dev-util/geany-plugins+="autoclose automark commander ctags debugger defineformat devhelp enchant -git gpg gtkspell markdown multiterm nls overview scope webkit"
 >> dev-util/geany+="-gtk3"
 >> dev-util/devhelp+="gedit"
 emerge --ask dev-util/geany-plugins
# upgrade vim syntax
 >> app-admin/eselect+="vim-syntax"
 >> dev-java/jflex+="vim-syntax"
 >> dev-libs/protobuf+="vim-syntax"
 >> dev-util/ninja+="vim-syntax"
 >> dev-util/ragel+="vim-syntax"
 >> dev-vcs/subversion+="vim-syntax"
 >> net-misc/dhcp+="vim-syntax"
 >> net-misc/ntp+="vim-syntax"
 >> sys-libs/pam+="vim-syntax"
 >> x11-libs/gtk+ +="vim-syntax"
 emerge --ask --deep --update --newuse @world
 emerge --depclean
 emerge --ask app-vim/extra-syntax
 emerge --ask app-vim/json
 emerge --ask app-vim/autoalign
 emerge --ask app-vim/bash-support
# install redis
 emerge --ask dev-db/redis
 systemctl enable bluetooth.service
 systemctl enable ntpd.service
 systemctl enable ntpdate.service
 systemctl enable redis.service
 systemctl enable sntp.service
 systemctl enable gpsd.socket
# install nodejs
 >> net-libs/nodejs+="icu npm ssl"
 emerge --ask net-libs/nodejs
# configure security limits
 echo "root hard    nofile  16384" >> /etc/security/limits.conf
 echo "root soft    nofile  16384" >> /etc/security/limits.conf
 echo "wheel hard    nofile  16384" >> /etc/security/limits.conf
 echo "wheel soft    nofile  16384" >> /etc/security/limits.conf
# reboot system
 reboot
# install atom editor
 >> media-video/ffmpeg+="vpx"
 >> dev-util/electron+="proprietary-codecs system-ffmpeg cups gnome gnome-keyring hidpi pulseaudio -lto"
 echo "dev-util/electron ~amd64" >> /etc/portage/package.accept_keywords
 echo "app-editors/atom ~amd64" >> /etc/portage/package.accept_keywords

 emerge --ask app-editors/atom
# configure atom
 Atom -> Edit -> Preferences -> Install -> atom-runner
# close atom
 x
# configure atom-runner
 nano -w ~/.atom/config.cson
 > runner:
 >  scopes:
 >   js:"node"
# install jsbeautify
 npm install -g js-beautify
# continue configuring atom
 Atom -> Edit -> Preferences -> Instal -> atom-mocha
                                       -> linter-eslint
                                       -> vim-mode
                                       -> atom-easy-jsdoc
                                       -> formatter
                                       -> formatter-jsbeautify -> Javascript -> -s, 2, -j
                                                               -> Path to executable js-beautify -> /usr/bin/js-beautify
                                       -> atom-terminal-panel
                                       -> git-plus
                                       -> language-markdown
# REMEMBER: AUTO-FORMAT CODE IS "Ctrl + Alt + L"   
#           GIT TOOLS IS "Ctrl + Shift + H"

# configure git credentials
git config --global user.email "m_kharatizadeh@yahoo.com"
git config --global user.name "Mohamad mehdi Kharatizadeh"
# install rhythmbox
>> media-sound/rhythmbox+="cdr daap dbus gnome-keyring libnotify mtp nsplugin udev upnp-av visualizer webkit zeitgeist"
>> x11-libs/mx+="gtk dbus startup-notification"
emerge --ask media-sound/rhythmbox
# install nginx
nano -w /etc/portage/make.conf
 >> NGINX_MODULES_HTTP="access auth_basic auth_pam autoindex browser charset dav dav_ext empty_gif fancyindex fastcgi geo geoip gunzip gzip gzip_static limit_conn limit_req map memc memcached proxy push_stream realip referer rewrite scgi spdy split_clients ssi sticky sub upload_progress upstream_check upstream_ip_hash userid uwsgi xslt"
 >> NGINX_MODULES_MAIL="imap pop3 smtp"
 >> NGINX_MODULES_STREAM="access limit_conn upstream"
>> www-servers/nginx+="aio http http-cache http2 pcre pcre-jit rtmp ssl threads vim-syntax"
emerge --ask www-servers/nginx
systemctl enable nginx.service
systemctl restart nginx.service
# set lock screen background
 -> Settings -> Background -> Lock Screen
# install bind
>> net-dns/bind+="berkdb caps fetchlimit filter-aaaa geoip gost gssapi idn nslint odbc postgres rpz sit ssl threads xml dlz"
emerge --ask net-dns/bind
systemctl enable named.service
systemctl restart named.service
# configure bind
echo "127.0.0.1 ns1.arcane.net" >> /etc/hosts
echo "127.0.0.1 ns1" >> /etc/hosts
nano -w /etc/bind/named.conf
> zone "example.com" {
>   type master;
>   file "/etc/bind/db.arcane.net";
> };
nano -w /etc/bind/db.arcane.net
> $TTL 604800
> @	IN	SOA	ns1.arcane.net.	root.arcane.net. (
> 			5		; Serial
> 			604800		; Refresh
> 			86400		; Retry
> 			2419200		; Expire
> 			604800 )	; Negative Cache TTL
> ;
> 
> arcane.net.	IN	NS	ns1.arcane.net.
> ns1		IN	A	127.0.0.1
> @		IN	A	127.0.0.1
> www		IN	CNAME	arcane.net.
# test bind
systemctl restart named.service
nslookup www.arcane.net 127.0.0.1
# configure reverse lookup
nano -w /etc/bind/named.conf
> zone "0.0.127.in-addr.arpa" {
>   type master;
>   notify no;
>   file "/etc/bind/db.127";
> };
nano -w /etc/bind/db.127
> $TTL 604800
> @	IN	SOA	ns1.arcane.net.	root.arcane.net. (
> 			5		; Serial
> 			604800		; Refresh
> 			86400		; Retry
> 			2419200		; Expire
> 			604800 )	; Negative Cache TTL
> ;
> 
> @		IN	NS	ns1.arcane.net.
> 1		IN	PTR	www.arcane.net.
# test bind
systemctl restart named.service
nslookup 127.0.0.1 127.0.0.1
# set local DNS server
 ----- set DNS servers to "127.0.0.1" and "4.2.2.4" in GNOME settings.
 ----- also turn off automatic DNS discovery
# configure nginx
mkdir -p /etc/nginx/vhosts
nano -w /etc/nginx/nginx.conf
> include /etc/nginx/vhosts/*
# install swagger-editor
cd /opt
git clone https://github.com/swagger-api/swagger-editor.git
cd swagger-editor
npm install
npm run build
vim /etc/nginx/vhosts/swagger-editor.arcane.net
> server {
>  listen 80;
>  server_name swagger-editor.arcane.net;
>  
>  access_log /var/log/nginx/swagger-editor.arcane.net.access_log main;
>  error_log /var/log/nginx/swagger-editor.arcane.net.error_log info;
>
>  root /opt/swagger-editor;
>  index index.html;
> }
systemctl restart nginx.service
nano -w /etc/bind/db.arcane.net
> swagger-editor	IN	A	127.0.0.1
systemctl restart named.service
# install gtk+extra
emerge --ask x11-libs/gtk+extra
# install cinnamon
emerge --ask gnome-extra/cinnamon-menus
>> gnome-extra/cinnamon-desktop+="systemd"
emerge --ask gnome-extra/cinnamon-desktop
>> sys-power/pm-utils+="ntp"
>> gnome-extra/cinnamon-settings-daemon+="colord cups systemd"
emerge --ask gnome-extra/cinnamon-settings-daemon
emerge --ask gnome-extra/cinnamon-control-center
emerge --ask gnome-extra/cinnamon-translations
>> gnome-extra/cinnamon-session+="systemd"
emerge --ask gnome-extra/cinnamon-session
>> gnome-extra/cinnamon-screensaver+="pam systemd"
emerge --ask gnome-extra/cinnamon-screensaver
>> gnome-extra/nemo+="nls exif tracker xmp"
emerge --ask gnome-extra/nemo
>> x11-wm/muffin+="xinerama"
emerge --ask gnome-extra/cinnamon
# add gtk support to transmission
>> net-p2p/transmission+="gtk"
emerge --ask --deep --update --newuse @world
# more configuration to transmission
 -> Transmission -> Edit -> Preferences -> Speed -> Scheduled times -> 02:00 -> 07:00
                                        -> Seeding -> Stop seeding at ratio -> 1.0
                                        -> Desktop -> Show Transmission icon in the notification area
# install terminal based mail client
emerge --ask mail-client/mailx
# install unar package to open archieves
>> sys-devel/gcc+="objc"
>> gnustep-base/gnustep-make+="native-exceptions"
emerge --ask app-arch/unar
# add proxy VPN to bind
nano -w /etc/bind/db.arcane.net
> proxy		IN	A	178.162.207.98
systemctl restart named.service
# install delegate
>> download latest delegate sourcecode from delegate.org website
mkdir -p /usr/local/src
cd /usr/local/src
wget http://delegate.hpcc.jp/anonftp/DeleGate/delegate9.9.13.tar.gz
tar xvf delegate9.9.13.tar.gz
cd delegate9.9.13
make -j5
cp src/delegated /usr/local/bin/
# create proxy scripts on desktop
cd /home/arcana/Desktop
nano -w socks.sh
> #!/bin/bash
> ssh -D 8082 proxy.arcane.net
nano -w http.sh
> #!/bin/bash
> delegated -P8083 SERVER=http SOCKS=localhost:8082
chmod +x socks.sh http.sh
# install docker
>> app-emulation/runc+="seccomp"
>> app-emulation/containerd+="seccomp"
>> app-emulation/docker+="seccomp -device-mapper overlay"
>> sys-fs/lvm2+="thin"
>> sys-libs/libseccomp+="static-libs"
emerge --ask --deep --update --newuse @world
emerge --depclean
emerge --ask app-emulation/docker
mkdir -p /etc/systemd/system/docker.service.d
nano -w /etc/systemd/system/docker.service.d/http_proxy.conf
> [Service]
> Environment="HTTP_PROXY=http://127.0.0.1:8083/"
nano -w /etc/systemd/system/docker.service.d/no_proxy.conf
> [Service]
> Environment="NO_PROXY=127.0.0.0/8, localhost, ::1"
systemctl daemon-reload
systemctl enable docker.service
usermod -aG docker arcana
usermod -aG docker root
systemctl restart docker.service
####
##
## NOTE: ALWAYS HAVE PROXY AS DOCKER HAS SANCTIONED IRAN
##
####
# reboot
reboot
# test docker installation
docker run hello-world
# run an ubuntu shell
docker run -it ubuntu bash
# install docker machine
echo "app-emulation/docker-machine ~amd64" >> /etc/portage/package.accept_keywords
emerge --ask app-emulation/docker-machine
# install docker swarm
echo "app-emulation/docker-swarm ~amd64" >> /etc/portage/package.accept_keywords
emerge --ask app-emulation/docker-swarm
# disable git HTTPS check
git config --global http.sslVerify false
#########################################################
##         SYSTEM BOOTSTRAP USING DOCKER               ##
#########################################################
systemctl stop named
systemctl stop nginx
systemctl stop postgresql-9.5.service
systemctl disable named
systemctl disable nginx
systemctl disable postgresql-9.5.service
# create network
docker network create -d bridge arcana.me
# configure bind
docker run -td --restart=always --name ns1.arcana.me -h ns1.arcana.me -e ROOT_PASSWORD=root --net arcana.me -w /etc/webmin -p 53:53/udp -p 53:53/tcp -p 10000:10000/tcp sameersbn/bind:latest
echo "127.0.0.1 ns1.arcana.me" >> /etc/hosts
>> open https://ns1.arcana.me:10000 in browser
>> login with root/root
>> open Servers -> BIND DNS Server
-> Setup RDNC
-> Forwarding and Transfers -> 4.2.2.4
                            -> 8.8.8.8
-> Create Master Zone -> Domain name/Network -> arcana.me.
                      -> Email Address -> root@arcana.me
                      -> Addresses -> Name -> @
                                   -> Address -> 127.0.0.1
                                   -> Update reverse? -> Yes
                      -> Addresses -> Name -> ns1
                                   -> Address -> 127.0.0.1
                                   -> Update reverse? -> No
                      -> Addresses -> Name -> www
                                   -> Address -> 127.0.0.1
                                   -> Update reverse? -> No
                      -> Addresses -> Name -> vpn
                                   -> Address -> 178.162.207.98
                                   -> Update reverse? -> Yes
                      -> Apply Zone
# configure socks proxy
docker run -td --restart=always --name socks.arcana.me -h socks.arcana.me --net arcana.me -w /root -p 8082:8082 ubuntu
docker exec -it socks.arcana.me bash
> apt-get update && apt-get install -y ssh
> ssh-keygen -t rsa
> ssh root@178.162.207.98 mkdir -p .ssh
> cat ~/.ssh/id_rsa.pub | ssh root@178.162.207.98 'cat >> .ssh/authorized_keys'
> ssh root@178.162.207.98 "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"
> ssh root@178.162.207.98
> > exit
> cat <<EOF > socks.sh
  #!/bin/bash
  while true; do ssh -D 0.0.0.0:8082 root@178.162.207.98; done
EOF
> chmod +x socks.sh 
> ./socks.sh
> Ctrl+P + Ctrl+Q
>>> Add socks.arcana.me to BIND
# configure http proxy
docker run -td --restart=always --name proxy.arcana.me -h proxy.arcana.me --net arcana.me -w /root -p 8083:8083 ubuntu
docker cp /usr/local/bin/delegated proxy.arcana.me:/usr/bin
docker exec -it proxy.arcana.me bash
> delegated --help
> cat <<EOF > http.sh
  #!/bin/bash
  delegated -P8083 SERVER=http SOCKS=socks.arcana.me:8082
EOF
> chmod +x http.sh
> ./http.sh
> Ctrl+P + Ctrl+Q
>>> Add proxy.arcana.me to BIND
nano -w /etc/systemd/system/docker.service.d/http_proxy.conf
> [Service]
> Environment="HTTP_PROXY=http://proxy.arcana.me:8083/"
systemctl daemon-reload
>>> TEST NEW HTTP/SOCKS PROXY CONFIGS IN FIREFOX FOXYPROXY
systemctl restart docker.service
cat <<EOF > /home/arcana/Desktop/socks.sh
#!/bin/bash
docker exec -d socks.arcana.me bash socks.sh
EOF

cat <<EOF > /home/arcana/Desktop/http.sh
#!/bin/bash
docker exec -d proxy.arcana.me bash http.sh
EOF

# configure nginx reverse proxy server
docker pull nginx
docker run -td --restart=always --name arcana.me -h arcana.me --net arcana.me -w /etc/nginx -p 80:80 -p 443:443 nginx
docker exec -it arcana.me bash
> apt-get update && apt-get install -y nano vim net-tools iputils-ping dnsutils
> exit
docker commit arcana.me arcana.me-snap-...
docker exec -it arcana.me bash
> vim nginx.conf
> >> include /etc/nginx/vhosts/*;
> mkdir -p /etc/nginx/vhosts
> mkdir -p /etc/nginx/ssl
> openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/nginx/ssl/ns1.arcana.me.key -out /etc/nginx/ssl/ns1.arcana.me.crt

cat <<EOF > /etc/nginx/vhosts/ns1.arcana.me
server {
  listen 443 ssl;
  server_name ns1.arcana.me;
  ssl_verify_client off;
  ssl_certificate /etc/nginx/ssl/ns1.arcana.me.crt;
  ssl_certificate_key /etc/nginx/ssl/ns1.arcana.me.key;
  location / {
    proxy_pass https://ns1.arcana.me:10000/;
    proxy_pass_header Set-Cookie;
    proxy_pass_header P3P;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-NginX-Proxy true;
    proxy_cookie_domain ns1.arcana.me:10000 ns1.arcana.me;
  }
}
server {
  listen 80;
  server_name ns1.arcana.me;
  return 301 https://\$host\$request_uri;
}
EOF

> exit

docker restart arcana.me
docker commit arcana.me arcana.me-snap-...
docker exec -it ns1.arcana.me bash

> sed -i -- 's/referers_none=1/referers_none=0/g' /etc/webmin/config
> echo "referers=ns1.arcana.me" >> /etc/webmin/config
> exit
docker restart ns1.arcana.me
# configure a local mail server
cd /usr/local/src
git clone https://github.com/MLstate/PEPS
cd PEPS
echo mail.arcana.me > domain
echo mail.arcana.me > hostname
make build
make certificate
make data_init
>> edit Makefile and set HTTPS_PORT to 10010,
>> also setup auto restart
nano -w Makefile
> HTTPS_PORT=10010
> DOCKER_DAEMON=docker run -dt --restart=always -h $(HOSTNAME)
make run
docker network connect arcana.me peps_server
docker exec -it arcana.me bash
> openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/nginx/ssl/mail.arcana.me.key -out /etc/nginx/ssl/mail.arcana.me.crt
> nano -w etc/nginx/vhosts/mail.arcana.me
>> server {
>>  listen 443 ssl;
>>  server_name mail.arcana.me;
>>  ssl_verify_client off;
>>  ssl_certificate /etc/nginx/ssl/mail.arcana.me.crt;
>>  ssl_certificate_key /etc/nginx/ssl/mail.arcana.me.key;
>>  location / {
>>    proxy_pass https://peps_server:443/;
>>    proxy_pass_header Set-Cookie;
>>    proxy_pass_header P3P;
>>    proxy_set_header X-Real-IP $remote_addr;
>>    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
>>    proxy_set_header X-Forwarded-Proto $scheme;
>>    proxy_set_header X-NginX-Proxy true;
>>    proxy_cookie_domain peps_server mail.arcana.me;
>>  }
>> }
>> server {
>>  listen 80;
>>  server_name mail.arcana.me;
>>  return 301 https://$host$request_uri;
>> }
> exit
docker restart arcana.me
>> add mail.arcana.me address record
>> login to mail.arcana.me
>> set admin password (user will be called admin)
>> Settings -> Mail Domain Name -> arcana.me
>> People -> Users -> New User -> arcana@arcana.me
>> Create MX record
>>> Mail Server Records -> Name = @, Mail Server = mail.arcana.me, Priority = 1
>> add smtp.arcana.me and imap.arcana.me and pop3.arcana.me records
# configure local gitlab instance
docker pull gilab/gitlab-ce
docker run -td --restart=always --name git.arcana.me -h git.arcana.me -w /root --net arcana.me -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-ce
docker exec -it arcana.me bash
> openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/nginx/ssl/git.arcana.me.key -out /etc/nginx/ssl/git.arcana.me.crt
> nano -w /etc/nginx/vhosts/git.arcana.me
>> server {
>>  listen 443 ssl;
>>  server_name git.arcana.me;
>>  ssl_verify_client off;
>>  ssl_certificate /etc/nginx/ssl/git.arcana.me.crt;
>>  ssl_certificate_key /etc/nginx/ssl/git.arcana.me.key;
>>  location / {
>>    proxy_pass http://git.arcana.me:80/;
>>    proxy_pass_header Set-Cookie;
>>    proxy_pass_header P3P;
>>    proxy_set_header X-Real-IP $remote_addr;
>>    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
>>    proxy_set_header X-Forwarded-Proto $scheme;
>>    proxy_set_header X-NginX-Proxy true;
>>    proxy_cookie_domain git.arcana.me:443 git.arcana.me;
>>  }
>> }
>> server {
>>  listen 80;
>>  server_name git.arcana.me;
>>  return 301 https://$host$request_uri;
>> }
> exit
docker restart arcana.me
>> add git.arcana.me address record
>> open git.arcana.me in browser and continue setup
>> login with user root and provided password
>> setup only HTTPS access
>> setup dind (docker in docker) to integrate CI
docker network connect bridge git.arcana.me
docker exec -it git.arcana.me bash
> apt-get update
> apt-get install -y docker.io
> docker info
> docker run -td --net arcana.me --name runner.git.arcana.me -h runner.git.arcana.me --restart always -v /var/run/docker.sock:/var/run/docker.sock -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner:latest
> docker exec -it runner.git.arcana.me gitlab-runner register
>> read shared token key from gitlab admin area
>> specify "docker" executor
>> specify "ubuntu" as default image
> docker exec -it runner.git.arcana.me bash
>> apt-get update
 >>>>>>>>> SINCE IMAGE IS 14.04 (cat /etc/issue)
 >>>>>>>>> WE NEED TO MANUALLY INSTALL LATEST VERSION OF DOCKER
>> apt-get install apt-transport-https ca-certificates
>> apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
>> nano -w /etc/apt/sources.list.d/docker.list
>>> deb https://apt.dockerproject.org/repo ubuntu-trusty main
>> apt-get update
>> apt-cache policy docker-engine
>> apt-get install -y docker-engine=1.11.0-0~trusty
>> docker info
>> nano -w /etc/gitlab-runner/config.toml
??? you might need to add following inside [runners.docker] in /etc/gitlab-runner/config.toml file
??? links = ["git.arcana.me"]
# install eclipse
layman -a java
emerge --ask dev-util/eclipse-sdk-bin
# install maven
emerge --ask dev-java/maven-bin
# install maven for eclipse
Help -> Install New Software -> All Available Sites -> maven -> m2e - Maven Integration For Eclipse
# install JavaEE support for eclipse
Help -> Install New Software -> All Available Sites -> Web, XML, JavaEE and OSGi Enterprise Development
  -> Eclipse Java EE Developer Tools
  -> Eclipse Java Web Developer Tools
  -> Eclipse Web Developer Tools
  -> Eclipse XML Editors and Tools
  -> Eclipse XSL Developer Tools
  -> JavaScript Development Tools
  -> JavaScript Development Tools Chromium/V8 Remote Debugger
  -> m2e connector For mavenarchiver pom properties
  -> m2e-wtp - Maven Integration For WTP
  -> JSF Tools
  -> JSF Tools - Web Page Editor
# install VAADIN plugins
Helper -> Eclipse MarketPlace -> VAADIN plugin
# configure preferences
 Window -> Preferences -> Editors -> Text Editors -> Show line numbers

