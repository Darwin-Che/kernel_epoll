#include <linux/kernel.h>
#include <sys/syscall.h>
#include <unistd.h>

#define __NR_try_then_epoll_wait 548
#define try_then_epoll_wait(...) \
	syscall(__NR_try_then_epoll_wait, \
			__VA_ARGS__)


