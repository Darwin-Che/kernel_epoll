#include "header.h"

struct sockaddr_un addr;
int listen_fd;
int accept_fd;
int connect_fd;
int epfd;

struct epoll_event event;
char buffer[100];

void errExit(const char * s) {
	printf("errExit: %s\n", s);
	finish();
	exit(1);
}

void assert_retval(int retval, int expected_retval, int expected_errno, const char * str) {
	printf("retval is %d", retval);
	if (retval < 0) {
		printf(", errno is %d", errno);
		// perror(str);
		assert(errno == expected_errno);
	}
	printf("\n");
	assert(retval == expected_retval);
}

void init(void) {
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

void finish(void) {
	close(connect_fd);
	close(accept_fd);
	close(listen_fd);
	close(epfd);
	unlink(SOCK_PATH);
}

void common_reset(int accept_fd_is_nonblocking) {
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
