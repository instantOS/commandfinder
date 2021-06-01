PREFIX = /usr/

all: install

install: cache
	install -Dm 755 commandfinder.sh ${DESTDIR}${PREFIX}bin/commandfinder
	mkdir -p ${DESTDIR}${PREFIX}share/commandfinder/
	cp -r cache ${DESTDIR}${PREFIX}share/commandfinder/

cache: commandfinder.sh
	./commandfinder.sh cache cache

uninstall:
	rm ${DESTDIR}${PREFIX}bin/commandfinder
	rm -rf ${DESTDIR}${PREFIX}share/commandfinder
