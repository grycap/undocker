BINARIES=undocker undockerparams
ETC=etc/*.conf
BINDIR=bin
SRCDIR=src
BASHC=bashc
BASHCFLAGS=-cSRC

BINS = $(patsubst %,$(BINDIR)/%,$(BINARIES))

$(BINDIR)/%:	$(SRCDIR)/%.bashc | $(BINDIR)
	$(BASHC) $(BASHCFLAGS) -o $@ -c $^

all:	$(BINS)

$(BINDIR):
	mkdir -p $(BINDIR)

clean:	
	rm $(BINS)

install-etc: $(ETC)
	@mkdir -p $(DESTDIR)/etc
	@for f in $(wildcard $^); do echo install -m 600 $$f $(DESTDIR)/etc; install -m 600 $$f $(DESTDIR)/etc; done

install-bin: $(BINS)
	@mkdir -p $(DESTDIR)/usr/local/bin
	@for f in $(wildcard $^); do echo install -m 755 $$f $(DESTDIR)/usr/local/bin; install -m 755 $$f $(DESTDIR)/usr/local/bin; done

__check:
	$(if $(value DESTDIR),, $(error DESTDIR is not set)) 

install: __check install-etc install-bin
	
