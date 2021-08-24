ARCH ?= $(shell uname -m)
DOCKER ?= docker
REPO ?= public.ecr.aws/d3g6c8d4
TOUCHSLEEP ?= sleep 1; touch

REV=$(shell test -f .rev && cat .rev)
ARCHS = aarch64 armv7l x86_64

GITHUB_VERSIONS=helm/helm roboll/helmfile mabels/neckless derailed/k9s 99designs/aws-vault cdr/code-server \
		actions/runner estesp/manifest-tool pulumi/pulumictl pulumi/pulumi containers/skopeo \
		nvm-sh/nvm cli/cli xo/usql

all: .rev base extend ghrunner codeserver.$(ARCH) tag # ghrunner-swift.$(ARCH) codeserver-swift.$(ARCH)
	@echo "ARCH=$(ARCH)"
	@echo REV=$(shell cat .rev)


prepare.tar: .rev
	(for arch in $(ARCHS); \
	do \
	   for image in "$(REPO)/developers-paradise:base-$${arch}-$(shell cat .rev)" "$(REPO)/developers-paradise:extend-$${arch}-$(shell cat .rev)" "$(REPO)/developers-paradise:ghrunner-$${arch}-$(shell cat .rev)" "$(REPO)/developers-paradise:codeserver-$${arch}-$(shell cat .rev)"; \
	   do \
		if DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect $$image > /dev/null; \
		then \
			touch .pushed.`basename $$image | sed 's/:/-/g'`; \
			touch .built.$$arch.Dockerfile.`echo $$image | sed 's/^.*:\([^-]*\)-.*$$/\1/'`; \
		else \
			echo "Needs Build: $$image"; \
		fi \
	   done \
	done)
	touch .pushed.DUMMY .built.DUMMY
	tar cf prepare.tar .build_versions .rev .versioner .pushed.* .built.* .npm_install.done node_modules

.rev: .versioner
	$(TOUCHSLEEP) /dev/null
	echo $(shell git rev-parse --short HEAD)-$(shell sha256sum .build_versions | cut -c1-8) > .rev

.versioner: .build_versions
	(echo "#!/bin/sh"; echo -n "sed "; for i in $(shell node merge_env.js .build_versions); \
	do \
		echo -n "-e s/@@`echo $${i} | cut -d= -f1`@@/`echo $${i} | cut -d= -f2`/g ";\
	done; echo "") > .versioner
	chmod 755 .versioner
	$(TOUCHSLEEP) /dev/null
	#cat .versioner


.build_versions: .npm_install.done
	rm -f .build_versions
	APIUSER=$(APIUSER) npm run --silent query $(GITHUB_VERSIONS) >> .build_versions
	APIUSER=$(APIUSER) npm run --silent latest dotnet/runtime aws/aws-cli kubernetes/kubernetes derailed/tview >> .build_versions
	npm run --silent git_version https://go.googlesource.com/go >> .build_versions
	@echo ESTESP_MANIFEST_TOOL_VERSION=main >> .build_versions
	cat .build_versions
	$(TOUCHSLEEP) /dev/null

clean_repo: .npm_install.done
	npm run clean_repo

.npm_install.done:
	npm install
	$(TOUCHSLEEP) .npm_install.done

manifest: .rev .npm_install.done manifest-latest manifest-base manifest-extend manifest-ghrunner
# manifest-codeserver manifest-ghrunner-swift manifest-codeserver-swift

manifest-latest:
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag latest --tag codeserver \
		$(ARCHSELECT) \
	       	--arch aarch64 \
		--arch armv7l:ghrunner \
		--arch x86_64 --out .build.manifest-latest.yaml
	manifest-tool push from-spec .build.manifest-latest.yaml
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag $(shell cat .rev) --tag codeserver \
		$(ARCHSELECT) \
	       	--arch aarch64 \
		--arch armv7l:ghrunner \
		--arch x86_64  --out .build.manifest-$(shell cat .rev).yaml
	manifest-tool push from-spec .build.manifest-$(shell cat .rev).yaml

