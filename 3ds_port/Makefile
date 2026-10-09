# The Choicer Voicer — Old 3DS native target
# Uses devkitPro's standard 3DS rules and can be built locally or in GitHub Actions.

.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error DEVKITARM is not set. Install the official devkitPro 3DS development tools.)
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

TARGET := TheChoicerVoicer3DS
BUILD := build
SOURCES := source
DATA := data
INCLUDES := include

ARCH := -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft
CFLAGS := -g -Wall -Werror=implicit-function-declaration -Werror=return-type -O2 -mword-relocations -ffunction-sections $(ARCH)
CFLAGS += -D__3DS__ -DOLD_3DS_PORT -I$(TOPDIR)/include -I$(CTRULIB)/include
CXXFLAGS := $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11
ASFLAGS := -g $(ARCH)
LDFLAGS := -specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(TARGET).map
LIBS := -lctru -lm
LIBDIRS := $(CTRULIB)

APP_TITLE := The Choicer Voicer
APP_DESCRIPTION := Native Old 3DS port
APP_AUTHOR := The Choicer Voicer contributors
ICON := icon.png

ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT := $(CURDIR)/$(TARGET)
export TOPDIR := $(CURDIR)
export VPATH := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
                $(foreach dir,$(DATA),$(CURDIR)/$(dir))
export DEPSDIR := $(CURDIR)/$(BUILD)

CFILES := $(notdir $(wildcard $(SOURCES)/*.c))
CPPFILES := $(notdir $(wildcard $(SOURCES)/*.cpp))
SFILES := $(notdir $(wildcard $(SOURCES)/*.s))

ifeq ($(strip $(CPPFILES)),)
export LD := $(CC)
else
export LD := $(CXX)
endif

export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES_BIN :=
export OFILES := $(OFILES_BIN) $(OFILES_SOURCES)
export HFILES :=
export INCLUDE := $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
                  $(foreach dir,$(LIBDIRS),-I$(dir)/include) \
                  -I$(CURDIR)/$(BUILD)
export LIBPATHS := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)
export _3DSXDEPS := $(OUTPUT).smdh
export _3DSXFLAGS := --smdh=$(OUTPUT).smdh
export APP_TITLE APP_DESCRIPTION APP_AUTHOR
export APP_ICON := $(CURDIR)/$(ICON)

.PHONY: all clean

all: $(BUILD)
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

$(BUILD):
	@mkdir -p "$@"

clean:
	@rm -rf $(BUILD) $(TARGET).3dsx $(TARGET).elf $(TARGET).smdh $(TARGET).map $(TARGET).lst

else

$(OUTPUT).3dsx: $(OUTPUT).elf $(_3DSXDEPS)
$(OFILES_SOURCES): $(HFILES)
$(OUTPUT).elf: $(OFILES)

-include $(DEPSDIR)/*.d

endif
