all:
	sh -c ./utils/make_cloudinit_userdata.sh
	sh -c ./utils/make_provisioning_script.sh

clean:
	rm -rf ./build

cloudinit:
	sh -c ./utils/make_cloudinit_userdata.sh

provisioning_script:
	sh -c ./utils/make_provisioning_script.sh
