TAG = $(shell gitmeta image tag)

TOOLCHAIN_VERSION = 7362500
TOOLCHAIN_IMAGE = autonomy/toolchain:$(TOOLCHAIN_VERSION)

COMMON_ARGS = --progress=plain
COMMON_ARGS += --frontend=dockerfile.v0
COMMON_ARGS += --local context=.
COMMON_ARGS += --local dockerfile=.
COMMON_ARGS += --frontend-opt build-arg:TOOLCHAIN_IMAGE=$(TOOLCHAIN_IMAGE)

all: kernel

kernel-build:
	@buildctl --addr $(BUILDKIT_HOST) \
		build \
		--exporter=docker \
		--exporter-opt output=$@.tar \
		--exporter-opt name=docker.io/autonomy/$@:$(TAG) \
		--frontend-opt build-arg:TOOLCHAIN_IMAGE=$(TOOLCHAIN_IMAGE) \
		--frontend-opt target=$@ \
		$(COMMON_ARGS)

kernel:
	@buildctl --addr $(BUILDKIT_HOST) \
		build \
		--exporter=docker \
		--exporter-opt output=$@.tar \
		--exporter-opt name=docker.io/autonomy/$@:$(TAG) \
		--frontend-opt build-arg:TOOLCHAIN_IMAGE=$(TOOLCHAIN_IMAGE) \
		--frontend-opt target=$@ \
		$(COMMON_ARGS)
	@docker load < $@.tar

.PHONY: login
login:
	@docker login --username "$(DOCKER_USERNAME)" --password "$(DOCKER_PASSWORD)"

push:
	@docker tag autonomy/kernel:$(TAG) autonomy/kernel:latest
	@docker push autonomy/kernel:$(TAG)
	@docker push autonomy/kernel:latest
