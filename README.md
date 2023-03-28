# Starfive Visionfive2 Debian Image builder

This is a quick way to build a sd card image for a Starfive Visionfive 2 board. The idea it to keep it as simple as possible. It uses vmdb2 to build an image from vanilla Debian, eg you can be sure of provenance, rather than getting an image from a random google drive. Details on the build can be seen in visionfive2.yaml. Obviously because of this some of the hardware might not function, but serial console and ethernet works which fill my usecase.

It assumes that the board already has opensbi and u-boot on the SPI storage and the board is configured to boot from SPI with vanilla settings. However v2.11.5 is copied from https://github.com/starfive-tech/VisionFive2/releases/ and are stored in /boot/fw to allow updating:

```
cd /boot
flashcp -v u-boot-spl.bin.normal.out /dev/mtd0
flashcp -v visionfive2_fw_payload.img  /dev/mtd1
```

The move from v2.10.4 to v2.11.5 where mtd0 increased in size required me to perform firmware update in uboot via sftp following https://doc-en.rvspace.org/VisionFive2/Quick_Start_Guide/VisionFive2_SDK_QSG/updating_spl_and_u_boot%20-%20vf2.html

The kernel is from https://github.com/starfive-tech/linux/ and is compiled on 28th March 2023 (https://github.com/starfive-tech/linux/tree/a87c6861c6d96621026ee53b94f081a1a00a4cc7 tag: VF2_v2.11.5) with starfive instructions using the deb-pkg to create a deb, the resultant kernel deb is in this repo and is installed during the vmdb2 run. This was done with:

```
git clone git@github.com:starfive-tech/linux.git -b JH7110_VisionFive2_devel
cd linux
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- starfive_jh7110_defconfig
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- LOCALVERSION=-custom deb-pkg
```

There is a little work to try to build in a container, however this does not work yet, see: Dockerfile and build.sh.

A sample run looks like:
```
~/src/starfive-visionfive2 $ sudo vmdb2 --verbose --output visionfive2.img visionfive2.yaml
Load spec file visionfive2.yaml
Exec: ['dpkg', '--print-architecture']
Exec: ['qemu-img', 'create', '-f', 'raw', 'visionfive2.img', '1000M']
Exec: ['parted', '-s', 'visionfive2.img', 'mklabel', 'gpt']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['parted', '-s', 'visionfive2.img', '--', 'mkpart', 'spl', 'ext2', '2MiB', '4MiB']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['parted', '-s', 'visionfive2.img', '--', 'mkpart', 'uboot', 'ext2', '4MiB', '8MiB']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['parted', '-s', 'visionfive2.img', '--', 'mkpart', 'boot', 'fat32', '8MiB', '128MiB']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['parted', '-s', '/home/thomas/src/starfive-visionfive2/visionfive2.img', '--', 'set', '3', 'boot', 'on']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['parted', '-s', 'visionfive2.img', '--', 'mkpart', 'root', 'ext2', '128MiB', '100%']
Exec: ['parted', '-m', 'visionfive2.img', 'print']
Exec: ['kpartx', '-asv', 'visionfive2.img']
remembering /dev/mapper/loop0p1 as spl
remembering /dev/mapper/loop0p2 as uboot
remembering /dev/mapper/loop0p3 as boot
remembering /dev/mapper/loop0p4 as root
Exec: ['/sbin/mkfs', '-t', 'vfat', '-n', 'boot', '/dev/mapper/loop0p3']
Exec: ['blkid', '-c/dev/null', '-ovalue', '-sUUID', '/dev/mapper/loop0p3']
Exec: ['/sbin/mkfs', '-t', 'ext4', '-L', 'root', '/dev/mapper/loop0p4']
Exec: ['blkid', '-c/dev/null', '-ovalue', '-sUUID', '/dev/mapper/loop0p4']
Exec: ['mount', '/dev/mapper/loop0p4', '/tmp/tmpm1ye7pn_']
Exec: ['mount', '/dev/mapper/loop0p3', '/tmp/tmpm1ye7pn_/.//boot']
Exec: ['qemu-debootstrap', '--keyring', '/usr/share/keyrings/debian-ports-archive-keyring.gpg', '--arch', 'riscv64', '--variant', '-', '--components', 'main', 'sid', '/tmp/tmpm1ye7pn_', 'http://deb.debian.org/debian-ports']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'apt-get', 'update']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'apt-get', 'update']
crypts: []
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'apt-get', 'update']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'apt-get', '-y', '--no-show-progress', '', 'install', 'eatmydata']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'eatmydata', 'apt-get', 'update']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'eatmydata', 'apt-get', '-y', '--no-show-progress', '', 'install', 'debian-ports-archive-keyring', 'initramfs-tools', 'mtd-utils', 'ssh', 'systemd-timesyncd', 'u-boot-menu', 'wget']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'apt-get', 'clean']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'sh', '-ec', 'mkdir /boot/fw /boot/dtbs\ncd /boot/fw\nwget https://github.com/starfive-tech/VisionFive2/releases/download/VF2_v2.8.0/u-boot-spl.bin.normal.out\nwget https://github.com/starfive-tech/VisionFive2/releases/download/VF2_v2.8.0/visionfive2_fw_payload.img\n\nwget https://raw.githubusercontent.com/thomasdstewart/starfive-visionfive2/main/linux-image-5.15.0-custom-dirty_5.15.0-custom-dirty-1_riscv64.deb\napt-get install ./linux-image-5.15.0-custom-dirty_5.15.0-custom-dirty-1_riscv64.deb\nrm linux-image-5.15.0-custom-dirty_5.15.0-custom-dirty-1_riscv64.deb\ncp /usr/lib/linux-image-5.15.0-custom-dirty/starfive/jh7110-visionfive-v2.dtb /boot/dtbs\n\necho "U_BOOT_PARAMETERS=\\"rw quiet console=ttyS0,115200 earlycon rootwait\\"" >> /etc/default/u-boot\necho "U_BOOT_ROOT=\\"root=LABEL=root\\""                                       >> /etc/default/u-boot\necho "U_BOOT_FDT=\\"dtbs/jh7110-visionfive-v2.dtb\\""                          >> /etc/default/u-boot\nu-boot-update']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'sh', '-ec', 'echo "visionfive2" > /etc/hostname\necho "nameserver 8.8.8.8" > /etc/resolv.conf']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'sh', '-ec', 'systemctl enable generate-ssh-host-keys.service']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'sh', '-ec', 'echo "starfive\\nstarfive\\n" | passwd root\necho "starfive\\nstarfive\\n" | adduser --comment user user']
Exec: ['chroot', '/tmp/tmpm1ye7pn_', 'sh', '-ec', 'rm -rf /var/lib/apt/lists\nrm -f /etc/machine-id /var/lib/dbus/machine-id\nrm -f /etc/ssh/ssh_host_*_key*']
WARNING:root:Not mounted: /tmp/tmpm1ye7pn_/.//boot
Exec: ['zerofree', '-v', '/dev/mapper/loop0p4']
Exec: ['kpartx', '-dsv', 'visionfive2.img']
Exec: ['losetup', '--json', '-l', '/dev/loop0']
All went fine.
~/src/starfive-visionfive2 $
```

The resultant img can then be copied to an sd card
```
~/src/starfive-visionfive2 $ ls -la visionfive2.img 
-rw-r--r-- 1 root root 1000M Feb  7 10:05 visionfive2.img
~/src/starfive-visionfive2 $
```
