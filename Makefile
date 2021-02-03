ARCH ?= $(shell uname -m)
DOCKER ?= docker
REPO ?= public.ecr.aws/d3g6c8d4

REV=$(shell test -f .rev && cat .rev)
ARCHS = aarch64 armv7l x86_64

GITHUB_VERSIONS=helm/helm roboll/helmfile mabels/neckless derailed/k9s 99designs/aws-vault cdr/code-server actions/runner estesp/manifest-tool pulumi/pulumi containers/skopeo nvm-sh/nvm dotnet/runtime cli/cli xo/usql

all: .rev base extend ghrunner codeserver.$(ARCH) tag ghrunner-swift.$(ARCH) codeserver-swift.$(ARCH)
	@echo "ARCH=$(ARCH)"
	@echo REV=$(shell cat .rev)


prepare.tar: .versioner .rev
	(for arch in $(ARCHS); \
	do \
	   for image in "$(REPO)/developers-paradise:base-$${arch}$(shell cat .rev)" "$(REPO)/developers-paradise:extend-$${arch}$(shell cat .rev)" "$(REPO)/developers-paradise:ghrunner-$${arch}$(shell cat .rev)" "$(REPO)/developers-paradise:codeserver-$${arch}$(shell cat .rev)"; \
	   do \
		if manifest-tool inspect $$image > /dev/null; \
		then \
			touch .pushed.`basename $$image | sed 's/:/-/g'`; \
			touch .built.$$arch.Dockerfile.`echo $$image | sed 's/^.*:\([^-]*\)-.*$$/\1/'`; \
		else \
			echo "Needs Build: $$image"; \
		fi \
	   done \
	done)
	touch .pushed.DUMMY .built.DUMMY
	tar cf prepare.tar .build_versions .rev .versioner .pushed.* .built.*

.rev: .versioner
	echo -$(shell git rev-parse --short HEAD)-$(shell sha256sum .build_versions | cut -c1-8) > .rev

.versioner: .build_versions 
	(echo "#!/bin/sh"; echo -n "sed "; for i in $(shell cat .build_versions); \
	do \
		echo -n "-e s/@@`echo $${i} | cut -d= -f1`@@/`echo $${i} | cut -d= -f2`/g ";\
	done; echo "") > .versioner
	chmod 755 .versioner
	#cat .versioner


.build_versions: Makefile
	rm -f .build_versions
	APIUSER=$(APIUSER) bash query_versions.sh $(GITHUB_VERSIONS) > .build_versions
	@echo KUBERNETES_VERSION=v1.20.2  >> .build_versions
	@echo GO_VERSION=1.15.7 >> .build_versions
	@echo AWSCLI_VERSION=2.1.23 >> .build_versions
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


push.base: .pushed.developers-paradise-base-$(ARCH)$(REV) \
	.pushed.developers-paradise-extend-$(ARCH)$(REV) \
	.pushed.developers-paradise-ghrunner-$(ARCH)$(REV)

.pushed.developers-paradise-base-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:base-$(ARCH)$(REV)"
	touch .pushed.developers-paradise-base-$(ARCH)$(REV)

.pushed.developers-paradise-extend-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:extend-$(ARCH)$(REV)"
	touch .pushed.developers-paradise-extend-$(ARCH)$(REV)

.pushed.developers-paradise-ghrunner-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:ghrunner-$(ARCH)$(REV)"
	touch .pushed.developers-paradise-ghrunner-$(ARCH)$(REV)

push.codeserver.armv7l:
	echo "Push Skip-CodeServer"

push.codeserver.x86_64 push.codeserver.aarch64: .pushed.developers-paradise-codeserver-$(ARCH)$(REV)

.pushed.developers-paradise-codeserver-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:codeserver-$(ARCH)$(REV)"
	touch .pushed.developers-paradise-codeserver-$(ARCH)$(REV)

base: .built.$(ARCH).Dockerfile.base

.built.$(ARCH).Dockerfile.base: .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base Dockertempl.base .versioner
	cat .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base > .build.$(ARCH).Dockerfile.base
	./.versioner < .build.$(ARCH).Dockerfile.base > .build.$(ARCH).Dockerfile.base.versioned
	$(DOCKER) build -t developers-paradise-base-$(ARCH) -f .build.$(ARCH).Dockerfile.base.versioned .
	touch .built.$(ARCH).Dockerfile.base

.build.x86_64.Dockerfile.base.x86_64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.x86_64

.build.aarch64.Dockerfile.base.aarch64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.aarch64

