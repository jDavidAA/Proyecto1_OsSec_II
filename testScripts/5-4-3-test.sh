#!/bin/bash

common_password_output=$(grep -P '^\h*password\h+([^#\n\r]+\h+)?pam_unix\.so\h+([^#\n\r]+\h+)?remember=([5-9]|[1-9][0-9]+)\b' /etc/pam.d/common-password)

if echo "$common_password_output" | grep -q "password\s\+\[success=1 default=ignore\]\s\+pam_unix.so\s\+obscure\s\+yescrypt\s\+remember=[1-5]"; then
    echo -e "\nPASS:\n Password reuse is limited"
else
    echo -e "\nFAIL:\n Password reuse is not limited"
fi