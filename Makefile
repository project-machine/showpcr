DOCKER_BASE ?= docker://
UBUNTU_MIRROR ?= http://archive.ubuntu.com/ubuntu

APP_VERSION = $(shell git describe --tags --always \
        "--match=v[0-9]*.[0-9]*.[0-9]*" || echo no-git)
ifeq ($(APP_VERSION),$(filter $(APP_VERSION), "", no-git))
$(error "Bad value for APP_VERSION: '$(APP_VERSION)'")
endif

TOP_D := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_D = $(TOP_D)/build
DL_D = $(TOP_D)/dl
DL_TOOLS = $(DL_D)/tools
STACKER = $(DL_TOOLS)/stacker
STACKER_URL ?= https://github.com/project-stacker/stacker/releases/download
STACKER_RELEASE ?= v1.0.0-rc4
MYPATH = $(DL_TOOLS)
EDK2_TARBALL = $(DL_D)/edk2.tar.gz
SHOWPCR_EFI = $(TOP_D)/showpcr.efi
SHELL_EFI = $(TOP_D)/shell.efi
export PATH := $(MYPATH):$(PATH)

all: showpcr.efi shell.efi

showpcr.efi: $(SHOWPCR_EFI)

shell.efi: $(SHELL_EFI)

edk2.tar.gz: $(EDK2_TARBALL)

$(EDK2_TARBALL): layers/edk2-tarball.yaml
	$(STACKER) --debug --storage-type=overlay \
	"--oci-dir=$(BUILD_D)/oci" "--roots-dir=$(BUILD_D)/roots" "--stacker-dir=$(BUILD_D)/stacker" \
	build --shell-fail \
	"--substitute=TOP_D=$(TOP_D)" \
	"--substitute=DOCKER_BASE=$(DOCKER_BASE)" \
	"--substitute=UBUNTU_MIRROR=$(UBUNTU_MIRROR)" \
	"--layer-type=tar" \
	"--stacker-file=$<"

$(SHOWPCR_EFI): $(STACKER) showpcr.c showpcr.inf layers/stacker.yaml $(EDK2_TARBALL)
	$(STACKER) --debug --storage-type=overlay \
    "--oci-dir=$(BUILD_D)/oci" "--roots-dir=$(BUILD_D)/roots" "--stacker-dir=$(BUILD_D)/stacker" \
    build --shell-fail \
	"--substitute=TOP_D=$(TOP_D)" \
	"--substitute=DOCKER_BASE=$(DOCKER_BASE)" \
	"--substitute=UBUNTU_MIRROR=$(UBUNTU_MIRROR)" \
	"--substitute=EDK2_TARBALL=$(EDK2_TARBALL)" \
	"--substitute=APP_VERSION=$(APP_VERSION)" \
	"--layer-type=tar" \
	"--stacker-file=layers/stacker.yaml"

$(SHELL_EFI): $(SHOWPCR_EFI)

$(STACKER):
	@mkdir -p $(DL_TOOLS)
	wget --progress=dot:mega -O $@ \
		$(STACKER_URL)/$(STACKER_RELEASE)/stacker && chmod +x $@ && $(STACKER) --version

clean:
	rm -f showpcr.efi $(TOP_D)/*.pcr7.txt $(TOP_D)/*.pcr7.bin

dist-clean: clean
	rm -Rf dl/
	rm -f $(TOP_D)/.env
	lxc-usernsexec -s -- rm -Rf $(TOP_D)/build

.PHONY: dist-clean clean all edk2.tar.gz
