#!/usr/bin/env expect
#
# This expect script prompts for a wikid token password and pin, obtains the
# wikid passcode, and uses it to log in to the bastion host. It assumes the
# SSH key password is the same as the wikid token password. It saves having to
# enter the password twice, and having to copy and paste the wikid passcode.
#
# Set the WIKIDPATH environment variable to the jar path containing wikid.

# Read the wikid token password and pin. This script assumes the SSH key
# password is the same as the wikid token password.
set bastion_host bastion
switch [llength $argv] {
        1       { set bastion_host [lindex $argv 0] }
}

stty -echo
send_user "This script assumes your Bastion SSH Password and WiKID Password are set the same. If they are not you need to change your ~/.ah_profile to use mywik2 instead of mywik.\n\n"
send_user "Bastion SSH Password: "
set timeout -1
expect_user -re "(.*)\n"
send_user "\n"
set password $expect_out(1,string)
send_user "WiKID PIN: "
expect_user -re "(.*)\n"
send_user "\n"
set pin $expect_out(1,string)
set timeout 60
stty echo

# Retrieve the wikid passcode.
spawn -noecho wikid
log_user 0
expect {
    "Enter passphrase: " {
        send "$password\n"
    }
}
expect {
    "Enter passphrase: " {
        send_user "WiKID passphrase incorrect.\n"
        stty -echo
        send_user "It appears your SSH password and WiKID passphrase are different; consider using mywik2.sh instead.\n"
        stty -echo
        send_user "WiKID passphrase: "
        set timeout -1
        expect_user -re "(.*)\n"
        send_user "\n"
        set password $expect_out(1,string)
        set timeout 10
        stty echo
        send "$password\n"
        exp_continue
    }
    "Enter PIN for the acquia domain: " {
        send "$pin\n"
        exp_continue
    }
    "Passcode: Failed" {
        close
        send_user "Acquia PIN Incorrect.\n"
        exit
    }
    "proxy hostname : DIRECT" {
        exp_continue
    }
    "No Proxy" {
        exp_continue
    }
    -re "Passcode: (.*)\n" {
        set passcode $expect_out(1,string)
    }
}
close
wait

# SSH and login to the bastion server.
# Check for AH_SSH_CONFIG
if {[info exists env(AH_SSH_CONFIG)]} {
    spawn -noecho ssh -f -N -F $env(AH_SSH_CONFIG) $bastion_host
} else {
    spawn -noecho ssh -f -N $bastion_host
}
expect {
    "Password:" {
        send "$passcode\n"
        exp_continue
    }
    "SSH passphrase:" {
        send "$password\n"
        log_user 1
    }
    -re "Permission denied.*" {
        send_user "$expect_out(buffer)\n"
        exit
    }
}
expect {
    "Password:" {
        send_user "Authentication failed.\n"
        exit
    }
    "Welcome" {
        # Let the user interact directly with SSH.
        interact
    }
}

# Oddly, expect does not exit when it hits the end of the script.
exit
