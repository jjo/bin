#!/bin/bash
echo -n "* Current: "
cat /sys/firmware/acpi/platform_profile
echo -n "* Choose from: "
cat /sys/firmware/acpi/platform_profile_choices
test "$1" != "" && {
    echo "INFO: Setting to: $1"
    echo "$1" | sudo tee /sys/firmware/acpi/platform_profile
}
