#include <sys/epoll.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <errno.h>
#include "syscall_header.h"

#define SOCK_PATH "/tmp/test_epoll_ctrl"

const char * DATA = "abcdefg";
const size_t DATASZ = sizeof(DATA);

void errExit(const char * s) {
	printf("errExit: %s\n", s);
	exit(1);
}

static struct sockaddr_un addr;
static int listen_fd;
static int accept_fd;
static int connect_fd;

static int epfd;
static struct epoll_event event;
static char buffer[100];

static void init(void) {
	// init socket fds
	memset(&addr, 0x0, sizeof(struct sockaddr_un));
	addr.sun_family = AF_UNIX;
	strncpy(addr.sun_path, SOCK_PATH, sizeof(addr.sun_path) - 1);

	listen_fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (listen_fd == -1) 
		errExit("create listen_fd");
	printf("listen_fd : %d\n", listen_fd);
	
	if (bind(listen_fd, (struct sockaddr *) &addr, sizeof(struct sockaddr_un)) == -1)
		errExit("bind socket");

	if (listen(listen_fd, 5) == -1)
		errExit("listen");

	connect_fd = socket(AF_UNIX, SOCK_STREAM, 0);
	if (connect_fd == -1) 
		errExit("create connect_fd");
	if (connect(connect_fd, (struct sockaddr *) &addr, sizeof(struct sockaddr_un)) == -1)
		errExit("connect");
	printf("connect_fd : %d\n", connect_fd);

	accept_fd = accept(listen_fd, NULL, NULL);
	printf("accept_fd: %d\n", accept_fd);

	// init epoll interface
	epfd = epoll_create(5);
}

static void reset(int accept_fd_is_nonblocking) {
	int opt;

	epoll_ctl(epfd, EPOLL_CTL_DEL, accept_fd, &event);

	opt = fcntl(accept_fd, F_GETFL);  
	if (opt < 0) errExit("getfl");
	if (accept_fd_is_nonblocking) {
		if (fcntl(accept_fd, F_SETFL, opt | O_NONBLOCK) < 0) // set O_NONBLOCK for accept_fd
			errExit("setfl");
	} else {
		if (fcntl(accept_fd, F_SETFL, opt & ~O_NONBLOCK) < 0) // unset O_NONBLOCK for accept_fd
			errExit("setfl");
	}

	memset(&event, 0x0, sizeof(event));
	event.events = EPOLLIN;
	event.data.fd = accept_fd;

	memset(buffer, 0x0, sizeof(buffer));
}

static void assert_retval(int retval, int expected_retval, int expected_errno, const char * str) {
	printf("retval is %d", retval);
	if (retval < 0) {
		printf(", errno is %d", errno);
		// perror(str);
		assert(errno == expected_errno);
	}
	printf("\n");
	assert(retval == expected_retval);
}

int main(void) {
	int retval;

	init();
	printf("init finished\n");

	// accept_fd is not nonblocking
	reset(0);
	retval = read_epoll_ctl(accept_fd, buffer, sizeof(buffer),
			epfd, EPOLL_CTL_ADD, &event);
	assert_retval(retval, -1, EINVAL, "read_epoll_ctl");
	

	// read doesn't block, epoll_ctl not executed
	reset(1);
	if (write(connect_fd, DATA, DATASZ) == -1) // write in advance so that read doesn't block
		errExit("write connect_fd");
	retval = read_epoll_ctl(accept_fd, buffer, sizeof(buffer),
			epfd, EPOLL_CTL_ADD, &event);
	printf("buffer is %s\n", buffer);
	assert_retval(retval, DATASZ, 0,"read_epoll_ctl");
	
	// read blocks, epoll_ctl executed
	reset(1);
	retval = read_epoll_ctl(accept_fd, buffer, sizeof(buffer),
			epfd, EPOLL_CTL_ADD, &event);
	assert_retval(retval, 0, 0, "read_epoll_ctl");
	retval = epoll_ctl(epfd, EPOLL_CTL_ADD, accept_fd, &event);
	assert_retval(retval, -1, EEXIST, "epoll_ctl_try_add");

	// cleanup
	close(connect_fd);
	close(accept_fd);
	close(listen_fd);
	unlink(SOCK_PATH);

	return 0;
}



