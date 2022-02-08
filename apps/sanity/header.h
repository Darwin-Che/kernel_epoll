#include <sys/epoll.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <errno.h>
#include <unistd.h>

#define EPOLL_CTL_MEMO	2048

#define SOCK_PATH "/tmp/test_epoll_ctrl"

#define DATA "abcdefg"
#define DATASZ sizeof(DATA)

extern struct sockaddr_un addr;
extern int listen_fd;
extern int accept_fd;
extern int connect_fd;

extern int epfd;
extern struct epoll_event event;
extern char buffer[100];
#define BUFCAP 100

void errExit(const char * s);

void assert_retval(int retval, int expected_retval, int expected_errno, const char * str);

void init(void);

void finish(void);

void common_reset(int accept_fd_is_nonblocking);
