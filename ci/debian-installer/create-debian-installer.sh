#!/bin/bash

ISO_IN=${ISO_IN:-debian-11.2.0-amd64-netinst.iso}
ISO_OUT=${ISO_OUT:-packetfence-debian-installer.iso}

if ! [ -f $ISO_IN ]; then
	wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$ISO_IN
fi

rm -fr isofiles/

cat preseed.cfg.tmpl | sed "s/%%PF_VERSION%%/$PF_RELEASE/g"  > preseed.cfg

xorriso -osirrox on -indev $ISO_IN -extract / isofiles

chmod +w -R isofiles/install.amd/
gunzip isofiles/install.amd/initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
gzip isofiles/install.amd/initrd
chmod -w -R isofiles/install.amd/

cd isofiles
chmod +w md5sum.txt
find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt
chmod -w md5sum.txt
cd ..

genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $ISO_OUT isofiles

rm -fr isofiles/

