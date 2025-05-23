#!/bin/bash

script_dir=$(dirname "${BASH_SOURCE[0]}")

pushd $script_dir > /dev/null

mkdir -p ../build
cd ../build

host_destination_path=/opt/F5Networks/onboarding

mkdir -p ./$host_destination_path
cp ../scripts/* ./$host_destination_path

tar czf scripts.tar.gz --exclude='user-data.yaml' ./*
archive=`cat scripts.tar.gz | base64 -w 0`

echo "#!/bin/bash" > onboarding.sh
echo "archive=$archive" >> onboarding.sh
echo "echo \$archive | base64 -d | tar -xz -C /" >> onboarding.sh
echo "chmod +x '$host_destination_path/onboarding.sh'" >> onboarding.sh
echo "nohup sh -c '$host_destination_path/onboarding.sh' >> /var/log/F5NetworksBIGIPOnboard.log" >> onboarding.sh

#echo '#!/bin/bash' > extract.sh
#echo "tar_marker=\$(sed -n '/^__TAR_BEGIN__\$/=' \$0)" >> extract.sh
#echo 'tail -n +$((tar_marker+1)) $0 | tar -xz -C /' >> extract.sh
#echo "chmod +x '$host_destination_path/onboarding.sh'" >> extract.sh
#echo "nohup sh -c '$host_destination_path/onboarding.sh' >> /var/log/F5NetworksBIGIPOnboard.log" >> extract.sh
#echo 'exit 0'  >> extract.sh
#echo '__TAR_BEGIN__'  >> extract.sh
#cat extract.sh scripts.tar.gz > onboarding.sh

rm -rf $(echo "$host_destination_path" | cut -d'/' -f2)
#rm -rf ./extract.sh
rm -rf ./scripts.tar.gz

popd > /dev/null
