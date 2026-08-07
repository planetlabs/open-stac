MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash -o pipefail -euc
.DEFAULT_GOAL := help
GO_STAC := ghcr.io/planetlabs/go-stac:v0.33.0
NODE := docker.io/library/node:26-alpine
STAC_BROWSER_URL := https://github.com/radiantearth/stac-browser.git
# radiant v5.0.0
STAC_BROWSER_SHA := ae1956e8cb2067ce27938b3ae70c00515ac0ff33
CATALOG_URL ?= https://www.planet.com/data/stac/catalog.json
PATH_PREFIX ?= /data/stac/browser/
STAC_URL_HASH := $(shell printf '%s' '$(CATALOG_URL)' | openssl dgst -sha256 | awk '{print substr($$2,1,8)}')
STAC_STAMP := build/.stac-$(STAC_URL_HASH)
BROWSER_OVERLAY_HASH := $(shell tar -cf - -C browser --exclude README.md . 2>/dev/null | openssl dgst -sha256 | awk '{print substr($$2,1,12)}')
BROWSER_PATH_HASH := $(shell printf '%s\0%s' '$(PATH_PREFIX)' '$(CATALOG_URL)' | openssl dgst -sha256 | awk '{print substr($$2,1,8)}')
BROWSER_STAMP := build/.browser-$(STAC_BROWSER_SHA)-$(BROWSER_OVERLAY_HASH)-$(BROWSER_PATH_HASH)

# Expand stac file lists only when the catalog build is actually considered (not on every make).
.SECONDEXPANSION:

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


.PHONY: build
build: $(STAC_STAMP) ## Rewrite all STAC files referenced by ./stac/catalog.json to use absolute links, write to build/stac dir

$(STAC_STAMP): $$(shell find stac -type f) Makefile
	@mkdir -p build
	@# Preserve a prior browser build if go-stac replaces build/stac
	@if [ -d build/stac/browser ]; then \
		rm -rf build/.browser-preserve; \
		mv build/stac/browser build/.browser-preserve; \
	fi
	@docker run \
		--rm \
		--volume $$(pwd):/work \
		$(GO_STAC) make-links-absolute \
			--entry /work/stac/catalog.json \
			--url $(CATALOG_URL) \
			--output /work/build/stac
	@if [ -d build/.browser-preserve ]; then \
		rm -rf build/stac/browser; \
		mv build/.browser-preserve build/stac/browser; \
	fi
	@rm -f build/.stac-*
	@touch $@


.PHONY: validate
validate: ## Validate all STAC files referenced by ./stac/catalog.json
	@docker run \
		--rm \
		--volume $$(pwd):/work \
		$(GO_STAC) validate \
			--entry /work/stac/catalog.json


.PHONY: stats
stats: ## Add stats metadata to ./stac/catalog.json
	@docker run \
		--rm \
		--volume $$(pwd):/work \
		$(GO_STAC) stats \
			--entry /work/stac/catalog.json \
			--output /work/stac/catalog.json


.PHONY: format
format: ## Format all STAC files referenced by ./stac/catalog.json
	@docker run \
		--rm \
		--volume $$(pwd):/work \
		$(GO_STAC) format \
			--entry /work/stac/catalog.json \
			--output /work/stac


.PHONY: browser
browser: $(BROWSER_STAMP) ## Build STAC Browser (radiant) with Planet overlays

$(BROWSER_STAMP): $(shell find browser -type f) Makefile
	@rm -rf stac-browser
	@mkdir -p stac-browser && \
		cd stac-browser && \
		git init && \
		git remote add origin $(STAC_BROWSER_URL) && \
		git fetch --depth 1 origin $(STAC_BROWSER_SHA) && \
		git checkout FETCH_HEAD
	@cp browser/config.mjs stac-browser/config.planet.mjs
	@cp browser/theme/variables.scss stac-browser/src/theme/variables.scss
	@cp browser/theme/custom.scss stac-browser/src/theme/custom.scss
	@cp browser/assets/planet-logo.svg stac-browser/public/planet-logo.svg
	@cp browser/components/HeaderTitle.vue stac-browser/src/components/HeaderTitle.vue
	@docker run \
		--volume $$(pwd)/stac-browser:/stac-browser \
		--workdir /stac-browser \
		--env SB_CONFIG=./config.planet.mjs \
		--env SB_pathPrefix=$(PATH_PREFIX) \
		--env SB_catalogUrl=$(CATALOG_URL) \
		--env SB_catalogImage=$(PATH_PREFIX)planet-logo.svg \
		$(NODE) sh -c 'npm install && npm run build:minimal'
	@mkdir -p build/stac/browser
	@rm -rf build/stac/browser/*
	@cp -r stac-browser/dist/* build/stac/browser
	@mkdir -p build
	@rm -f build/.browser-*
	@touch $@


.PHONY: preview
preview: build browser ## Preview the catalog
	@docker run \
		--rm \
		--volume $$(pwd):/work \
		--publish 8000:8000 \
		--workdir /work \
		us.gcr.io/planet-gcr/static serve \
			--dir build/stac \
			--prefix data/stac \
			--config static.json


.PHONY: clean
clean: ## Clean all generated files
	@rm -rf build stac-browser
