TARGET_NAME := tmenu

BUILD_DIR := build
SRC_DIRS := src

SRCS := $(shell find $(SRC_DIRS) -name '*.c')
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
INC_DIRS += ncurses/include/ncurses
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

CFLAGS := -Wall -Wextra -Wpedantic -Werror $(INC_FLAGS) -MMD -MP
LDFLAGS := -lncurses

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

.PHONY: clean compdb test valgrind

test: san
	./$(TARGET)

clean:
	rm -rf $(BUILD_DIR)

compdb: clean
	bear -- $(MAKE) san
	mv compile_commands.json build

valgrind: debug
	valgrind ./$(TARGET)

-include $(DEPS)
