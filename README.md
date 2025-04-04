# minui-terminal.pak

A MinUI app wrapping [`TermSP`](https://github.com/Nevrdid/TermSP), a terminal emulator.

## Requirements

This pak is designed and tested on the following MinUI Platforms and devices:

- `tg5040`: Trimui Brick (formerly `tg3040`), Trimui Smart Pro
- `rg35xxplus`: RG-35XX Plus, RG-34XX, RG-35XX H, RG-35XX SP

Use the correct platform for your device.

## Installation

1. Mount your MinUI SD card.
2. Download the latest release from Github. It will be named `Terminal.pak.zip`.
3. Copy the zip file to `/Tools/$PLATFORM/Terminal.pak.zip`.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/$PLATFORM/Terminal.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your MinUI device.

## Usage

Browse to `Tools > Terminal` and press `A` to turn on the terminal.

### shell

The terminal detects the available shells and uses the first one it finds. To utilize a different shell, create a file named `shell` in the pak folder with the full path to the shell you wish to execute.

The order of shell detection is as follows:

1. `/usr/bin/bash`
2. `/bin/bash`
3. `/bin/sh`

### Debug Logging

Debug logs are written to the`$SDCARD_PATH/.userdata/$PLATFORM/logs/` folder.
