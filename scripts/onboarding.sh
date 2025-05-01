#!/bin/bash

script_dir=$(dirname "${BASH_SOURCE[0]}")

full_script_path=$(realpath "$0")
full_script_dir=$(dirname "$SCRIPT")

# Source the installenv file
if [ -f "$script_dir/installenv" ]; then
  source "$script_dir/installenv"
else
  echo "Error: installenv file not found in $script_dir"
  exit 1
fi

function create_netplan {
    NETPLAN_TEMPLATE="$script_dir/netplan_template.yaml"
    NETPLAN="$script_dir/netplan.yaml"
    cp $NETPLAN_TEMPLATE $NETPLAN
    sed -i "s/__DNS_1__/$DNS_1/g" $NETPLAN
    sed -i "s/__DNS_2__/$DNS_2/g" $NETPLAN
    sed -i "s/__PUBLIC_IP_ADDRESS__/$PUBLIC_IP_ADDRESS/g" $NETPLAN
    sed -i "s/__PUBLIC_IP_MASK__/$PUBLIC_IP_MASK/g" $NETPLAN
    sed -i "s/__PUBLIC_NEXT_HOP__/$PUBLIC_NEXT_HOP/g" $NETPLAN
    sed -i "s/__PRIVATE_IP_ADDRESS__/$PRIVATE_IP_ADDRESS/g" $NETPLAN
    sed -i "s/__PRIVATE_IP_MASK__/$PRIVATE_IP_MASK/g" $NETPLAN
    sed -i "s/__PRIVATE_NEXT_HOP__/$PRIVATE_NEXT_HOP/g" $NETPLAN
    cp $NETPLAN /etc/netplan/01-netcfg.yaml
    netplan apply
}

function create_bigip_userdata {
    BIGIP_CLOUDINIT_USERDATA_TEMPLATE="$script_dir/BIGIPUserDataTemplate.yaml"
    BIGIP_CLOUD_USERDATA="$script_dir/BIGIPUserData.yaml"
    cp $BIGIP_CLOUDINIT_USERDATA_TEMPLATE $BIGIP_CLOUD_USERDATA
    sed -i "s/__TMOS_ADMIN_PASSWORD__/$TMOS_ADMIN_PASSWORD/g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__BIGIP_SSH_AUTH_KEY__|$BIGIP_SSH_AUTH_KEY|g" $BIGIP_CLOUD_USERDATA
    sed -i "s/__BIGIP_HOSTNAME__/$BIGIP_HOSTNAME/g" $BIGIP_CLOUD_USERDATA
    sed -i "s/__DNS_1__/$DNS_1/g" $BIGIP_CLOUD_USERDATA
    sed -i "s/__DNS_2__/$DNS_2/g" $BIGIP_CLOUD_USERDATA
    sed -i "s/__BIGIP_MANAGEMENT_IP__/$BIGIP_MANAGEMENT_IP_ADDRESS/g" $BIGIP_CLOUD_USERDATA
    sed -i "s/__BIGIP_MANAGEMENT_NETMASK__/$BIGIP_MANAGEMENT_NETMASK/g" $BIGIP_CLOUD_USERDATA
    sed -i "s/__BIGIP_MANAGEMENT_NEXT_HOP__/$BIGIP_MANAGEMENT_NEXT_HOP/g" $BIGIP_CLOUD_USERDATA
    sed -i "s/__BIGIP_MANAGEMENT_MTU__/$BIGIP_MANAGEMENT_MTU/g" $BIGIP_CLOUD_USERDATA
    rm -rf "$script_dir/cidataiso"
    mkdir -p "$script_dir/cidataiso"
    echo "instance-id: {{ $BIGIP_INSTANCE_ID }}" >> "$script_dir/cidataiso/meta-data"
    echo "local-hostname: {{ $BIGIP_HOSTNAME }}" >> "$script_dir/cidataiso/meta-data"
    mv $BIGIP_CLOUD_USERDATA "$script_dir/cidataiso/user-data"
    pushd $script_dir/cidataiso
    mkisofs -V cidata -lJR -o output.iso meta-data user-data
    popd
    cp $script_dir/cidataiso/output.iso $BIGIP_CLOUDINIT_ISO
}

