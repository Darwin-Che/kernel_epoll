#include <linux/kernel.h>
#include <sys/syscall.h>
#include <unistd.h>

#define __NR_recv_epoll_add 548
#define recv_epoll_add(...) \
	syscall(__NR_recv_epoll_add, \
			__VA_ARGS__)


