all:
	sh -c ./utils/make_cloudinit_userdata.sh
	sh -c ./utils/make_provisioning_script.sh
	sh -c ./utils/make_debian_package.sh

clean:
	rm -rf ./build

cloudinit:
	sh -c ./utils/make_cloudinit_userdata.sh

provisioning_script:
	sh -c ./utils/make_provisioning_script.sh

debian_package:
	sh -c ./utils/make_debian_package.sh
