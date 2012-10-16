INSTALLDIR=$(DESTDIR)/opt/mnimograph

mnimograph: bin/mnimograph.pl bin/mnimograph_gui.pl
	chmod 755 bin/mnimograph.pl
	chmod 755 bin/mnimograph_gui.pl
	@which gnuplot>/dev/null || (echo \
	"Please install gnuplot." && exit 1)
	@which convert>/dev/null || (echo \
	"Please install ImageMagick." && exit 1)
	@which perl>/dev/null || (echo \
	"Perl is not installed! Blasphemy! Please install Perl." && exit 1)
	@perl -e 'use Chart::Gnuplot' == /dev/null || (echo \
	"\nPlease install the Perl module 'Chart::Gnuplot'." && exit 1)
	@perl -e 'use Encode' == /dev/null || (echo \
	"\nPlease install the Perl module 'Encode'." && exit 1)
	@perl -e 'use Gtk2' == /dev/null || (echo \
	"\nPlease install the Perl module 'Gtk2'." && exit 1)
	@perl -e 'use Term::ReadKey' == /dev/null || (echo \
	"\nPlease install the Perl module 'Term::ReadKey'." && exit 1)

install:
	mkdir -p $(INSTALLDIR)/bin/
	cp -R images/ $(INSTALLDIR)
	cp README $(INSTALLDIR)
	mkdir -p $(DESTDIR)/usr/local/man/man1/
	cp mnimograph.1.gz $(DESTDIR)/usr/local/man/man1/
	mkdir -p $(DESTDIR)/usr/local/bin/
	install bin/mnimograph.pl $(INSTALLDIR)/bin/
	install bin/mnimograph_gui.pl $(INSTALLDIR)/bin/
	mkdir -p $(DESTDIR)/usr/share/applications/
	cp mnimograph.desktop $(DESTDIR)/usr/share/applications/
	rm -f $(DESTDIR)/usr/local/bin/mnimograph.pl
	rm -f $(DESTDIR)/usr/local/bin/mnimograph_gui.pl
	ln -s $(INSTALLDIR)/bin/mnimograph.pl $(DESTDIR)/usr/local/bin/mnimograph.pl
	ln -s $(INSTALLDIR)/bin/mnimograph_gui.pl $(DESTDIR)/usr/local/bin/mnimograph_gui.pl
	@echo "\033[1m\nAll done! Launch mnimograph with 'mnimograph.pl' or 'mnimograph_gui.pl'.\033[0m"

uninstall:
	rm -rf $(INSTALLDIR)/
	rm -rf $(DESTDIR)/usr/local/man/man1/mnimograph.1.gz
	rm -f $(DESTDIR)/usr/local/bin/mnimograph.pl
	rm -f $(DESTDIR)/usr/local/bin/mnimograph_gui.pl
