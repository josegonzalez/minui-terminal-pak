FROM golang:1.20.5-buster

ENV GOOS=linux
ENV GOARCH=arm64
ENV CGO_ENABLED=1
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV CC=aarch64-linux-gnu-gcc

RUN apt update && apt install -y libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev libtool-bin libfontconfig patch

ARG TERMSP_VERSION=5116aeda84b8d4bb125a214464c131c177260140
ENV TERMSP_VERSION=$TERMSP_VERSION

RUN git clone https://github.com/Nevrdid/TermSP /go/src/github.com/Nevrdid/TermSP && \
    git -C /go/src/github.com/Nevrdid/TermSP checkout "$TERMSP_VERSION"

WORKDIR /go/src/github.com/Nevrdid/TermSP
# ADD patches/Term.c.patch .
# RUN patch src/TERM.c Term.c.patch
RUN mkdir -p build && make all

RUN apt-get update && apt-get install -y file

RUN ls -lah /go/src/github.com/Nevrdid/TermSP/build
RUN file /go/src/github.com/Nevrdid/TermSP/build/TermSP