manifest-base:
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag base-latest --tag base \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch armv7l \
		--arch x86_64 --out .build.manifest-base-latest.yaml
	manifest-tool push from-spec .build.manifest-base-latest.yaml
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag base-$(shell cat .rev) --tag base \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch armv7l \
		--arch x86_64 --out .build.manifest-base-$(shell cat .rev).yaml
	manifest-tool push from-spec .build.manifest-base-$(shell cat .rev).yaml

manifest-extend:
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag extend-latest --tag extend \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch armv7l \
		--arch x86_64 --out .build.manifest-extend-latest.yaml
	manifest-tool push from-spec .build.manifest-extend-latest.yaml
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag extend-$(shell cat .rev) --tag extend \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch armv7l \
		--arch x86_64 --out .build.manifest-extend-$(shell cat .rev).yaml
	manifest-tool push from-spec .build.manifest-extend-$(shell cat .rev).yaml

manifest-ghrunner:
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag ghrunner-latest --tag ghrunner \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch armv7l \
		--arch x86_64 --out .build.manifest-ghrunner-latest.yaml
	manifest-tool push from-spec .build.manifest-ghrunner-latest.yaml
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag ghrunner-$(shell cat .rev) --tag ghrunner \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch armv7l \
		--arch x86_64 --out .build.manifest-ghrunner-$(shell cat .rev).yaml
	manifest-tool push from-spec .build.manifest-ghrunner-$(shell cat .rev).yaml

manifest-codeserver:
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag codeserver-latest --tag codeserver \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch x86_64 --out .build.manifest-codeserver-latest.yaml
	manifest-tool push from-spec .build.manifest-codeserver-latest.yaml
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag codeserver-$(shell cat .rev) --tag codeserver  \
		$(ARCHSELECT) \
		--arch aarch64 \
		--arch x86_64 --out .build.manifest-codeserver-$(shell cat .rev).yaml
	manifest-tool push from-spec .build.manifest-codeserver-$(shell cat .rev).yaml

manifest-codeserver-swift:
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag codeserver-swift-latest --tag codeserver-swift \
		$(ARCHSELECT) \
		--arch "x86_64" --out .build.manifest-codeserver-swift-latest.yaml
	manifest-tool push from-spec .build.manifest-codeserver-swift-latest.yaml
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag codeserver-swift-$(shell cat .rev)--tag codeserver-swift  \
		$(ARCHSELECT) \
		--arch "x86_64" --out .build.manifest-codeserver-swift-$(shell cat .rev).yaml
	manifest-tool push from-spec .build.manifest-codeserver-swift-$(shell cat .rev).yaml

manifest-ghrunner-swift:
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag ghrunner-swift-latest --tag ghrunner-swift \
		$(ARCHSELECT) \
		--arch "x86_64" --out .build.manifest-ghrunner-swift-latest.yaml
	manifest-tool push from-spec .build.manifest-ghrunner-swift-latest.yaml
	npm run produce -- --repo $(REPO) --rev $(shell cat .rev) --imageTag ghrunner-swift-$(shell cat .rev) --tag ghrunner-swift \
		$(ARCHSELECT) \
		--arch "x86_64" --out .build.manifest-ghrunner-swift-$(shell cat .rev).yaml
	manifest-tool push from-spec .build.manifest-ghrunner-swift-$(shell cat .rev).yaml

tag: .rev tag.codeserver.$(ARCH)
	$(DOCKER) tag developers-paradise:base-$(ARCH)-$(shell cat .rev) "$(REPO)/developers-paradise:base-$(ARCH)-$(shell cat .rev)"
	$(DOCKER) tag developers-paradise:extend-$(ARCH)-$(shell cat .rev) "$(REPO)/developers-paradise:extend-$(ARCH)-$(shell cat .rev)"
	$(DOCKER) tag developers-paradise:ghrunner-$(ARCH)-$(shell cat .rev) "$(REPO)/developers-paradise:ghrunner-$(ARCH)-$(shell cat .rev)"

tag.codeserver.armv7l:
	echo "Tag Skip-CodeServer"

tag.codeserver.x86_64:
	$(DOCKER) tag developers-paradise:codeserver-$(ARCH)-$(shell cat .rev) "$(REPO)/developers-paradise:codeserver-$(ARCH)-$(shell cat .rev)"

