ifeq ($(VERSION),)
	ifeq ($(RELEASE_VERSION),)
		CONFIG_VERSION:=SNAPSHOT
	else
		CONFIG_VERSION:=$(RELEASE_VERSION)
	endif
else
	ifeq ($(VERSION),*)
		CONFIG_VERSION:=$(shell date +%Y%m%d%H%M%S)
	else
		CONFIG_VERSION:=$(VERSION)
	endif
endif

.PHONY: version_phony
.ARG_VERSION: version_phony
	@if [[ `cat .ARG_VERSION 2>&1` != '$(CONFIG_VERSION)' ]]; then echo -n '$(CONFIG_VERSION)' >.ARG_VERSION; fi
