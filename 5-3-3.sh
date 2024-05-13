#!/bin/bash
#Control: 5.3.3 Ensure sudo log file exists
# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}\n' 'sudo' 2>/dev/null | grep -q installed; then

var_sudo_logfile='/var/log/sudo.log'


if /usr/sbin/visudo -qcf /etc/sudoers; then
    cp /etc/sudoers /etc/sudoers.bak
    if ! grep -P '^[\s]*Defaults[\s]*\blogfile\s*=\s*("(?:\\"|\\\\|[^"\\\n])*"\B|[^"](?:(?:\\,|\\"|\\ |\\\\|[^", \\\n])*)\b)\b.*$' /etc/sudoers; then
        # sudoers file doesn't define Option logfile
        echo "Defaults logfile=${var_sudo_logfile}" >> /etc/sudoers
    else
        # sudoers file defines Option logfile, remediate if appropriate value is not set
        if ! grep -P "^[\s]*Defaults.*\blogfile=${var_sudo_logfile}\b.*$" /etc/sudoers; then

            escaped_variable=${var_sudo_logfile//$'/'/$'\/'}
            sed -Ei "s/(^[\s]*Defaults.*\blogfile=)[-]?.+(\b.*$)/\1$escaped_variable\2/" /etc/sudoers
        fi
    fi

    # Check validity of sudoers and cleanup bak
    if /usr/sbin/visudo -qcf /etc/sudoers; then
        rm -f /etc/sudoers.bak
    else
        echo "Fail to validate remediated /etc/sudoers, reverting to original file."
        mv /etc/sudoers.bak /etc/sudoers
        false
    fi
else
    echo "Skipping remediation, /etc/sudoers failed to validate"
    false
fi

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi