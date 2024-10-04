.POSIX:
SRC			= t_done.sh
PREFIX		= /usr/local
TARGET		= t

install:
	install -m755 ${SRC} ${PREFIX}/bin/${TARGET}
