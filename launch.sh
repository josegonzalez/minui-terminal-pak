#!/bin/sh
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"
set -x

rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt"
exec 2>&1

echo "$0" "$@"
cd "$PAK_DIR" || exit 1
mkdir -p "$USERDATA_PATH/$PAK_NAME"

architecture=arm
if uname -m | grep -q '64'; then
    architecture=arm64
fi

export LD_LIBRARY_PATH="$PAK_DIR/lib/$architecture:$LD_LIBRARY_PATH"
export PATH="$PAK_DIR/bin/$architecture:$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin:$PATH"

service_on() {
    cd "$SDCARD_PATH" || return 1

    if [ -f "$USERDATA_PATH/$PAK_NAME/shell" ]; then
        shell="$(cat "$USERDATA_PATH/$PAK_NAME/shell")"
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

    SHELL="$shell" termsp -s 27 -f "$PAK_DIR/res/fonts/Hack-Regular.ttf" -b "$PAK_DIR/res/fonts/Hack-Bold.ttf" >"$LOGS_PATH/$PAK_NAME.service.txt" 2>&1
}

show_message() {
    message="$1"
    seconds="$2"

    if [ -z "$seconds" ]; then
        seconds="forever"
    fi

    killall minui-presenter >/dev/null 2>&1 || true
    echo "$message" 1>&2
    if [ "$seconds" = "forever" ]; then
        minui-presenter --message "$message" --timeout -1 &
    else
        minui-presenter --message "$message" --timeout "$seconds"
    fi
}

cleanup() {
    rm -f /tmp/stay_awake
    killall minui-presenter >/dev/null 2>&1 || true
}

main() {
    echo "1" >/tmp/stay_awake
    trap "cleanup" EXIT INT TERM HUP QUIT

    allowed_platforms="tg5040 rg35xxplus"
    if ! echo "$allowed_platforms" | grep -q "$PLATFORM"; then
        show_message "$PLATFORM is not a supported platform" 2
        return 1
    fi

    if ! command -v minui-presenter >/dev/null 2>&1; then
        show_message "minui-presenter not found" 2
        return 1
    fi

    chmod +x "$PAK_DIR/bin/$PLATFORM/minui-presenter"

    service_on
    killall minui-presenter >/dev/null 2>&1 || true
}

main "$@"
