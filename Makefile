ARCH ?= $(shell uname -m)
REV ?= -$(shell git rev-parse --short HEAD)
DOCKER ?= docker

all: base extend ghrunner codeserver.$(ARCH) tag ghrunner-swift.$(ARCH) codeserver-swift.$(ARCH)
	echo "ARCH=$(ARCH)"

manifest: manifest-base manifest-extend manifest-ghrunner manifest-codeserver manifest-ghrunner-swift manifest-codeserver-swift
	echo "image: fastandfearless/developers-paradise:latest" >> .build.manifest-latest.yaml
	echo "manifests:" >> .build.manifest-latest.yaml
	echo "  -" >> .build.manifest-latest.yaml
	echo "    image: fastandfearless/developers-paradise:codeserver-aarch64$(REV)" >> .build.manifest-latest.yaml
	echo "    platform:" >> .build.manifest-latest.yaml
	echo "      architecture: arm64" >> .build.manifest-latest.yaml
	echo "      os: linux" >> .build.manifest-latest.yaml
	echo "  -" >> .build.manifest-latest.yaml
	echo "    image: fastandfearless/developers-paradise:ghrunner-armv7l$(REV)" >> .build.manifest-latest.yaml
	echo "    platform:" >> .build.manifest-latest.yaml
	echo "      architecture: arm" >> .build.manifest-latest.yaml
	echo "      os: linux" >> .build.manifest-latest.yaml
	echo "  -" >> .build.manifest-latest.yaml
	echo "    image: fastandfearless/developers-paradise:codeserver-x86_64$(REV)" >> .build.manifest-latest.yaml
	echo "    platform:" >> .build.manifest-latest.yaml
	echo "      architecture: amd64" >> .build.manifest-latest.yaml
	echo "      os: linux" >> .build.manifest-latest.yaml
	manifest-tool push from-spec .build.manifest-latest.yaml

manifest-base:
	echo "image: fastandfearless/developers-paradise:base-latest" >> .build.manifest-base.yaml
	echo "manifests:" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: fastandfearless/developers-paradise:base-aarch64$(REV)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: arm64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: fastandfearless/developers-paradise:base-armv7l$(REV)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: arm" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: fastandfearless/developers-paradise:base-x86_64$(REV)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: amd64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	manifest-tool push from-spec .build.manifest-base.yaml

manifest-extend:
	echo "image: fastandfearless/developers-paradise:extend-latest" >> .build.manifest-extend.yaml
	echo "manifests:" >> .build.manifest-extend.yaml
	echo "  -" >> .build.manifest-extend.yaml
	echo "    image: fastandfearless/developers-paradise:extend-aarch64$(REV)" >> .build.manifest-extend.yaml
	echo "    platform:" >> .build.manifest-extend.yaml
	echo "      architecture: arm64" >> .build.manifest-extend.yaml
	echo "      os: linux" >> .build.manifest-extend.yaml
	echo "  -" >> .build.manifest-extend.yaml
	echo "    image: fastandfearless/developers-paradise:extend-armv7l$(REV)" >> .build.manifest-extend.yaml
	echo "    platform:" >> .build.manifest-extend.yaml
	echo "      architecture: arm" >> .build.manifest-extend.yaml
	echo "      os: linux" >> .build.manifest-extend.yaml
	echo "  -" >> .build.manifest-extend.yaml
	echo "    image: fastandfearless/developers-paradise:extend-x86_64$(REV)" >> .build.manifest-extend.yaml
	echo "    platform:" >> .build.manifest-extend.yaml
	echo "      architecture: amd64" >> .build.manifest-extend.yaml
	echo "      os: linux" >> .build.manifest-extend.yaml
	manifest-tool push from-spec .build.manifest-extend.yaml

manifest-ghrunner:
	echo "image: fastandfearless/developers-paradise:ghrunner-latest" >> .build.manifest-ghrunner.yaml
	echo "manifests:" >> .build.manifest-ghrunner.yaml
	echo "  -" >> .build.manifest-ghrunner.yaml
	echo "    image: fastandfearless/developers-paradise:ghrunner-aarch64$(REV)" >> .build.manifest-ghrunner.yaml
	echo "    platform:" >> .build.manifest-ghrunner.yaml
	echo "      architecture: arm64" >> .build.manifest-ghrunner.yaml
	echo "      os: linux" >> .build.manifest-ghrunner.yaml
	echo "  -" >> .build.manifest-ghrunner.yaml
	echo "    image: fastandfearless/developers-paradise:ghrunner-armv7l$(REV)" >> .build.manifest-ghrunner.yaml
	echo "    platform:" >> .build.manifest-ghrunner.yaml
	echo "      architecture: arm" >> .build.manifest-ghrunner.yaml
	echo "      os: linux" >> .build.manifest-ghrunner.yaml
	echo "  -" >> .build.manifest-ghrunner.yaml
	echo "    image: fastandfearless/developers-paradise:ghrunner-x86_64$(REV)" >> .build.manifest-ghrunner.yaml
	echo "    platform:" >> .build.manifest-ghrunner.yaml
	echo "      architecture: amd64" >> .build.manifest-ghrunner.yaml
	echo "      os: linux" >> .build.manifest-ghrunner.yaml
	manifest-tool push from-spec .build.manifest-ghrunner.yaml

