TESTLIST = eptest1 # recv recvfrom recvmsg

.PHONY : all clean

all : $(TESTLIST)

clean : 
	rm -f $(TESTLIST) *.o

$(TESTLIST) : % : %.o common.o
	${CC} $^ -o $@

%.o : %.c
	${CC} $^ -c -o $@
