#!/bin/bash

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Remove old symlinks
if [ -e /usr/local/bin/ahmc ]
  then
    sudo rm /usr/local/bin/ahmc
fi
if [ -e /usr/local/bin/ahdc ]
  then
    sudo rm /usr/local/bin/ahdc
fi

if ! grep -q '# set PATH so it includes Support-Tools bin' ~/.profile
  then
    echo "

# set PATH so it includes Support-Tools bin
if [ -d \"$DIR/bin\" ] ; then
    PATH=\"$DIR/bin:\$PATH\"
fi" >> ~/.profile
fi

if ! grep -q '# set bastion function to use' ~/.profile
  then
    same=''
    while [ "$same" != "yes" ] && [ "$same" != "no" ]
      do
        if [ "$same" != "" ]
          then
            echo "yes or no are the only two valid responses."
        fi
        echo -n "Is your SSH Password the same as the password you use to unlock WiKiD? (yes/no): "
        read same
     done

  if [ "$same" == "yes" ]
    then
      echo "
# set bastion function to use
function bastion { mywik ; }
" >> ~/.profile
  else
      echo "
# set bastion function to use
function bastion { mywik2 ; }
" >> ~/.profile
  fi
fi

source ~/.profile

install_ssh=''
while [ "$install_ssh" != "yes" ] && [ "$install_ssh" != "no" ]
  do
    if [ "$install_ssh" != "" ]
      then
        echo "yes or no are the only two valid responses."
    fi
    echo -n "Do you want to install the ssh config on your machine? (yes/no) [yes]: "
    read install_ssh
    if [ "$install_ssh" == "" ]
      then
        install_ssh="yes"
    fi
done

if [ "$install_ssh" == "yes" ]
  then
    echo -n "What is your acquia hosting username? [$USER]: "
    read acquia_username
    if [ "$acquia_username" == "" ]
      then
        acquia_username=$USER
    fi

    echo -n "Where is your private key located? [~/.ssh/id_rsa]: "
    read acquia_private_key
    if [ "$acquia_private_key" == "" ]
      then
        acquia_private_key="~/.ssh/id_rsa"
    fi

    cp -f $DIR/lib/acquia_ssh_config ~/.ssh/config
    perl -pi -e s,--USERNAME--,$acquia_username,g ~/.ssh/config
    perl -pi -e s,--KEYNAME--,$acquia_private_key,g ~/.ssh/config
fi