function create_bigip_domain_xml {
    BIGIP_DOMAIN_TEMPLATE="$script_dir/BIGIPDomainTemplate.xml"
    BIGIP_DOMAIN="$script_dir/BIGIPDomain.xml"
    BIGIP_IMAGE_FILE="$full_script_dir/BIGIPImages/$BIGIP_IMAGE_DOWNLOAD_IMAGE_NAME"
    cp $BIGIP_DOMAIN_TEMPLATE $BIGIP_DOMAIN
    sed -i 's|__BIGIP_VM_NAME__|'${BIGIP_VM_NAME}'|g' $BIGIP_DOMAIN
    sed -i "s/__BIGIP_VM_MEMORY__/$BIGIP_VM_MEMORY/g" $BIGIP_DOMAIN
    sed -i "s/__BIGIP_VM_VCPUS__/$BIGIP_VM_VCPUS/g" $BIGIP_DOMAIN
    sed -i 's|__BIGIP_IMAGE_FILE__|'${BIGIP_IMAGE_FILE}'|g' $BIGIP_DOMAIN
    sed -i 's|__BIGIP_CLOUDINIT_ISO__|'${BIGIP_CLOUDINIT_ISO}'|g' $BIGIP_DOMAIN
    virsh define $BIGIP_DOMAIN
}

function manual_network_setup {
    ip addr del $PRIVATE_IP/32 dev $PRIVATE_INTERFACE
    # Create management bridge to private network
    PRIVATE_BRIDGE=br0
    brctl addbr $PRIVATE_BRIDGE
    ip set link br0 up
    ip addr add $PRIVATE_IP_ADDRESS/$PRIVATE_IP_MASK dev $PRIVATE_BRIDGE
    brctl addif $PRIVATE_BRIDGE $PRIVATE_INTERFACE
    ip route add 10.0.0.0/8 via $PRIVATE_NEXT_HOP

    ## Add SR-IOV vfs for BIG-IP data plane
    echo 2 > /sys/class/net/eth0/device/sriov_numvfs
    echo 2 > /sys/class/net/eth1/device/sriov_numvfs
    echo 2 > /sys/class/net/eth2/device/sriov_numvfs
    echo 2 > /sys/class/net/eth3/device/sriov_numvfs

    # BIG-IP 1.1 SL_PRIVATE_BOND0 - ETH0 VF0
    brctl addbr eth0vf0
    brctl addif eth0vf0 ens1f0v0
    ip link set up ens1f0v0

    # BIG-IP 1.2 SL_PRIVATE_BOND1  - ETH2 VF0
    brctl addbr eth2vf0
    brctl addif eth2vf0 ens1f2v0
    ip link set up ens1f2v0

    # BIG-IP 1.3 SL_PUBLIC_BOND0 -  ETH1 VF0
    brctl addbr eth1vf0
    brctl addif eth1vf0 ens1f1v0
    ip link set up ens1f1v0

    # BIG-IP 1.4 SL_PUBLIC_BOND1 -  ETH3 VF0
    brctl addbr eth3vf0
    brctl addif eth3vf0 ens1f3v0
    ip link set up ens1f3v0

    # BIG-IP 1.5 CUST_PRIVATE_BOND0 - ETH0 VF1
    brctl addbr eth0vf1
    brctl addif eth0vf1 ens1f0v1
    ip link set up ens1f0v1

    # BIG-IP 1.6 CUST_PRIVATE_BOND1 - ETH2 VF1
    brctl addbr eth2vf1
    brctl addif eth2vf1 ens1f2v1
    ip link set up ens1f2v1

    # BIG-IP 1.7 CUST_PRIVATE_BOND0 - ETH1 VF1
    brctl addbr eth1vf1onboarding
    brctl addif eth1vf1 ens1f1v1
    ip link set up ens1f1v1

    # BIG-IP 1.8 CUST_PRIVATE_BOND1 - ETH3 VF1
    brctl addbr eth3vf1
    brctl addif eth3vf1 ens1f3v1
    ip link set up ens1f3v1
}

function download_bigip_image {
    mkdir -p "$script_dir/BIGIPImages"
    wget -nc $BIGIP_IMAGE_DOWNLOAD_PATH/$BIGIP_IMAGE_DOWNLOAD_IMAGE_NAME -P "$script_dir/BIGIPImages"
}

download_bigip_image
create_netplan
create_bigip_userdata
create_bigip_domain_xml

virsh start $BIGIP_VM_NAME
