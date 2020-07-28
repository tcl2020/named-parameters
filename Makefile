#
# Makefile for named parameters pacakge
#

PREFIX		?= /usr/local

LIB			?= $(PREFIX)/lib
TCLSH		?= tclsh

INSTALLUSER = root
#INSTALLGROUP = wheel
INSTALLGROUP = root

PACKAGE=np
TARGET=$(LIB)/$(PACKAGE)
FILES= np.tcl pkgIndex.tcl

all:
	@echo "'make install' to install"

install: install-package

install-package:
	echo "pkg_mkIndex ." | $(TCLSH)
	install -o $(INSTALLUSER) -g $(INSTALLGROUP) -m 0755 -d $(TARGET)
	install -o $(INSTALLUSER) -g $(INSTALLGROUP) -m 0644 $(FILES) $(TARGET)/
	@echo "Installed $(PACKAGE) package to $(LIB)"

clean:
	@rm -f pkgIndex.tcl

test:
	cd tests; tclsh all.tcl -singleproc true
