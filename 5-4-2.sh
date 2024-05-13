#!/bin/bash
#Control: 5.4.2
# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}\n' 'libpam-runtime' 2>/dev/null | grep -q installed; then

var_accounts_passwords_pam_faillock_deny='4'


if [ -f /usr/bin/authselect ]; then
    if ! authselect check; then
echo "
authselect integrity check failed. Remediation aborted!
This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
It is not recommended to manually edit the PAM files when authselect tool is available.
In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
exit 1
fi
authselect enable-feature with-faillock

authselect apply-changes -b
else
    
pam_file="/etc/pam.d/common-auth"
if ! grep -qE '^\s*auth\s+required\s+pam_faillock\.so\s+preauth.*$' "$pam_file" ; then
    # insert at the top
    sed -i --follow-symlinks '/^# here are the per-package modules/i auth        required      pam_faillock.so preauth' "$pam_file"
fi
if ! grep -qE '^\s*auth\s+\[default=die\]\s+pam_faillock\.so\s+authfail.*$' "$pam_file" ; then

    num_lines=$(sed -n 's/^\s*auth.*success=\([1-9]\).*pam_unix\.so.*/\1/p' "$pam_file")
    if [ ! -z "$num_lines" ]; then

        # Add pam_faillock (authfail) module below pam_unix, skipping N-1 lines, where N is
        # the number of jumps in the pam_unix success=N statement. Ignore commented and empty lines.

        append_position=$(cat -n "${pam_file}" \
                          | grep -P "^\s+\d+\s+auth\s+.*$" \
                          | grep -w "pam_unix.so" -A $(( num_lines - 1 )) \
                          | tail -n 1 | cut -f 1 | tr -d ' '
                         )
        sed -i --follow-symlinks ''${append_position}'a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
    else
        sed -i --follow-symlinks '/^auth.*pam_unix\.so.*/a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
    fi
fi
if ! grep -qE '^\s*auth\s+sufficient\s+pam_faillock\.so\s+authsucc.*$' "$pam_file" ; then
    sed -i --follow-symlinks '/^auth.*pam_faillock\.so.*authfail.*/a auth        sufficient      pam_faillock.so authsucc' "$pam_file"
fi

pam_file="/etc/pam.d/common-account"
if ! grep -qE '^\s*account\s+required\s+pam_faillock\.so.*$' "$pam_file" ; then
    echo 'account   required     pam_faillock.so' >> "$pam_file"
fi

fi

AUTH_FILES=("/etc/pam.d/common-auth")

