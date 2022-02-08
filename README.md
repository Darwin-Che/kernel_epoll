# Setup

Download kernel source from https://www.kernel.org/. This implementation uses the most recent stable version 5.15.11.

Download kernel build tool `git clone https://github.com/buildroot/buildroot.git`.

Download libfibre from `git clone https://git.uwaterloo.ca/mkarsten/libfibre.git`, place it in `apps/`.

# Modified syscall

```
#define EPOLL_CTL_MEMO 2048

int epoll_ctl(int epfd, EPOLL_CTL_MEMO, int fd, struct epoll_event *event)
int epoll_ctl(int epfd, EPOLL_CTL_ADD | EPOLL_CTL_MEMO, int fd, struct epoll_event *event)
```

## syscall effects:

If `EPOLL_CTL_ADD` is present, then do it before memo. 

Register the parameters in the `struct file` of `fd`. Then these parameters with `EPOLL_CTL_ADD` will be invoked in the following conditions:

- syscalls `accept[4]`, `recv`, `recvfrom`, `recvmsg` are invoked on `fd`

- the invoked syscall returns `EAGAIN` or `EWOULDBLOCK`

- `fd` is not already registered in `epfd`

If these conditions are met, then the return value of the syscall (including `errno`) will be the result of 
`epoll_ctl` invoked with the registered parameters.
