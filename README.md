# Setup

Step 0: The required softwares are `unzip qemu git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison`. `apt install` them if not installed. 

Step 1: `./setup.sh -i` to download and prepare the env and source code for 'kernel', 'buildroot', and 'libfibre'.

Step 2 (optional): Initialize an empty repo at `linux/` to track the the source code of the kernel.

Step 3: `./setup.sh -k` to build the source code under `linux/`.

Step 4: `./setup.sh -b` to build the source code under `buildroot/` (toolchain and rootfs) and `apps/`.

Step 5: `./setup.sh -r` to run the qemu with the unmodified kernel and unmodified libfibre.

Step 6: `./usepatch.sh lx` to apply the patch to the kernel.

Step 7: `./usepatch.sh fb` to apply the patch to the libfibre.

Step 8: `./setup.sh -kbr` to rebuild the kernel and libfibre, then run the qemu for the modified kernel and libfibre

Step 9: `./usepatch.sh lx -R` to undo the patch to the kernel.

Step 10: `./usepatch.sh fb -R` to undo the patch to the libfibre.

## Key Control

Sometimes the script pauses, press Enter to continue or Ctrl-C to abort.

Inside qemu, press Ctrl-C to kill the process inside qemu, and press Ctrl-] to kill qemu itself. 

# Modified syscall

```
#define EPOLL_CTL_MEMO 2048

int epoll_ctl(int epfd, EPOLL_CTL_MEMO, int fd, struct epoll_event *event)
int epoll_ctl(int epfd, EPOLL_CTL_ADD | EPOLL_CTL_MEMO, int fd, struct epoll_event *event)
```

## syscall effects:

If `EPOLL_CTL_ADD` is present, then will perform it after `EPOLL_CTL_MEMO`. 

Register the parameters in the `struct file` of `fd`. Then these parameters with `EPOLL_CTL_ADD` will be invoked in the following conditions:

- syscalls `accept[4]`, `recv`, `recvfrom`, `recvmsg` are invoked on `fd`

- the invoked syscall returns `EAGAIN` or `EWOULDBLOCK`

If these conditions are met, then proceed to `do_epoll_memo` which have 3 cases:

- If `fd` is not already registered in `epfd`, then execute `err = epoll_ctl(epfd, EPOLL_CTL_ADD, fd, event)`

- Else If `fd` is deactivated after `ONESHOT`, then execute `err = epoll_ctl(epfd, EPOLL_CTL_MOD, fd, event)`

- Otherwise do nothing

The return value and errno of the syscalls will be `err ? : err`, 
i.e. if `epoll_ctl` fails, then the return value is the failure, 
otherwise, return `EAGAIN` or `EWOULDBLOCK`.

