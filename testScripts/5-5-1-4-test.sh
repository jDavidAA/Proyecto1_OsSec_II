#!/bin/bash

useradd_output=$(useradd -D | grep INACTIVE | awk -F= '{print $2}')

shadow_output=$(awk -F: '(/^[^:]+:[^!*]/ && ($7~/(\\s*$|-1)/ || $7>30)){print $1 " " $7}' /etc/shadow)

if [ "$useradd_output" -le 30 ] && [ -z "$shadow_output" ]; then
    echo -e "\nPASS:\n Inactive password lock is set to 30 or less"
else
    echo -e "\nFAIL:\n Inactive password lock is set higher than 30"
fi