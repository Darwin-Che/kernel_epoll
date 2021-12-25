#include <stdio.h>
#include "syscall_header.h"

int main(void) {
	try_then_epoll_wait(3);
	return 0;
}

