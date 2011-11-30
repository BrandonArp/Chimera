FILES = *.rb env chimera-server

.PHONY: chimera-server

build: chimera-server

install: build
	mkdir -p $(DESTDIR)/chimera/bin/
	cp $(FILES) $(DESTDIR)/chimera/bin/
	cp -r lib $(DESTDIR)/chimera/bin
	cp -r chimera-service/gen-rb $(DESTDIR)/chimera/bin/lib

chimera-server:
	$(MAKE) -C chimera-service $(MFLAGS)
	cp chimera-service/chimera-server .

clean:
	$(MAKE) -C chimera-service $(MFLAGS) $@
	rm -f chimera-server
