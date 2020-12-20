DOCKER_IMAGE=danielpieper/neovim-docker

build:
	docker build -t ${DOCKER_IMAGE}:latest .

run:
	docker run --rm -it ${DOCKER_IMAGE}:latest

clean:
	docker rmi ${DOCKER_IMAGE}:latest

.PHONY: build clean run
.DEFAULT_GOAL := build
