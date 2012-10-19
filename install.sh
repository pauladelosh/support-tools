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


if ! grep -q '# set PATH so it includes Support-Tools bin' ${profile_file}
  then
    echo "

# set PATH so it includes Support-Tools bin
if [ -d \"$DIR/bin\" ] ; then
    export PATH=\"$DIR/bin:\$PATH\"
fi" >> $profile_file
fi

if ! grep -q '# set bastion function to use' $profile_file
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
" >> $profile_file
  else
      echo "
# set bastion function to use
function bastion { mywik2 ; }
" >> $profile_file
  fi
fi

if ! grep -q '# set ahtools autocomplete' $profile_file
  then
    echo "
# set ahtools autocomplete
complete -W '\$($DIR/ahmc --autocomplete)' ahmc
complete -W '\$($DIR/ahdc --autocomplete)' ahdc
complete -W '\$($DIR/ahdc --autocomplete)' aht
" >> $profile_file
fi

source $profile_file

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
    existing_user=$USER
    if [ -e ~/.ssh/config ]
      then
        existing_user=`grep -A 10 'Host bastion' ~/.ssh/config | grep -m 1 User | grep -o '[a-zA-Z0-9]\+$'`
    fi
    echo -n "What is your acquia hosting username? [$existing_user]: "
    read acquia_username
    if [ "$acquia_username" == "" ]
      then
        acquia_username=$existing_user
    fi

    existing_key='~/.ssh/id_rsa'
    if [ -e ~/.ssh/config ]
      then
        existing_key=`grep -A 10 'Host bastion' ~/.ssh/config | grep -m 1 IdentityFile | grep -o '[^ ]\+$'`
    fi
    echo -n "Where is your private key located? [$existing_key]: "
    read acquia_private_key
    if [ "$acquia_private_key" == "" ]
      then
        acquia_private_key=$existing_key
    fi

    current_datetime=`date "+%Y%m%d_%H%M%S"`
    if [ -e ~/.ssh/config ]
      then
        mv ~/.ssh/config ~/.ssh/config_${current_datetime}
    fi
    cp -f $DIR/lib/acquia_ssh_config ~/.ssh/config

    # append any custom rules from myconfig to the end of the file
    if [ -e ~/.ssh/myconfig ]
      then
        echo "

### Additional config appended from ~/.ssh/myconfig ###
" >> ~/.ssh/config
        cat ~/.ssh/myconfig >> ~/.ssh/config
    fi

    # replace the username and private key variables
    perl -pi -e s,--USERNAME--,$acquia_username,g ~/.ssh/config
    perl -pi -e s,--KEYNAME--,$acquia_private_key,g ~/.ssh/config

    if [ -e ~/.ssh/config_${current_datetime} ] && diff -q ~/.ssh/config_${current_datetime} ~/.ssh/config > /dev/null
      then
        rm ~/.ssh/config_${current_datetime}
    fi
fi
