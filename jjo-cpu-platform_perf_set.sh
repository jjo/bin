#!/bin/bash
echo -n "* Current: "
cat /sys/firmware/acpi/platform_profile
echo -n "* Choose from: "
cat /sys/firmware/acpi/platform_profile_choices
test "$1" != "" && {
    echo "INFO: Setting to: $1"
    echo "$1" | sudo tee /sys/firmware/acpi/platform_profile
}
case "$1" in
    performance)
        (set -x; echo performance | sudo tee /sys/devices/system/cpu/cpu?/cpufreq/scaling_governor)
        (set -x; echo 4800000|sudo tee /sys/devices/system/cpu/cpu?/cpufreq/scaling_max_freq)
        ;;
esac
