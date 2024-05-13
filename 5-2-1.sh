#!/bin/bash
#Control: 5.2.1
# Remediation is applicable only in certain platforms
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then

chown root:root /etc/ssh/sshd_config
chmod u-xs,g-xwrs,o-xwrt /etc/ssh/sshd_config

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi
