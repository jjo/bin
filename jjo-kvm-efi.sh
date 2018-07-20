#!/bin/bash
# kvm w/EFI support via "ovmf" bios
EFI_BIOS=/usr/share/ovmf/OVMF.fd
test -f ${EFI_BIOS} || {
    echo "ERROR: EFI_BIOS at ${EFI_BIOS} not found, may need to: apt install ovmf"
    exit 1
}
set -x
kvm -drive file=${EFI_BIOS},if=pflash,format=raw,unit=0,readonly=on "${@}"

