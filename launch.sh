#!/bin/sh
echo "$0" "$@"
progdir="$(dirname "$0")"
cd "$progdir" || exit 1
[ -f "$progdir/debug" ] && set -x
PAK_NAME="$(basename "$progdir")"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$progdir/lib"
echo 1 >/tmp/stay_awake

SERVICE_NAME="termsp"
HUMAN_READABLE_NAME="Terminal"
ONLY_LAUNCH_THEN_EXIT=1
LAUNCHES_SCRIPT="false"
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

service_off() {
    killall "$SERVICE_NAME"
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

is_service_running() {
    if pgrep "$SERVICE_NAME" >/dev/null 2>&1; then
        return 0
    fi

    if [ "$LAUNCHES_SCRIPT" = "true" ]; then
        if pgrep -fn "$SERVICE_NAME" >/dev/null 2>&1; then
            return 0
        fi
    fi

    return 1
}

wait_for_service() {
    max_counter="$1"
    counter=0

    while ! is_service_running; do
        counter=$((counter + 1))
        if [ "$counter" -gt "$max_counter" ]; then
            return 1
        fi
        sleep 1
    done
}

main_daemonize() {
    echo "Toggling $SERVICE_NAME..."
    if is_service_running; then
        show_message "Disabling the $HUMAN_READABLE_NAME" 2
        service_off
    else
        show_message "Enabling the $HUMAN_READABLE_NAME" 2
        service_on

        if ! wait_for_service 10; then
            show_message "Failed to start $HUMAN_READABLE_NAME" 2
            return 1
        fi
    fi

    show_message "Done" 1
}

main_process() {
    if is_service_running; then
        show_message "Disabling the $HUMAN_READABLE_NAME" 2
        service_off
    fi

    show_message "Starting $HUMAN_READABLE_NAME" 2
    service_on
    sleep 1

    echo "Waiting for $HUMAN_READABLE_NAME to be running"
    if ! wait_for_service 10; then
        show_message "Failed to start $HUMAN_READABLE_NAME" 2
        return 1
    fi

    show_message "Press B to exit"

    "$progdir/bin/minui-btntest-$PLATFORM" wait just_pressed all btn_b
    show_message "Stopping $HUMAN_READABLE_NAME"
    service_off
    sync
    sleep 1
    show_message "Done" 1
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
        exit 1
    fi

    if [ ! -f "$progdir/bin/minui-btntest-$PLATFORM" ]; then
        show_message "$progdir/bin/minui-btntest-$PLATFORM not found" 2
        exit 1
    fi

    chmod +x "$progdir/bin/minui-btntest-$PLATFORM"
    chmod +x "$progdir/bin/sdl2imgshow"

    if [ "$ONLY_LAUNCH_THEN_EXIT" -eq 1 ]; then
        service_on
        return $?
    fi

    if [ -f "$progdir/daemon-mode" ]; then
        main_daemonize
    else
        main_process
    fi
    killall sdl2imgshow >/dev/null 2>&1 || true
}

main "$@" >"$LOGS_PATH/$PAK_NAME.txt" 2>&1
