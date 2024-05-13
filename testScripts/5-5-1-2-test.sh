#!/bin/bash

login_defs_output=$(grep PASS_MAX_DAYS /etc/login.defs | awk '{print $2}')
shadow_output=$(awk -F: '(/^[^:]+:[^!*]/ && ($5>365 || $5~/([0-1]|-1|\s*)/)){print $1 " " $5}' /etc/shadow)

if [ "$login_defs_output" -le 365 ] && [ -z "$shadow_output" ]; then
    echo -e "\nPASS:\n SSH PassMaxDays is set to 365 or less"
else
    echo -e "\nFAIL:\n SSH PassMaxDays is set higher than 365"
fi