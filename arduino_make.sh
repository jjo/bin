#!/bin/sh
# jjo:
ARDUINO_DIR=/opt/arduino-root/arduino
AVR_TOOLS_PATH=/opt/avr/bin
ARDUINO_BOARD='atmega328'

#
# This script is Copyright (c) 2009 Kimmo Kulovesi <http://arkku.com/>.
# Use at your own risk only. Released under GPL, see below for details.
#
# Last been tested with Arduino version 0017 on Ubuntu 9.04, with
# avr-gcc and avrdude installed from Ubuntu packages.
#
#
#
# This script runs the Makefile included with Arduino to compile and
# upload projects on the command-line. Variables are set here so that
# the original Makefile need not be changed every time the Arduino
# installation is updated. This script also does autodetection of
# libraries and allows specifying a custom path where to look for
# libraries (something not currently supported by the Arduino
# IDE graphical user interface, although it did finally add support
# for libraries in the "sketchbook" directory).
#
#   CHANGES:
#
# October 2009      - Support AVRISP and burning bootloaders
#                   - Support building object files into the
#                     applet directory instead of the core and
#                     library directories.
#                   - Generate automatic dependecies for libraries
#                   - Support uploading specified .hex or .bin
#                     directly without compiling anything
#                   - Support downloading flash memory from
#                     microcontroller to .hex or .bin file
#                   - Replace the slightly broken build target:
#                       - Proper dependencies
#                       - Show correct file name and line numbers for errors
#                       - Display program size compared to controller capacity
# September 2009    - Support Arduino 017
# March 2009        - Support Arduino 014
# February 2009     - Initial version
#
#
# Note that the Arduino Makefile compiles the Arduino programming
# libraries inside the Arduino install directory. This means that
# the user running this script must either have write permissions
# to that directory, or they must all be compiled once as part of
# the installation process (e.g. by compiling any project with this
# script while having write permissions to the Arduino install
# directory). This script offers experimental support for circumventing
# this if you specify BUILD_LOCALLY=1 at the end of the command
# line.
# 
# If specify BUILD_LOCALLY=1, everything will be built locally
# instead in the library locations. However, the building of core
# dependencies is hard-coded into the most recent Arduino Makefiles,
# so you either need to comment out the include-directives on the
# very last lines of the Arduino Makefile, or alternatively compile
# one simple program while having write permissions to the core
# directory (the files are not re-built unless the core is edited).
#
#
# The typical usage is to create a directory named after your project
# (or "sketch"), e.g. "Blink" and place your Arduino program in that
# directory with the same name and the extension ".pde", e.g.
# "Blink.pde". Then run this script from that directory to compile,
# and if everything went well, run this script again with the
# command-line parameter "upload" to upload it.
#
#
# The default port for the Arduino is set to "/dev/arduino", which
# requires udev rules (but avoids the problem of changing ttyUSB names).
# Alternatively, it can be changed in this file. The udev rule that
# works for the Arduino clone that I have is this:
#
# KERNEL=="ttyUSB*", ATTRS{product}=="FT232R USB UART", \
# ATTRS{idProduct}=="6001", ATTRS{idVendor}=="0403", \
# SYMLINK+="arduino arduino_$attr{serial}", GROUP="avrprog", MODE="0660"
#
# You will probably want to change the group to "dialout", or create
# the "avrprog" group on your system (like I did). On Ubuntu Linux, place
# the rule in a file inside "/etc/udev/rules.d", e.g. "80-arduino.rules".
#
# If you have many devices with the same product and vendor ids,
# as may be the case with a popular chip like FT232R, you can
# add the condition "ATTRS{serial}" to your udev rules. You can
# see the serial if you first use the above rules and then look at
# the symlink "arduino_SERIAL" where SERIAL is the serial number
# of that particular device. Then create one rule for each of your
# devices' serial numbers (add ATTRS{serial}=="MySerial", right
# before SYMLINK in the above rules).
#
#
# The Arduino installation directory defaults to "$HOME/arduino" or
# "/opt/arduino" if that directory does not contain an executable
# file called "arduino". It can also be specified as the environment
# variable "ARDUINO_DIR".
#
# Otherwise settings are read from Arduino's "board.txt", defaulting
# to the board type "diecimila" (works for modern clones, too, like
# Seeeduino v1.1). This can be overridden in the environment by setting
# ARDUINO_BOARD, or by editing this script.
#
#
# Run this script with the argument --help for more!
#
#
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License,
# or (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script.  If not, see <http://www.gnu.org/licenses/>.


###################################################################################
# Configurable defaults:

# Board type (change here or set environmental variable ARDUINO_BOARD
# to one of the boardnames defined in "arduino/hardware/boards.txt".
[ -z "$ARDUINO_BOARD" ] && ARDUINO_BOARD='atmega328'

# Try to figure out Arduino install directory (first from environment
# variable ARDUINO_DIR, then ~/arduino, then opt/arduino)
if [ -n "$ARDUINO_DIR" ]; then
    INSTALL_DIR="$ARDUINO_DIR"
