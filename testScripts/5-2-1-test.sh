#!/bin/bash

permissions=$(stat -c "%a" /etc/ssh/sshd_config)

owner=$(stat -c "%U" /etc/ssh/sshd_config)

group=$(stat -c "%G" /etc/ssh/sshd_config)

if [ "$permissions" -eq "600" ] && [ "$owner" == "root" ] && [ "$group" == "root" ]; then
    echo -e "\nPASS:\n Permissions on /etc/ssh/sshd_config file are correct."
else
    echo -e "\nFAIL:\n Permissions on /etc/ssh/sshd_config file are not correct."
fi