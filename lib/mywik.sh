#!/usr/bin/env expect -f
#
# This expect script prompts for a wikid token password and pin, obtains the
# wikid passcode, and uses it to log in to the bastion host. It assumes the
# SSH key password is the same as the wikid token password. It saves having to
# enter the password twice, and having to copy and paste the wikid passcode.
#
# Set the WIKIDPATH environment variable to the jar path containing wikid.

# Always run from $HOME so wikid uses the correct token file.
cd 
cd .WiKID

# Read the wikid token password and pin. This script assumes the SSH key 
# password is the same as the wikid token password.
stty -echo
send_user "SSH Password: "
expect_user -re "(.*)\n"
send_user "\n"
set password $expect_out(1,string)
send_user "Acquia PIN: "
expect_user -re "(.*)\n"
send_user "\n"
set pin $expect_out(1,string)
stty echo

# Retrieve the wikid passcode.
spawn -noecho java -cp $::env(PWD)/../lib/wikidtoken-3.1.15.jar com.wikidsystems.jw.JWcl 050019123119
expect {
    "Enter passphrase: " { 
    send "$password\n"
    }
}
expect {
    "Enter passphrase: " { 
    send_user "Password incorrect.\n"
    exit
    }
    "Enter PIN for the acquia domain: " {
    send "$pin\n"
    }
}
expect {
    "Enter PIN for the acquia domain: " {
    send_user "PIN incorrect.\n"
    exit
    }
    -re "Passcode: (.*)\n" {
    set passcode $expect_out(1,string)
    }
}
close
wait

# SSH and login to the bastion server.
spawn -noecho ssh bastion
expect {
    "Password:" {
    send "$passcode\n"
    exp_continue
    }
    "SSH passphrase:" {
    send "$password\n"
    }
}

# Let the user interact directly with SSH.
interact

# Oddly, expect does not exit when it hits the end of the script.
exit	
