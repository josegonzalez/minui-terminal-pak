#!/bin/sh
echo "$0" "$@"
progdir="$(dirname "$0")"
cd "$progdir" || exit 1
[ -f "$progdir/debug" ] && set -x
PAK_NAME="$(basename "$progdir")"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir/lib"
echo 1 >/tmp/stay_awake

SERVICE_NAME="termsp"

service_on() {
    cd "$SDCARD_PATH" || return 1

    if [ -f "$progdir/shell" ]; then
        shell="$(cat "$progdir/shell")"
    fi

    if [ -z "$shell" ]; then
        if [ -x "/usr/bin/bash" ]; then
            shell="/usr/bin/bash"
        elif [ -x "/bin/bash" ]; then
            shell="/bin/bash"
        fi

        if [ -z "$shell" ]; then
            shell="$SHELL"
        fi

        if [ -z "$shell" ]; then
            shell="/bin/sh"
        fi

        if [ ! -x "$shell" ]; then
            shell="/bin/sh"
        fi
    fi

    SHELL="$shell" "$progdir/bin/termsp" -s 27 -f "$progdir/res/fonts/Hack-Regular.ttf" -b "$progdir/res/fonts/Hack-Bold.ttf" >"$LOGS_PATH/$PAK_NAME.service.txt" 2>&1
}

show_message() {
    message="$1"
    seconds="$2"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall sdl2imgshow >/dev/null 2>&1 || true
    echo "$message"
    if [ "$seconds" = "forever" ]; then
        "$progdir/bin/sdl2imgshow" \
            -i "$progdir/res/background.png" \
            -f "$progdir/res/fonts/BPreplayBold.otf" \
            -s 27 \
            -c "220,220,220" \
            -q \
            -t "$message" >/dev/null 2>&1 &
    else
        "$progdir/bin/sdl2imgshow" \
            -i "$progdir/res/background.png" \
            -f "$progdir/res/fonts/BPreplayBold.otf" \
            -s 27 \
            -c "220,220,220" \
            -q \
            -t "$message" >/dev/null 2>&1
        sleep "$seconds"
    fi
}

cleanup() {
    rm -f /tmp/stay_awake
    killall sdl2imgshow >/dev/null 2>&1 || true
}

main() {
    trap "cleanup" EXIT INT TERM HUP QUIT

    allowed_platforms="tg5040 rg35xxplus"
    if ! echo "$allowed_platforms" | grep -q "$PLATFORM"; then
        show_message "$PLATFORM is not a supported platform" 2
        return 1
    fi

    if [ ! -f "$progdir/bin/minui-btntest-$PLATFORM" ]; then
        show_message "$progdir/bin/minui-btntest-$PLATFORM not found" 2
        return 1
    fi

    chmod +x "$progdir/bin/minui-btntest-$PLATFORM"
    chmod +x "$progdir/bin/sdl2imgshow"

    service_on
    killall sdl2imgshow >/dev/null 2>&1 || true
}

main "$@" >"$LOGS_PATH/$PAK_NAME.txt" 2>&1
