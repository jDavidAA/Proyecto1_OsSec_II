#!/bin/bash
#Control: 1.6.1.2
# Remediation is applicable only in certain platforms
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then

# Correct the form of default kernel command line in GRUB
if grep -q '^GRUB_CMDLINE_LINUX=.*apparmor=.*"'  '/etc/default/grub' ; then
       # modify the GRUB command-line if an apparmor= arg already exists
       sed -i "s/\(^GRUB_CMDLINE_LINUX=\".*\)apparmor=[^[:space:]]\+\(.*\"\)/\1apparmor=1\2/"  '/etc/default/grub'
else
       # no apparmor=arg is present, append it
       sed -i "s/\(^GRUB_CMDLINE_LINUX=\".*\)\"/\1 apparmor=1\"/"  '/etc/default/grub'
fi
# Correct the form of default kernel command line in GRUB
if grep -q '^GRUB_CMDLINE_LINUX=.*security=.*"'  '/etc/default/grub' ; then
       # modify the GRUB command-line if an security= arg already exists
       sed -i "s/\(^GRUB_CMDLINE_LINUX=\".*\)security=[^[:space:]]\+\(.*\"\)/\1security=apparmor\2/"  '/etc/default/grub'
else
       # no security=arg is present, append it
       sed -i "s/\(^GRUB_CMDLINE_LINUX=\".*\)\"/\1 security=apparmor\"/"  '/etc/default/grub'
fi


update-grub

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi