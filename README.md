# EPOLLONDEMAND

## Background

For description/justification of this kernel patch, please read `epollondemand.txt`.

A user-level threading library 'libfibre' has adopted an option to use this patch.
Here is the link: [libfibre](https://git.uwaterloo.ca/mkarsten/libfibre)

## Setup

Step 0: The required softwares are `unzip qemu git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison`. `apt install` them if not installed. 

Step 1: `./setup.sh -i` to download and prepare the env and source code for 'kernel', 'buildroot', and 'libfibre'.

Step 2 (optional): Initialize an empty repo at `linux-5.4/` to track the the source code of the kernel.

Step 3: `./setup.sh -k` to build the source code under `linux-5.4/`.

Step 4: `./setup.sh -b` to build the source code under `buildroot/` (toolchain and rootfs) and `apps/`.

Step 5: `./setup.sh -r` to run the qemu with the unmodified kernel and unmodified libfibre.

Step 6: `./usepatch.sh lx` to apply the patch to the kernel.

Step 7: `./setup.sh -kbr` to rebuild the kernel and libfibre, then run the qemu for the modified kernel and libfibre

Step 8: `./usepatch.sh lx -R` to undo the patch to the kernel.

## Key Control

Sometimes the script pauses, press Enter to continue or Ctrl-C to abort.

Inside qemu, press Ctrl-C to kill the process inside qemu, and press Ctrl-] to kill qemu itself. 
