MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash -o pipefail -euc
.DEFAULT_GOAL := help
GO_STAC := us.gcr.io/planet-gcr/go-stac:v0.17.0


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


.PHONY: clean
clean: ## Clean all generated files
	@rm -rf build