else
    INSTALL_DIR="$HOME/arduino"
    if [ ! -x "$INSTALL_DIR/arduino" -a -x '/opt/arduino/arduino' ]; then
        INSTALL_DIR='/opt/arduino'
    fi
fi

# Path to avr tools (/usr/bin if installed from Linux distribution packages)
[ -z "$AVR_TOOLS_PATH" ] && AVR_TOOLS_PATH=/usr/bin

# Path to search for additional Arduino libraries (separated by : colons).
# The "official" script directory at hardware/libraries is always searched!

if [ -z "$ARDUINO_LIBRARY_PATH" ]; then
    ARDUINO_LIBRARY_PATH="../libraries:$HOME/arduino/libraries"
fi

###################################################################################

BOARDFILE="$INSTALL_DIR/hardware/boards.txt"
if [ ! -r "$BOARDFILE" ]; then
    cat >&2 <<EOF
Error: Could not read "$BOARDFILE".
Please set ARDUINO_DIR correctly so that \$ARDUINO_DIR/hardware/boards.txt
is the location of the boards.txt in your Arduino installation.
EOF
    exit 1
fi

# The extension for Arduino program files (.pde at the time of writing, but
# this is the same as for Processing - .ade would be more fitting)
EXT='pde'

if [ "$1" = 'help' -o "$1" = '--help' ]; then
    basename="$(basename "$0")"
    cat | less <<EOF
Arduino command-line make-wrapper and library auto-detector,
copyright (c) 2009 Kimmo Kulovesi <http://arkku.com/>. This
is provided as free software under GPL with ABSOLUTELY NO WARRANTY.


Usage: $basename [target] [options for Make]

This script calls Make on the Arduino Makefile to build and/or upload
projects using the Arduino programming libraries without the Arduino
graphical user-interface. The "official" way to use that Makefile is to
copy it to each project directory and edit the settings accordingly,
but this script eliminates all this trouble by setting the necessary
parameters for the original Makefile.

This script includes support for autodetecting libraries used by
projects (similar to the real Arduino IDE), reading board parameters
from Arduino settings, programming via external ISP programmers, etc.


    Targets (specify as the first parameter):

compile (default):  Compile the applet (.hex file) ready for uploading.
                    Do this first after making changes to your program!

upload:             Upload to Arduino/Freeduino/Sanguino. The default
                    port to upload to is /dev/arduino, but it can be
                    overridden by setting ARDUINO_PORT in the environment.
                    The basic usage is: $basename upload

                    To upload a pre-compiled file to the microcontroller,
                    you can specify a filename after upload on the
                    command line. The file must have the extension
                    .hex for Intel hex format, or the extension .bin
                    for raw binary format. For example, to upload
                    Intel hex file myprog.hex:

                    $basename upload myprog.hex

download:           Download the microcontroller's flash memory to
                    the file specified as the next command line
                    parameter. The file name MUST have either the
                    extension .hex for Intel hex format, or the
                    extension .bin for raw binary format. For example:

                    $basename download backup.bin

coff:               Build an applet .cof file for debugging/etc.
lss:                Build an applet .lss file to show annotated assembler. 

    Targets for burning a bootloader (requires a programming device!):

bootloader:         Program the fuses and burn a bootloader. The
                    filenames and settings are obtained from the
                    file ARDUINO_DIR/harware/boards.txt according
                    to the board named as ARDUINO_BOARD. Note that
                    this requires an external programmer; if yours
                    uses settings other than those for your target
                    board, follow this target with one of the ISP
                    programming targets (see below).

                    For example, to burn the ADABoot bootloader for
                    ATMega168 using an AVRISP device, you would set
                    ARDUINO_BOARD="ADABoot168" and then run:
                    $basename bootloader isp

                    You can also follow the bootloader target with
                    a .bin or .hex filename to burn a custom
                    bootloader without entering it into boards.txt, e.g.:
                    $basename bootloader myloader.hex dragon

fuses:              Just program the fuses and set the lock bits
                    to unlock. For example:
                    $basename fuses isp

    Targets for ISP programming (e.g. for DIY projects with no
    direct serial or USB connection):

isp:                Upload with an AVRISP programmer or clone thereof
                    (using STK500v2 protocol). This uses the "upload"
                    target in the Arduino Makefile. The programmer's
                    default port is "/dev/avrisp", but it can be
                    overridden by setting AVRISP_PORT in the environment.
                    The default protocol (STK500v2) can be overridden
                    by setting AVRISP_PROTOCOL.

dragon:             Upload with the Atmel AVRDragon in ISP mode, using
                    the "upload" target in the Makefile. The USB port
                    is autodetected by avrdude.

As with the "upload" target, it is possible to specify a .hex or .bin
file name as the following parameter for these ISP programmer targets.


    Setup:

Arduino should be installed in the directory "arduino" inside the
user's home directory, or else the environmental variable ARDUINO_DIR
should be set to the path where Arduino is installed.

