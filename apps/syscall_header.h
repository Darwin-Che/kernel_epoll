#include <linux/kernel.h>
#include <sys/syscall.h>
#include <unistd.h>

#define __NR_read_epoll_ctl 548
#define read_epoll_ctl(...) \
	syscall(__NR_read_epoll_ctl, \
			__VA_ARGS__)


