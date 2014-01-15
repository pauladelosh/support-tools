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

profile_file=''
# are we using .profile or .bash_profile
if [ -e ~/.bash_profile ]
  then
    profile_file=~/.bash_profile
elif [ -e ~/.bash_login ]
  then
    profile_file=~/.bash_login
elif [ -e ~/.profile ]
  then
    profile_file=~/.profile
else
    touch ~/.profile
    profile_file=~/.profile
fi

install_bash=''
while [ "$install_bash" != "yes" ] && [ "$install_bash" != "no" ]
  do
    if [ "$install_bash" != "" ]
      then
        echo "yes or no are the only two valid responses."
    fi
    echo -n "Do you want to install the bash config on your machine? (yes/no) [yes]: "
    read install_bash
    if [ "$install_bash" == "" ]
      then
        install_bash="yes"
    fi
done

if [ "$install_bash" == "yes" ]
  then
     if ! grep -q '# include AH profile' $profile_file
      then
        echo "
# include AH profile
. ~/.ah_profile
" >> $profile_file
    fi

    cp -f $DIR/lib/bastion_bashrc ~/.ah_profile
    ah_profile_file=~/.ah_profile

    if ! grep -q '# set PATH so it includes Support-Tools bin' $ah_profile_file
      then
        echo "
# set PATH so it includes Support-Tools bin
if [ -d \"$DIR/bin\" ] ; then
  export PATH=\"$DIR/bin:\$PATH\"
fi" >> $ah_profile_file
    fi

    if ! grep -q '# set bastion function to use' $ah_profile_file
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
function bastion { mywik ; }" >> $ah_profile_file
      else
          echo "
# set bastion function to use
function bastion { mywik2 ; }" >> $ah_profile_file
      fi
    fi

    if ! grep -q '# set ahtools autocomplete' $ah_profile_file
      then
        echo "
# set ahtools autocomplete
complete -W '\$($DIR/aht --autocomplete)' aht" >> $ah_profile_file
    fi

    # replace the username and private key variables
    perl -pi -e s,--LOCAL_USERNAME--,$USER,g $ah_profile_file
fi

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
    ssh_config_file=~/.ssh/ah_config

    existing_user=$USER
    if [ -e ~/.ssh/ah_config ]
      then
        existing_user=`grep -A 10 'Host bastion' ${ssh_config_file} | grep -m 1 User | grep -o '[a-zA-Z0-9]\+$'`
    fi
    echo -n "What is your bastion username? [$existing_user]: "
    read acquia_username
    if [ "$acquia_username" == "" ]
      then
        acquia_username=$existing_user
    fi

    existing_key='~/.ssh/id_rsa'
    if [ -e ~/.ssh/ah_config ]
      then
        existing_key=`grep -A 10 'Host bastion' ${ssh_config_file} | grep -m 1 IdentityFile | grep -o '[^ ]\+$'`
    fi
    echo -n "Where is your private key located? [$existing_key]: "
    read acquia_private_key
    if [ "$acquia_private_key" == "" ]
      then
        acquia_private_key=$existing_key
    fi

    existing_bastion='bastion-21'
    if [ -e ~/.ssh/ah_config ]
      then
        existing_bastion=`grep -A 1 'Host bastion' ${ssh_config_file} | grep -m 1 -o 'HostName [^.]\+' | cut -d ' ' -f 2`
    fi
    echo -n "Which is your bastion server? [$existing_bastion]: "
    read acquia_bastion
    if [ "$acquia_bastion" == "" ]
      then
        acquia_bastion=$existing_bastion
    fi

    cp -f $DIR/lib/acquia_ssh_config ~/.ssh/ah_config

    # replace the username and private key variables
    perl -pi -e s,--USERNAME--,$acquia_username,g $ssh_config_file
    perl -pi -e s,--KEYNAME--,$acquia_private_key,g $ssh_config_file
    perl -pi -e s,--BASTION--,$acquia_bastion,g $ssh_config_file
fi
