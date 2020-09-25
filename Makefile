ARCH ?= $(shell uname -m)
REV ?= -$(shell git rev-parse --short HEAD)

all: base extend ghrunner codeserver tag 

publish: all push

tag:
	docker tag developers-paradise-base-$(ARCH) "fastandfearless/developers-paradise:base-$(ARCH)$(REV)"
	docker tag developers-paradise-extend-$(ARCH) "fastandfearless/developers-paradise:extend-$(ARCH)$(REV)"
	docker tag developers-paradise-codeserver-$(ARCH) "fastandfearless/developers-paradise:codeserver-$(ARCH)$(REV)"
	docker tag developers-paradise-ghrunner-$(ARCH) "fastandfearless/developers-paradise:ghrunner-$(ARCH)$(REV)"

push:
	docker push "fastandfearless/developers-paradise:base-$(ARCH)$(REV)"
	docker push "fastandfearless/developers-paradise:extend-$(ARCH)$(REV)"
	docker push "fastandfearless/developers-paradise:codeserver-$(ARCH)$(REV)"
	docker push "fastandfearless/developers-paradise:ghrunner-$(ARCH)$(REV)"

base: 
	docker build -t developers-paradise-base-$(ARCH) -f Dockerfile.base .

extend:
	echo "FROM developers-paradise-base-$(ARCH) AS base" > Dockerfile.extend
	cat Dockertempl.dotnet Dockertempl.node Dockertempl.swift >> Dockerfile.extend
	docker build -t developers-paradise-extend-$(ARCH) -f Dockerfile.extend .

ghrunner:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > Dockerfile.ghrunner
	cat Dockertempl.ghrunner >> Dockerfile.ghrunner
	docker build -t developers-paradise-ghrunner-$(ARCH) -f Dockerfile.ghrunner .

codeserver:
	echo "FROM developers-paradise-extend-$(ARCH) AS base" > Dockerfile.codeserver
	cat Dockertempl.codeserver >> Dockerfile.codeserver
	docker build -t developers-paradise-codeserver-$(ARCH) -f Dockerfile.codeserver .

