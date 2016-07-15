CC = clang

.PHONY: clean
.DEFAULT_GOAL=all

SRCS := src/prenc.m
OBJS := $(SRCS:.m=.o)
#HEADERS := $(wildcard *.h)
BIN := prenc

#%.c: $(HEADERS)

#%.o: %.c $(HEADERS)
%.o: %.m
	$(CC) -Wall -g -std=c99 -x objective-c $(CFLAGS) -c $*.m -o $*.o

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) -Wall -g -fobjc-link-runtime $< -o $@ -framework VideoToolbox -framework CoreFoundation -framework CoreMedia -framework CoreVideo -framework AVFoundation

clean:
	rm -f src/*.o $(BIN)
