#!/bin/bash

output1=$(grep "^\s*linux" /boot/grub/grub.cfg | grep -v "apparmor=1")

output2=$(grep "^\s*linux" /boot/grub/grub.cfg | grep -v "security=apparmor")

if [[ -z "$output1" && -z "$output2" ]]; then
    echo -e "\nPASS:\n AppArmor is enabled in the bootloader configuration"
else
    echo -e "\nFAIL:\n AppArmor is not enabled in the bootloader configuration"
fi