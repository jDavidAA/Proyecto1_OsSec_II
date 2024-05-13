#!/bin/bash

sshd_output=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i maxsessions)
ssh_config_output=$(grep -Ei '^\s*MaxSessions\s+(1[1-9]|[2-9][0-9]|[1-9][0-9][0-9]+)' /etc/ssh/sshd_config)

if [ "$(echo "$sshd_output" | awk '{print $2}')" -le 10 ] && [ -z "$ssh_config_output" ]; then
    echo -e "\nPASS:\n SSH MaxSessions is set to 10 or less"
else
    echo -e "\nFAIL:\n SSH MaxSessions is set higher than 10"
fi