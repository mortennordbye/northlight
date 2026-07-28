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
# 0/62 container-side across three sampling runs. Deleting and recreating through the
# same mount client is the cheapest thing that removed it.
#
# If it ever comes back, it will be because something outside make deleted public/ —
# Finder, git clean, a stray rm -rf — which bypasses this entirely.

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

# `serve` renders to disk, into the same exampleSite/public that this target builds and
# tests/run.sh then reads. With a dev server running and any file being edited, the two
# race: the watcher rebuilds with --buildDrafts and a localhost baseURL, `check` rebuilds
# without them, and the suite reads whichever finished last. Measured at 4 failures in 8
# runs with a server up and a template being touched, against 0 in 55 runs with no server
# — which is why this looked like a mysterious intermittent flake for so long, and why it
# always went green on a re-run.
#
# Refusing is deliberate rather than papering over it: a gate that silently produces a
# different answer depending on what else is running is worse than one that stops.
check: ## THE GATE — build with warnings as errors, then run the test suite
	@if docker ps --filter ancestor=$(HUGO_IMAGE) --format '{{.Command}}' 2>/dev/null | grep -q serv; then \
		echo "make check: a dev server is running, and it writes the same exampleSite/public"; \
		echo "            this gate builds and tests. Stop it first (Ctrl-C in the 'make serve'"; \
		echo "            terminal), or the results depend on which build finished last."; \
		exit 1; \
	fi
	$(RUN) $(HUGO_IMAGE) $(SITE) --minify --gc --panicOnWarning
	@sh tests/run.sh

# Same gate, for a Docker daemon that cannot see this directory — DOCKER_HOST pointing at
# another machine, or a daemon in its own VM without the repo on a shared path. There the
# bind mount in RUN resolves to an empty directory and `check` dies with
# "failed to open dir /src/northlight/exampleSite". This ships the source over the daemon
# socket instead. Same image, same flags, same test suite; only the delivery differs.
#
# `check` remains the gate. Reach for this one only when `check` cannot see the source.
#
# Only files git knows about are sent, tracked and untracked-but-not-ignored alike, so
# build output and caches never make the trip.
check-remote: ## THE GATE, for a Docker daemon that cannot bind-mount this directory
	@set -eu; \
	tarball=$$(mktemp); \
	cid=""; \
	trap 'rm -f "$$tarball"; [ -n "$$cid" ] && docker rm -f "$$cid" >/dev/null 2>&1 || true' EXIT; \
	{ git ls-files -z; git ls-files -z --others --exclude-standard; } \
		| tar --null -T - -cf "$$tarball"; \
	chmod 644 "$$tarball"; \
	cid=$$(docker create --entrypoint sh $(HUGO_IMAGE) -c \
		'mkdir -p /tmp/northlight \
			&& tar -xf /tmp/src.tar -C /tmp/northlight \
			&& cd /tmp/northlight \
			&& hugo $(SITE) --minify --gc --panicOnWarning'); \
	docker cp "$$tarball" "$$cid:/tmp/src.tar" >/dev/null; \
	docker start -a "$$cid"; \
	rm -rf exampleSite/public; \
	docker cp "$$cid:/tmp/northlight/exampleSite/public" exampleSite/public >/dev/null
	@sh tests/run.sh

test: ## Run the test suite against the current build (see check)
	@sh tests/run.sh

clean: ## Remove build output and caches
	$(RUN) --entrypoint sh $(HUGO_IMAGE) -c 'rm -rf $(PATHS)'

.PHONY: help serve build check check-remote test clean
