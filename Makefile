FILES = *.rb env
OUTDIR = build

build: builddir debcontrol
	mkdir -p $(OUTDIR)/chimera/bin
	cp $(FILES) $(OUTDIR)/chimera/bin/

deb: build
	dpkg-deb -b build chimera.deb

debcontrol:
	cp -r DEBIAN $(OUTDIR)/DEBIAN

builddir:
	mkdir -p $(OUTDIR)

clean: cleandeb
	rm -rf build

cleandeb:
	rm -f chimera.deb
