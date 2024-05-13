#!/bin/bash

sudoers_output=$(grep -rPsi "^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$" /etc/sudoers*)

if echo "$sudoers_output" | grep -q "Defaults logfile=\"/var/log/sudo.log\""; then
    echo -e "\nPASS:\n Sudo log file exists"
else
    echo -e "\nFAIL:\n Sudo log file doesn't exists"
fi