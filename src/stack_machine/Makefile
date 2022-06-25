CC = gcc
LEX = flex
YACC = bison
LFLAGS =
#CFLAGS = -g -Wall -DDEBUG_ALL -DSHOW_REDUCE -DSHOW_LINE -DSHOW_INFO
#CFLAGS = -g -Wall -DSHOW_LINE
#CFLAGS = -g -Wall -DDEBUG_ALL
CFLAGS = -g -Wall
YFLAGS = -vd

SRCS = lex.yy.c gram.tab.c idhash.c
OBJS = lex.yy.o gram.tab.o idhash.o

all: $(SRCS) $(OBJS)
	$(CC) -o sim $(CFLAGS) $(LFLAGS) $(OBJS)

lex.yy.c	: asm.l
	$(LEX) asm.l

gram.tab.h gram.tab.c	: gram.y
	$(YACC) $(YFLAGS) gram.y

.c.o	:
	$(CC) -c $(CFLAGS) $<

clean:
	rm -f sim *.o lex.yy.c gram.tab.c gram.tab.h
