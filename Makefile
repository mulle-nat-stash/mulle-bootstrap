SCRIPTS=install.sh \
	src/mulle-bootstrap-array.sh \
	src/mulle-bootstrap-auto-update.sh \
	src/mulle-bootstrap-brew.sh \
	src/mulle-bootstrap-build.sh \
	src/mulle-bootstrap-clean.sh \
	src/mulle-bootstrap-common-settings.sh \
	src/mulle-bootstrap-copy.sh \
	src/mulle-bootstrap-dependency-resolve.sh \
	src/mulle-bootstrap-fetch.sh \
	src/mulle-bootstrap-functions.sh \
	src/mulle-bootstrap-gcc.sh \
	src/mulle-bootstrap-init.sh \
	src/mulle-bootstrap-install.sh \
	src/mulle-bootstrap-local-environment.sh \
	src/mulle-bootstrap-logging.sh \
	src/mulle-bootstrap-mingw.sh \
	src/mulle-bootstrap-repositories.sh \
	src/mulle-bootstrap-scm.sh \
	src/mulle-bootstrap-scripts.sh \
	src/mulle-bootstrap-settings.sh \
	src/mulle-bootstrap-tag.sh \
	src/mulle-bootstrap-warn-scripts.sh \
	src/mulle-bootstrap-xcode.sh \
	src/mulle-bootstrap-zombify.sh

CHECKSTAMPS=$(SCRIPTS:.sh=.chk)
SHELLFLAGS=-x -e SC2164,SC2166,SC2006,SC1091,SC2039,SC2181,SC2059 -s sh

.PHONY: all
.PHONY: clean
.PHONY: shellcheck_check

%.chk:	%.sh
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

all:	$(CHECKSTAMPS) mulle-bootstrap.chk shellcheck_check jq_check

mulle-bootstrap.chk:	mulle-bootstrap
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

install:
	@ ./install.sh

clean:
	@- rm *.chk

shellcheck_check:
	which shellcheck || brew install shellcheck

jq_check:
	which shellcheck || brew install shellcheck
