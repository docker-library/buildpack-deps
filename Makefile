hide := @

DOCKER_REPO := buildpack-deps
DOCKER_USER := $(shell docker info | awk '/^Username:/ { print $$2 }')

ifneq ($(strip $(DRY_RUN)),)
  DOCKER := echo docker
else
  DOCKER := docker
endif

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

# $(1): base image name, e.g. "foo/bar:tag"
define enumerate-build-dep-for-build-inner
$(if $(filter $(DOCKER_USER)/$(DOCKER_REPO):%,$(1)),$(patsubst $(DOCKER_USER)/$(DOCKER_REPO):%,%,$(1)))
endef

# $(1): relative directory path, e.g. "jessie/amd64", "jessie/amd64/scm"
define enumerate-build-dep-for-build
$(call enumerate-build-dep-for-build-inner,$(shell cat $(1)/Dockerfile | grep ^FROM | awk '{print $$2}'))
endef

# $(1): suite
# $(2): arch
# $(3): func
define enumerate-additional-tags-for
$(if $(filter amd64,$(2)),$(1)$(if $(3),-$(3)))
endef

define do-build
@echo "$@ <= building $(PRIVATE_PATH)";
$(hide) if [ -n "$(FORCE)" -o -z "$$(docker inspect $(DOCKER_USER)/$(DOCKER_REPO):$(PRIVATE_TARGET) 2>/dev/null | grep Created)" ]; then \
  $(DOCKER) build -t $(DOCKER_USER)/$(DOCKER_REPO):$(PRIVATE_TARGET) $(PRIVATE_PATH); \
fi

endef

define do-tag
@echo "$@ <= tagging $(PRIVATE_PATH)";
$(if $(strip $(PRIVATE_TAGS)), \
  $(hide) for tag in $(PRIVATE_TAGS); do \
    $(DOCKER) tag -f $(DOCKER_USER)/$(DOCKER_REPO):$(PRIVATE_TARGET) $(DOCKER_USER)/$(DOCKER_REPO):$${tag}; \
  done, \
  @echo "No additional tags to do" \
)

endef

# $(1): relative directory path, e.g. "jessie/amd64", "jessie/amd64/scm"
define define-target-from-path
$(eval target := $(call target-name-from-path,$(1)))
$(eval suite := $(call suite-name-from-path,$(1)))
$(eval arch := $(call arch-name-from-path,$(1)))
$(eval func := $(call func-name-from-path,$(1)))

.PHONY: $(target) build-$(target) tag-$(target)
all: $(target)
$(target): build-$(target) tag-$(target)
	@echo "$$@ done"

build-$(target): PRIVATE_TARGET := $(target)
build-$(target): PRIVATE_PATH := $(1)
build-$(target): $(call enumerate-build-dep-for-build,$(1))
	$$(call do-build)

tag-$(target): PRIVATE_TARGET := $(target)
tag-$(target): PRIVATE_PATH := $(1)
tag-$(target): PRIVATE_TAGS := $(call enumerate-additional-tags-for,$(suite),$(arch),$(func))
tag-$(target): build-$(target)
	$$(call do-tag)

endef

all:
	@echo "Build $(DOCKER_USER)/$(DOCKER_REPO) done"

$(foreach f,$(shell find . -type f -name Dockerfile | cut -d/ -f2-), \
  $(eval path := $(patsubst %/Dockerfile,%,$(f))) \
  $(if $(wildcard $(path)/skip), \
    $(info Skipping $(path): $(shell cat $(path)/skip)), \
    $(eval $(call define-target-from-path,$(path))) \
  ) \
)
