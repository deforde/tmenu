TARGET_NAME := tmenu

BUILD_DIR := build
SRC_DIRS := src

SRCS := $(shell find $(SRC_DIRS) -name '*.c')
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

CFLAGS := -Wall -Wextra -Wpedantic -Werror $(INC_FLAGS) -MMD -MP
LDFLAGS :=

TARGET := $(BUILD_DIR)/$(TARGET_NAME)

all: CFLAGS += -O3 -DNDEBUG
all: target

debug: CFLAGS += -g3 -D_FORTIFY_SOURCE=2
debug: target

san: debug
san: CFLAGS += -fsanitize=address,undefined
san: LDFLAGS += -fsanitize=address,undefined

target: ncurses $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean compdb valgrind

clean:
	@rm -rf $(BUILD_DIR)

compdb: clean
	@bear -- $(MAKE) san
	@mv compile_commands.json build

valgrind: debug
	@valgrind ./$(TARGET)

ncurses:
	mkdir ncurses-src
	curl -L https://invisible-island.net/datafiles/release/ncurses.tar.gz | \
	tar -C ncurses-src --strip-components=1 -xz
	cd ncurses-src && \
	./configure --prefix=$$PWD/../ncurses --with-install-prefix= && \
	make install

-include $(DEPS)
