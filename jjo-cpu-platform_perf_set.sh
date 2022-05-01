#!/bin/bash
echo "* Current:"
cat /sys/firmware/acpi/platform_profile
echo "* Choose from:"
cat /sys/firmware/acpi/platform_profile_choices
test "$1" != "" && {
    echo "$1" | sudo tee /sys/firmware/acpi/platform_profile
}
