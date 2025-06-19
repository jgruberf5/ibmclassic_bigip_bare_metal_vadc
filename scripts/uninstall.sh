#!/bin/bash

export script_dir=/opt/F5Networks/onboarding

# Source the installenv file
if [ -f "$script_dir/installenv" ]; then
  source "$script_dir/installenv"
else
  echo "Error: installenv file not found in $script_dir"
  exit 1
fi

stop_systemd_service
disable_systemd_service
remove_systemd_unit_file
undefine_bigip_domain
remove_bigip_image
revert_netplan

[[ -z "${DEB_PACKAGE_PRERM}" ]] && DEB_PACKAGE_PRERM=0
if [ "$DEB_PACKAGE_PRERM" -ne "1" ]; then 
    rm -rf /opt/F5Networks
else
    rm -rf /opt/F5Networks/onboarding/*
fi
