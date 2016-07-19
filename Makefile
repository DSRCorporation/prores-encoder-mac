CC = clang

CFLAGS_RELEASE = -O2
CFLAGS_DEBUG   = -O0 -g

ifeq ($(RELEASE),1)
	CFLAGS += $(CFLAGS_RELEASE)
else
	CFLAGS += $(CFLAGS_DEBUG)
endif

WFLAGS = -Wall \
		 -Wno-objc-missing-super-calls

FRAMEWORKS = VideoToolbox \
			 AVFoundation \
			 CoreVideo \
			 CoreMedia \
			 CoreFoundation


SOURCE_DIR = prenc/prenc
BUILD_DIR  = build
OBJS_DIR   = $(BUILD_DIR)/obj

SRCS_NAMES = prenc.m \
	   		 MovieWriter.m \
	   		 ProresEncoder.m
OBJS_NAMES = $(SRCS_NAMES:.m=.o)
BIN_NAME   = prenc

OBJS = $(addprefix $(OBJS_DIR)/, $(OBJS_NAMES))
BIN  = $(BUILD_DIR)/$(BIN_NAME)

INSTALL_DIR = /usr/local/bin


.PHONY: clean
.DEFAULT_GOAL=all

all: dir $(BIN)

$(BIN): $(OBJS)
	$(CC) -Wall -fobjc-link-runtime $(addprefix -framework , $(FRAMEWORKS)) $^ -o $@

$(OBJS_DIR)/%.o: $(SOURCE_DIR)/%.m
	$(CC) $(CFLAGS) $(WFLAGS) -std=c99 -x objective-c -c $< -o $@

install: $(BIN)
	@if test ! -d $(INSTALL_DIR); then mkdir -p $(INSTALL_DIR); fi
	cp -f $(BIN) $(INSTALL_DIR)

uninstall:
	rm -f $(INSTALL_DIR)/$(BIN_NAME)

dir:
	@mkdir -p $(OBJS_DIR)

ctags:
	ctags -R --languages=ObjectiveC --langmap=ObjectiveC:.h.m .

clean:
	rm -rf $(BUILD_DIR)
