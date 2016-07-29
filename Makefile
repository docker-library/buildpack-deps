SHELL := /bin/bash

ifneq ($(strip $(V)),)
  hide :=
else
  hide := @
endif

LATEST := jessie

DOCKER ?= docker
DOCKER_REPO := buildpack-deps
DOCKER_USER := $(shell $(DOCKER) info | awk '/^Username:/ { print $$2 }')

SUITE_ARCH :=

DEBIAN_SUITES := wheezy jessie stretch sid
UBUNTU_SUITES := precise trusty vivid wily xenial

# $(1): relative directory path, e.g. "jessie/amd64"
define target-name-from-path
$(subst /,-,$(1))
endef

# $(1): relative directory path, e.g. "jessie/amd64"
define suite-name-from-path
$(word 1,$(subst /, ,$(1)))
endef

# $(1): relative directory path, e.g. "jessie/amd64"
define arch-name-from-path
$(word 2,$(subst /, ,$(1)))
endef

# $(1): relative directory path, e.g. "jessie/amd64/curl"
define func-name-from-path
$(word 3,$(subst /, ,$(1)))
endef

# $(1): relative directory path, e.g. "jessie/amd64"
define base-image-from-path
$(shell cat $(1)/Dockerfile | grep ^FROM | awk '{print $$2}')
endef

# $(1): base image name, e.g. "foo/bar:tag"
define enumerate-build-dep-for-docker-build-inner
$(if $(filter $(DOCKER_USER)/$(DOCKER_REPO):%,$(1)),$(patsubst $(DOCKER_USER)/$(DOCKER_REPO):%,%,$(1)))
endef

# $(1): relative directory path, e.g. "jessie/amd64", "jessie/amd64/scm"
define enumerate-build-dep-for-docker-build
$(call enumerate-build-dep-for-docker-build-inner,$(call base-image-from-path,$(1)))
endef

# $(1): suite
# $(2): arch
# $(3): func
define enumerate-additional-tags-for
$(if $(filter amd64,$(2)),$(1)$(if $(3),-$(3))) $(if $(filter $(LATEST),$(1)),latest-$(2)$(if $(3),-$(3)) $(if $(filter amd64,$(2)),latest$(if $(3),-$(3))))
endef

define do-dockerfile
$(hide) if [ -n "$$(grep '^# GENERATED' $@)" ]; then \
  echo "$@ <= $<"; \
  sed 's!DIST!$(PRIVATE_DIST)!g; s!SUITE!$(PRIVATE_SUITE)!g; s!ARCH!$(PRIVATE_ARCH)!g;' "$<" > "$@"; \
else \
  echo "$@ is not automatically generated. Skipping ..."; \
fi
endef

# $(1): relative directory path, e.g. "jessie/amd64", "jessie/amd64/scm"
# $(2): target name, e.g. jessie-amd64-scm
# $(3): suite name, e.g. jessie
# $(4): arch name, e.g. amd64
# $(5): func name, e.g. scm
define define-dockerfile-target
$(1)/Dockerfile: PRIVATE_DIST := $(if $(filter $(DEBIAN_SUITES),$(3)),debian,ubuntu)
$(1)/Dockerfile: PRIVATE_SUITE := $(3)
$(1)/Dockerfile: PRIVATE_ARCH := $(4)
$(1)/Dockerfile: Dockerfile.template$(if $(5),-$(5))
	$$(call do-dockerfile)

endef

define do-docker-build
@echo "$@ <= docker building $(PRIVATE_PATH)";
$(hide) if [ -n "$(FORCE)" -o -z "$$($(DOCKER) inspect $(DOCKER_USER)/$(DOCKER_REPO):$(PRIVATE_TARGET) 2>/dev/null | grep Created)" ]; then \
  $(DOCKER) build -t $(DOCKER_USER)/$(DOCKER_REPO):$(PRIVATE_TARGET) $(PRIVATE_PATH); \
fi

endef

