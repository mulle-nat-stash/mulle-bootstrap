SCRIPTS=install.sh \
mulle-bootstrap-brew.sh \
mulle-bootstrap-build.sh \
mulle-bootstrap-clean.sh \
mulle-bootstrap-convert-pre-0.10.sh \
mulle-bootstrap-fetch.sh \
mulle-bootstrap-functions.sh \
mulle-bootstrap-gcc.sh \
mulle-bootstrap-init.sh \
mulle-bootstrap-local-environment.sh \
mulle-bootstrap-settings.sh \
mulle-bootstrap-scm.sh \
mulle-bootstrap-scripts.sh \
mulle-bootstrap-tag.sh \
mulle-bootstrap-warn-scripts.sh \
mulle-bootstrap-xcode.sh

CHECKSTAMPS=$(SCRIPTS:.sh=.chk)
SHELLFLAGS=-x -e SC2164,SC2166,SC2006 -s sh

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
