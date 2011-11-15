FILES = *.rb
OUTDIR = build

build: builddir debcontrol
	cp $(FILES) $(OUTDIR)

debcontrol:
	cp -r DEBIAN $(OUTDIR)/DEBIAN
builddir:
	mkdir -p $(OUTDIR)

clean:
	rm -rf build
