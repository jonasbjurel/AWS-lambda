#############################################################################
# Copyright (c) 2015 Jonas Bjurel and others as listed below:
# jonasbjurel@hotmail.com
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##############################################################################
# Description:
#
##############################################################################

SHELL = /bin/bash

############################################################################
# BEGIN of variables to customize
#
#Input args

# Build variables
export BUILD_BASE := $(shell pwd)
export TOPDIR := $(shell pwd)

#Build subclasses
#SUBDIRS := lambda

#
# END of variables to customize
#############################################################################

#SUBCLEAN = $(addsuffix .clean,$(SUBDIRS))

.PHONY: all
all: clean release
	deploy.sh -p

############################################################################
# BEGIN of Include definitions
#
include config.mk
#
# END Include definitions
#############################################################################

.PHONY: release
release:
	./deploy.sh -p
	./deploy.sh -d
	./deploy.sh -v


.PHONY: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ -f Makefile release

.PHONY: clean
clean: $(SUBCLEAN)
	./deploy.sh -c
	rm -rf release

$(SUBCLEAN): %.clean:
	$(MAKE) -C $* -f Makefile clean
