PREFIX = /usr/

all: install

install:
	install -Dm 755 commandfinder.sh ${DESTDIR}${PREFIX}bin/commandfinder
	mkdir -p ${DESTDIR}${PREFIX}share/commandfinder/
	cp -r cache ${DESTDIR}${PREFIX}share/commandfinder/

uninstall:
	rm ${DESTDIR}${PREFIX}bin/commandfinder
	rm -rf ${DESTDIR}${PREFIX}share/commandfinder
