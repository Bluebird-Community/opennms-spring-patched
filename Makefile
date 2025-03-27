##
# Makefile to build patches Spring dependencies from source
##
.DEFAULT_GOAL      := jars

SHELL              := /bin/bash -o nounset -o pipefail -o errexit
MAVEN_BIN          := $(shell command -v mvn)
JAVA_MAJOR_VERSION := 17
ARTIFACTS_DIR      := target/artifacts

GIT_BRANCH          := $(shell git branch --show-current)
RELEASE_VERSION     := UNSET
RELEASE_BRANCH      := main
PUSH_RELEASE        := false
MAJOR_VERSION       := $(shell echo $(RELEASE_VERSION) | cut -d. -f1)
SNAPSHOT_VERSION    := $(shell expr $(MAJOR_VERSION) + 1)
MAVEN_REPO          := bluebird-snapshots
MAVEN_USERNAME      := ""
MAVEN_PASSWORD      := ""
RELEASE_LOG         := target/release.log
OK                  := "[ 👍 ]"
SKIP                := "[ ⏭️ ]"

.PHONY: deps-build
deps-build:
	@echo -n "👮‍♀️Check Maven binary:          "
	@command -v $(MAVEN_BIN) > /dev/null
	@echo $(OK)
	@echo -n "👮‍♀️Check Java runtime:          "
	@command -v java > /dev/null
	@echo $(OK)
	@echo -n "👮‍♀️Check Java compiler:         "
	@command -v javac > /dev/null
	@echo $(OK)
	@mkdir -p $(ARTIFACTS_DIR)
	@echo -n "👮‍♀️Check Java version $(JAVA_MAJOR_VERSION):       "
	@java -version 2>&1 | grep '$(JAVA_MAJOR_VERSION)\..*' >/dev/null
	@echo $(OK)

.PHONY: jars
jars: deps-build
	@$(MAVEN_BIN) install

.PHONY: release
release: deps-build
	@mkdir -p target
	@echo ""
	@echo "Release version:                $(RELEASE_VERSION)"
	@echo "New snapshot version:           $(SNAPSHOT_VERSION)"
	@echo "Git version tag:                v$(RELEASE_VERSION)"
	@echo "Release log:                    $(RELEASE_LOG)"
	@echo "Current branch:                 $(GIT_BRANCH)"
	@echo "Release branch:                 $(RELEASE_BRANCH)"
	@echo ""
	@echo -n "👮‍♀️ Check release branch:        "
	@if [ "$(GIT_BRANCH)" != "$(RELEASE_BRANCH)" ]; then echo "Releases are made from the $(RELEASE_BRANCH) branch, your branch is $(GIT_BRANCH)."; exit 1; fi
	@echo "$(OK)"
	@echo -n "👮‍♀️ Check branch in sync         "
	@if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then echo "$(RELEASE_BRANCH) branch not in sync with remote origin."; exit 1; fi
	@echo "$(OK)"
	@echo -n "👮‍♀️ Check uncommited changes     "
	@if git status --porcelain | grep -q .; then echo "There are uncommited changes in your repository."; exit 1; fi
	@echo "$(OK)"
	@echo -n "👮‍♀️ Check release version:       "
	@if [ "$(RELEASE_VERSION)" = "UNSET" ]; then echo "Set a release version, e.g. make release RELEASE_VERSION=1.0.0"; exit 1; fi
	@echo "$(OK)"
	@echo -n "👮‍♀️ Check version tag available: "
	@if git rev-parse v$(RELEASE_VERSION) >$(RELEASE_LOG) 2>&1; then echo "Tag v$(RELEASE_VERSION) already exists"; exit 1; fi
	@echo "$(OK)"
	@echo -n "💅 Set Maven release version:   "
	@mvn versions:set -DnewVersion=$(RELEASE_VERSION) >>$(RELEASE_LOG) 2>&1
	@echo "$(OK)"
	@echo -n "👮‍♀️ Validate:                    "
	@$(MAKE) jars >>$(RELEASE_LOG) 2>&1
	@echo "$(OK)"
	@echo -n "🎁 Git commit new release       "
	@git commit --signoff -am "release: BluebirdOps $(RELEASE_VERSION)" >>$(RELEASE_LOG) 2>&1
	@echo "$(OK)"
	@echo -n "🦄 Set Git version tag:         "
	@git tag -a "v$(RELEASE_VERSION)" -m "Release BluebirdOps version $(RELEASE_VERSION)" >>$(RELEASE_LOG) 2>&1
	@echo "$(OK)"
	@echo -n "⬆️ Set Maven snapshot version:  "
	@mvn versions:set -DnewVersion=$(SNAPSHOT_VERSION) >>$(RELEASE_LOG) 2>&1
	@echo "$(OK)"
	@echo -n "🎁 Git commit snapshot release: "
	@git commit --signoff -am "release: BluebirdOps $(SNAPSHOT_VERSION)" >>$(RELEASE_LOG) 2>&1
	@echo "$(OK)"
	@if [ "$(PUSH_RELEASE)" = "true" ]; then \
	    echo -n "🦄 Push commits                  "; \
  		git push >>$(RELEASE_LOG) 2>&1; \
		echo "$(OK)"; \
		echo -n "🚀 Push tag                      "; \
  		git push origin v$(RELEASE_VERSION) >>$(RELEASE_LOG) 2>&1; \
  		echo "$(OK)"; \
  	else \
  		echo "Push commits and tag:           $(SKIP)"; \
  	fi;


.PHONY: publish
publish: deps-build
	@$(MAVEN_BIN) $(MAVEN_ARGS) -Drepo.id=$(MAVEN_REPO) -Drepo.username=$(MAVEN_USERNAME) -Drepo.password=$(MAVEN_PASSWORD) -DskipTests deploy

