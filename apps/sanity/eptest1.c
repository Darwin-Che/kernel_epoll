#include "header.h"

static void reset(void) {
	common_reset(1);
}

int main(void) {
	int retval;

	init();
	printf("init finished\n");

	reset();
	retval = epoll_ctl(epfd, EPOLL_CTL_ADD, accept_fd, &event);
	if (write(connect_fd, DATA, DATASZ) == -1) errExit("write connect_fd");
	retval = recv(accept_fd, buffer, sizeof(buffer), 0);
	printf("buffer is %s\n", buffer);

	// recv doesn't block, epoll_memo not executed
#if 0
	reset();
	if (write(connect_fd, DATA, DATASZ) == -1) // write in advance so that read doesn't block
		errExit("write connect_fd");
	retval = recv(accept_fd, buffer, sizeof(buffer), 0);
	printf("buffer is %s\n", buffer);
	assert_retval(retval, DATASZ, 0, "recv");
	retval = epoll_ctl(epfd, EPOLL_CTL_ADD, accept_fd, &event);
	assert_retval(retval, 0, 0, "epoll_ctl_try_add"); // should not already been added

	// recv blocks, epoll_memo executed
	reset();
	retval = recv(accept_fd, buffer, sizeof(buffer), 0);
	assert_retval(retval, 0, 0, "read_epoll_ctl");
	retval = epoll_ctl(epfd, EPOLL_CTL_ADD, accept_fd, &event);
	assert_retval(retval, -1, EEXIST, "epoll_ctl_try_add"); // should already been added

	// recv blocks, epoll_memo executed
	//reset();
	retval = recv(accept_fd, buffer, sizeof(buffer), 0);
	assert_retval(retval, 0, 0, "read_epoll_ctl");
	retval = epoll_ctl(epfd, EPOLL_CTL_ADD, accept_fd, &event);
	assert_retval(retval, -1, EEXIST, "epoll_ctl_try_add"); // should already been added

#endif

	finish();

	return 0;
}



