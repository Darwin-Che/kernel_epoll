# Setup

Download kernel source from https://www.kernel.org/. This implementation uses the most recent stable version 5.15.11.

Download kernel build tool `git clone https://github.com/buildroot/buildroot.git`.

# New syscall

syscall number: `548`

syscall name: `recv_epoll_add(int fd, void *buf, size_t count, unsigned flags, int epfd, struct epoll_event *event)`

syscall param: 

```
int fd -> the socket fd
void * buf -> the buffer for recv
size_t count -> the size of buf
unsigned flags -> recv flags
int epfd -> the epoll fd
struct epoll_event * event -> the epoll_ctl event
```

syscall effects:

1) assert that `fd` is in `O_NONBLOCK` mode.

2) try `recv(fd, buf, count, flags)`, if the result is not `EAGAIN` or `EWOULDBLOCK`, then proceed to return the results.

3) otherwise, perform `epoll_ctl(epfd, EPOLL_CTL_ADD, fd, event)`, and return the results. 

syscall return values:

1) If `fd` is not in `O_NONBLOCK` mode, return $-1$, and `errno = EINVAL`.

2) If `recv` success, then return the number of bytes read into buf, which should be non-negative.

3) If `recv` fails but not `EAGAIN` or `EWOULDBLOCK`, then return $-1$ and `errno` is set by `recv` correspondingly.

4) If `recv` returns `EAGAIN` or `EWOULDBLOCK`, and `epoll_ctl` success, returns $0$.

5) If `recv` returns `EAGAIN` or `EWOULDBLOCK`, and `epoll_ctl` fails, returns $-1$ and `errno` is set by `epoll_ctl` correspondingly.

