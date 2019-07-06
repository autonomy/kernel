TAG = $(shell gitmeta image tag)

TOOLCHAIN_VERSION = 397e6c2
TOOLCHAIN_IMAGE = autonomy/toolchain:$(TOOLCHAIN_VERSION)

COMMON_ARGS = --progress=plain
COMMON_ARGS += --frontend=dockerfile.v0
COMMON_ARGS += --local context=.
COMMON_ARGS += --local dockerfile=.
COMMON_ARGS += --opt build-arg:TOOLCHAIN_IMAGE=$(TOOLCHAIN_IMAGE)

BUILDKIT_HOST ?= tcp://0.0.0.0:1234

all: kernel

kernel-src:
	@buildctl --addr $(BUILDKIT_HOST) \
		build \
		--output type=docker,dest=$@.tar,name=docker.io/autonomy/$@:$(TAG) \
		--opt build-arg:TOOLCHAIN_IMAGE=$(TOOLCHAIN_IMAGE),target=$@ \
		$(COMMON_ARGS)

kernel-build:
	@buildctl --addr $(BUILDKIT_HOST) \
		build \
		--output type=docker,dest=$@.tar,name=docker.io/autonomy/$@:$(TAG) \
		--opt target=$@ \
		$(COMMON_ARGS)

kernel:
	@buildctl --addr $(BUILDKIT_HOST) \
		build \
		--output type=docker,dest=$@.tar,name=docker.io/autonomy/$@:$(TAG) \
		--opt build-arg:TOOLCHAIN_IMAGE=$(TOOLCHAIN_IMAGE),target=$@ \
		$(COMMON_ARGS)
	@docker load < $@.tar

.PHONY: login
login:
	@docker login --username "$(DOCKER_USERNAME)" --password "$(DOCKER_PASSWORD)"

push:
	@docker tag autonomy/kernel:$(TAG) autonomy/kernel:latest
	@docker push autonomy/kernel:$(TAG)
	@docker push autonomy/kernel:latest
