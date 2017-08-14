SRC_ROOT := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
SRC_PATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))t_done.sh
PREFIX ?= /usr/local/bin
NAME ?= t
DEST_PATH = $(PREFIX)/$(NAME)

help :
	$(info prefix : ${PREFIX})
	$(info name : ${NAME})
	$(info make install : install to ${PREFIX})
	$(info make link : create symbolic link ${SRC_PATH} -> ${DEST_PATH})

link : t_done.sh
	ln -sf $(SRC_PATH) $(DEST_PATH)

install : t_done.sh
	cp -RP $(SRC_PATH) $(DEST_PATH)
