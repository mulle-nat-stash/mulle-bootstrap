SCRIPTS=install.sh \
mulle-bootstrap-build.sh \
mulle-bootstrap-clean.sh \
mulle-bootstrap-fetch.sh \
mulle-bootstrap-functions.sh \
mulle-bootstrap-gcc.sh \
mulle-bootstrap-init.sh \
mulle-bootstrap-local-environment.sh \
mulle-bootstrap-setup-xcode.sh \
mulle-bootstrap-tag.sh \
mulle-bootstrap-warn-scripts.sh

CHECKSTAMPS=$(SCRIPTS:.sh=.chk)
SHELLFLAGS=-e SC2006 -s sh

.PHONY: all
.PHONY: clean

%.chk:	%.sh
		- ( shellcheck $(SHELLFLAGS) $< || touch $@ )

all:	$(CHECKSTAMPS) mulle-bootstrap.chk

mulle-bootstrap.chk:	mulle-bootstrap
		- ( shellcheck $(SHELLFLAGS) $< || touch $@ )

install:
	@ ./install.sh

clean:
	@- rm *.chk

