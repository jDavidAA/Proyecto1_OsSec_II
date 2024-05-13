#!/bin/bash

common_auth_output=$(grep "pam_faillock.so" /etc/pam.d/common-auth)
common_account_output=$(grep "pam_faillock.so" /etc/pam.d/common-account)

if echo "$common_auth_output" | grep -q "auth\s\+required\s\+pam_faillock.so\s\+preauth" && \
   echo "$common_auth_output" | grep -q "auth\s\+\[default=die\]\s\+pam_faillock.so\s\+authfail" && \
   echo "$common_auth_output" | grep -q "auth\s\+sufficient\s\+pam_faillock.so\s\+authsucc" && \
   echo "$common_account_output" | grep -q "account\s\+required\s\+pam_faillock.so"; then
    echo -e "\nPASS:\n PAM faillock configuration is correct"
else
    echo -e "\nFAIL:\n PAM faillock configuration is incorrect"
fi