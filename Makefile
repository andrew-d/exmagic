.SUFFIX:

# Get include path for Erlang, add to CFLAGS
ERLANG_PATH := $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

# Other directory paths
OUT_DIR := priv

# NOTE: This is necessary due to the way that Mix builds projects.  When we're
# building ExMagic by itself, the `deps` directory will be nested inside the
# `exmagic` directory.  However, when ExMagic is included in another project,
# the `exmagic` directory is located in the top-level `deps` directory, next to
# the `libmagic` directory.
ifeq ($(wildcard deps/libmagic),)
	LIBMAGIC_PATH := ../libmagic
else
	LIBMAGIC_PATH := $(shell pwd)/deps/libmagic
endif


# Set up compiler flags
CFLAGS := -g -O3 -fPIC -ansi -pedantic -Wall -Wextra -Wno-unused-parameter
CPPFLAGS := -I$(ERLANG_PATH) -I$(LIBMAGIC_PATH)/src
LDFLAGS := -lz #-L$(LIBMAGIC_PATH) -lmagic


############################################################
## PLATFORM-SPECIFIC

ifeq ($(shell uname),Darwin)
LDFLAGS += -undefined dynamic_lookup -dynamiclib
endif

############################################################
## RULES

LIBMAGIC_AR := $(LIBMAGIC_PATH)/src/.libs/libmagic.a

.PHONY: all env clean

all: $(OUT_DIR)/exmagic.so $(OUT_DIR)/magic.mgc

# Note: need to run the build to create the header file
$(OUT_DIR)/exmagic.o: c_src/exmagic.c $(OUT_DIR)/libmagic.stamp | $(OUT_DIR)
	$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ c_src/exmagic.c

$(OUT_DIR)/exmagic.so: $(OUT_DIR)/exmagic.o $(OUT_DIR)/libmagic.stamp | $(OUT_DIR)
	$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ $(OUT_DIR)/exmagic.o $(LIBMAGIC_AR)

$(OUT_DIR)/libmagic.stamp: | $(OUT_DIR)
	cd $(LIBMAGIC_PATH) && autoreconf -i
	cd $(LIBMAGIC_PATH) && ./configure \
		--disable-dependency-tracking \
		--disable-shared \
		--enable-static \
		CFLAGS="-g -O3 -fPIC"
	$(MAKE) -C $(LIBMAGIC_PATH)
	@touch $@

$(OUT_DIR)/magic.mgc: $(OUT_DIR)/libmagic.stamp | $(OUT_DIR)
	cp $(LIBMAGIC_PATH)/magic/magic.mgc $@

$(OUT_DIR):
	mkdir -p $@


############################################################
## UTIL

env:
	@echo "CFLAGS        = $(CFLAGS)"
	@echo "CPPFLAGS      = $(CFPPLAGS)"
	@echo "LDFLAGS       = $(LDFLAGS)"
	@echo "ERLANG_PATH   = $(ERLANG_PATH)"
	@echo "OUT_DIR       = $(OUT_DIR)"
	@echo "LIBMAGIC_PATH = $(LIBMAGIC_PATH)"

clean:
	$(MAKE) -C $(LIBMAGIC_PATH) clean || true
	$(RM) \
		$(OUT_DIR)/exmagic.so* \
		$(OUT_DIR)/exmagic.o \
		$(OUT_DIR)/*.stamp \
		$(OUT_DIR)/magic.mgc
