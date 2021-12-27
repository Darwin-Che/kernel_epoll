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
	

static void old_syscall(void) {
}

static void new_syscall(void) {
}

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

static void reset(void) {
}

int main(void) {
	int opt;
	int retval;

	init();
	printf("init finished\n");

	// accept_fd is not nonblocking
	reset();

	memset(&event, 0x0, sizeof(event));
	event.events = EPOLLIN;
	event.data.fd = accept_fd;
	retval = read_epoll_ctl(accept_fd, buffer, sizeof(buffer),
			epfd, EPOLL_CTL_ADD, &event);
	if (retval != 0) perror("read_epoll_ctl");
	printf("retval is %d\n", retval);
	assert(retval == -1);
	

	// read doesn't block, epoll_ctl not executed
	reset();
	opt = fcntl(accept_fd, F_GETFL);
	if (opt < 0)
		errExit("getfl");
	if (fcntl(accept_fd, F_SETFL, opt | O_NONBLOCK) < 0)
		errExit("setfl");

	if (write(connect_fd, DATA, DATASZ) == -1) 
		errExit("write connect_fd");
	memset(&event, 0x0, sizeof(event));
	event.events = EPOLLIN;
	event.data.fd = accept_fd;
	retval = read_epoll_ctl(accept_fd, buffer, sizeof(buffer),
			epfd, EPOLL_CTL_ADD, &event);
	if (retval != 0) perror("read_epoll_ctl");
	printf("retval is %d\n", retval);
	assert(retval == 0);
	
	// read blocks, epoll_ctl executed

	// cleanup
	close(connect_fd);
	close(accept_fd);
	close(listen_fd);
	unlink(SOCK_PATH);

	return 0;
}




	


