#!/bin/bash

echo  -e "Fetching buildroot source... \t\t\t"
if [[ -d buildroot ]]; then
	echo "done!"
else
	git clone https://github.com/buildroot/buildroot.git
fi

echo  -e "Fetching kernel 5.15.11 ... \t\t\t"
if [[ -d linux ]]; then
	echo "done!"
else
	echo  -e "\tstart download ... \t\t\t"
	curl "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.11.tar.xz" --output "linux-5.15.11.tar.xz"
	echo  -e "\tdownload complete ... \t\t\t"
	echo  -e "\tstart unzip... \t\t\t"
	tar -xf "linux-5.15.11.tar.xz" 
	mv "linux-5.15.11" "linux"
	echo  -e "\tunzip complete ... \t\t\t"
	rm "linux-5.15.11.tar.xz"
fi

echo -n -e "Compiling user space app... \t\t\t"
mkdir -p buildroot/overlay/root
rm buildroot/overlay/root/*
cp apps/* buildroot/overlay/root/
for i in buildroot/overlay/root/??*.c ; do
	gcc -static $i -o ${i%.c}.o;
done
echo "done!"

echo -n -e "Compiling kernel... \t\t\t\t"
pushd linux
make x86_64_defconfig
CC="ccache gcc" make -j$(nproc)
echo "done!"
popd

echo -n -e "Adding init scripts... \t\t\t"
mkdir -p buildroot/overlay/etc/init.d
cp buildroot/output/target/etc/init.d/* buildroot/overlay/etc/init.d/
echo "echo abcdefg" > buildroot/overlay/etc/init.d/myinit
chmod 777 buildroot/overlay/etc/init.d/myinit
echo "done!"

echo -n -e "Building rootfs image... \t\t\t"
pushd buildroot
CC="ccache gcc" make -j$(nproc) &> /tmp/br_compile.log
echo "done! (log at /tmp/br_recompile.log)"
popd

# just run

qemu-system-x86_64 \
	-kernel linux/arch/x86/boot/bzImage \
	-boot c \
	-smp 1 \
	-m 1024 \
	-drive file=buildroot/output/images/rootfs.ext4,format=raw \
	-append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" \
	-serial stdio \
	-display none

