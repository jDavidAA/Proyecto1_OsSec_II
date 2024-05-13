#!/bin/bash
#Control: 5.2.9 Ensure SSH PermitEmptyPasswords is disabled
# Remediation is applicable only in certain platforms
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then

mkdir -p /etc/ssh/sshd_config.d
touch /etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf

LC_ALL=C sed -i "/^\s*PermitEmptyPasswords\s\+/Id" "/etc/ssh/sshd_config"
LC_ALL=C sed -i "/^\s*PermitEmptyPasswords\s\+/Id" "/etc/ssh/sshd_config.d"/*.conf
if [ -e "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf" ] ; then

    LC_ALL=C sed -i "/^\s*PermitEmptyPasswords\s\+/Id" "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"
else
    touch "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"
fi
# make sure file has newline at the end
sed -i -e '$a\' "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"

cp "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf" "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf.bak"
# Insert before the line matching the regex '^Match'.
line_number="$(LC_ALL=C grep -n "^Match" "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf.bak" | LC_ALL=C sed 's/:.*//g')"
if [ -z "$line_number" ]; then
    # There was no match of '^Match', insert at
    # the end of the file.
    printf '%s\n' "PermitEmptyPasswords no" >> "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"
else
    head -n "$(( line_number - 1 ))" "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf.bak" > "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"
    printf '%s\n' "PermitEmptyPasswords no" >> "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"
    tail -n "+$(( line_number ))" "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf.bak" >> "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf"
fi
# Clean up after ourselves.
rm "/etc/ssh/sshd_config.d/01-complianceascode-reinforce-os-defaults.conf.bak"

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi