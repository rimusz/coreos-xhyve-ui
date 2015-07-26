#!/bin/bash

#  first-init.command
#

#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/coreos-xhyve-ui/.env/resouces_path)

# path to the bin folder where we store our binary files
export PATH=${HOME}/coreos-xhyve-ui/bin:$PATH

echo " "
echo "Setting up CoreOS-xhyve VM on OS X"

# add ssh key to custom.conf
echo " "
echo "Reading ssh key from $HOME/.ssh/id_rsa.pub  "
file="$HOME/.ssh/id_rsa.pub"
if [ -f "$file" ]
then
    echo "$file found, updating custom.conf..."
    echo "SSHKEY='$(cat $HOME/.ssh/id_rsa.pub)'" >> ~/coreos-xhyve-ui/custom.conf
else
    echo "$file not found."
    echo "please run 'ssh-keygen -t rsa' before you continue !!!"
    pause 'Press [Enter] key to continue...'
    echo "SSHKEY="$(cat $HOME/.ssh/id_rsa.pub)"" >> ~/coreos-xhyve-ui/custom.conf
fi
#

# save user password to file
echo "  "
echo "Your Mac user password will be saved to '~/coreos-xhyve-ui/.env/password' "
echo "and later one used for 'sudo' commnand to start VM !!!"
echo "Please type your Mac user's password followed by [ENTER]:"
read -s password
echo -n ${password} | base64 > ~/coreos-xhyve-ui/.env/password
#

# create persistant disk
cd ~/coreos-xhyve-ui/
echo "  "
echo "Please type extra disk size in GB followed by [ENTER]:"
echo -n [default is 5]:
read disk_size
if [ -z "$disk_size" ]
then
    echo "Creating 5GB disk ..."
    dd if=/dev/zero of=extra.img bs=1024 count=0 seek=$[1024*5120]
else
    echo "Creating "$disk_size"GB disk ..."
    dd if=/dev/zero of=extra.img bs=1024 count=0 seek=$[1024*$disk_size*1024]
fi
#

# Set release channel
release_channel


# now let's fetch ISO file
echo " "
echo "Fetching lastest CoreOS $channel channel ISO ..."
echo " "
cd ~/coreos-xhyve-ui/
"${res_folder}"/bin/coreos-xhyve-fetch -f custom.conf
echo " "
#

echo " "
# Start VM
echo "Starting VM ..."
"${res_folder}"/bin/dtach -n ~/coreos-xhyve-ui/.env/.console -z "${res_folder}"/CoreOS-xhyve_UI_VM.command
#

# wait till VM is booted up
echo "You can connect to VM console from menu 'Attach to VM's console' "
echo "When you done with console just close it's window/tab with CMD+W "
echo "Waiting for VM to boot up..."
spin='-\|/'
i=0
until [ -e ~/coreos-xhyve-ui/.env/.console ] >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#
sleep 3

# get VM IP
echo "Waiting for VM to be ready..."
spin='-\|/'
i=0
until cat ~/coreos-xhyve-ui/.env/ip_address | grep 192.168.64 >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
vm_ip=$(cat ~/coreos-xhyve-ui/.env/ip_address)
#
# waiting for VM's response to ping
spin='-\|/'
i=0
while ! ping -c1 $vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
#

echo " "
# download latest versions of etcdctl, fleetctl and docker clients
download_osx_clients
#

# set fleetctl endpoint and install fleet units
export FLEETCTL_ENDPOINT=http://$vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
echo "fleetctl list-machines:"
fleetctl list-machines
echo " "

#

echo "Installation has finished, CoreOS VM is up and running !!!"
echo " "
echo "Assigned static VM's IP: $vm_ip"
echo " "
echo "Enjoy CoreOS-xhyve VM on your Mac !!!"
echo " "
echo "Run from menu 'OS Shell' to open a terninal window with rkt, docker, fleetctl and etcdctl pre-set !!!"
echo " "
pause 'Press [Enter] key to continue...'
