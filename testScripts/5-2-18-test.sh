#!/bin/bash

sshd_output=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep maxauthtries)
ssh_config_output=$(grep -Ei '^\s*maxauthtries\s+([5-9]|[1-9][0-9]+)' /etc/ssh/sshd_config)

if [ "$(echo "$sshd_output" | awk '{print $2}')" -le 4 ] && [ -z "$ssh_config_output" ]; then
    echo -e "\nPASS:\n SSH MaxAuthTries is set to 4 or less"
else
    echo -e "\nFAIL:\n SSH MaxAuthTries is set higher than 4"
fi