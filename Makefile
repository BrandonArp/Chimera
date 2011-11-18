FILES = *.rb env

build:

install:
	mkdir -p $(DESTDIR)/chimera/bin/
	cp $(FILES) $(DESTDIR)/chimera/bin/

