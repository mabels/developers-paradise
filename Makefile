ARCH ?= $(shell uname -m)
DOCKER ?= docker
REPO ?= public.ecr.aws/d3g6c8d4

all: .rev base extend ghrunner codeserver.$(ARCH) tag ghrunner-swift.$(ARCH) codeserver-swift.$(ARCH)
	@echo "ARCH=$(ARCH)"
	@echo REV=$(shell cat .rev)

.rev: .versioner
	echo -$(shell git rev-parse --short HEAD)-$(shell sha256sum .build_versions | cut -c1-8) > .rev

.versioner: .build_versions Makefile
	(echo "#!/bin/sh"; echo -n "sed "; for i in $(shell cat .build_versions); \
	do \
		echo -n "-e s/@@`echo $${i} | cut -d= -f1`@@/`echo $${i} | cut -d= -f2`/g ";\
	done; echo "") > .versioner
	chmod 755 .versioner
	cat .versioner


.build_versions: Makefile
	@echo HELM_VERSION=$(shell curl --silent "https://api.github.com/repos/helm/helm/releases/latest" | jq -r .tag_name)  >> .build_versions
	@echo HELMFILE_VERSION=$(shell curl --silent "https://api.github.com/repos/roboll/helmfile/releases/latest" | jq -r .tag_name) >> .build_versions
	@echo NECKLESS_VERSION=$(shell curl --silent "https://api.github.com/repos/mabels/neckless/releases/latest" | jq -r .tag_name)  >> .build_versions
	@echo K9S_VERSION=$(shell curl --silent "https://api.github.com/repos/derailed/k9s/releases/latest" | jq -r .tag_name)  >> .build_versions
	@echo AWSVAULT_VERSION=$(shell curl --silent "https://api.github.com/repos/99designs/aws-vault/releases/latest" | jq -r .tag_name)  >> .build_versions
	@echo KUBERNETES_VERSION=v1.20.1  >> .build_versions
	@echo CODESERVER_VERSION=$(shell curl --silent "https://api.github.com/repos/cdr/code-server/releases/latest" | jq -r .tag_name)  >> .build_versions
	@echo ACTIONRUNNER_VERSION=$(shell curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r .tag_name)  >> .build_versions
	@echo MANIFESTTOOL_VERSION=$(shell curl --silent "https://api.github.com/repos/estesp/manifest-tool/releases/latest" | jq -r .tag_name)  >> .build_versions
	@echo PULUMI_VERSION=$(shell curl --silent "https://api.github.com/repos/pulumi/pulumi/releases/latest" | jq -r .tag_name) >> .build_versions
	@echo SKOPEO_VERSION=$(shell curl --silent "https://api.github.com/repos/containers/skopeo/releases/latest" | jq -r .tag_name) >> .build_versions
	@echo NVMSH_VERSION=$(shell curl --silent "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | jq -r .tag_name) >> .build_versions
	@echo DOTNET_VERSION=$(shell curl --silent "https://api.github.com/repos/dotnet/runtime/releases/latest" | jq -r .tag_name) >> .build_versions
	@echo GO_VERSION=1.15.6 >> .build_versions
	cat .build_versions

manifest: .rev manifest-base manifest-extend manifest-ghrunner manifest-codeserver manifest-ghrunner-swift manifest-codeserver-swift
	echo "image: $(REPO)/developers-paradise:latest" >> .build.manifest-latest.yaml
	echo "manifests:" >> .build.manifest-latest.yaml
	echo "  -" >> .build.manifest-latest.yaml
	echo "    image: $(REPO)/developers-paradise:codeserver-aarch64$(shell cat .rev)" >> .build.manifest-latest.yaml
	echo "    platform:" >> .build.manifest-latest.yaml
	echo "      architecture: arm64" >> .build.manifest-latest.yaml
	echo "      os: linux" >> .build.manifest-latest.yaml
	echo "  -" >> .build.manifest-latest.yaml
	echo "    image: $(REPO)/developers-paradise:ghrunner-armv7l$(shell cat .rev)" >> .build.manifest-latest.yaml
	echo "    platform:" >> .build.manifest-latest.yaml
	echo "      architecture: arm" >> .build.manifest-latest.yaml
	echo "      os: linux" >> .build.manifest-latest.yaml
	echo "  -" >> .build.manifest-latest.yaml
	echo "    image: $(REPO)/developers-paradise:codeserver-x86_64$(shell cat .rev)" >> .build.manifest-latest.yaml
	echo "    platform:" >> .build.manifest-latest.yaml
	echo "      architecture: amd64" >> .build.manifest-latest.yaml
	echo "      os: linux" >> .build.manifest-latest.yaml
	manifest-tool push from-spec .build.manifest-latest.yaml

manifest-base: .rev
	echo "image: $(REPO)/developers-paradise:base-latest" >> .build.manifest-base.yaml
	echo "manifests:" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: $(REPO)/developers-paradise:base-aarch64$(shell cat .rev)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: arm64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: $(REPO)/developers-paradise:base-armv7l$(shell cat .rev)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: arm" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: $(REPO)/developers-paradise:base-x86_64$(shell cat .rev)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: amd64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	manifest-tool push from-spec .build.manifest-base.yaml

manifest-extend: .rev
	echo "image: $(REPO)/developers-paradise:extend-latest" >> .build.manifest-extend.yaml
	echo "manifests:" >> .build.manifest-extend.yaml
	echo "  -" >> .build.manifest-extend.yaml
	echo "    image: $(REPO)/developers-paradise:extend-aarch64$(shell cat .rev)" >> .build.manifest-extend.yaml
	echo "    platform:" >> .build.manifest-extend.yaml
	echo "      architecture: arm64" >> .build.manifest-extend.yaml
	echo "      os: linux" >> .build.manifest-extend.yaml
	echo "  -" >> .build.manifest-extend.yaml
	echo "    image: $(REPO)/developers-paradise:extend-armv7l$(shell cat .rev)" >> .build.manifest-extend.yaml
	echo "    platform:" >> .build.manifest-extend.yaml
	echo "      architecture: arm" >> .build.manifest-extend.yaml
	echo "      os: linux" >> .build.manifest-extend.yaml
	echo "  -" >> .build.manifest-extend.yaml
	echo "    image: $(REPO)/developers-paradise:extend-x86_64$(shell cat .rev)" >> .build.manifest-extend.yaml
	echo "    platform:" >> .build.manifest-extend.yaml
	echo "      architecture: amd64" >> .build.manifest-extend.yaml
	echo "      os: linux" >> .build.manifest-extend.yaml
	manifest-tool push from-spec .build.manifest-extend.yaml

manifest-ghrunner: .rev
	echo "image: $(REPO)/developers-paradise:ghrunner-latest" >> .build.manifest-ghrunner.yaml
	echo "manifests:" >> .build.manifest-ghrunner.yaml
	echo "  -" >> .build.manifest-ghrunner.yaml
	echo "    image: $(REPO)/developers-paradise:ghrunner-aarch64$(shell cat .rev)" >> .build.manifest-ghrunner.yaml
	echo "    platform:" >> .build.manifest-ghrunner.yaml
	echo "      architecture: arm64" >> .build.manifest-ghrunner.yaml
	echo "      os: linux" >> .build.manifest-ghrunner.yaml
	echo "  -" >> .build.manifest-ghrunner.yaml
	echo "    image: $(REPO)/developers-paradise:ghrunner-armv7l$(shell cat .rev)" >> .build.manifest-ghrunner.yaml
	echo "    platform:" >> .build.manifest-ghrunner.yaml
	echo "      architecture: arm" >> .build.manifest-ghrunner.yaml
	echo "      os: linux" >> .build.manifest-ghrunner.yaml
	echo "  -" >> .build.manifest-ghrunner.yaml
	echo "    image: $(REPO)/developers-paradise:ghrunner-x86_64$(shell cat .rev)" >> .build.manifest-ghrunner.yaml
	echo "    platform:" >> .build.manifest-ghrunner.yaml
	echo "      architecture: amd64" >> .build.manifest-ghrunner.yaml
	echo "      os: linux" >> .build.manifest-ghrunner.yaml
	manifest-tool push from-spec .build.manifest-ghrunner.yaml

manifest-codeserver: .rev
	echo "image: $(REPO)/developers-paradise:codeserver-latest" >> .build.manifest-codeserver.yaml
	echo "manifests:" >> .build.manifest-codeserver.yaml
	echo "  -" >> .build.manifest-codeserver.yaml
	echo "    image: $(REPO)/developers-paradise:codeserver-aarch64$(shell cat .rev)" >> .build.manifest-codeserver.yaml
	echo "    platform:" >> .build.manifest-codeserver.yaml
	echo "      architecture: arm64" >> .build.manifest-codeserver.yaml
	echo "      os: linux" >> .build.manifest-codeserver.yaml
	echo "  -" >> .build.manifest-codeserver.yaml
	echo "    image: $(REPO)/developers-paradise:codeserver-x86_64$(shell cat .rev)" >> .build.manifest-codeserver.yaml
	echo "    platform:" >> .build.manifest-codeserver.yaml
	echo "      architecture: amd64" >> .build.manifest-codeserver.yaml
	echo "      os: linux" >> .build.manifest-codeserver.yaml
	manifest-tool push from-spec .build.manifest-codeserver.yaml

manifest-codeserver-swift: .rev
	echo "image: $(REPO)/developers-paradise:base-latest" >> .build.manifest-base.yaml
	echo "manifests:" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: $(REPO)/developers-paradise:base-x86_64$(shell cat .rev)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: amd64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	manifest-tool push from-spec .build.manifest-base.yaml

manifest-ghrunner-swift: .rev
	echo "image: $(REPO)/developers-paradise:base-latest" >> .build.manifest-base.yaml
	echo "manifests:" >> .build.manifest-base.yaml
	echo "  -" >> .build.manifest-base.yaml
	echo "    image: $(REPO)/developers-paradise:base-x86_64$(shell cat .rev)" >> .build.manifest-base.yaml
	echo "    platform:" >> .build.manifest-base.yaml
	echo "      architecture: amd64" >> .build.manifest-base.yaml
	echo "      os: linux" >> .build.manifest-base.yaml
	manifest-tool push from-spec .build.manifest-base.yaml

tag: tag.codeserver.$(ARCH)
	$(DOCKER) tag developers-paradise-base-$(ARCH) "$(REPO)/developers-paradise:base-$(ARCH)$(shell cat .rev)"
	$(DOCKER) tag developers-paradise-extend-$(ARCH) "$(REPO)/developers-paradise:extend-$(ARCH)$(shell cat .rev)"
	$(DOCKER) tag developers-paradise-ghrunner-$(ARCH) "$(REPO)/developers-paradise:ghrunner-$(ARCH)$(shell cat .rev)"

tag.codeserver.armv7l:
	echo "Tag Skip-CodeServer"

tag.codeserver.x86_64 tag.codeserver.aarch64:
	$(DOCKER) tag developers-paradise-codeserver-$(ARCH) "$(REPO)/developers-paradise:codeserver-$(ARCH)$(shell cat .rev)"


push: push.base push.codeserver.$(ARCH)

push.base:
	$(DOCKER) push "$(REPO)/developers-paradise:base-$(ARCH)$(shell cat .rev)"
	$(DOCKER) push "$(REPO)/developers-paradise:extend-$(ARCH)$(shell cat .rev)"
	$(DOCKER) push "$(REPO)/developers-paradise:ghrunner-$(ARCH)$(shell cat .rev)"

push.codeserver.armv7l:
	echo "Push Skip-CodeServer"

push.codeserver.x86_64 push.codeserver.aarch64:
	$(DOCKER) push "$(REPO)/developers-paradise:codeserver-$(ARCH)$(shell cat .rev)"

base: .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base Dockertempl.base .versioner
	cat .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base > .build.$(ARCH).Dockerfile.base
	./.versioner < .build.$(ARCH).Dockerfile.base > .build.$(ARCH).Dockerfile.base.versioned
	$(DOCKER) build -t developers-paradise-base-$(ARCH) -f .build.$(ARCH).Dockerfile.base.versioned .

.build.x86_64.Dockerfile.base.x86_64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.x86_64

.build.aarch64.Dockerfile.base.aarch64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.aarch64

.build.armv7l.Dockerfile.base.armv7l: Dockerfile.base.debian
	cp Dockerfile.base.debian .build.$(ARCH).Dockerfile.base.armv7l

extend: .versioner
	echo "FROM developers-paradise-base-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.dotnet Dockertempl.node Dockertempl.pulumi >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.manifest-tool >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.skopeo >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.kryptco >> .build.$(ARCH).Dockerfile.extend
	./.versioner < .build.$(ARCH).Dockerfile.extend > .build.$(ARCH).Dockerfile.extend.versioned
	$(DOCKER) build -t developers-paradise-extend-$(ARCH) -f .build.$(ARCH).Dockerfile.extend.versioned .

#	cat Dockertempl.rustup >> .build.$(ARCH).Dockerfile.extend

ghrunner-swift.aarch64 ghrunner-swift.armv7l:
	echo "Skip GHRunner Swift"

ghrunner-swift.x86_64:
	echo "FROM developers-paradise-ghrunner-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.ghrunner-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.ghrunner-swift
	./.versioner < .build.$(ARCH).Dockerfile.ghrunner-swift > .build.$(ARCH).Dockerfile.ghrunner-swift.versioned
	$(DOCKER) build -t developers-paradise-ghrunner-swift-$(ARCH) -f .build.$(ARCH).Dockerfile.ghrunner-swift.versioned .
	$(DOCKER) tag developers-paradise-ghrunner-swift-$(ARCH) "$(REPO)/developers-paradise:ghrunner-swift-$(ARCH)$(shell cat .rev)"

codeserver-swift.aarch64 codeserver-swift.armv7l:
	echo "Skip GHRunner Swift"

codeserver-swift.x86_64:
	echo "FROM developers-paradise-codeserver-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.codeserver-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.codeserver-swift
	./.versioner < .build.$(ARCH).Dockerfile.codeserver-swift > .build.$(ARCH).Dockerfile.codeserver-swift.versioned
	$(DOCKER) build -t developers-paradise-codeserver-swift-$(ARCH) -f .build.$(ARCH).Dockerfile.codeserver-swift.versioned .
	$(DOCKER) tag developers-paradise-codeserver-swift-$(ARCH) "$(REPO)/developers-paradise:codeserver-swift-$(ARCH)$(shell cat .rev)"

ghrunner:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.ghrunner
	cat Dockertempl.ghrunner >> .build.$(ARCH).Dockerfile.ghrunner
	./.versioner < .build.$(ARCH).Dockerfile.ghrunner > .build.$(ARCH).Dockerfile.ghrunner.versioned
	$(DOCKER) build -t developers-paradise-ghrunner-$(ARCH) -f .build.$(ARCH).Dockerfile.ghrunner.versioned .

codeserver.armv7l:
	echo "Skip-CodeServer"

codeserver.x86_64 codeserver.aarch64:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.codeserver
	cat Dockertempl.codeserver >> .build.$(ARCH).Dockerfile.codeserver
	./.versioner < .build.$(ARCH).Dockerfile.codeserver > .build.$(ARCH).Dockerfile.codeserver.versioned
	$(DOCKER) build -t developers-paradise-codeserver-$(ARCH) -f .build.$(ARCH).Dockerfile.codeserver.versioned .

