#!/bin/bash

CF_SMP=6
CF_MEM=1024

CF_INSTALL=0
CF_BUILDROOT=0
CF_KERNEL=0
CF_RUN=1

if [[ $# -ne 0 ]]; then 

	CF_INSTALL=0
	CF_BUILDROOT=0
	CF_KERNEL=0
	CF_RUN=0
	
	while getopts "ibkrd" arg; do
		case $arg in
			i) 
				CF_INSTALL=1
				echo "Activate Install"
				;;
			b) 
				CF_BUILDROOT=1
				echo "Activate Recompile Buildroot"
				;;
			k) 
				CF_KERNEL=1
				echo "Activate Recompile Kernel"
				;;
			r) 
				CF_RUN=1
				echo "Activate Run"
				;;
			d) 
				CF_RUN=2
				echo "Activate Debug"
				;;
		esac
	done

	read
fi

function install_libfibre {

echo -e "Fetching libfibre source... \t\t\t"
mkdir -p apps
pushd apps
if [[ -d libfibre ]]; then
	echo "done!"
else 
	git clone https://git.uwaterloo.ca/mkarsten/libfibre.git
fi
if [[ -d liburing ]]; then
	echo "done!"
else
	git clone https://github.com/axboe/liburing.git
fi
popd

}

function install_buildroot {

echo  -e "Fetching buildroot source... \t\t\t"
if [[ ! -d buildroot ]]; then
	git clone https://github.com/buildroot/buildroot.git
fi
echo "cp conf/buildroot.config buildroot/.config"
cp conf/buildroot.config buildroot/.config
echo "done!"

}

function install_kernel {

echo  -e "Fetching kernel 5.15.11 ... \t\t\t"
if [[ ! -d linux ]]; then
	echo  -e "\tstart download ... \t\t\t"
	curl "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.11.tar.xz" --output "linux-5.15.11.tar.xz"
	echo  -e "\tdownload complete ... \t\t\t"
	echo  -e "\tstart unzip... \t\t\t"
	tar -xf "linux-5.15.11.tar.xz" 
	mv "linux-5.15.11" "linux"
	echo  -e "\tunzip complete ... \t\t\t"
	rm "linux-5.15.11.tar.xz"
fi
echo "cp conf/linux.config linux/.config"
cp conf/linux.config linux/.config
echo "done!"

}

function compile_kernel {

echo -n -e "Compiling kernel... \t\t\t\t"
pushd linux
CC="ccache gcc" make -j$(nproc)
if [[ $? -ne 0 ]]; then 
	echo "Compiling kernel fail"
	exit 0
fi
echo "done!"
popd

}

function compile_toolchain {

if [[ ! -f "buildroot/output/host/bin/x86_64-buildroot-linux-gnu-gcc" ]]; then
	echo -n -e "Building buildroot toolchain..."
	pushd buildroot
	CC="ccache gcc" make -j$(nproc) # &> /tmp/br_compile.log
	echo "done! (log at /tmp/br_recompile.log)"
	popd
fi

}

function compile_apps {

export PATH="$(realpath buildroot/output/host/bin):$PATH"

echo -n -e "Copying apps to overlay... \t\t\t"
mkdir -p buildroot/overlay/root
rm -rf buildroot/overlay/root/*
cp -r apps/* buildroot/overlay/root/
echo "done!"

echo -n -e "Compiling liburing... \t\t\t"
pushd buildroot/overlay/root/liburing
CC=x86_64-linux-cc CXX=x86_64-linux-g++ ./configure \
	--includedir=$(realpath ../libfibre/src) \
	--libdir=$(realpath ../libfibre/src) \
	--libdevdir=$(realpath ../libfibre/src)
pushd src
CC=x86_64-linux-cc CXX=x86_64-linux-g++ make install
popd
popd
echo "done!"

pushd buildroot/overlay/root/libfibre
ls -l .
CC=x86_64-linux-cc CXX=x86_64-linux-g++ \
	LIBS='-luring' \
	make all
popd
pushd buildroot/overlay/root/sanity
CC=x86_64-linux-cc CXX=x86_64-linux-g++ \
	make all
popd

}

function add_LD_PATH {

echo -n -e "Adding init scripts... \t\t\t"
mkdir -p buildroot/overlay/etc/
rm -rf buildroot/overlay/etc/*
cp buildroot/output/target/etc/profile buildroot/overlay/etc/profile
cat << EOT >> buildroot/overlay/etc/profile

export LD_LIBRARY_PATH="/root/libfibre/src:\$LD_LIBRARY_PATH"

EOT
chmod 777 buildroot/overlay/etc/profile
echo "done!"

}

function compile_final_buildroot {

pushd buildroot
echo -n -e "Building rootfs image... \t\t\t"
CC="ccache gcc" make -j$(nproc) # &> /tmp/br_compile.log
echo "done! (log at /tmp/br_recompile.log)"
popd

}


function run_qemu {

qemu-system-x86_64 \
		-kernel linux/arch/x86/boot/bzImage \
		-boot c \
		-smp ${CF_SMP} \
		-m ${CF_MEM} \
		-drive file=buildroot/output/images/rootfs.ext4,format=raw \
		-append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" \
		-serial stdio \
		-display none

}

function debug_qemu {

tmux split-window -h "gdb -q linux/vmlinux -ex 'target remote :1234'" \;
qemu-system-x86_64 \
		-s -S \
		-kernel linux/arch/x86/boot/bzImage \
		-boot c \
		-smp ${CF_SMP} \
		-m ${CF_MEM} \
		-drive file=buildroot/output/images/rootfs.ext4,format=raw \
		-append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" \
		-serial stdio \
		-display none

}

# ========================================================================
# ========================================================================
# ========================================================================


if [[ $CF_INSTALL = 1 ]]; then
	install_kernel
	install_buildroot
	install_libfibre
fi

if [[ $CF_KERNEL = 1 ]]; then
	compile_kernel
fi

if [[ $CF_BUILDROOT = 1 ]]; then
	compile_toolchain
	compile_apps
	add_LD_PATH
	compile_final_buildroot
fi

if [[ $CF_RUN = 1 ]]; then
	stty intr ^]
	run_qemu
	stty intr ^C
fi

if [[ $CF_RUN = 2 ]]; then
	stty intr ^]
	debug_qemu
	stty intr ^C
fi