# $(1): relative directory path, e.g. "jessie/amd64", "jessie/amd64/scm"
# $(2): target name, e.g. jessie-amd64-scm
# $(3): suite name, e.g. jessie
# $(4): arch name, e.g. amd64
# $(5): func name, e.g. scm
define define-docker-build-target
.PHONY: docker-build-$(2)
$(2): docker-build-$(2)
docker-build-$(2): PRIVATE_TARGET := $(2)
docker-build-$(2): PRIVATE_PATH := $(1)
docker-build-$(2): $(1)/Dockerfile
docker-build-$(2): $(call enumerate-build-dep-for-docker-build,$(1))
	$$(call do-docker-build)

endef

define do-docker-tag
@echo "$@ <= docker tagging $(PRIVATE_PATH)";
$(hide) for tag in $(PRIVATE_TAGS); do \
  $(DOCKER) tag -f $(DOCKER_USER)/$(DOCKER_REPO):$(PRIVATE_TARGET) $(DOCKER_USER)/$(DOCKER_REPO):$${tag}; \
done

endef

# $(1): relative directory path, e.g. "jessie/amd64", "jessie/amd64/scm"
# $(2): target name, e.g. jessie-amd64-scm
# $(3): suite name, e.g. jessie
# $(4): arch name, e.g. amd64
# $(5): func name, e.g. scm
define define-docker-tag-target
.PHONY: docker-tag-$(2)
$(2): docker-tag-$(2)
docker-tag-$(2): PRIVATE_TARGET := $(2)
docker-tag-$(2): PRIVATE_PATH := $(1)
docker-tag-$(2): PRIVATE_TAGS := $(call enumerate-additional-tags-for,$(3),$(4),$(5))
docker-tag-$(2): docker-build-$(2)
	$$(call do-docker-tag)

endef

# $(1): relative directory path, e.g. "jessie/amd64", "jessie/amd64/scm"
define define-target-from-path
$(eval target := $(call target-name-from-path,$(1)))
$(eval suite := $(call suite-name-from-path,$(1)))
$(eval arch := $(call arch-name-from-path,$(1)))
$(eval func := $(call func-name-from-path,$(1)))

.PHONY: $(target)
$(target):
	@echo "$$@ done"

dockerfiles: $(1)/Dockerfile
$(call define-dockerfile-target,$(1),$(target),$(suite),$(arch),$(func))

$(if $(wildcard $(1)/skip), \
  $(info Skipping $(1): $(shell cat $(1)/skip)) \
  , \
  $(eval SUITE_ARCH += $(suite)/$(arch)) \
  $(eval .PHONY: $(suite) $(arch) $(func)) \
  $(eval all $(suite) $(arch) $(func): $(target)) \
  $(call define-docker-build-target,$(1),$(target),$(suite),$(arch),$(func)) \
  $(if $(strip $(call enumerate-additional-tags-for,$(suite),$(arch),$(func))), \
    $(call define-docker-tag-target,$(1),$(target),$(suite),$(arch),$(func))) \
)
endef

.PHONY: .travis.yml
.travis.yml:
	$(hide) travisEnv= ; \
	$(foreach sa,$(sort $(SUITE_ARCH)),travisEnv+='\n  - VERSION='$(sa)); \
	travis="$$(awk -v 'RS=\n\n' '$$1 == "env:" { $$0 = "env:'"$$travisEnv"'" } { printf "%s%s", $$0, RS }' $@)"; \
	echo "$$travis" > $@

all: .travis.yml
	@echo "Build $(DOCKER_USER)/$(DOCKER_REPO) done"

$(foreach f,$(shell find . -type f -name Dockerfile | cut -d/ -f2-), \
  $(eval path := $(patsubst %/Dockerfile,%,$(f))) \
  $(eval $(call define-target-from-path,$(path))) \
)

.PHONY: debian ubuntu
debian: $(DEBIAN_SUITES)
ubuntu: $(UBUNTU_SUITES)
