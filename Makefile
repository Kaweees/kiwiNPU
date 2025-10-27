# Begin Variables Section

## Container Section: change these variables based on your container
# -----------------------------------------------------------------------------
# The container name.
TARGET := asic-tools

# The base container.
CONTAINER_NAME := hpretl/iic-osic-tools

## Command Section: change these variables based on your commands
# -----------------------------------------------------------------------------
# Targets
.PHONY: all pull build $(TARGET) zsh clean arch

# Default target: build and run everything
all: pull build $(TARGET) zsh

# Rule to pull the container image
pull:
	docker pull ${CONTAINER_NAME}

# Rule to build the Docker image
build:
	docker build . -t ${TARGET} --build-arg BASE_IMAGE=${CONTAINER_NAME}

# Rule to run the container
$(TARGET):
	docker run -d --rm \
		--name $(TARGET) \
		${TARGET} \
		--skip tail -f /dev/null

# Rule to run the zsh shell
zsh:
	docker exec -it $(TARGET) /bin/bash

# Rule to clean the containers
clean:
	-docker rm -f $(TARGET) 2>/dev/null || true

# Rule to check the architecture
arch:
	@echo "Architecture: ${ARCH}"
	@echo "Container: ${CONTAINER_NAME}"
