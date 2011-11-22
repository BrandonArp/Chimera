FILES = *.rb env

build:

install:
	mkdir -p $(DESTDIR)/chimera/bin/
	cp $(FILES) $(DESTDIR)/chimera/bin/
	cp -r lib $(DESTDIR)/chimera/bin

