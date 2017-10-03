# Copyright 2017 Johannes Schriewer <hallo@dunkelstern.de>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# name for the target project
PROJECT     := ws2812_i2s
TARGET		:= $(addsuffix .a,$(addprefix lib,$(PROJECT)))

BUILD_DIR   ?= build

# source code to compile
SRC		    := $(wildcard src/*.c)
OBJ		    := $(patsubst %.c,$(BUILD_DIR)/%.o,$(SRC))
INCDIR	    := -I./include  -I./src
INCDIR      +=

LIB_SDK_INCDIR ?= include include/espressif extra_include

CFLAGS      ?= -Os -Wpointer-arith -Wundef -fno-inline-functions -Werror
CFLAGS      += -DLED_TYPE=LED_TYPE_WS2812 -DLED_MODE=LED_MODE_RGB
CFLAGS      += -Wl,-EL -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ \
               -DICACHE_FLASH -ffunction-sections -fdata-sections -fno-builtin-printf \
               -fno-jump-tables --std=c99

# OS-Detection
ifeq ($(OS),Windows_NT)
    OS = Windows
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        OS = Linux
    endif
    ifeq ($(UNAME_S),Darwin)
        OS = Darwin
    endif
endif

# base directory for the compiler
# base directory of the ESP8266 SDK package, absolute
# serial port to use for flashing
# esptool.py path
ifeq ($(OS),Windows)
    XTENSA_TOOLS_ROOT ?= /c/ESP8266/xtensa-lx106-elf/bin
    SDK_PATH          ?= /c/ESP8266/ESP8266_RTOS_SDK
endif
ifeq ($(OS),Darwin)
    XTENSA_TOOLS_ROOT ?= /Volumes/ESP8266/esp-open-sdk/xtensa-lx106-elf/bin
    SDK_PATH          ?= /Volumes/ESP8266/ESP8266_RTOS_SDK
endif
ifeq ($(OS),Linux)
    XTENSA_TOOLS_ROOT ?= /opt/Espressif/crosstool-NG/builds/xtensa-lx106-elf/bin
    SDK_PATH          ?= /opt/Espressif/ESP8266_RTOS_SDK
endif

# select which tools to use as compiler, librarian and linker
CC := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
AR := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD := $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc

####
#### no user configurable options below here
####

TARGET          := $(addprefix $(BUILD_DIR)/../,$(TARGET))
DEP             := $(patsubst %.c,$(BUILD_DIR)/%.d,$(SRC))
LIB_SDK_INCDIR  := $(addprefix -I$(SDK_PATH)/,$(LIB_SDK_INCDIR))

V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

vpath %.c $(SRC_DIR)

.PHONY: all checkdirs flash clean

all: checkdirs $(TARGET)

$(TARGET): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

checkdirs: $(BUILD_DIR) $(BUILD_DIR)/src

$(BUILD_DIR)/src:
	$(Q) mkdir -p $(BUILD_DIR)/src

$(BUILD_DIR):
	$(Q) mkdir -p $@

clean:
	$(vecho) "Clean $(abspath $(TARGET))"
	$(Q) rm -f $(abspath $(TARGET))
	$(vecho) "Clean $(BUILD_DIR)"
	$(Q) rm -rf $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.c
	$(vecho) "CC $<"
	$(Q) $(CC) $(INCDIR) $(LIB_SDK_INCDIR) $(SDK_INCDIR) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.d: %.c $(BUILD_DIR)/src
	$(vecho) "Depend $<"
	$(Q) set -e; rm -f $@; \
	 $(CC) -M $(INCDIR) $(LIB_SDK_INCDIR) $(SDK_INCDIR) $(CPPFLAGS) $< > $@.$$$$; \
	 sed 's,\(.*\)\.o[ :]*,$(BUILD_DIR)/$(dir $<)\1.o $@: ,g' < $@.$$$$ > $@; \
	 rm -f $@.$$$$

-include $(DEP)