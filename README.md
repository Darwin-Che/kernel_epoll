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
#define EPOLL_CTL_ONDEMAND 2048

int epoll_ctl(int epfd, EPOLL_CTL_ADD | EPOLL_CTL_ONDEMAND, int fd, struct epoll_event *event)
```

## syscall effects:

With `EPOLL_CTL_ADD | EPOLL_CTL_ONDEMAND` in `epoll_ctl()`, the `event->events` is saved separated for use in `epoll_modify_ondemand()`.

The following extra procedure is added to syscalls `accept[4]`, `recv`, `recvfrom`, `recvmsg`:

If the invoked syscall returns `EAGAIN` or `EWOULDBLOCK`, then
each epi in the list registered on this socket will be invoked with `epoll_modify_ondemand()`.
In this function, if the epi is created with `EPOLL_CTL_ONDEMAND`, and this epi is `EPOLLONESHOT`,
and this epi is deactivated by `ep_send_events()`,
then this epi is reactivated by the events stored at creation.

These syscalls will still return `EAGAIN` or `EWOULDBLOCK`.

## `epoll_modify_ondemand()` correctness

Look at all functions that read/write the `epi->event.events`:
Read-only: `ep_poll_callback()`, 
Read-write: `ep_send_events()`, `ep_modify()`, `ep_remove()`

At this stage, ignore `ep_modify()` and `ep_remove()`, assume they never happen concurrently with `ep_modify_ondemand()`.

Since `ep_poll_callback()`'s caller `sock_def_readable()` holds `wq_head->lock` for the callback functions,
so `ep_poll_callback()` won't overlap with `ep_modify_ondemand()`.

Notice that if `ep_send_events()` deactivates epi, then the related socket will be returned to the Poller, 
and the socket is bound to a recv call. If this recv call success, then it is intended that this epi is inactive.
If this recv call fails (in case that another thread fetch the received data before this thread), 
then `ep_modify_ondemand()` will be invoked again.

In conclusion, after `ep_modify_ondemand()` is invoked, at least one of the things will happen:
1) epi is active;
2) recv is called again.

Note: If both of them happen, and the recv succeed, then there is a false active epi for this socket.
So there will be a wakeup of the Poller if the next data is received while a recv call hasn't been made to this socket.

