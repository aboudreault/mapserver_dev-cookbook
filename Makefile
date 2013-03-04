VERSION=$(shell cat metadata.rb|grep version|sed 's/[(version)" ]//g')
TMPPATH=/tmp/mapserver-dev-$(VERSION)

dist:
	mkdir $(TMPPATH)
	cp Vagrantfile $(TMPPATH)
	cp Berksfile.conf $(TMPPATH)/Berksfile
	cp Gemfile $(TMPPATH)
	tar -czv -C /tmp -f mapserver-dev-$(VERSION).tar.gz mapserver-dev-$(VERSION)
	rm -rf $(TMPPATH)
