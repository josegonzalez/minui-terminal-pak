TAG ?= 391f0909d86df038c0fa749a619eb7a947358481
BUILD_DATE := "$(shell date -u +%FT%TZ)"
PAK_NAME := $(shell jq -r .label config.json)

clean:
	rm -f bin/evtest || true
	rm -f bin/sdl2imgshow || true
	rm -f bin/termsp || true
	rm -f lib/libsdlfox.so || true
	rm -f lib/libvterm.so.0 || true
	rm -f res/fonts/BPreplayBold.otf || true
	rm -f res/fonts/Hack-Regular.ttf || true
	rm -f res/fonts/Hack-Bold.ttf || true

build: bin/evtest bin/sdl2imgshow bin/termsp lib/libsdlfox.so lib/libvterm.so.0 res/fonts/Hack-Regular.ttf res/fonts/Hack-Bold.ttf res/fonts/BPreplayBold.otf

bin/evtest:
	docker buildx build --platform linux/arm64 --load -f Dockerfile.evtest --progress plain -t app/evtest:$(TAG) .
	docker container create --name extract app/evtest:$(TAG)
	docker container cp extract:/go/src/github.com/freedesktop/evtest/evtest bin/evtest
	docker container rm extract
	chmod +x bin/evtest

bin/sdl2imgshow:
	docker buildx build --platform linux/arm64 --load -f Dockerfile.sdl2imgshow --progress plain -t app/sdl2imgshow:$(TAG) .
	docker container create --name extract app/sdl2imgshow:$(TAG)
	docker container cp extract:/go/src/github.com/kloptops/sdl2imgshow/build/sdl2imgshow bin/sdl2imgshow
	docker container rm extract
	chmod +x bin/sdl2imgshow

bin/termsp:
	docker buildx build --platform linux/arm64 --load --build-arg BUILD_DATE=$(BUILD_DATE) -f Dockerfile.termsp --progress plain -t app/termsp:$(TAG) .
	docker container create --name extract app/termsp:$(TAG)
	docker container cp extract:/go/src/github.com/Nevrdid/TermSP/build/TermSP bin/termsp
	docker container rm extract
	chmod +x bin/termsp

lib/libsdlfox.so:
	docker buildx build --platform linux/arm64 --load --build-arg BUILD_DATE=$(BUILD_DATE) -f Dockerfile.termsp --progress plain -t app/termsp:$(TAG) .
	docker container create --name extract app/termsp:$(TAG)
	docker container cp extract:/go/src/github.com/Nevrdid/TermSP/libs/libsdlfox.so lib/libsdlfox.so
	docker container rm extract

lib/libvterm.so.0:
	docker buildx build --platform linux/arm64 --load --build-arg BUILD_DATE=$(BUILD_DATE) -f Dockerfile.termsp --progress plain -t app/termsp:$(TAG) .
	docker container create --name extract app/termsp:$(TAG)
	docker container cp extract:/go/src/github.com/Nevrdid/TermSP/libs/libvterm.so lib/libvterm.so.0
	docker container rm extract

res/fonts/Hack-Regular.ttf:
	curl -sL https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.gz | tar -xz -C res/fonts/ --strip-components=1 "ttf/Hack-Regular.ttf"

res/fonts/Hack-Bold.ttf:
	curl -sL https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.tar.gz | tar -xz -C res/fonts/ --strip-components=1 "ttf/Hack-Bold.ttf"

res/fonts/BPreplayBold.otf:
	mkdir -p res/fonts
	curl -sSL -o res/fonts/BPreplayBold.otf "https://raw.githubusercontent.com/shauninman/MinUI/refs/heads/main/skeleton/SYSTEM/res/BPreplayBold-unhinted.otf"

release: build
	mkdir -p dist
	git archive --format=zip --output "dist/$(PAK_NAME).pak.zip" HEAD
	while IFS= read -r file; do zip -r "dist/$(PAK_NAME).pak.zip" "$$file"; done < .gitarchiveinclude
	ls -lah dist
