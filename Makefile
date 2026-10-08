PAK_NAME := $(shell jq -r .name pak.json)
PAK_TYPE := $(shell jq -r .type pak.json)
PAK_FOLDER := $(shell echo $(PAK_TYPE) | cut -c1)$(shell echo $(PAK_TYPE) | tr '[:upper:]' '[:lower:]' | cut -c2-)s

PUSH_SDCARD_PATH ?= /mnt/SDCARD
PUSH_PLATFORM ?= tg5040

ARCHITECTURES := arm64
PLATFORMS := h700 my355 rg35xxplus tg5040 tg5050

MINUI_PRESENTER_VERSION := 0.13.4
TERMSP_VERSION := 5116aeda84b8d4bb125a214464c131c177260140
TERMSP_IMAGE ?= minui-terminal-termsp

# NextUI on BaseOS ships no libfontconfig, so the h700 build takes it from the toolchain sysroot
H700_TOOLCHAIN_IMAGE ?= savant/minui-toolchain:h700-nextui
H700_SYSROOT_LIB := /opt/aarch64-nextui-linux-gnu/aarch64-nextui-linux-gnu/libc/usr/lib

RELEASE_VERSION ?= latest

clean:
	rm -f bin/*/minui-presenter || true
	rm -f bin/*/termsp || true
	rm -f lib/arm64/libsdlfox.so || true
	rm -f lib/arm64/libvterm.so.0 || true
	rm -f lib/h700/libfontconfig.so.1 || true
	rm -f res/fonts/Hack-Bold.ttf || true
	rm -f res/fonts/Hack-Regular.ttf || true

build: $(foreach platform,$(PLATFORMS),bin/$(platform)/minui-presenter) $(foreach architecture,$(ARCHITECTURES),bin/$(architecture)/termsp lib/$(architecture)/libsdlfox.so lib/$(architecture)/libvterm.so.0) bin/h700/termsp lib/h700/libfontconfig.so.1 res/fonts/Hack-Regular.ttf res/fonts/Hack-Bold.ttf

bin/h700/minui-presenter:
	mkdir -p bin/h700
	curl -f -o bin/h700/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-h700-nextui
	chmod +x bin/h700/minui-presenter

bin/tg5050/minui-presenter:
	mkdir -p bin/tg5050
	curl -f -o bin/tg5050/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-tg5050-nextui
	chmod +x bin/tg5050/minui-presenter

bin/%/minui-presenter:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-presenter -fsSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

bin/arm64/termsp: Dockerfile.termsp patches/termsp-input.patch
	mkdir -p bin/arm64
	docker buildx build --platform linux/arm64 --load --build-arg TERMSP_VERSION=$(TERMSP_VERSION) -f Dockerfile.termsp -t $(TERMSP_IMAGE):arm64 .
	docker run --rm --platform linux/arm64 $(TERMSP_IMAGE):arm64 cat /go/src/github.com/Nevrdid/TermSP/build/TermSP > bin/arm64/termsp.tmp
	chmod +x bin/arm64/termsp.tmp
	mv bin/arm64/termsp.tmp bin/arm64/termsp

# NextUI on BaseOS gets a termsp built against the NextUI toolchain sysroot
bin/h700/termsp: Dockerfile.termsp-h700 patches/termsp-input.patch
	mkdir -p bin/h700
	docker build --build-arg TERMSP_VERSION=$(TERMSP_VERSION) -f Dockerfile.termsp-h700 -t $(TERMSP_IMAGE):h700 .
	docker run --rm $(TERMSP_IMAGE):h700 cat /go/src/github.com/Nevrdid/TermSP/build/TermSP > bin/h700/termsp.tmp
	chmod +x bin/h700/termsp.tmp
	mv bin/h700/termsp.tmp bin/h700/termsp

lib/arm64/libsdlfox.so:
	mkdir -p lib/arm64
	curl -o lib/arm64/libsdlfox.so -fsSL https://github.com/Nevrdid/TermSP/raw/refs/heads/master/libs/libsdlfox.so

lib/arm64/libvterm.so.0:
	mkdir -p lib/arm64
	curl -o lib/arm64/libvterm.so.0 -sSLf https://github.com/Nevrdid/TermSP/raw/refs/heads/master/libs/libvterm.so

lib/h700/libfontconfig.so.1:
	mkdir -p lib/h700
	docker run --rm $(H700_TOOLCHAIN_IMAGE) cat $(H700_SYSROOT_LIB)/libfontconfig.so.1 > lib/h700/libfontconfig.so.1.tmp
	mv lib/h700/libfontconfig.so.1.tmp lib/h700/libfontconfig.so.1

res/fonts/Hack-Regular.ttf:
	mkdir -p res/fonts
	curl -fsSL https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.gz | tar -xz -C res/fonts/ --strip-components=1 "ttf/Hack-Regular.ttf"

res/fonts/Hack-Bold.ttf:
	mkdir -p res/fonts
	curl -fsSL https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.gz | tar -xz -C res/fonts/ --strip-components=1 "ttf/Hack-Bold.ttf"

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	$(MAKE) bump-version
	zip -r "dist/$(PAK_NAME).pak.zip" pak.json
	ls -lah dist

bump-version:
	jq '.version = "$(RELEASE_VERSION)"' pak.json > pak.json.tmp
	mv pak.json.tmp pak.json

push: release
	rm -rf "dist/$(PAK_NAME).pak"
	cd dist && unzip "$(PAK_NAME).pak.zip" -d "$(PAK_NAME).pak"
	adb push "dist/$(PAK_NAME).pak/." "$(PUSH_SDCARD_PATH)/$(PAK_FOLDER)/$(PUSH_PLATFORM)/$(PAK_NAME).pak"
