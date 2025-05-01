all:
	sh -c ./utils/make_cloudinit_userdata.sh
	sh -c ./utils/make_provisioning_script.sh

