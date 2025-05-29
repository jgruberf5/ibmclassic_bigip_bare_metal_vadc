#!/bin/bash

script_dir=$(dirname "${BASH_SOURCE[0]}")

pushd $script_dir > /dev/null

mkdir -p ../build

cloudinit_file=../build/user-data.yaml

destination_dir="/opt/F5Networks/onboarding"

rm -rf $cloudinit_file

# install packages
echo "#cloud-config" > $cloudinit_file
echo "package_update: true" >> $cloudinit_file
echo "package_upgrade: true" >> $cloudinit_file
echo "packages:" >> $cloudinit_file
echo "  - bridge-utils" >> $cloudinit_file
echo "  - cpu-checker" >> $cloudinit_file
echo "  - libvirt-clients" >> $cloudinit_file
echo "  - libvirt-daemon" >> $cloudinit_file
echo "  - libvirt-daemon-system" >> $cloudinit_file
echo "  - qemu" >> $cloudinit_file
echo "  - qemu-kvm" >> $cloudinit_file
echo "  - genisoimage" >> $cloudinit_file
echo "  - ipcalc" >> $cloudinit_file

# boot commands
echo "bootcmd:" >> $cloudinit_file
echo "  - [ cloud-init-per, once, mkdir, -m, 0755, -p, '$destination_dir' ]" >> $cloudinit_file

echo "write_files:" >> $cloudinit_file
echo "  - path: $destination_dir/installenv" >> $cloudinit_file
echo "    permissions: 0755" >> $cloudinit_file
echo "    content: |" >> $cloudinit_file

while IFS= read -r line; do
  echo "      $line" >> $cloudinit_file
done < "../scripts/installenv"

# onboarding script
echo "  - path: $destination_dir/onboarding.sh" >> $cloudinit_file
echo "    permissions: 0755" >> $cloudinit_file
echo "    content: |" >> $cloudinit_file

while IFS= read -r line; do
  echo "      $line" >> $cloudinit_file
done < "../scripts/onboarding.sh"

# onboarding script
echo "  - path: $destination_dir/start" >> $cloudinit_file
echo "    permissions: 0755" >> $cloudinit_file
echo "    content: |" >> $cloudinit_file

while IFS= read -r line; do
  echo "      $line" >> $cloudinit_file
done < "../scripts/start"

# onboarding script
echo "  - path: $destination_dir/stop" >> $cloudinit_file
echo "    permissions: 0755" >> $cloudinit_file
echo "    content: |" >> $cloudinit_file

while IFS= read -r line; do
  echo "      $line" >> $cloudinit_file
done < "../scripts/stop"

# BIGIPDomainTemplate
echo "  - path: $destination_dir/BIGIPDomainTemplate.xml" >> $cloudinit_file
echo "    permissions: 0644" >> $cloudinit_file
echo "    content: |" >> $cloudinit_file

while IFS= read -r line; do
  echo "      $line" >> $cloudinit_file
done < "../scripts/BIGIPDomainTemplate.xml"

# netplan
echo "  - path: $destination_dir/netplan_template.yaml" >> $cloudinit_file
echo "    permissions: 0644" >> $cloudinit_file
echo "    content: |" >> $cloudinit_file

while IFS= read -r line; do
  echo "      $line" >> $cloudinit_file
done < "../scripts/netplan_template.yaml"

# BIGIP user-data
echo "  - path: $destination_dir/BIGIPUserDataTemplate.yaml" >> $cloudinit_file
echo "    permissions: 0644" >> $cloudinit_file
echo "    content: |" >> $cloudinit_file

while IFS= read -r line; do
  echo "      $line" >> $cloudinit_file
done < "../scripts/BIGIPUserDataTemplate.yaml"

# runcmd
echo "runcmd: [nohup sh -c '$destination_dir/onboarding.sh' >> /var/log/F5NetworksBIGIPOnboard.log &]" >> $cloudinit_file

popd > /dev/null