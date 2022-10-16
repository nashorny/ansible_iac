#!/bin/bash
export VAGRANT_HOME=/inst/vagrant
export VMDOMAIN=/inst/vmdomains/$1
export HOST_VARS=$WORKSPACE/ansible/inventories/host_vars
export INVFILE=$WORKSPACE/ansible/inventories/iacinventory
export SCRIPT=vgrprov.sh
# export CSVFILE=$WORKSPACE/input/inv.csv
# export INPUTCSVFILE=$WORKSPACE/input/inv.in
export INPUTCSVFILE=$2
export SSHKEY=$WORKSPACE/input/id_rsa.pub

#process input csv file
# head -n 1 $CSVFILE > $INPUTCSVFILE
# while read line; do
# 	grep ^$line $CSVFILE >> $INPUTCSVFILE;
# done <<< "$nodes"

INPUTCSVFILTERED=$(grep -v '#' $INPUTCSVFILE)

# Ubuntu or Centos
if [ "$OS" == "generic/ubuntu1604" ]; then
	export SCRIPT=vgrubuntu.sh
fi

#Clean previous vagrant domain
mkdir -p $VMDOMAIN
cd $VMDOMAIN
/usr/bin/vagrant destroy -f
rm -rf $VMDOMAIN/*

#Prepare new vagrant domain
cp $WORKSPACE/vagrant/Vagrantfile $VMDOMAIN
cp $WORKSPACE/scripts/vagrantdestroy.sh $VMDOMAIN
mkdir -p $VMDOMAIN/sync

#Generate ansible inventory and Vagrantfile
/usr/bin/python $WORKSPACE/scripts/auto-inv-vagrantfile.py $INPUTCSVFILE $VMDOMAIN $SCRIPT $HOST_VARS $WORKSPACE/vagrant/Vagrantfile $OS $INVFILE
#Copy vagrant provision scripts
cp -p $WORKSPACE/scripts/$SCRIPT $SSHKEY $VMDOMAIN/sync

#Prepare kvm net
/usr/bin/virsh net-destroy default
/usr/bin/virsh net-define $WORKSPACE/input/kvm-net.xml
/usr/bin/virsh net-start default
sleep 2

#Update kvm static dhcp ips
while read line; do

	HOSTN=$(echo $line | cut -d';' -f1)
	MAC=$(echo $line | cut -d';' -f2)
	IP=$(echo $line | cut -d';' -f3)	
	/usr/bin/virsh net-update default add ip-dhcp-host "<host mac='$MAC' name='$HOSTN' ip='$IP'/>" --live --config

	#Update etc host info
	cp -p /etc/hosts $WORKSPACE
	EXIST=$(grep $HOSTN /etc/hosts)
	if [ "$EXIST" != "" ]; then
		sudo sed -i "s/.*$HOSTN/$IP $HOSTN/" /etc/hosts
	else		
		echo "$IP $HOSTN" | sudo tee -a /etc/hosts
	fi

done <<< "$INPUTCSVFILTERED"
sleep 2

#Start Vagrant environment
/usr/bin/vagrant up --provider=libvirt

echo "Wait kvm to spawm"
sleep 5