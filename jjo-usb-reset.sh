#!/bin/bash
## Reset USB, found it consuming 100% of one cpu core, with:
#  perf record -g -a sleep 3
#  perf report
#  -> xhci_hub_control
# ref: https://forums.linuxmint.com/viewtopic.php?t=240569
usb_id=$(lspci |awk '/USB/{ print $1 }'); echo -n "0000:${usb_id?}" | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind; sleep 1; echo -n "0000:${usb_id?}" | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind
