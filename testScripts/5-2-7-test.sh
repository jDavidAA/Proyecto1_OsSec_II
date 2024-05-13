#!/bin/bash

permitrootlogin_output=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permitrootlogin)

if [ "$permitrootlogin_output" == "permitrootlogin no" ]; then
    sshd_config_output=$(grep -Ei '^\s*PermitRootLogin\s+no' /etc/ssh/sshd_config)
    
    if [ "$sshd_config_output" == "PermitRootLogin no" ]; then
        echo -e "\nPASS:\n Root login is disabled"
    else
        echo -e "\nFAIL:\n Root login is enabled"
    fi
else
    echo -e "\nFAIL:\n Root login is enabled"
fi
