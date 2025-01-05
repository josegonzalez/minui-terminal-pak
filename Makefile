TAG ?= 391f0909d86df038c0fa749a619eb7a947358481
BUILD_DATE := "$(shell date -u +%FT%TZ)"

clean:
	rm -f bin/evtest || true
	rm -f bin/termsp || true
	rm -f lib/libsdlfox.so || true
	rm -f lib/libvterm.so || true

build: bin/evtest bin/termsp lib/libsdlfox.so lib/libvterm.so

bin/evtest:
	docker buildx build --platform linux/arm64 --load -f Dockerfile.evtest --progress plain -t app/evtest:$(TAG) .
	docker container create --name extract app/evtest:$(TAG)
	docker container cp extract:/go/src/github.com/freedesktop/evtest/evtest bin/evtest
	docker container rm extract
	chmod +x bin/evtest

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

lib/libvterm.so:
	docker buildx build --platform linux/arm64 --load --build-arg BUILD_DATE=$(BUILD_DATE) -f Dockerfile.termsp --progress plain -t app/termsp:$(TAG) .
	docker container create --name extract app/termsp:$(TAG)
	docker container cp extract:/go/src/github.com/Nevrdid/TermSP/libs/libvterm.so lib/libvterm.so
	docker container rm extract
