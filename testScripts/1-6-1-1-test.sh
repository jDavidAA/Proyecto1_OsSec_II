#!/bin/bash

if dpkg-query -l apparmor &>/dev/null; then
    echo "\nPASS:\n AppArmor is installed"
else
    echo "\nFAIL:\n AppArmor is not installed"
fi