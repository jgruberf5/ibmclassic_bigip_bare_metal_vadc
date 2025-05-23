#!/bin/bash

script_dir=$(dirname "${BASH_SOURCE[0]}")

full_script_path=$(realpath "$0")
full_script_dir=$(dirname "$full_script_path")

# Source the installenv file
if [ -f "$script_dir/installenv" ]; then
  source "$script_dir/installenv"
else
  echo "Error: installenv file not found in $script_dir"
  exit 1
fi

function assure_packages {
  echo "Installing hypervisor and qemu agent requirements"
  nohup sh -c apt update || true
  nohup sh -c apt install -y bridge-utils cpu-checker libvirt-clients libvirt-daemon libvirt-daemon-system qemu qemu-kvm genisoimage || true
}

function create_netplan {
    echo "Creating BIG-IP virtual edition management access and activating SR-IOV virtual functions"
    NETPLAN_TEMPLATE="$script_dir/netplan_template.yaml"
    NETPLAN="$script_dir/netplan.yaml"
    cp $NETPLAN_TEMPLATE $NETPLAN
    sed -i "s|__DNS_1__|$DNS_1|g" $NETPLAN
    sed -i "s|__DNS_2__|$DNS_2|g" $NETPLAN
    sed -i "s|__PUBLIC_IP_ADDRESS__|$PUBLIC_IP_ADDRESS|g" $NETPLAN
    sed -i "s|__PUBLIC_IP_MASK__|$PUBLIC_IP_MASK|g" $NETPLAN
    sed -i "s|__PUBLIC_NEXT_HOP__|$PUBLIC_NEXT_HOP|g" $NETPLAN
    sed -i "s|__PRIVATE_IP_ADDRESS__|$PRIVATE_IP_ADDRESS|g" $NETPLAN
    sed -i "s|__PRIVATE_IP_MASK__|$PRIVATE_IP_MASK|g" $NETPLAN
    sed -i "s|__PRIVATE_NEXT_HOP__|$PRIVATE_NEXT_HOP|g" $NETPLAN
    sed -i "s|__HOST_LINK_LOCAL_MANAGEMENT_IP__|$HOST_LINK_LOCAL_MANAGEMENT_IP|g" $NETPLAN
}

function apply_netplan {
    echo "Applying Netplan"
    cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.original
    cp $NETPLAN /etc/netplan/01-netcfg.yaml
    netplan apply
}

function create_bigip_userdata {
    echo "Creating BIG-IP cloud-init user_data"
    BIGIP_CLOUDINIT_USERDATA_TEMPLATE="$script_dir/BIGIPUserDataTemplate.yaml"
    BIGIP_CLOUD_USERDATA="$script_dir/BIGIPUserData.yaml"
    cp $BIGIP_CLOUDINIT_USERDATA_TEMPLATE $BIGIP_CLOUD_USERDATA
    sed -i "s|__TMOS_ADMIN_PASSWORD__|$TMOS_ADMIN_PASSWORD|g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__BIGIP_SSH_AUTH_KEY__|$BIGIP_SSH_AUTH_KEY|g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__BIGIP_HOSTNAME__|$BIGIP_HOSTNAME|g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__DNS_1__|$DNS_1|g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__DNS_2__|$DNS_2|g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__BIGIP_MANAGEMENT_IP__|$BIGIP_MANAGEMENT_IP|g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__BIGIP_MANAGEMENT_NEXT_HOP__|$BIGIP_MANAGEMENT_NEXT_HOP|g" $BIGIP_CLOUD_USERDATA
    sed -i "s|__BIGIP_MANAGEMENT_MTU__|$BIGIP_MANAGEMENT_MTU|g" $BIGIP_CLOUD_USERDATA
    rm -rf "$script_dir/cidataiso"
    mkdir -p "$script_dir/cidataiso"
    echo "instance-id: {{ $BIGIP_INSTANCE_ID }}" >> "$script_dir/cidataiso/meta-data"
    echo "local-hostname: {{ $BIGIP_HOSTNAME }}" >> "$script_dir/cidataiso/meta-data"
    mv $BIGIP_CLOUD_USERDATA "$script_dir/cidataiso/user-data"
    pushd $script_dir/cidataiso
    mkisofs -V cidata -lJR -o output.iso meta-data user-data || true
    popd
    cp $script_dir/cidataiso/output.iso $BIGIP_CLOUDINIT_ISO
}

function create_bigip_domain_xml {
    echo "Creating libvirt domain XML for BIG-IP virtual edition"
    BIGIP_DOMAIN_TEMPLATE="$script_dir/BIGIPDomainTemplate.xml"
    BIGIP_DOMAIN="$script_dir/BIGIPDomain.xml"
    BIGIP_IMAGE_FILE="$full_script_dir/BIGIPImages/$BIGIP_IMAGE_DOWNLOAD_IMAGE_NAME"
    cp $BIGIP_DOMAIN_TEMPLATE $BIGIP_DOMAIN
    sed -i 's|__BIGIP_VM_NAME__|'${BIGIP_VM_NAME}'|g' $BIGIP_DOMAIN
    sed -i "s|__BIGIP_VM_MEMORY__|$BIGIP_VM_MEMORY|g" $BIGIP_DOMAIN
    sed -i "s|__BIGIP_VM_VCPUS__|$BIGIP_VM_VCPUS|g" $BIGIP_DOMAIN
    sed -i 's|__BIGIP_IMAGE_FILE__|'${BIGIP_IMAGE_FILE}'|g' $BIGIP_DOMAIN
    sed -i 's|__BIGIP_CLOUDINIT_ISO__|'${BIGIP_CLOUDINIT_ISO}'|g' $BIGIP_DOMAIN
    virsh define $BIGIP_DOMAIN
}

function download_bigip_image {
    mkdir -p "$script_dir/BIGIPImages"
    echo "Downloading $BIGIP_IMAGE_DOWNLOAD_PATH/$BIGIP_IMAGE_DOWNLOAD_IMAGE_NAME..."
    wget --retry-connrefused --waitretry=1 --read-timeout=30 --timeout=15 -t 0 -nc $BIGIP_IMAGE_DOWNLOAD_PATH/$BIGIP_IMAGE_DOWNLOAD_IMAGE_NAME -P "$script_dir/BIGIPImages"
}

function forward_management_traffic {
    echo "creating port forwarding rules for BIG-IP VE management"
}

create_netplan
assure_packages
download_bigip_image
apply_netplan
create_bigip_userdata
create_bigip_domain_xml

echo "starting BIG-IP virtual edition"
virsh start $BIGIP_VM_NAME || true
