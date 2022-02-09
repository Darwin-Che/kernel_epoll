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

If these conditions are met, then proceed to `do_epoll_memo` which have 3 cases:

- If `fd` is not already registered in `epfd`, then execute `err = epoll_ctl(epfd, EPOLL_CTL_ADD, fd, event)`

- Else If `fd` is deactivated after `ONESHOT`, then execute `err = epoll_ctl(epfd, EPOLL_CTL_MOD, fd, event)`

- Otherwise do nothing

The return value and errno of the syscalls will be `err ? : err`, 
i.e. if `epoll_ctl` fails, then the return value is the failure, 
otherwise, return `EAGAIN` or `EWOULDBLOCK`.