The Diecimila board is assumed by default, but the board can be specified
by setting the environmental variable ARDUINO_BOARD to an exact value
defined in "hardware/boards.txt" (case-sensitive, e.g. "sanguino" or
"lilypad"). All board-related settings are read from that file, so it
should not be necessary to manually set things like the CPU frequency
(just define a board in "hardware/boards.txt").

The AVR tools should be installed in "/usr/bin" (e.g. on Ubuntu Linux you
can just do "sudo apt-get install avrdude binutils-avr gcc-avr avr-libc").
The install location can be overridden by setting AVR_TOOLS_PATH in
the environment.

Uploading is normally done to /dev/arduino (or /dev/sanguino, or
whatever the "core" for your board is called). You can override this
by specifying the device node in the environmental variable ARDUINO_PORT.
Linux users may wish to specify udev rules for always linking their
Arduino as /dev/arduino; see the comments at the top of this script
file ($0) for instructions.

Normally the Arduino installation directory is searched for libraries,
as is "../libraries" (i.e. the directory "libraries" with the same parent
directory as your current project) and "~/arduino/libraries". You can
override these last two directories by defining ARDUINO_LIBRARY_PATH
in the environment as a :-separated list of directories where to look
for libraries, e.g. "../:\$HOME/sketchbook/libraries". The "real"
Arduino library directory is always searched last, so your custom
versions of libraries override the ones in the official distribution,
which is convenient for customising libraries.

    NOTE: Your program and Arduino installation should all reside in
    paths with NO SPACES in them! This is because Makefiles do not
    cope very well with spaces in filenames, and this script doesn't
    even try to escape them for all possible situations.


    Compiling libraries into the applet-directory:

Normally the Arduino Makefile compiles the core and library objects
into the same directory where the source files are. This is generally
very nice because it means that these common parts only need to be
compiled once on the system, but it also means that the user must
have write permissions to these locations. It is also problematic when
different types of microcontrollers are used in the same environment
and core and/or library behaviour depends on microcontroller-dependant
compile-time parameters.

To compile everything into the applet-directory (created automatically
by this script), specify BUILD_LOCALLY=1 at the end of the command line.
You may also need to comment out the include directives from the
very last lines of the Arduino Makefile in harware/cores/arduino/Makefile
or alternatively compile any one program while having write permissions
to the Arduino directory.


    If you get a compile-time error about __cxa_pure_virtual:

Some versions of Arduino and avr-gcc cause an error about a missing
function "__cxa_pure_virtual" in programs where C++ classes are used.
To fix this problem, add the following line anywhere in your program:

extern "C" void __cxa_pure_virtual() {}


  How to use this script for command-line Arduino programming:

1) Create a new directory, e.g. "MyProgram" and enter that directory.
2) Place your code in the file "MyProgram.$EXT", i.e. same name as the
   directory and having extension ".$EXT".
3) Run this script (after setting up things as described above).
4) If everything builds correctly, upload your program by running this
   script with the parameter "upload" (or "dragon" to use AVRDragon,
   or "isp" to use AVRISP).

