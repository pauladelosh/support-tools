Support Tools
=============

AH Tools
--------

### Installation

1. Clone the repository to your home directory or some other location you want to keep the repository. (git clone git@github.com:acquia/Support-Tools.git)
2. Execute the install.sh script which is inside the root of the repo. (/path/to/repo/install.sh)
3. Use the commands by simply typing aht. The commands are self documenting.

### Upgrading

1. Go to the directory where you cloned the repository in step 1 of the AH Tools installation.
2. Git pull the changes. (git pull origin master)
3. Run the install.sh script again after.

### Extra

If you have extra entries that you would like added to your ~/.ssh/config file you can add them to ~/.ssh/myconfig and they will automatically be appended to the ~/.ssh/config file when running the install.sh script.

### Migrating to a new computer

1. Clone this repo to the same place on the new machine
1. Copy your ~/.ssh/config from the old machine to the new
1. Copy the RSA keypair used to log onto the bastion from the old machine to the new
1. Copy your ~/.WiKID from the old machine to the new
1. Copy your ~/.bash_profile from the old machine to the new
1. source ~/.bash_profile
1. You should be able to log onto the bastion without an OP ticket
