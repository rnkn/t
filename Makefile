PROGRAM		= t_done.sh
PREFIX		?= /usr/local
CLI			?= t

install:
	install -m 755 $(PROGRAM) $(PREFIX)/bin/$(CLI)
