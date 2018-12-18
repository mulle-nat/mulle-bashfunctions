SCRIPTS=./bin/installer \
src/mulle-array.sh \
src/mulle-bashfunctions.sh \
src/mulle-exekutor.sh \
src/mulle-file.sh \
src/mulle-init.sh \
src/mulle-logging.sh \
src/mulle-options.sh \
src/mulle-path.sh \
src/mulle-string.sh \
src/mulle-version.sh


CHECKSTAMPS=$(SCRIPTS:.sh=.chk)
SHELLFLAGS=-x -e SC2164,SC2166,SC2006,SC1091,SC2039,SC2181,SC2059 -s sh

.PHONY: all
.PHONY: clean
.PHONY: shellcheck_check

%.chk:	%.sh
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

all:	$(CHECKSTAMPS) mulle-bashfunctions-env.chk shellcheck_check jq_check

mulle-bashfunctions-env.chk:	mulle-bashfunctions-env
	- shellcheck $(SHELLFLAGS) $<
	(shellcheck -f json $(SHELLFLAGS) $< | jq '.[].level' | grep -w error > /dev/null ) && exit 1 || touch $@

installer:
	@ ./bin/installer

clean:
	@- rm *.chk

shellcheck_check:
	which shellcheck || brew install shellcheck

jq_check:
	which jq || brew install jq
