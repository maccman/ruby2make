#
#CXX=gcc
#OFILES=uthread.o test_threads.o
#OUTFILE=threadpkg
#FLAGS=-D__MAKECONTEXT_V2_SOURCE -Wall
#
#.SUFFIXES: .o .c
#
#all:	$(OFILES)
#	$(CXX) $(FLAGS) $(OFILES) -o $(OUTFILE)
#
#threadpkg: $(OFILES)
#   $(CXX) $(FLAGS) $(OFILES) -o $(OUTFILE)
#
#library: 	
#	$(CXX) $(FLAGS) -c uthread.c -o uthread.o
#
#clean:
#	rm -f *.o *~
#	rm -f $(OUTFILE)
#
#uthread.o: uthread.c uthread.h
#main.o: main.c uthread.c uthread.h

vars :CXX => "gcc", :OFILES => "uthread.o test_threads.o",
     :OUTFILE => "threadpkg", :FLAGS => "-D__MAKECONTEXT_V2_SOURCE -Wall"
