.SUFFIX:

# Get include path for Erlang, add to CFLAGS
ERLANG_PATH := $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

# Other directory paths
OUT_DIR := priv
LIBMAGIC_PATH := $(shell pwd)/deps/libmagic

# Set up compiler flags
CFLAGS := -g -O3 -fPIC -ansi -pedantic -Wall -Wextra -Wno-unused-parameter
CPPFLAGS := -I$(ERLANG_PATH) -I$(LIBMAGIC_PATH)/src
LDFLAGS := #-L$(LIBMAGIC_PATH) -lmagic


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
	$(RM) \
		$(OUT_DIR)/exmagic.so* \
		$(OUT_DIR)/exmagic.o \
		$(OUT_DIR)/*.stamp \
		$(OUT_DIR)/magic.mgc
