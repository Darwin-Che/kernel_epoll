#!/bin/bash

CONFIG_SMP=1
CONFIG_MEM=1024

CONFIG_RUN=1
CONFIG_BUILD=1

while getopts "rbds" arg; do
	case $arg in
		r) 
			CONFIG_RUN=0
			echo "only build -----"
			;;
		b) 
			CONFIG_BUILD=0
			echo "only download ----"
			;;
		d) 
			CONFIG_RUN=2
			echo "enable debug ----"
			;;
	esac
done
			

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
	pushd linux
	git init
	git add .
	git commit -m "init"
	popd
fi

if [[ ${CONFIG_BUILD} -eq 0 ]]; then
	echo "donwload done!"
	exit 0
fi

echo -n -e "Compiling kernel... \t\t\t\t"
pushd linux
CC="ccache gcc" make -j$((2*$(nproc)))
if [[ $? -ne 0 ]]; then 
	echo "Compiling kernel fail"
	exit 0
fi
echo "done!"
popd

if [[ ! -f "buildroot/output/host/bin/x86_64-buildroot-linux-gnu-gcc" ]]; then
	echo -n -e "Building buildroot toolchain..."
	pushd buildroot
	CC="ccache gcc" make -j$((2*$(nproc))) # &> /tmp/br_compile.log
	echo "done! (log at /tmp/br_recompile.log)"
	popd
fi

export PATH="$(realpath buildroot/output/host/bin):$PATH"

echo -n -e "Compiling user space app... \t\t\t"
mkdir -p buildroot/overlay/root
rm -rf buildroot/overlay/root/*
pushd apps/sanity
CC=x86_64-linux-cc CXX=x86_64-linux-g++ make all
popd
pushd apps/libfibre
CC=x86_64-linux-cc CXX=x86_64-linux-g++ make all
popd
cp -r apps/* buildroot/overlay/root/
echo "done!"

echo -n -e "Adding init scripts... \t\t\t"
mkdir -p buildroot/overlay/etc/
rm -rf buildroot/overlay/etc/*
cp buildroot/output/target/etc/profile buildroot/overlay/etc/profile
cat << EOT >> buildroot/overlay/etc/profile

export LD_LIBRARY_PATH="/root/libfibre/src:\$LD_LIBRARY_PATH"

EOT
chmod 777 buildroot/overlay/etc/profile
echo "done!"

pushd buildroot
echo -n -e "Building rootfs image... \t\t\t"
CC="ccache gcc" make -j$((2*$(nproc))) # &> /tmp/br_compile.log
echo "done! (log at /tmp/br_recompile.log)"
popd

# just run
if [[ ${CONFIG_RUN} -eq 1 ]]; then
	qemu-system-x86_64 \
		-kernel linux/arch/x86/boot/bzImage \
		-boot c \
		-smp ${CONFIG_SMP} \
		-m ${CONFIG_MEM} \
		-drive file=buildroot/output/images/rootfs.ext4,format=raw \
		-append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" \
		-serial stdio \
		-display none
fi

if [[ ${CONFIG_RUN} -eq 2 ]]; then
	tmux split-window -h "gdb -q linux/vmlinux -ex 'target remote :1234'" \;
	qemu-system-x86_64 \
		-s -S \
		-kernel linux/arch/x86/boot/bzImage \
		-boot c \
		-smp ${CONFIG_SMP} \
		-m ${CONFIG_MEM} \
		-drive file=buildroot/output/images/rootfs.ext4,format=raw \
		-append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" \
		-serial stdio \
		-display none
fi

