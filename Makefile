#!/bin/bash
#
# undocker
# Copyright (C) - Docker for unprivileged users
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BINARIES=undocker undocker-rt undocker-rtb
BINDEST=/usr/bin
ETC=etc/*.conf etc/sudoers.d/undocker
COMMONFILES=LICENSE src/version README.md
BINDIR=bin
SRCDIR=src
BASHC=bashc
BASHCFLAGS=-cSRC
GCC=gcc

BINS = $(patsubst %,$(BINDIR)/%,$(BINARIES))

all:	$(BINS)

$(BINDIR)/%:	$(SRCDIR)/%.bashc | $(BINDIR)
	$(BASHC) $(BASHCFLAGS) -o $@ -c $^

$(BINDIR)/undocker-rtb: 
	$(GCC) -o $@ $(SRCDIR)/undocker-rtb.c
	chmod u+s $@

$(BINDIR):
	mkdir -p $(BINDIR)

clean:	
	rm $(BINS)

install-etc: $(ETC)
	@mkdir -p $(DESTDIR)/etc
	@for f in $(wildcard $^); do DD=$(DESTDIR)/`dirname $$f`; mkdir -p $$DD; echo install -m 600 $$f $$DD; install -m 600 $$f $$DD; done

install-bin: $(BINS)
	@mkdir -p $(DESTDIR)$(BINDEST)
	@for f in $(wildcard $^); do echo install -m 755 $$f $(DESTDIR)$(BINDEST); install -m 755 $$f $(DESTDIR)$(BINDEST); done

install-setuid: $(BINDIR)/undocker-rtb
	@echo install -m 4755 $(BINDIR)/undocker-rtb $(DESTDIR)$(BINDEST)
	@install -o root -m 4755 $(BINDIR)/undocker-rtb $(DESTDIR)$(BINDEST)

install-common: $(COMMONFILES)
	@mkdir -p $(DESTDIR)/usr/share/undocker
	@for f in $(wildcard $^); do echo install -m 644 $$f $(DESTDIR)/usr/share/undocker; install -m 644 $$f $(DESTDIR)/usr/share/undocker; done

__check:
	$(if $(value DESTDIR),, $(error DESTDIR is not set)) 

install: __check install-common install-etc install-bin install-setuid
	
