#!/bin/bash

script_dir=$(dirname "${BASH_SOURCE[0]}")

mkdir -p $script_dir/../provisioning_script

host_destination_path=/opt/F5Networks/onboarding

pushd ../provisioning_script > /dev/null

mkdir -p ./$host_destination_path
cp ../scripts/* ./$host_destination_path

tar czf scripts.tar.gz ./*

echo '!/bin/bash' >> extract.sh
echo 'cd /' > extract.sh
echo "tail -n +\$(sed -n '/^__ARCHIVE_BELOW__/=' \$0) \$0 | tar -xz" >> extract.sh
echo 'nohup sh -c '/opt/F5Networks/onboarding/onboarding.sh' >> /var/log/F5NetworksBIGIPOnboard.log' >> extract.sh
echo 'exit 0' >> extract.sh
echo '__ARCHIVE_BELOW__' >> extract.sh

cat extract.sh scripts.tar.gz > onboarding.sh

rm -rf $(echo "$host_destination_path" | cut -d'/' -f2)
rm -rf ./extract.sh
rm -rf ./scripts.tar.gz

popd > /dev/null
