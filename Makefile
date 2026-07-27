# Northlight — every workflow runs in a container.
# Do not install Hugo, Node or npm on the host. The official Hugo image is multi-arch,
# so this works on Apple silicon where the plain linux-amd64 tarball does not.
#
# Pinned to an exact version rather than a floating tag, so a build is reproducible
# and an upgrade is a reviewable one-line change. Keep this in step with
# theme.toml's min_version and README's "Requirements". The image entrypoint is hugo
# itself, so recipes pass subcommands and flags directly.
#
# The repo is mounted at /src/northlight rather than /src because Hugo resolves
# --themesDir relative to --source: exampleSite/../.. must be the directory that
# *contains* a folder named after the theme.
#
# `clean` deletes from inside the container rather than from the host. Deleting the
# output directories on the host and then having the container recreate them races on
# a macOS bind mount: the build dies with "open .../public/robots.txt: no such file or
# directory", and the same event surfaces a second time as a misleading
# "resource is nil" template error. Measured over cold builds: 2/12 host-side,
# 0/37 container-side. Deleting and recreating through the same mount client is the
# cheapest thing that removed it.

HUGO_IMAGE ?= ghcr.io/gohugoio/hugo:v0.164.0
RUN         = docker run --rm -v "$(CURDIR)":/src/northlight -w /src/northlight
SITE        = --source exampleSite --themesDir ../..
PATHS       = exampleSite/public exampleSite/resources resources .hugo_build.lock

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

serve: ## Live-reload dev server on http://localhost:1313
	$(RUN) -p 1313:1313 $(HUGO_IMAGE) server $(SITE) \
		--bind 0.0.0.0 --baseURL http://localhost:1313 \
		--buildDrafts --disableFastRender

build: ## Production build of exampleSite
	$(RUN) $(HUGO_IMAGE) $(SITE) --minify --gc

check: ## THE GATE — build with warnings as errors, then sanity-check the output
	$(RUN) $(HUGO_IMAGE) $(SITE) --minify --gc --panicOnWarning
	@test -f exampleSite/public/index.html || { echo "FAIL: no index.html"; exit 1; }
	@test -f exampleSite/public/index.xml  || { echo "FAIL: no RSS"; exit 1; }
	@test -f exampleSite/public/index.json || { echo "FAIL: no search index"; exit 1; }
	@test -f exampleSite/public/404.html   || { echo "FAIL: no 404"; exit 1; }
	@grep -rqi nordbye layouts assets static 2>/dev/null \
		&& { echo "FAIL: author-specific value hardcoded in theme files"; exit 1; } || true
	@echo "OK"

clean: ## Remove build output and caches
	$(RUN) --entrypoint sh $(HUGO_IMAGE) -c 'rm -rf $(PATHS)'

.PHONY: help serve build check clean