tag.codeserver.aarch64:
	$(DOCKER) tag developers-paradise:codeserver-$(ARCH)-$(shell cat .rev) "$(REPO)/developers-paradise:codeserver-$(ARCH)-$(shell cat .rev)"


push: push.base push.codeserver.$(ARCH)


push.base: .pushed.developers-paradise-base-$(ARCH)$(REV) \
	.pushed.developers-paradise-extend-$(ARCH)$(REV) \
	.pushed.developers-paradise-ghrunner-$(ARCH)$(REV)

.pushed.developers-paradise-base-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:base-$(ARCH)-$(REV)"
	$(TOUCHSLEEP) .pushed.developers-paradise-base-$(ARCH)$(REV)

.pushed.developers-paradise-extend-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:extend-$(ARCH)-$(REV)"
	$(TOUCHSLEEP) .pushed.developers-paradise-extend-$(ARCH)$(REV)

.pushed.developers-paradise-ghrunner-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:ghrunner-$(ARCH)-$(REV)"
	$(TOUCHSLEEP) .pushed.developers-paradise-ghrunner-$(ARCH)$(REV)

push.codeserver.armv7l:
	echo "Push Skip-CodeServer"

push.codeserver.x86_64: .pushed.developers-paradise-codeserver-$(ARCH)$(REV)

push.codeserver.aarch64: .pushed.developers-paradise-codeserver-$(ARCH)$(REV)

.pushed.developers-paradise-codeserver-$(ARCH)$(REV):
	$(DOCKER) push "$(REPO)/developers-paradise:codeserver-$(ARCH)-$(REV)"
	$(TOUCHSLEEP) .pushed.developers-paradise-codeserver-$(ARCH)$(REV)

base: .rev .built.$(ARCH).Dockerfile.base

.built.$(ARCH).Dockerfile.base: .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base Dockertempl.base
	cat .build.$(ARCH).Dockerfile.base.$(ARCH) Dockertempl.base > .build.$(ARCH).Dockerfile.base
	./.versioner < .build.$(ARCH).Dockerfile.base > .build.$(ARCH).Dockerfile.base.versioned
	$(DOCKER) build -t developers-paradise:base-$(ARCH)-$(shell cat .rev) -f .build.$(ARCH).Dockerfile.base.versioned .
	$(TOUCHSLEEP) .built.$(ARCH).Dockerfile.base

.build.x86_64.Dockerfile.base.x86_64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.x86_64

.build.aarch64.Dockerfile.base.aarch64: Dockerfile.base.ubuntu
	cp Dockerfile.base.ubuntu .build.$(ARCH).Dockerfile.base.aarch64

.build.armv7l.Dockerfile.base.armv7l: Dockerfile.base.debian
	cp Dockerfile.base.debian .build.$(ARCH).Dockerfile.base.armv7l

extend: .versioner .built.$(ARCH).Dockerfile.extend

.built.$(ARCH).Dockerfile.extend: Dockertempl.dotnet Dockertempl.node Dockertempl.pulumi Dockertempl.manifest-tool Dockertempl.skopeo Dockertempl.githubcli Dockertempl.kryptco Dockertempl.usql.$(ARCH) Dockertempl.oracle.$(ARCH)
	echo "FROM developers-paradise:base-$(ARCH)-$(shell cat .rev) AS base" > .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.dotnet Dockertempl.node Dockertempl.pulumi >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.manifest-tool >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.skopeo >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.githubcli >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.oracle.$(ARCH) >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.usql.$(ARCH) >> .build.$(ARCH).Dockerfile.extend
	cat Dockertempl.kryptco >> .build.$(ARCH).Dockerfile.extend
	./.versioner < .build.$(ARCH).Dockerfile.extend > .build.$(ARCH).Dockerfile.extend.versioned
	$(DOCKER) build -t developers-paradise:extend-$(ARCH)-$(shell cat .rev) -f .build.$(ARCH).Dockerfile.extend.versioned .
	$(TOUCHSLEEP) .built.$(ARCH).Dockerfile.extend

Dockertempl.usql.$(ARCH):
	$(TOUCHSLEEP) Dockertempl.usql.$(ARCH)

Dockertempl.usql.x86_64:

Dockertempl.oracle.$(ARCH):
	$(TOUCHSLEEP) Dockertempl.oracle.$(ARCH)

