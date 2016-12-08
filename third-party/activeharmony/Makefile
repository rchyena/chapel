ifndef CHPL_MAKE_HOME
export CHPL_MAKE_HOME=$(shell pwd)/../..
endif

include $(CHPL_MAKE_HOME)/make/Makefile.base
include Makefile.include

AH_TAR=ah-4.6.1.tar.bz2
AH_URL=http://www.dyninst.org/sites/default/files/downloads/harmony/$(AH_TAR)
AH_SRC_DIR=$(ACTIVEHARMONY_BUILD_DIR)/activeharmony-4.6.1
AH_BUILD_FLAGS=prefix=$(ACTIVEHARMONY_INSTALL_DIR) install

AH_INSTALLED_MARKER=$(ACTIVEHARMONY_BUILD_DIR)/.ah-installed
AH_EXTRACTED_MARKER=$(ACTIVEHARMONY_BUILD_DIR)/.ah-extracted

default: all

all: $(AH_INSTALLED_MARKER)

clean: FORCE
	rm -rf $(ACTIVEHARMONY_INSTALL_DIR) $(AH_INSTALLED_MARKER)

cleanall: clean
	rm -rf $(ACTIVEHARMONY_TARBALL) $(AH_SRC_DIR) $(AH_EXTRACTED_MARKER)

clobber: clean
	rm -rf *~ $(ACTIVEHARMONY_BUILD_DIR)

$(AH_INSTALLED_MARKER): $(AH_EXTRACTED_MARKER)
	$(MAKE) -C $(AH_SRC_DIR) $(AH_BUILD_FLAGS)
	touch $@

$(AH_EXTRACTED_MARKER): build/$(AH_TAR)
	tar --bzip2 --directory=build -xf build/$(AH_TAR)
	touch $@

build/$(AH_TAR):
	mkdir -p build
	wget --no-verbose --directory-prefix=build $(AH_URL)

FORCE:

.NOTPARALLEL:
