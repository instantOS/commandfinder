PREFIX = /usr/

all: install

install:
	install -Dm 755 commandfinder.sh ${DESTDIR}${PREFIX}bin/commandfinder

uninstall:
	rm ${DESTDIR}${PREFIX}bin/commandfinder
