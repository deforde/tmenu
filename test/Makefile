TARGET_NAME := test

UNITY_ROOT_DIR := Unity
UNITY_LIB := $(UNITY_ROOT_DIR)/build/libunity.a
UNITY_INC_DIR := $(UNITY_ROOT_DIR)/src

BASE_BUILD_DIR := build
BUILD_DIR := $(BASE_BUILD_DIR)/test_build
SRC_DIRS := src ../src
SRCS := $(filter-out ../src/main.c,$(shell find $(SRC_DIRS) -name '*.c'))
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

INC_DIRS := $(shell find $(SRC_DIRS) -type d)
INC_DIRS += ncurses/include/ncurses
INC_DIRS += $(UNITY_INC_DIR)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

CFLAGS := -Wall -Wextra -Wpedantic -Werror $(INC_FLAGS) -MMD -MP -fsanitize=address,undefined
LDFLAGS := $(UNITY_LIB) -fsanitize=address,undefined

TARGET := $(BASE_BUILD_DIR)/$(TARGET_NAME)

.PHONY: all build-only

all: unity $(TARGET)
	./$(TARGET)

clean:
	rm -rf $(BASE_BUILD_DIR)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

unity: $(UNITY_LIB)

$(UNITY_LIB):
	git clone https://github.com/ThrowTheSwitch/Unity && \
	mkdir -p Unity/build && \
	cd Unity/build && \
	cmake .. && \
	cmake --build . -j 7

build-only: clean unity $(TARGET)

-include $(DEPS)
