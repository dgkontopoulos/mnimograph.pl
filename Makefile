INSTALLDIR=$(DESTDIR)/usr/local/bin

mnimograph: mnimograph.pl
	chmod 755 mnimograph.pl
	@which gnuplot>/dev/null || (echo \
	"Please install gnuplot." && exit 1)
	@which perl>/dev/null || (echo \
	"Perl is not installed! Blasphemy! Please install Perl." && exit 1)
	@perl -e 'use Chart::Gnuplot' == /dev/null || (echo \
	"\nPlease install the Perl module 'Chart::Gnuplot'." && exit 1)
	@perl -e 'use Term::ReadKey' == /dev/null || (echo \
	"\nPlease install the Perl module 'Term::ReadKey'." && exit 1)

install:
	mkdir -p $(INSTALLDIR)/
	mkdir -p $(DESTDIR)/usr/local/man/man1/
	cp mnimograph.1.gz $(DESTDIR)/usr/local/man/man1/
	install mnimograph.pl $(INSTALLDIR)
	@echo "\nAll done! Launch mnimograph with 'mnimograph.pl'."

uninstall:
	rm -rf $(INSTALLDIR)/mnimograph.pl
	rm -rf $(DESTDIR)/usr/local/man/man1/mnimograph.1.gz
