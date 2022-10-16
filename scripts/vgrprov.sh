#!/bin/bash
sudo useradd -s /bin/bash ansible
sudo mkdir -p /home/ansible/.ssh
sudo cat /vagrant/sync/id_rsa.pub >> /home/ansible/.ssh/authorized_keys
sudo chown -R ansible:ansible /home/ansible
sudo echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
sudo timedatectl set-timezone Europe/Madrid