.build.armv7l.Dockerfile.base.armv7l: Dockerfile.base.debian
	cp Dockerfile.base.debian .build.$(ARCH).Dockerfile.base.armv7l

extend: .versioner .built.$(ARCH).Dockerfile.extend

.built.$(ARCH).Dockerfile.extend: Dockertempl.dotnet Dockertempl.node Dockertempl.pulumi Dockertempl.manifest-tool Dockertempl.skopeo Dockertempl.githubcli Dockertempl.kryptco .versioner Dockertempl.usql
	echo "FROM developers-paradise-base-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.dotnet Dockertempl.node Dockertempl.pulumi >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.manifest-tool >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.skopeo >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.githubcli >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.usql >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.kryptco >> .build.$(ARCH).Dockerfile.extend
	./.versioner < .build.$(ARCH).Dockerfile.extend > .build.$(ARCH).Dockerfile.extend.versioned
	$(DOCKER) build -t developers-paradise-extend-$(ARCH) -f .build.$(ARCH).Dockerfile.extend.versioned .
	touch .built.$(ARCH).Dockerfile.extend

#	cat Dockertempl.rustup >> .build.$(ARCH).Dockerfile.extend

ghrunner-swift.aarch64 ghrunner-swift.armv7l:
	echo "Skip GHRunner Swift"

ghrunner-swift.x86_64: .built.$(ARCH).Dockerfile.ghrunner-swift

.built.$(ARCH).Dockerfile.ghrunner-swift:
	echo "FROM developers-paradise-ghrunner-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.ghrunner-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.ghrunner-swift
	./.versioner < .build.$(ARCH).Dockerfile.ghrunner-swift > .build.$(ARCH).Dockerfile.ghrunner-swift.versioned
	$(DOCKER) build -t developers-paradise-ghrunner-swift-$(ARCH) -f .build.$(ARCH).Dockerfile.ghrunner-swift.versioned .
	touch .built.$(ARCH).Dockerfile.ghrunner-swift
	$(DOCKER) tag developers-paradise-ghrunner-swift-$(ARCH) "$(REPO)/developers-paradise:ghrunner-swift-$(ARCH)$(shell cat .rev)"

codeserver-swift.aarch64 codeserver-swift.armv7l:
	echo "Skip GHRunner Swift"

codeserver-swift.x86_64: .built.$(ARCH).Dockerfile.codeserver-swift

.built.$(ARCH).Dockerfile.codeserver-swift:
	echo "FROM developers-paradise-codeserver-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.codeserver-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.codeserver-swift
	./.versioner < .build.$(ARCH).Dockerfile.codeserver-swift > .build.$(ARCH).Dockerfile.codeserver-swift.versioned
	$(DOCKER) build -t developers-paradise-codeserver-swift-$(ARCH) -f .build.$(ARCH).Dockerfile.codeserver-swift.versioned .
	touch .built.$(ARCH).Dockerfile.codeserver-swift
	$(DOCKER) tag developers-paradise-codeserver-swift-$(ARCH) "$(REPO)/developers-paradise:codeserver-swift-$(ARCH)$(shell cat .rev)"

ghrunner: .built.$(ARCH).Dockerfile.ghrunner

.built.$(ARCH).Dockerfile.ghrunner:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.ghrunner
	cat Dockertempl.ghrunner >> .build.$(ARCH).Dockerfile.ghrunner
	./.versioner < .build.$(ARCH).Dockerfile.ghrunner > .build.$(ARCH).Dockerfile.ghrunner.versioned
	$(DOCKER) build -t developers-paradise-ghrunner-$(ARCH) -f .build.$(ARCH).Dockerfile.ghrunner.versioned .
	touch .built.$(ARCH).Dockerfile.ghrunner

codeserver.armv7l:
	echo "Skip-CodeServer"

codeserver.x86_64 codeserver.aarch64: .built.$(ARCH).Dockerfile.codeserver

.built.$(ARCH).Dockerfile.codeserver:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > .build.$(ARCH).Dockerfile.codeserver
	cat Dockertempl.codeserver >> .build.$(ARCH).Dockerfile.codeserver
	./.versioner < .build.$(ARCH).Dockerfile.codeserver > .build.$(ARCH).Dockerfile.codeserver.versioned
	$(DOCKER) build -t developers-paradise-codeserver-$(ARCH) -f .build.$(ARCH).Dockerfile.codeserver.versioned .
	touch .built.$(ARCH).Dockerfile.codeserver

