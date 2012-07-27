Support Tools
=============

AH Tools
--------

### Installation

1. Clone the repository to your home directory or some other location you want to keep the repository. (git clone git@github.com:acquia/Support-Tools.git)
2. Symlink the ahmc and ahdc files to your /usr/local/bin directory. (ln -s /path/to/ahmc /usr/local/bin/ && ln -s /path/to/ahdc /usr/local/bin/)
3. Use the commands by simply typing ahmc or ahdc. The commands are self documenting.

### Upgrading

1. Go to the directory where you cloned the repository in step 1 of the AH Tools installation.
2. Git pull the changes. (git pull origin master)


SSH Config
------------------

### Installation

1. Copy the file bastion_ssh_config to ~/.ssh/ (cp bastion_ssh_config ~/.ssh/config)
2. To replace --USERNAME-- with your bastion username, run this command after replacing 'myname' with your bastion username: (perl -pi -e s,--USERNAME--,myname,g ~/.ssh/config)
3. To replace --KEYNAME-- with your ssh key name, run this command after replacing 'id_rsa' with your ssh private key name: (perl -pi -e s,--KEYNAME--,id_rsa,g ~/.ssh/config)

### Upgrading

Unfortunately upgrading is not as simple as doing a git pull. After you have done a git pull you will need to follow the installation instructions again and overwrite your existing ~/.ssh/config file.
