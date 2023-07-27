MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash -o pipefail -euc
.DEFAULT_GOAL := help
GO_STAC := us.gcr.io/planet-gcr/go-stac:v0.22.0
NODE := docker.io/library/node:20-alpine3.17
STAC_BROWSER_URL := https://github.com/m-mohr/planet-stac-browser.git
STAC_BROWSER_SHA := 949f67cb971e85c9c71a077d588b3ddaa05e55b1

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


.PHONY: build
build: ## Rewrite all STAC files referenced by ./stac/catalog.json to use absolute links, write to build/stac dir
	@docker run \
		--volume $$(pwd):/work \
		$(GO_STAC) make-links-absolute \
			--entry /work/stac/catalog.json \
			--url https://www.planet.com/data/stac/catalog.json \
			--output /work/build/stac


.PHONY: validate
validate: ## Validate all STAC files referenced by ./stac/catalog.json
	@docker run \
		--volume $$(pwd):/work \
		$(GO_STAC) validate \
			--entry /work/stac/catalog.json


.PHONY: stats
stats: ## Add stats metadata to ./stac/catalog.json
	@docker run \
		--volume $$(pwd):/work \
		$(GO_STAC) stats \
			--entry /work/stac/catalog.json \
			--output /work/stac/catalog.json


.PHONY: format
format: ## Format all STAC files referenced by ./stac/catalog.json
	@docker run \
		--volume $$(pwd):/work \
		$(GO_STAC) format \
			--entry /work/stac/catalog.json \
			--output /work/stac


.PHONY: browser
browser: build/.browser-$(STAC_BROWSER_SHA) ## Build the customized STAC Browser

build/.browser-$(STAC_BROWSER_SHA):
	@mkdir -p stac-browser && \
		cd stac-browser && \
		git init && \
		git config remote.origin.url >&- || git remote add origin $(STAC_BROWSER_URL) && \
		git fetch --depth 1 origin $(STAC_BROWSER_SHA) && \
		git checkout FETCH_HEAD
	@docker run \
		--volume $$(pwd)/stac-browser:/stac-browser \
		--workdir /stac-browser \
		$(NODE) sh -c 'npm install && npm run build:minimal -- --pathPrefix="/data/stac/browser/"'
	@mkdir -p build/stac/browser
	@cp -r stac-browser/dist/* build/stac/browser
	touch $@


.PHONY: clean
clean: ## Clean all generated files
	@rm -rf build
