#!/bin/bash

sshd_output=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep permituserenvironment)
ssh_config_output=$(grep -Ei '^\s*PermitUserEnvironment\s+yes' /etc/ssh/sshd_config)

if [ "$sshd_output" == "permituserenvironment no" ] && [ -z "$ssh_config_output" ]; then
    echo -e "\nPASS:\n SSH PermitUserEnvironment is disabled"
else
    echo -e "\nFAIL:\n SSH PermitUserEnvironment is enabled"
fi
