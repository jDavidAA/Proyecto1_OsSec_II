#!/bin/bash

login_defs_output=$(grep PASS_MIN_DAYS /etc/login.defs)
shadow_output=$(awk -F : '(/^[^:]+:[^!*]/ && $4 < 1){print $1 " " $4}' /etc/shadow)

if [ "$(echo "$login_defs_output" | awk '{print $2}')" -ge 1 ] && [ -z "$shadow_output" ]; then
    echo -e "\nPASS:\n SSH PassMinDays is set to 1 or more"
else
    echo -e "\nFAIL:\n SSH PassMinDays is set lower than 1"
fi