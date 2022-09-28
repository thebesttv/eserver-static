# Use bash as shell
SHELL := /bin/bash

.PHONY: all clean		\
	publish upload		\
	server-start server-stop server-status	\
	target-dir mount unmount

SCRIPT = $(abspath main.el)
SOURCE = $(abspath blog)
TARGET = $(abspath target)

all: mount clean publish server-start

clean:
	rm -rf ${TARGET}/*

publish: target-dir
	emacs -Q \
		--script ${SCRIPT} \
		--source=${SOURCE} \
		--target=${TARGET}
# remove sitemap
	rm ${TARGET}/.sitemap.{org,html}

################################################################
# local http server
################################################################

SERVER_CMD = python -m http.server --directory ${TARGET} 8080
SERVER_DOWN = down
SERVER_STATUS = $(or $(shell pgrep -f "${SERVER_CMD}"),${SERVER_DOWN})

server-start:
ifeq ($(SERVER_STATUS), ${SERVER_DOWN})
	@echo "Starting server"
	${SERVER_CMD}
else
	@echo "Server already started"
endif

server-stop:
ifneq ($(SERVER_STATUS), ${SERVER_DOWN})
	pkill -f "${SERVER_CMD}"
	@echo "Server stopped"
else
	@echo "Server not started"
endif

server-status:
	@echo ${SERVER_STATUS}

################################################################
# tmpfs mounting
################################################################

MOUNT_DOWN = unmounted
MOUNT_STATUS = $(or $(shell mount -l -t tmpfs | grep ${TARGET}),${MOUNT_DOWN})

target-dir:
	mkdir -p ${TARGET}

mount: target-dir
ifeq (${MOUNT_STATUS}, ${MOUNT_DOWN})
	sudo mount -v -o size=1G -t tmpfs none ${TARGET}
else
	@echo "Target already mounted at ${TARGET}"
endif

unmount:
ifneq (${MOUNT_STATUS}, ${MOUNT_DOWN})
	sudo umount ${TARGET}
else
	@echo "Target not mounted"
endif
