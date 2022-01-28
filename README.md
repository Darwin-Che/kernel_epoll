# Setup

Download kernel source from https://www.kernel.org/. This implementation uses the most recent stable version 5.15.11.

Download kernel build tool `git clone https://github.com/buildroot/buildroot.git`.

# Modified syscall

```
int epoll_ctl(int epfd, EPOLL_CTL_MEMO, int fd, struct epoll_event *event)
```

## syscall effects:

Register the parameters with the `struct file` related to `fd`. Then these parameters with `EPOLL_CTL_ADD` will be invoked in the following conditions:

- syscalls `recv`, `recvfrom`, `recvmsg` are invoked on `fd`

- the invoked syscall returns `EAGAIN` or `EWOULDBLOCK`

If the conditions are met, then the return value of the syscall (including `errno`) will be the result of 
`epoll_ctl` invoked with the registered parameters.
