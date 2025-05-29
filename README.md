# ibmclassic_bigip_bare_metal_vadc
BIG-IP TMOS Running on IBM Bare Metal Servers for vADC Reference Architecture

Assumes one BIG-IP virtual edition instance per bare metal server.

Set install varables in a `/etc/bigip` file in `sh` ENV exported variable format.

Install variables:

| Variable    | Default | Description |
| -------- | ------- |
| TMOS_ADMIN_PASSWORD  | F5Networks! | The initial ssh root account and XUI admin password |
| BIGIP_HOSTNAME | The bare metal host hostname | BIG-IP virtual edition instance hostname |
| BIGIP_MANAGEMENT_IP | generated IPv4 link local address | BIG-IP virtual edition management inteface IP CIDR on the bond0 bridge |
| BIGIP_MANAGEMENT_NEXT_HOP | generated host IPv4 link local address | BIG-IP virtual edition management gateway address |
| BIGIP_MANAGEMENT_MTU | 1460 | BIG-IP virtual edition management interface MTU |
| BIGIP_INSTANCE_ID | bigipinstance1 | user-data CI data instance ID for the BIG-IP virtual edition |
| BIGIP_VM_NAME | BIG-IP-Virtual-Edition | libvirt instance name for the BIG-IP virtual edition |
| BIGIP_VM_MEMORY | 4194304 | Size in KB of the BIG-IP virtual edition RAM |
| BIGIP_VM_VCPUS | 2 | Number of virtual CPUs to allocate to BIG-IP virtual edition |
| BIGIP_VM_IMAGE_DOWNLOAD_PATH | IBM COS 17.5.0-0.0.15 ALL 1SLOT Bucket | Object storage bucket for the BIG-IP virtual edition qcow2 disk image |
| BIGIP_VM_IMAGE_DOWNLOAD_IMAGE_NAME | BIGIP-17.5.0-0.0.15.ALL_1SLOT-031025001.qcow2 | Object storage file for the BIG-IP virtual edition qcow2 disk image |
| BIGIP_VM_IMAGE_DOWNLOAD_IMAGE_MD5 | BIGIP-17.5.0-0.0.15.ALL_1SLOT-031025001.qcow2.md5 | Object storage file for the BIG-IP virtual edition qcow2 md5 hash |

Example `/etc/bigip`

```
export TMOS_ADMIN_PASSWORD='SuperSecureF5Password!123'
export BIGIP_MANAGEMENT_IP='10.120.92.159/26'
export BIGIP_MANAGEMENT_NEXT_HOP='10.120.92.129'
export BIGIP_VM_MEMORY=17179869
export BIGIP_VM_VCPUS=8
export BIGIP_VM_IMAGE_DOWNLOAD_PATH='https://s3.us-east.cloud-object-storage.appdomain.cloud/f5-adc-bigip-17.5.0-0.0.15.all-1slot-031025001-us-east'
export BIGIP_VM_IMAGE_DOWNLOAD_IMAGE_NAME='BIGIP-17.5.0-0.0.15.ALL_1SLOT-031025001.qcow2'
export BIGIP_VM_IMAGE_DOWNLOAD_IMAGE_MD5='BIGIP-17.5.0-0.0.15.ALL_1SLOT-031025001.qcow2.md5'
```