Dockertempl.oracle.x86_64:

ghrunner-swift.aarch64:
	echo "Skip GHRunner Swift"

ghrunner-swift.armv7l:
	echo "Skip GHRunner Swift"

ghrunner-swift.x86_64: .built.$(ARCH).Dockerfile.ghrunner-swift

.built.$(ARCH).Dockerfile.ghrunner-swift:
	echo "FROM developers-paradise:ghrunner-$(ARCH)-$(shell cat .rev) AS base" > .build.$(ARCH).Dockerfile.ghrunner-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.ghrunner-swift
	./.versioner < .build.$(ARCH).Dockerfile.ghrunner-swift > .build.$(ARCH).Dockerfile.ghrunner-swift.versioned
	$(DOCKER) build -t developers-paradise:ghrunner-swift-$(ARCH)-$(shell cat .rev) -f .build.$(ARCH).Dockerfile.ghrunner-swift.versioned .
	$(DOCKER) tag developers-paradise:ghrunner-swift-$(ARCH)-$(shell cat .rev) "$(REPO)/developers-paradise:ghrunner-swift-$(ARCH)-$(shell cat .rev)"
	$(TOUCHSLEEP) .built.$(ARCH).Dockerfile.ghrunner-swift

codeserver-swift.aarch64:
	echo "Skip GHRunner Swift"
codeserver-swift.armv7l:
	echo "Skip GHRunner Swift"

codeserver-swift.x86_64: .built.$(ARCH).Dockerfile.codeserver-swift

.built.$(ARCH).Dockerfile.codeserver-swift:
	echo "FROM developers-paradise:codeserver-$(ARCH)-$(shell cat .rev) AS base" > .build.$(ARCH).Dockerfile.codeserver-swift
	cat Dockertempl.swift >> .build.$(ARCH).Dockerfile.codeserver-swift
	./.versioner < .build.$(ARCH).Dockerfile.codeserver-swift > .build.$(ARCH).Dockerfile.codeserver-swift.versioned
	$(DOCKER) build -t developers-paradise:codeserver-swift-$(ARCH)-$(shell cat .rev) -f .build.$(ARCH).Dockerfile.codeserver-swift.versioned .
	$(DOCKER) tag developers-paradise:codeserver-swift-$(ARCH)-$(shell cat .rev) "$(REPO)/developers-paradise:codeserver-swift-$(ARCH)-$(shell cat .rev)"
	$(TOUCHSLEEP) .built.$(ARCH).Dockerfile.codeserver-swift

ghrunner: .built.$(ARCH).Dockerfile.ghrunner

.built.$(ARCH).Dockerfile.ghrunner:
	echo "FROM developers-paradise:extend-$(ARCH)-$(shell cat .rev) AS base" > .build.$(ARCH).Dockerfile.ghrunner
	cat Dockertempl.ghrunner >> .build.$(ARCH).Dockerfile.ghrunner
	./.versioner < .build.$(ARCH).Dockerfile.ghrunner > .build.$(ARCH).Dockerfile.ghrunner.versioned
	$(DOCKER) build -t developers-paradise:ghrunner-$(ARCH)-$(shell cat .rev) -f .build.$(ARCH).Dockerfile.ghrunner.versioned .
	$(TOUCHSLEEP) .built.$(ARCH).Dockerfile.ghrunner

codeserver.armv7l:
	echo "Skip-CodeServer"

codeserver.x86_64: .built.$(ARCH).Dockerfile.codeserver

codeserver.aarch64: .built.$(ARCH).Dockerfile.codeserver

.built.$(ARCH).Dockerfile.codeserver:
	echo "FROM developers-paradise:extend-$(ARCH)-$(shell cat .rev) AS base" > .build.$(ARCH).Dockerfile.codeserver
	cat Dockertempl.codeserver >> .build.$(ARCH).Dockerfile.codeserver
	./.versioner < .build.$(ARCH).Dockerfile.codeserver > .build.$(ARCH).Dockerfile.codeserver.versioned
	$(DOCKER) build -t developers-paradise:codeserver-$(ARCH)-$(shell cat .rev) -f .build.$(ARCH).Dockerfile.codeserver.versioned .
	$(TOUCHSLEEP) .built.$(ARCH).Dockerfile.codeserver

