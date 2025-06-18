#!/bin/bash

if command -v dpkg-deb &> /dev/null; then
    script_dir=$(dirname "${BASH_SOURCE[0]}")
    pushd $script_dir > /dev/null
    mkdir -p ../build
    pacakge_file_name="bigip-virtual-edition"
    host_destination_dir="/opt/F5Networks/onboarding"
    cd ../build
    mkdir -p ./$pacakge_file_name/$host_destination_dir
    mkdir -p ./$pacakge_file_name/DEBIAN
    cp ../scripts/* ./$pacakge_file_name/$host_destination_dir
    control_file="./$pacakge_file_name/DEBIAN/control"
    echo "Package: bigip-virtual-edition" > $control_file
    echo "Version: 0.9" >> $control_file
    echo "Maintainer: F5 Networks - Business Development for IBM" >> $control_file
    echo "Architecture: all" >> $control_file
    echo "Description: BIG-IP Virtual Edition for IBM Cloud Classic Infrastructure Bare Metal servers" >> $control_file
    # post-install
    postinst_file="./$pacakge_file_name/DEBIAN/postinst"
    echo "#!/bin/bash" > $postinst_file
    echo "export DEB_PACKAGE_POST_INST=1" >> $postinst_file
    echo "chmod +x $host_destination_dir/onboarding.sh" >> $postinst_file
    echo "$host_destination_dir/onboarding.sh >> /var/log/F5NetworksBIGIPOnboard.log" >> $postinst_file
    chmod 775 $postinst_file
    prerm_file="./$pacakge_file_name/DEBIAN/prerm"
    echo "#!/bin/bash" > $prerm_file
    echo "export DEB_PACKAGE_PRERM=1" >> $prerm_file
    echo "chmod +x $host_destination_dir/uninstall.sh" >> $prerm_file
    echo "$host_destination_dir/uninstall.sh >> /var/log/F5NetworksBIGIPOnboard.log" >> $prerm_file
    chmod 775 $prerm_file
    dpkg-deb --build $pacakge_file_name
    rm -rf ./$pacakge_file_name
    popd > /dev/null    
else
    echo "debian package util dpkg-deb is not installed... skiling deb package build"
fi
