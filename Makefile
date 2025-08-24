PAK_NAME := $(shell jq -r .name pak.json)
PAK_TYPE := $(shell jq -r .type pak.json)
PAK_FOLDER := $(shell echo $(PAK_TYPE) | cut -c1)$(shell echo $(PAK_TYPE) | tr '[:upper:]' '[:lower:]' | cut -c2-)s

PUSH_SDCARD_PATH ?= /mnt/SDCARD
PUSH_PLATFORM ?= tg5040

ARCHITECTURES := arm64
PLATFORMS := my355 rg35xxplus tg5040

MINUI_PRESENTER_VERSION := 0.9.0
TERMSP_VERSION=0.1.0

RELEASE_VERSION ?= latest

clean:
	rm -f bin/*/minui-presenter || true
	rm -f bin/*/termsp || true
	rm -f lib/arm64/libsdlfox.so || true
	rm -f lib/arm64/libvterm.so.0 || true
	rm -f res/fonts/Hack-Bold.ttf || true
	rm -f res/fonts/Hack-Regular.ttf || true

build: $(foreach platform,$(PLATFORMS),bin/$(platform)/minui-presenter) $(foreach architecture,$(ARCHITECTURES),bin/$(architecture)/termsp lib/$(architecture)/libsdlfox.so lib/$(architecture)/libvterm.so.0) res/fonts/Hack-Regular.ttf res/fonts/Hack-Bold.ttf

bin/%/minui-presenter:
	mkdir -p bin/$*
	curl -f -o bin/$*/minui-presenter -fsSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

bin/arm64/termsp:
	mkdir -p bin/arm64
	curl -o bin/arm64/termsp -fsSL https://github.com/josegonzalez/compiled-termsp/releases/download/$(TERMSP_VERSION)/termsp-arm64
	chmod +x bin/arm64/termsp

lib/arm64/libsdlfox.so:
	mkdir -p lib/arm64
	curl -o lib/arm64/libsdlfox.so -fsSL https://github.com/Nevrdid/TermSP/raw/refs/heads/master/libs/libsdlfox.so

lib/arm64/libvterm.so.0:
	mkdir -p lib/arm64
	curl -o lib/arm64/libvterm.so.0 -sSLf https://github.com/Nevrdid/TermSP/raw/refs/heads/master/libs/libvterm.so

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
