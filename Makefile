CC=$(TARGET)gcc

.PHONY: clean
.DEFAULT_GOAL=all

SRCS := src/prenc.c
OBJS := $(SRCS:.c=.o)
#HEADERS := $(wildcard *.h)
BIN := prenc

#%.c: $(HEADERS)

#%.o: %.c $(HEADERS)
%.o: %.c
	$(CC) -Wall -g -std=gnu99 $(CFLAGS) -c $*.c -o $*.o

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) -Wall -g $< -o $@ -framework VideoToolbox -framework CoreFoundation

clean:
	rm -f *.o $(BIN)
