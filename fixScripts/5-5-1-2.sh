#!/bin/bash
#Control: 5.5.1.2
# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}\n' 'login' 2>/dev/null | grep -q installed; then

var_accounts_maximum_age_login_defs='365'


grep -q ^PASS_MAX_DAYS /etc/login.defs && \
  sed -i "s/PASS_MAX_DAYS.*/PASS_MAX_DAYS     $var_accounts_maximum_age_login_defs/g" /etc/login.defs
if ! [ $? -eq 0 ]; then
    echo "PASS_MAX_DAYS      $var_accounts_maximum_age_login_defs" >> /etc/login.defs
fi

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi

while IFS= read -r i; do
    chage -M $var_accounts_maximum_age_login_defs $i
done <   <(awk -v var="$var_accounts_maximum_age_login_defs" -F: '(/^[^:]+:[^!*]/ && ($5 > var || $5 == "")) {print $1}' /etc/shadow)