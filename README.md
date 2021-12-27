# Setup

Download kernel source from https://www.kernel.org/. This implementation uses the most recent stable version 5.15.11.

Download kernel build tool `git clone https://github.com/buildroot/buildroot.git`.

# New syscall

syscall number: `548`

syscall name: `read_epoll_ctl`

syscall param: 

```
int fd -> the socket fd
void * buf -> the buffer for read
size_t count -> the size of buf
int epfd -> the epoll fd
int op -> the epoll_ctl op
struct epoll_event * event -> the epoll_ctl event
```

