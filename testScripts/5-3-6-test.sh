#!/bin/bash

sudoers_output=$(grep -roP "timestamp_timeout=\K[0-9]*" /etc/sudoers*)

if [ "$sudoers_output" == "/etc/sudoers:15" ]; then
    echo -e "\nPASS:\n Sudo authentication timeout is configured correctly"
else
    echo -e "\nFAIL:\n Sudo authentication timeout is missconfigured"
fi