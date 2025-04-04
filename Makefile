PAK_NAME := $(shell jq -r .label config.json)

ARCHITECTURES := arm64
PLATFORMS := rg35xxplus tg5040

MINUI_PRESENTER_VERSION := 0.7.0
TERMSP_VERSION=0.1.0

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
	curl -f -o bin/$*/minui-presenter -sSL https://github.com/josegonzalez/minui-presenter/releases/download/$(MINUI_PRESENTER_VERSION)/minui-presenter-$*
	chmod +x bin/$*/minui-presenter

bin/arm64/termsp:
	mkdir -p bin/arm64
	curl -o bin/arm64/termsp -sSL https://github.com/josegonzalez/compiled-termsp/releases/download/$(TERMSP_VERSION)/termsp-arm64
	chmod +x bin/arm64/termsp

lib/arm64/libsdlfox.so:
	mkdir -p lib/arm64
	curl -o lib/arm64/libsdlfox.so -sSL https://github.com/Nevrdid/TermSP/blob/master/libs/libsdlfox.so

lib/arm64/libvterm.so.0:
	mkdir -p lib/arm64
	curl -o lib/arm64/libvterm.so.0 -sSL https://github.com/Nevrdid/TermSP/blob/master/libs/libvterm.so

res/fonts/Hack-Regular.ttf:
	mkdir -p res/fonts
	curl -sL https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.gz | tar -xz -C res/fonts/ --strip-components=1 "ttf/Hack-Regular.ttf"

res/fonts/Hack-Bold.ttf:
	mkdir -p res/fonts
	curl -sL https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.gz | tar -xz -C res/fonts/ --strip-components=1 "ttf/Hack-Bold.ttf"

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist
