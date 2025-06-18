#!/bin/bash

export script_dir=/opt/F5Networks/onboarding

# Source the installenv file
if [ -f "$script_dir/installenv" ]; then
  source "$script_dir/installenv"
else
  echo "Error: installenv file not found in $script_dir"
  exit 1
fi

set_permissions
create_systemd_unit_file
enable_systemd_service

[[ -z "${DEB_PACKAGE_POST_INST}" ]] && DEB_PACKAGE_POST_INST=0
if [ "$DEB_PACKAGE_POST_INST" -ne "1" ]; then 
    start_systemd_service
fi
