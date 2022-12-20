TARGET_NAME := tmenu

BUILD_DIR := build
SRC_DIRS := src
TEST_DIR := test

SRCS := $(shell find $(SRC_DIRS) -name '*.c')
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
INC_DIRS += ncurses/include/ncurses
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

CFLAGS := -Wall -Wextra -Wpedantic -Werror $(INC_FLAGS) -MMD -MP
LDFLAGS := -lncurses -lmenu

TARGET := $(BUILD_DIR)/$(TARGET_NAME)

all: CFLAGS += -O3 -DNDEBUG
all: target

debug: CFLAGS += -g3 -D_FORTIFY_SOURCE=2
debug: target

san: debug
san: CFLAGS += -fsanitize=address,undefined
san: LDFLAGS += -fsanitize=address,undefined

target: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean compdb run test valgrind test-compdb

run: san
	./$(TARGET)

test:
	$(MAKE) -C $(TEST_DIR)

clean:
	rm -rf $(BUILD_DIR)
	$(MAKE) -C $(TEST_DIR) clean

compdb: clean
	bear -- $(MAKE) san
	mv compile_commands.json build

test-compdb:
	bear -- $(MAKE) -C $(TEST_DIR) build-only
	mkdir -p build
	mv compile_commands.json build

valgrind: debug
	valgrind ./$(TARGET)

install: all
	cp build/tmenu $$HOME/.local/bin/tmenu

dev-install: all
	ln -s -f $(realpath build/tmenu) $$HOME/.local/bin/tmenu

-include $(DEPS)
