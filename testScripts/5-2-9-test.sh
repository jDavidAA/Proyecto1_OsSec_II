#!/bin/bash

sshd_output=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permitemptypasswords)
ssh_config_output=$(grep -Ei '^\s*PermitEmptyPasswords\s+yes' /etc/ssh/sshd_config)

if [ "$sshd_output" == "permitemptypasswords no" ] && [ -z "$ssh_config_output" ]; then
    echo -e "\nPASS:\n SSH PermitEmptyPasswords is disabled"
else
    echo -e "\nFAIL:\n SSH PermitEmptyPasswords is enabled"
fi