manifest-codeserver:
	echo "image: fastandfearless/developers-paradise:codeserver-latest" >> .build.manifest-codeserver.yaml
	echo "manifests:" >> .build.manifest-codeserver.yaml
	echo "  -" >> .build.manifest-codeserver.yaml
	echo "    image: fastandfearless/developers-paradise:codeserver-aarch64$(REV)" >> .build.manifest-codeserver.yaml
	echo "    platform:" >> .build.manifest-codeserver.yaml
	echo "      architecture: arm64" >> .build.manifest-codeserver.yaml
	echo "      os: linux" >> .build.manifest-codeserver.yaml
	echo "  -" >> .build.manifest-codeserver.yaml
	echo "    image: fastandfearless/developers-paradise:codeserver-x86_64$(REV)" >> .build.manifest-codeserver.yaml
	echo "    platform:" >> .build.manifest-codeserver.yaml
	echo "      architecture: amd64" >> .build.manifest-codeserver.yaml
	echo "      os: linux" >> .build.manifest-codeserver.yaml
	manifest-tool push from-spec .build.manifest-codeserver.yaml

manifest-codeserver-swift:
	echo "image: fastandfearless/developers-paradise:base-latest" >> .build.manifest-base.yaml
	echo "manifests:" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: fastandfearless/developers-paradise:base-x86_64$(REV)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: amd64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	manifest-tool push from-spec .build.manifest-base.yaml

manifest-ghrunner-swift:
	echo "image: fastandfearless/developers-paradise:base-latest" >> .build.manifest-base.yaml
	echo "manifests:" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: fastandfearless/developers-paradise:base-x86_64$(REV)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: amd64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	manifest-tool push from-spec .build.manifest-base.yaml

tag: tag.codeserver.$(ARCH)
	$(DOCKER) tag developers-paradise-base-$(ARCH) "fastandfearless/developers-paradise:base-$(ARCH)$(REV)"
	$(DOCKER) tag developers-paradise-extend-$(ARCH) "fastandfearless/developers-paradise:extend-$(ARCH)$(REV)"
	$(DOCKER) tag developers-paradise-ghrunner-$(ARCH) "fastandfearless/developers-paradise:ghrunner-$(ARCH)$(REV)"

tag.codeserver.armv7l:
	echo "Tag Skip-CodeServer"

tag.codeserver.x86_64 tag.codeserver.aarch64:
	$(DOCKER) tag developers-paradise-codeserver-$(ARCH) "fastandfearless/developers-paradise:codeserver-$(ARCH)$(REV)"


push: push.base push.codeserver.$(ARCH)

push.base:
	$(DOCKER) push "fastandfearless/developers-paradise:base-$(ARCH)$(REV)"
	$(DOCKER) push "fastandfearless/developers-paradise:extend-$(ARCH)$(REV)"
	$(DOCKER) push "fastandfearless/developers-paradise:ghrunner-$(ARCH)$(REV)"

push.codeserver.armv7l:
	echo "Push Skip-CodeServer"

push.codeserver.x86_64 push.codeserver.aarch64:
	$(DOCKER) push "fastandfearless/developers-paradise:codeserver-$(ARCH)$(REV)"

base: .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base Dockertempl.base
	cat .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base > .build.$(ARCH).Dockerfile.base
	$(DOCKER) build -t developers-paradise-base-$(ARCH) -f .build.$(ARCH).Dockerfile.base .

.build.x86_64.Dockerfile.base.x86_64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.x86_64

.build.aarch64.Dockerfile.base.aarch64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.aarch64

.build.armv7l.Dockerfile.base.armv7l: Dockerfile.base.debian
	cp Dockerfile.base.debian .build.$(ARCH).Dockerfile.base.armv7l

extend:
	echo "FROM developers-paradise-base-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.dotnet Dockertempl.node Dockertempl.pulumi >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.manifest-tool >> .build.$(ARCH).Dockerfile.extend
	$(DOCKER) build -t developers-paradise-extend-$(ARCH) -f .build.$(ARCH).Dockerfile.extend .

ghrunner-swift.aarch64 ghrunner-swift.armv7l:
	echo "Skip GHRunner Swift"

ghrunner-swift.x86_64:
	echo "FROM developers-paradise-ghrunner-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.ghrunner-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.ghrunner-swift
	$(DOCKER) build -t developers-paradise-ghrunner-swift-$(ARCH) -f .build.$(ARCH).Dockerfile.ghrunner-swift .
	$(DOCKER) tag developers-paradise-ghrunner-swift-$(ARCH) "fastandfearless/developers-paradise:ghrunner-swift-$(ARCH)$(REV)"

codeserver-swift.aarch64 codeserver-swift.armv7l:
	echo "Skip GHRunner Swift"

codeserver-swift.x86_64:
	echo "FROM developers-paradise-codeserver-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.codeserver-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.codeserver-swift
	$(DOCKER) build -t developers-paradise-codeserver-swift-$(ARCH) -f .build.$(ARCH).Dockerfile.codeserver-swift .
	$(DOCKER) tag developers-paradise-codeserver-swift-$(ARCH) "fastandfearless/developers-paradise:codeserver-swift-$(ARCH)$(REV)"

ghrunner:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.ghrunner
	cat Dockertempl.ghrunner >> .build.$(ARCH).Dockerfile.ghrunner
	$(DOCKER) build -t developers-paradise-ghrunner-$(ARCH) -f .build.$(ARCH).Dockerfile.ghrunner .

codeserver.armv7l:
	echo "Skip-CodeServer"

codeserver.x86_64 codeserver.aarch64:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.codeserver
	cat Dockertempl.codeserver >> .build.$(ARCH).Dockerfile.codeserver
	$(DOCKER) build -t developers-paradise-codeserver-$(ARCH) -f .build.$(ARCH).Dockerfile.codeserver .