To use additional Arduino libraries in your program, just include the
library header (e.g. #include <LiquidCrystal.h>). The library should
exist in a directory with the same basename as the header file (without
the extension .h). Library directories are searched for in the directory
"hardware/libraries" inside the Arduino directory and in all directories
listed in the environmental variable ARDUINO_LIBRARY_PATH (see above).

    In short:
mkdir Program; cd Program; vim Program.$EXT; $basename; $basename upload
EOF
    exit 0
fi

# Try to read the hardware configuration for this board:
eval $(awk -v FS== -v board="$ARDUINO_BOARD" '$1 ~ /[.]name$/ {
                                if (found)
                                    exit 0
                                sub(/[.]name$/, "", $1)
                                if (board == $1 || board == $2) {
                                    boardname = $2
                                    found=1
                                }
                                speed=0; core=""; mcu=""; protocol=""; f_cpu=0;
                                lfuse=""; hfuse=""; efuse="";
                                unlock_bits=""; lock_bits="";
                                bootloader_dir=""; bootlader_file="";
                                next
                            }
                           $1 ~ /[.]upload[.]protocol$/ {
                                protocol = $2
                                next
                           }
                           $1 ~ /[.]upload[.]f_cpu$/ {
                                f_cpu = $2
                                next
                           }
                           $1 ~ /[.]upload[.]speed$/ {
                                speed = $2
                                next
                           }
                           $1 ~ /[.]upload[.]maximum_size$/ {
                                max_size = $2
                                next
                           }
                           $1 ~ /[.]build[.]core$/ {
                                core = $2
                                next
                           }
                           $1 ~ /[.]build[.]mcu$/ {
                                mcu = $2
                                next
                           }
                           $1 ~ /[.]bootloader[.]low_fuses$/ {
                                lfuse = $2
                                next
                           }
                           $1 ~ /[.]bootloader[.]high_fuses$/ {
                                hfuse = $2
                                next
                           }
                           $1 ~ /[.]bootloader[.]extended_fuses$/ {
                                efuse = $2
                                next
                           }
                           $1 ~ /[.]bootloader[.]unlock_bits$/ {
                                unlock_bits = $2
                                next
                           }
                           $1 ~ /[.]bootloader[.]lock_bits$/ {
                                lock_bits = $2
                                next
                           }
                           $1 ~ /[.]bootloader[.]path$/ {
                                bootloader_dir = $2
                                next
                           }
                           $1 ~ /[.]bootloader[.]file$/ {
                                bootloader_file = $2
                                next
                           }
                            END {
                                if (found) {
                                    if (speed) {
                                        gsub(/[^0-9]/, "", speed)
                                        print "UPLOAD_RATE=\"" speed "\""
                                    }
                                    if (f_cpu) {
                                        gsub(/[^0-9]/, "", f_cpu)
                                        print "F_CPU=\"" f_cpu "\""
                                    }
                                    if (core) {
                                        gsub(/[^a-zA-Z0-9_.:-]/, "", core)
                                        print "CORE=\"" core "\""
                                    }
                                    if (mcu) {
                                        gsub(/[^a-zA-Z0-9_.:-]/, "", mcu)
                                        print "MCU=\"" mcu "\""
                                    }
                                    if (protocol) {
                                        gsub(/[^a-zA-Z0-9_.:-]/, "", protocol)
                                        print "AVRDUDE_PROGRAMMER=\"" \
                                            protocol "\""
                                    }
                                    if (max_size) {
                                        gsub(/[^0-9]/, "", max_size)
                                        print "MAX_SIZE=\"" max_size "\""
                                    }
                                    if (boardname) {
                                        gsub(/[^a-zA-Z0-9 _,./():-]/, "",
                                             boardname)
                                        if (!boardname)
                                            boardname = board
                                    }
                                    if (hfuse != "") {
                                        gsub(/[^0-9xA-Fa-f]/, "", hfuse)
                                        print "BL_HFUSE=\"" hfuse "\""
                                    }
                                    if (lfuse != "") {
                                        gsub(/[^0-9xA-Fa-f]/, "", lfuse)
                                        print "BL_LFUSE=\"" lfuse "\""
                                    }
                                    if (efuse != "") {
                                        gsub(/[^0-9xA-Fa-f]/, "", efuse)
                                        print "BL_EFUSE=\"" efuse "\""
                                    }
                                    if (lock_bits != "") {
                                        gsub(/[^0-9xA-Fa-f]/, "", lock_bits)
                                        print "BL_LOCK=\"" lock_bits "\""
                                    }
                                    if (unlock_bits != "") {
                                        gsub(/[^0-9xA-Fa-f]/, "", unlock_bits)
                                        print "BL_UNLOCK=\"" unlock_bits "\""
                                    }
                                    if (bootloader_dir && bootloader_file) {
                                        gsub(/[^a-zA-Z0-9_.:+/-]/, "", 
                                                            bootloader_dir)
                                        gsub(/[^a-zA-Z0-9_.:+-]/, "", bootloader_file)
                                        print "BL_PATH=\"" bootloader_dir "/" \
                                                           bootloader_file "\""
                                    }
                                    print "BOARDNAME=\"" boardname "\""
                                }
                            }' "$BOARDFILE")


[ -z "$CORE" ] && CORE=arduino
[ -z "$F_CPU" ] && F_CPU=16000000UL
[ -z "$MAX_SIZE" ] && MAX_SIZE=14336
[ -z "$MCU" ] && MCU="$ARDUINO_BOARD"
[ -z "$AVRDUDE_PROGRAMMER" ] && AVRDUDE_PROGRAMMER=stk500v1
[ -z "$UPLOAD_RATE" ] && UPLOAD_RATE=19200
MAKEFILE="$INSTALL_DIR/hardware/cores/$CORE/Makefile"
[ ! -e "$MAKEFILE" ] && MAKEFILE="$INSTALL_DIR/hardware/cores/arduino/Makefile"
ARDUINO="$INSTALL_DIR/hardware/cores/$CORE"
LIBRARY_DIR="$INSTALL_DIR/hardware/libraries"

if grep -q -s -F 'wiring_serial.c' "$MAKEFILE"; then
    if [ ! -e "$ARDUINO/wiring_serial.c" ]; then
        echo '/* Empty file created due to bug in Arduino Makefile */' \
            > "$ARDUINO/wiring_serial.c"
    fi
fi

# Correct the programmer "stk500" specified for pretty much every
# Arduino board to "stk500v1", since avrdude recommends that anyway.
[ "$AVRDUDE_PROGRAMMER" = "stk500" ] && AVRDUDE_PROGRAMMER='stk500v1'

# Programmer port (e.g. /dev/ttyUSBx)
if [ -n "$ARDUINO_PORT" ]; then
    PORT="$ARDUINO_PORT"
else
    PORT="/dev/$CORE"
    if [ ! -e "$PORT" ]; then
        PORT="/dev/$ARDUINO_BOARD"
        if [ ! -e "$PORT" ]; then
            PORT='/dev/avr'
            [ ! -e "$PORT" ] && PORT='/dev/ttyUSB0'
        fi
    fi
fi

if [ -z "$BOARDNAME" ]; then
    cat >&2 <<EOF

Warning: A board called "$ARDUINO_BOARD" is not defined in the file
"$INSTALL_DIR/hardware/boards.txt". Settings may be incorrect!"

EOF
else
    cat <<EOF
Read settings for ARDUINO_BOARD="$ARDUINO_BOARD":
    $BOARDNAME

EOF
fi

# Configure AVRDUDE here, since the Makefile included with Arduino
# has non-working paths hard-coded:

AVRDUDE_CONFIG="$INSTALL_DIR/hardware/tools/avrdude.conf"
[ ! -e "$AVRDUDE_CONFIG" ] && AVRDUDE_CONFIG="/etc/avrdude.conf"
AVRDUDE_FLAGS="-F -D -p $MCU -v -v"

# Change the target "dragon" to "upload", but perform the upload using
# the AVRDragon in ISP mode instead of the instead of the typical Arduino
# programming method (e.g. for DIY projects using the same microprocessor
# as an Arduino but not having the programming capability themselves).

burn_bootloader=''
program_fuses=''
if [ "$1" = "bootloader" -o "$1" = "fuses" ]; then
    program_fuses='yes'
    [ "$1" = "bootloader" ] && burn_bootloader='yes'
    shift
    [ ! -x "$AVR_TOOLS_PATH/avrdude" ] && AVR_TOOLS_PATH=''

    if [ -z "$BL_HFUSE" -o -z "$BL_LFUSE" -o -z "$BL_EFUSE" -o \
         -z "$BL_UNLOCK" -o -z "$BL_PATH" ]
    then
        cat >&2 <<EOF
Error: boards.txt did not define the information necessary for burning
a bootloader and/or setting the fuses. You must ensure that the file
$INSTALL_DIR/hardware/boards.txt is available and contains the following
settings for your board type (currently "$ARDUINO_BOARD"):

$ARDUINO_BOARD.bootloader.low_fuses=0x??
$ARDUINO_BOARD.bootloader.high_fuses=0x??
$ARDUINO_BOARD.bootloader.extended_fuses=0x??
$ARDUINO_BOARD.bootloader.unlock_bits=0x??
$ARDUINO_BOARD.bootloader.lock_bits=0x??
$ARDUINO_BOARD.bootloader.file=filename.hex
$ARDUINO_BOARD.bootloader.path=dirname

Aborting...
EOF
        exit 1
    fi
    BOOTLOADER_FILE="$INSTALL_DIR/hardware/bootloaders/$BL_PATH"
    if [ -n "$1" -a -r "$1" ] && echo "$1" | grep -E -q -s '\.(hex|bin)$' ; then
        BOOTLOADER_FILE="$1"
        shift
    elif [ ! -r "$BOOTLOADER_FILE" ]; then
        echo "Error: Bootloader file "$BOOTLOADER_FILE" is not readable!" >&2
        exit 1
    fi
    cat <<EOF
This command line will set the following:

EOF
    [ -n "$burn_bootloader" ] && echo "Bootloader: $BOOTLOADER_FILE"
    cat <<EOF
Fuses: high=$BL_HFUSE low=$BL_LFUSE extended=$BL_EFUSE

    WARNING!

Burning a bootloader and/or setting the fuse bits is potentially
dangerous and incorrect settings can make your device stop working!
Note that an external programmer is required for this operation,
i.e. you can't burn the bootloader via Arduino's own USB.

Press Return to continue (at your own risk), or Ctrl-C to cancel!

EOF
    read press_enter >/dev/null 2>&1
fi

if [ "$1" = "dragon" ]; then
    # Uploading with the AVR Dragon:

    AVRDUDE_PROGRAMMER='dragon_isp'
    PORT='usb'
    UPLOAD_RATE=''
    target='upload'
    shift
elif [ "$1" = "isp" ]; then
    # Uploading via AVRISP with the stk500v2 protocol:

    if [ -n "$AVRISP_PORT" ]; then
        PORT="$AVRISP_PORT"
    else
        PORT='/dev/avrisp'
        [ ! -e "$PORT" ] && PORT='/dev/ttyUSB0'
    fi
    AVRDUDE_PROGRAMMER='stk500v2'
    [ -n "$AVRISP_PROTOCOL" ] && AVRDUDE_PROGRAMMER="$AVRISP_PROTOCOL"
    UPLOAD_RATE="$AVRISP_BAUD"
    target='upload'
    shift
else
    if [ "$1" = "upload" ]; then
        target='upload_autoreset'
        shift
    else
        target=''
    fi
fi
AVRDUDE_FLAGS="$AVRDUDE_FLAGS -P $PORT -c $AVRDUDE_PROGRAMMER${UPLOAD_RATE:+ -b $UPLOAD_RATE}"

# Show the configuration

cat <<EOF
    Core................... $CORE
    Core directory......... $ARDUINO
    Microcontroller........ $MCU
    Clock frequency........ $(echo "$F_CPU" | sed 's/UL$//') Hz
    Programming protocol... $AVRDUDE_PROGRAMMER
    Port................... $PORT
    Maximum upload size.... $MAX_SIZE bytes

EOF


# Program the fuses (usually as the first step for burning a bootloader):

if [ -n "$program_fuses" ]; then
    "$AVR_TOOLS_PATH/avrdude" ${AVRDUDE_CONFIG:+-C }"${AVRDUDE_CONFIG:-}" \
        $AVRDUDE_FLAGS -e -U "lock:w:$BL_UNLOCK:m" \
        -U "efuse:w:$BL_EFUSE:m" -U "hfuse:w:$BL_HFUSE:m" \
        -U "lfuse:w:$BL_LFUSE:m" || exit 1
    cat <<EOF

Programmed fuses: high=$BL_HFUSE low=$BL_LFUSE extended=$BL_EFUSE
Setting lock bits to unlock: $BL_UNLOCK
EOF
fi

# Burn the bootloader:

if [ -n "$burn_bootloader" ]; then
cat <<EOF

Burning bootloader: $BOOTLOADER_FILE

EOF
    sleep 5
    exec "$AVR_TOOLS_PATH/avrdude" ${AVRDUDE_CONFIG:+-C }"${AVRDUDE_CONFIG:-}" \
          $AVRDUDE_FLAGS -e -U "flash:w:$BOOTLOADER_FILE:a" -U "lock:w:$BL_LOCK:m"
elif [ -n "$program_fuses" ]; then
    exit 0
fi

# Upload custom file (.hex or .bin) with compiling:

if [ "$target" = "upload" -o "$target" = "upload_autoreset" \
     -a -r "$1" ] && echo "$1" | grep -E -q -s '\.(hex|bin)$' ; then
    echo "Uploading file '$1' to microcontroller..."
    exec "$AVR_TOOLS_PATH/avrdude" ${AVRDUDE_CONFIG:+-C }"${AVRDUDE_CONFIG:-}" \
          $AVRDUDE_FLAGS -U "flash:w:$1:a"
fi

# Download flash to file (.hex or .bin, Intel Hex or raw binary format):

if [ "$1" = "download" -a -n "$2" ] && \
    echo "$2" | grep -E -q -s '\.(hex|bin)$' ; then
    echo "Downloading flash memory to file '$2'..."
    exec "$AVR_TOOLS_PATH/avrdude" ${AVRDUDE_CONFIG:+-C }"${AVRDUDE_CONFIG:-}" \
          $AVRDUDE_FLAGS \
          -U "flash:r:$2:$(echo "$2" | sed 's/^.*hex$/i/; s/^.*bin$/r/')"
fi

# Escape AVRDUDE_CONFIG path for the Makefile:

[ -n "$AVRDUDE_CONFIG" ] && AVRDUDE_FLAGS="-C \"$AVRDUDE_CONFIG\" $AVRDUDE_FLAGS"

# Try to figure out the name of the project (first from the first
# parameter give on the command line, then the directory name):
if [ -r "./$1.$EXT" ]; then
    TARGET="$1"
    shift
else
    TARGET=$(basename "$(pwd)")
fi
if [ ! -e "./$TARGET.$EXT" ]; then
    cat >&2 <<EOF

Error: "$TARGET.$EXT" not found! Please specify the base name of your
project as the first command-line parameter to $(basename "$0"), or
run this in a directory with the same name as your project.

Run "$(basename "$0") help" for instructions!
EOF
    exit 1
fi

# Figure out what libraries are being used:

LIBRARIES_DIR="\$(INSTALL_DIR)/hardware/libraries"
LIBSRC=''
LIBASRC=''
LIBCXXSRC=''
CINCS=''
CXXINCS='$(CINCS)'
LIBCHECK_FILES=' '

ARDUINO_LIBRARY_PATH=$(echo "$ARDUINO_LIBRARY_PATH" | \
                       sed 's/ /\\ /g; s/[^a-zA-Z0-9!:,._+/-]//g; s/:/ /g')

echo 'Looking for libraries in these directories:'
for libpath in $ARDUINO_LIBRARY_PATH "$LIBRARY_DIR"; do
    echo "    $libpath/"
done
echo

# Check an included header for matching .c, .cpp and/or .S files
# (simply by filename) and add any of those to the sources.

check_header () {
    local libname="$1"
    local base="$2"
    local inlib="$3"
    local pfx="$base/$libname"
    [ ! -e "$pfx.h" ] && return 1

    check_for_libraries "$pfx.h"

    local makepfx="$pfx"
    if [ "$base" = "$ARDUINO" ]; then
        # Beautify the Arduino directory path
        makepfx="\$(ARDUINO)/$libname"
    elif [ -n "$inlib" ]; then
        # Beautify the Arduino library directory path
        if echo "$base" | grep -q -s -F "$LIBRARY_DIR/$inlib/utility"
        then
            makepfx="\$(LIBRARIES_DIR)/$inlib/utility/$libname"
        elif echo "$base" | grep -q -s -F "$LIBRARY_DIR/$inlib"
        then
            makepfx="\$(LIBRARIES_DIR)/$inlib/$libname"
        fi
    fi

    if [ -e "$pfx.c" ]; then
        check_for_libraries "$pfx.c" "$inlib" && \
            LIBSRC="$LIBSRC $makepfx.c"
    fi
    if [ -e "$pfx.cpp" ]; then
        check_for_libraries "$pfx.cpp" "$inlib" && \
            LIBCXXSRC="$LIBCXXSRC $makepfx.cpp"
    fi
    [ -e "$pfx.S" ] && LIBASRC="$LIBASRC $makepfx.S"

    return 0
}

# Check a file for new libraries we need to include. This is done simply
# by locating the #include-lines in the C/C++ sources. Obviously no
# pre-processor conditionals or such are supported, but for simple purposes
# this seems to work reasonably well. (All examples included with Arduino
# version 013 compile correctly.)

check_for_libraries () {
    [ ! -r "$1" ] && return 1
    if echo "$LIBCHECK_FILES" | grep -q -s -F " |$1| "; then
        return 1
    fi
    LIBCHECK_FILES="${LIBCHECK_FILES}|$1| "
    local basedir=$(dirname "$1")
    local inlib="$2"

    # Note: Print.cpp is a standard dependency for Arduino programs, but
    # the dependency was not included in the official Makefile up to and
    # including version 0014. If this script is used with old versions of
    # Arduino, compilation may fail due to missing Print.cpp. The suggested
    # solution is to update Arduino, but if that is not possible you can
    # add "Print" after the closing ")" on the line before "do":

    for lib in $(awk -F '[<>"]' '/^[ ]*#include [<"]/ { sub(/[.]h[p]*$/, "", $2);
                                    gsub(/[^a-zA-Z0-9_.:/-]/, "", $2);
                                    print $2; next }' "$1" 2>/dev/null)
    do
        local found=''
        local libpath=''
        local libname="$lib"
        local header="$ARDUINO/$libname.h"
        local base=''

        for libpath in $ARDUINO_LIBRARY_PATH "$LIBRARY_DIR"; do
            local libdir="$libpath/$libname"

            if [ -e "$libdir" ]; then
                if check_for_libraries "$libdir/$libname.h" "$libname"; then
                    if [ "$libpath" = "$LIBRARY_DIR" ]; then
                        echo "Including Arduino library: $libname"
                        CINCS="$CINCS -I\$(LIBRARIES_DIR)/$libname"
                        [ -e "$libdir/utility" ] && \
                            CINCS="$CINCS -I\$(LIBRARIES_DIR)/$libname/utility"
                    else
                        echo "Including local library: $libname"
                        CINCS="$CINCS -I$libdir"
                        [ -e "$libdir/utility" ] && \
                            CINCS="$CINCS -I$libdir/utility"
                    fi
                fi
                check_header "$libname" "$libdir" "$libname"
                found=1
                break
            fi
        done

        if [ -z "$found" ]; then
            for base in "$ARDUINO" "$basedir" "$basedir/utility"; do
                check_header "$libname" "$base" "$inlib" && break
            done
        fi
    done
    return 0
}

check_for_libraries "$TARGET.$EXT"

# Display settings:

old_CINCS="$CINCS"
CINCS="-I. -I./utility -I\$(ARDUINO)$CINCS"
if [ -n "$old_CINCS" ]; then
    echo
    echo "Includes = $CINCS"
    [ -n "$LIBSRC" ] && echo "LIBSRC =$LIBSRC"
    [ -n "$LIBASRC" ] && echo "LIBASRC =$LIBASRC"
    [ -n "$LIBCXXSRC" ] && echo "LIBCXXSRC =$LIBCXXSRC"
fi
unset old_CINCS

# Set the compiler options to better match the IDE

CTUNING="-fshort-enums -fno-exceptions -ffunction-sections -fdata-sections"
CFLAGS='$(CDEBUG) $(CDEFS) $(CINCS) -O$(OPT) $(CWARN) $(CSTANDARD) $(CTUNING) $(CEXTRA)'
CXXFLAGS='$(CDEFS) $(CINCS) -O$(OPT) $(CTUNING)'

# Fire up the Arduino Makefile

if [ -z "$target" -o "$target" = "build" -o "$target" = "all" \
     -o "$target" = "compile" ]; then
    # Ensure applet/core.a gets re-built every time, because otherwise
    # we don't get the correct dependencies and this operation is
    # really fast with pre-compiled libraries anyhow
    if [ -w "applet/core.a" ]; then
        echo "rm -f applet/core.a"
        rm -f "applet/core.a"
    fi
fi

[ "$target" = "upload_autoreset" -a ! -c "$PORT" ] && target=upload

# Ensure the applet directory exists:

[ ! -d applet ] && mkdir applet

# Now the REALLY dirty parts, featuring rather explicit Make:

echo -e 'compile: replace_all

include $(MAKEFILE)

replace_all: replace_build show_size
replace_build: applet/$(TARGET).hex
applet/$(TARGET).hex: applet/$(TARGET).elf

applet/$(TARGET).elf: applet/$(TARGET).cpp applet/core.a
\t$(CXX) $(ALL_CXXFLAGS) $(LDFLAGS) -L. -Lapplet/ -o $@ $< applet/core.a
\t@chmod a-x $@ >/dev/null 2>&1 || true

applet/$(TARGET).cpp: $(TARGET).$(EXT) $(ARDUINO)/main.cxx $(ARDUINO)/WProgram.h
\t@echo
\t@echo "The script initiated an improved build target. The original"
\t@echo "behaviour can be accessed by specifying \\"all\\" as the target!"
\t@echo
\techo '\''#include "WProgram.h"'\'' >$@
\t@echo '\''#line 1 "$<"'\'' >>$@
\tcat $(TARGET).$(EXT) >>$@
\t@echo '\''#line 1 "$(ARDUINO)/main.cxx"'\'' >>$@
\tcat $(ARDUINO)/main.cxx >>$@

show_size:
\t@echo
\t@echo Program size:
\t@$(HEXSIZE) | awk -v m="$(MAX_SIZE)" '\''{print;if(NR^1){s=$$4}} \\
    END {printf("\\n%d/%d bytes (%.1f%% of capacity, %d bytes left)\\n\\n",\\
    s,m,s*100.0/m,m-s);}'\''

upload_autoreset: do_autoreset upload

do_autoreset:
\t@echo Sending reset to prepare for upload...
\tstty -F $(PORT) hupcl || true
\t@echo

$(APPC): applet/%.o: %.c
\t$(CC) -c $(ALL_CFLAGS) -o $@ $<

$(APPCXX): applet/%.o: %.cpp
\t$(CXX) -c $(ALL_CXXFLAGS) -o $@ $<

$(APPA): applet/%.o: %.S
\t$(CC) -c $(ALL_ASFLAGS) -o $@ $<

$(APPC:.o=.d): applet/%.d: %.c
\t$(CC) -M $(ALL_CFLAGS) $< | sed '\''s;^[^:]*:;applet/$*.o applet/$*.d:;'\'' >$@

$(APPCXX:.o=.d): applet/%.d: %.cpp
\t$(CXX) -M $(ALL_CXXFLAGS) $< | sed '\''s;^[^:]*:;applet/$*.o applet/$*.d:;'\'' >$@

$(APPA:.o=.d): applet/%.d: %.S
\t$(CC) -M $(ALL_ASFLAGS) $< | sed '\''s;^[^:]*:;applet/$*.o applet/$*.d:;'\'' >$@

vpath %.c applet/ $(sort $(dir $(OBJC)))
vpath %.cpp applet/ $(sort $(dir $(OBJCXX)))
vpath %.S applet/ $(sort $(dir $(OBJA)))

include $(DEPS)
' | \
make -f - \
    MAKEFILE="$MAKEFILE" \
    AVRDUDE_FLAGS="$AVRDUDE_FLAGS" AVRDUDE_PROGRAMMER="$AVRDUDE_PROGRAMMER" \
    TARGET="$TARGET" PORT="$PORT" MCU="$MCU" F_CPU="$F_CPU" MAX_SIZE="$MAX_SIZE" \
    AVR_TOOLS_PATH="$AVR_TOOLS_PATH" INSTALL_DIR="$INSTALL_DIR" EXT="$EXT" \
    UPLOAD_RATE="$UPLOAD_RATE" ARDUINO="$ARDUINO" LIBRARIES_DIR="$LIBRARIES_DIR" \
    LIBSRC="$LIBSRC" LIBASRC="$LIBASRC" LIBCXXSRC="$LIBCXXSRC" \
    CINCS="$CINCS" CXXINCS="$CXXINCS" \
    CTUNING="$CTUNING" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" \
    OBJC='$(sort $(SRC:.c=.o) $(abspath $(LIBSRC:.c=.o)))' \
    OBJCXX='$(sort $(CXXSRC:.cpp=.o) $(abspath $(LIBCXXSRC:.cpp=.o)))' \
    OBJA='$(sort $(ASRC:.S=.o) $(abspath $(LIBASRC:.S=.o)))' \
    OBJARDUINODIR='$(OBJC) $(OBJCXX) $(OBJA)' \
    APPC='$(addprefix applet/,$(notdir $(OBJC)))' \
    APPCXX='$(addprefix applet/,$(notdir $(OBJCXX)))' \
    APPA='$(addprefix applet/,$(notdir $(OBJA)))' \
    OBJAPPDIR='$(APPC) $(APPCXX) $(APPA)' \
    OBJ='$(if $(BUILD_LOCALLY),$(OBJAPPDIR),$(OBJARDUINODIR))' \
    DEPS='$(OBJ:.o=.d) applet/$(TARGET).d' LST='$(OBJ:.o=.lst)' \
    $target "$@"
