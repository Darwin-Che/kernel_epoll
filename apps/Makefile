CC := ../buildroot/output/host/bin/x86_64-buildroot-linux-gnu-gcc

TESTLIST = recv recvfrom recvmsg

.PHONY : all clean

all : bin/runtest.sh $(patsubst %, bin/%, $(TESTLIST))

clean : 
	rm -f bin/*

bin/% : %.o common.o
	${CC} $^ -o $@

bin/runtest.sh : runtest.sh
	cp runtest.sh bin/
	