FAILLOCK_CONF="/etc/security/faillock.conf"
if [ -f $FAILLOCK_CONF ]; then
    regex="^\s*deny\s*="
    line="deny = $var_accounts_passwords_pam_faillock_deny"
    if ! grep -q $regex $FAILLOCK_CONF; then
        echo $line >> $FAILLOCK_CONF
    else
        sed -i --follow-symlinks 's|^\s*\(deny\s*=\s*\)\(\S\+\)|\1'"$var_accounts_passwords_pam_faillock_deny"'|g' $FAILLOCK_CONF
    fi
    for pam_file in "${AUTH_FILES[@]}"
    do
        if [ -e "$pam_file" ] ; then
            PAM_FILE_PATH="$pam_file"
            if [ -f /usr/bin/authselect ]; then
                
                if ! authselect check; then
                echo "
                authselect integrity check failed. Remediation aborted!
                This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
                It is not recommended to manually edit the PAM files when authselect tool is available.
                In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
                exit 1
                fi

                CURRENT_PROFILE=$(authselect current -r | awk '{ print $1 }')
                # If not already in use, a custom profile is created preserving the enabled features.
                if [[ ! $CURRENT_PROFILE == custom/* ]]; then
                    ENABLED_FEATURES=$(authselect current | tail -n+3 | awk '{ print $2 }')
                    authselect create-profile hardening -b $CURRENT_PROFILE
                    CURRENT_PROFILE="custom/hardening"
                    
                    authselect apply-changes -b --backup=before-hardening-custom-profile
                    authselect select $CURRENT_PROFILE
                    for feature in $ENABLED_FEATURES; do
                        authselect enable-feature $feature;
                    done
                    
                    authselect apply-changes -b --backup=after-hardening-custom-profile
                fi
                PAM_FILE_NAME=$(basename "$pam_file")
                PAM_FILE_PATH="/etc/authselect/$CURRENT_PROFILE/$PAM_FILE_NAME"

                authselect apply-changes -b
            fi
            
        if grep -qP '^\s*auth\s.*\bpam_faillock.so\s.*\bdeny\b' "$PAM_FILE_PATH"; then
            sed -i -E --follow-symlinks 's/(.*auth.*pam_faillock.so.*)\bdeny\b=?[[:alnum:]]*(.*)/\1\2/g' "$PAM_FILE_PATH"
        fi
            if [ -f /usr/bin/authselect ]; then
                
                authselect apply-changes -b
            fi
        else
            echo "$pam_file was not found" >&2
        fi
    done
else
    for pam_file in "${AUTH_FILES[@]}"
    do
        if ! grep -qE '^\s*auth.*pam_faillock\.so (preauth|authfail).*deny' "$pam_file"; then
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*preauth.*silent.*/ s/$/ deny='"$var_accounts_passwords_pam_faillock_deny"'/' "$pam_file"
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*authfail.*/ s/$/ deny='"$var_accounts_passwords_pam_faillock_deny"'/' "$pam_file"
        else
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*preauth.*silent.*\)\('"deny"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_deny"'\3/' "$pam_file"
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*authfail.*\)\('"deny"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_deny"'\3/' "$pam_file"
        fi
    done
fi

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi

if dpkg-query --show --showformat='${db:Status-Status}\n' 'libpam-runtime' 2>/dev/null | grep -q installed; then

var_accounts_passwords_pam_faillock_fail_interval='900'


if [ -f /usr/bin/authselect ]; then
    if ! authselect check; then
echo "
authselect integrity check failed. Remediation aborted!
This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
It is not recommended to manually edit the PAM files when authselect tool is available.
In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
exit 1
fi
authselect enable-feature with-faillock

authselect apply-changes -b
else
    
pam_file="/etc/pam.d/common-auth"
if ! grep -qE '^\s*auth\s+required\s+pam_faillock\.so\s+preauth.*$' "$pam_file" ; then
    # insert at the top
    sed -i --follow-symlinks '/^# here are the per-package modules/i auth        required      pam_faillock.so preauth' "$pam_file"
fi
if ! grep -qE '^\s*auth\s+\[default=die\]\s+pam_faillock\.so\s+authfail.*$' "$pam_file" ; then

    num_lines=$(sed -n 's/^\s*auth.*success=\([1-9]\).*pam_unix\.so.*/\1/p' "$pam_file")
    if [ ! -z "$num_lines" ]; then

        # Add pam_faillock (authfail) module below pam_unix, skipping N-1 lines, where N is
        # the number of jumps in the pam_unix success=N statement. Ignore commented and empty lines.

        append_position=$(cat -n "${pam_file}" \
                          | grep -P "^\s+\d+\s+auth\s+.*$" \
                          | grep -w "pam_unix.so" -A $(( num_lines - 1 )) \
                          | tail -n 1 | cut -f 1 | tr -d ' '
                         )
        sed -i --follow-symlinks ''${append_position}'a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
    else
        sed -i --follow-symlinks '/^auth.*pam_unix\.so.*/a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
    fi
fi
if ! grep -qE '^\s*auth\s+sufficient\s+pam_faillock\.so\s+authsucc.*$' "$pam_file" ; then
    sed -i --follow-symlinks '/^auth.*pam_faillock\.so.*authfail.*/a auth        sufficient      pam_faillock.so authsucc' "$pam_file"
fi

pam_file="/etc/pam.d/common-account"
if ! grep -qE '^\s*account\s+required\s+pam_faillock\.so.*$' "$pam_file" ; then
    echo 'account   required     pam_faillock.so' >> "$pam_file"
fi

fi

AUTH_FILES=("/etc/pam.d/common-auth")

FAILLOCK_CONF="/etc/security/faillock.conf"
if [ -f $FAILLOCK_CONF ]; then
    regex="^\s*fail_interval\s*="
    line="fail_interval = $var_accounts_passwords_pam_faillock_fail_interval"
    if ! grep -q $regex $FAILLOCK_CONF; then
        echo $line >> $FAILLOCK_CONF
    else
        sed -i --follow-symlinks 's|^\s*\(fail_interval\s*=\s*\)\(\S\+\)|\1'"$var_accounts_passwords_pam_faillock_fail_interval"'|g' $FAILLOCK_CONF
    fi
    for pam_file in "${AUTH_FILES[@]}"
    do
        if [ -e "$pam_file" ] ; then
            PAM_FILE_PATH="$pam_file"
            if [ -f /usr/bin/authselect ]; then
                
                if ! authselect check; then
                echo "
                authselect integrity check failed. Remediation aborted!
                This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
                It is not recommended to manually edit the PAM files when authselect tool is available.
                In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
                exit 1
                fi

                CURRENT_PROFILE=$(authselect current -r | awk '{ print $1 }')
                # If not already in use, a custom profile is created preserving the enabled features.
                if [[ ! $CURRENT_PROFILE == custom/* ]]; then
                    ENABLED_FEATURES=$(authselect current | tail -n+3 | awk '{ print $2 }')
                    authselect create-profile hardening -b $CURRENT_PROFILE
                    CURRENT_PROFILE="custom/hardening"
                    
                    authselect apply-changes -b --backup=before-hardening-custom-profile
                    authselect select $CURRENT_PROFILE
                    for feature in $ENABLED_FEATURES; do
                        authselect enable-feature $feature;
                    done
                    
                    authselect apply-changes -b --backup=after-hardening-custom-profile
                fi
                PAM_FILE_NAME=$(basename "$pam_file")
                PAM_FILE_PATH="/etc/authselect/$CURRENT_PROFILE/$PAM_FILE_NAME"

                authselect apply-changes -b
            fi
            
        if grep -qP '^\s*auth\s.*\bpam_faillock.so\s.*\bfail_interval\b' "$PAM_FILE_PATH"; then
            sed -i -E --follow-symlinks 's/(.*auth.*pam_faillock.so.*)\bfail_interval\b=?[[:alnum:]]*(.*)/\1\2/g' "$PAM_FILE_PATH"
        fi
            if [ -f /usr/bin/authselect ]; then
                
                authselect apply-changes -b
            fi
        else
            echo "$pam_file was not found" >&2
        fi
    done
else
    for pam_file in "${AUTH_FILES[@]}"
    do
        if ! grep -qE '^\s*auth.*pam_faillock\.so (preauth|authfail).*fail_interval' "$pam_file"; then
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*preauth.*silent.*/ s/$/ fail_interval='"$var_accounts_passwords_pam_faillock_fail_interval"'/' "$pam_file"
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*authfail.*/ s/$/ fail_interval='"$var_accounts_passwords_pam_faillock_fail_interval"'/' "$pam_file"
        else
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*preauth.*silent.*\)\('"fail_interval"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_fail_interval"'\3/' "$pam_file"
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*authfail.*\)\('"fail_interval"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_fail_interval"'\3/' "$pam_file"
        fi
    done
fi

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi

if dpkg-query --show --showformat='${db:Status-Status}\n' 'libpam-runtime' 2>/dev/null | grep -q installed; then

var_accounts_passwords_pam_faillock_unlock_time='600'


if [ -f /usr/bin/authselect ]; then
    if ! authselect check; then
echo "
authselect integrity check failed. Remediation aborted!
This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
It is not recommended to manually edit the PAM files when authselect tool is available.
In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
exit 1
fi
authselect enable-feature with-faillock

authselect apply-changes -b
else
    
pam_file="/etc/pam.d/common-auth"
if ! grep -qE '^\s*auth\s+required\s+pam_faillock\.so\s+preauth.*$' "$pam_file" ; then
    # insert at the top
    sed -i --follow-symlinks '/^# here are the per-package modules/i auth        required      pam_faillock.so preauth' "$pam_file"
fi
if ! grep -qE '^\s*auth\s+\[default=die\]\s+pam_faillock\.so\s+authfail.*$' "$pam_file" ; then

    num_lines=$(sed -n 's/^\s*auth.*success=\([1-9]\).*pam_unix\.so.*/\1/p' "$pam_file")
    if [ ! -z "$num_lines" ]; then

        # Add pam_faillock (authfail) module below pam_unix, skipping N-1 lines, where N is
        # the number of jumps in the pam_unix success=N statement. Ignore commented and empty lines.

        append_position=$(cat -n "${pam_file}" \
                          | grep -P "^\s+\d+\s+auth\s+.*$" \
                          | grep -w "pam_unix.so" -A $(( num_lines - 1 )) \
                          | tail -n 1 | cut -f 1 | tr -d ' '
                         )
        sed -i --follow-symlinks ''${append_position}'a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
    else
        sed -i --follow-symlinks '/^auth.*pam_unix\.so.*/a auth        [default=die]      pam_faillock.so authfail' "$pam_file"
    fi
fi
if ! grep -qE '^\s*auth\s+sufficient\s+pam_faillock\.so\s+authsucc.*$' "$pam_file" ; then
    sed -i --follow-symlinks '/^auth.*pam_faillock\.so.*authfail.*/a auth        sufficient      pam_faillock.so authsucc' "$pam_file"
fi

pam_file="/etc/pam.d/common-account"
if ! grep -qE '^\s*account\s+required\s+pam_faillock\.so.*$' "$pam_file" ; then
    echo 'account   required     pam_faillock.so' >> "$pam_file"
fi

fi

AUTH_FILES=("/etc/pam.d/common-auth")

FAILLOCK_CONF="/etc/security/faillock.conf"
if [ -f $FAILLOCK_CONF ]; then
    regex="^\s*unlock_time\s*="
    line="unlock_time = $var_accounts_passwords_pam_faillock_unlock_time"
    if ! grep -q $regex $FAILLOCK_CONF; then
        echo $line >> $FAILLOCK_CONF
    else
        sed -i --follow-symlinks 's|^\s*\(unlock_time\s*=\s*\)\(\S\+\)|\1'"$var_accounts_passwords_pam_faillock_unlock_time"'|g' $FAILLOCK_CONF
    fi
    for pam_file in "${AUTH_FILES[@]}"
    do
        if [ -e "$pam_file" ] ; then
            PAM_FILE_PATH="$pam_file"
            if [ -f /usr/bin/authselect ]; then
                
                if ! authselect check; then
                echo "
                authselect integrity check failed. Remediation aborted!
                This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
                It is not recommended to manually edit the PAM files when authselect tool is available.
                In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
                exit 1
                fi

                CURRENT_PROFILE=$(authselect current -r | awk '{ print $1 }')
                # If not already in use, a custom profile is created preserving the enabled features.
                if [[ ! $CURRENT_PROFILE == custom/* ]]; then
                    ENABLED_FEATURES=$(authselect current | tail -n+3 | awk '{ print $2 }')
                    authselect create-profile hardening -b $CURRENT_PROFILE
                    CURRENT_PROFILE="custom/hardening"
                    
                    authselect apply-changes -b --backup=before-hardening-custom-profile
                    authselect select $CURRENT_PROFILE
                    for feature in $ENABLED_FEATURES; do
                        authselect enable-feature $feature;
                    done
                    
                    authselect apply-changes -b --backup=after-hardening-custom-profile
                fi
                PAM_FILE_NAME=$(basename "$pam_file")
                PAM_FILE_PATH="/etc/authselect/$CURRENT_PROFILE/$PAM_FILE_NAME"

                authselect apply-changes -b
            fi
            
        if grep -qP '^\s*auth\s.*\bpam_faillock.so\s.*\bunlock_time\b' "$PAM_FILE_PATH"; then
            sed -i -E --follow-symlinks 's/(.*auth.*pam_faillock.so.*)\bunlock_time\b=?[[:alnum:]]*(.*)/\1\2/g' "$PAM_FILE_PATH"
        fi
            if [ -f /usr/bin/authselect ]; then
                
                authselect apply-changes -b
            fi
        else
            echo "$pam_file was not found" >&2
        fi
    done
else
    for pam_file in "${AUTH_FILES[@]}"
    do
        if ! grep -qE '^\s*auth.*pam_faillock\.so (preauth|authfail).*unlock_time' "$pam_file"; then
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*preauth.*silent.*/ s/$/ unlock_time='"$var_accounts_passwords_pam_faillock_unlock_time"'/' "$pam_file"
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*authfail.*/ s/$/ unlock_time='"$var_accounts_passwords_pam_faillock_unlock_time"'/' "$pam_file"
        else
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*preauth.*silent.*\)\('"unlock_time"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_unlock_time"'\3/' "$pam_file"
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*authfail.*\)\('"unlock_time"'=\)[0-9]\+\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_unlock_time"'\3/' "$pam_file"
        fi
    done
fi

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi