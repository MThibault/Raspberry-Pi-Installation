#!/usr/bin/env bash

#####################
#   Configure SSH   #
#####################

## Author   : Thibault MILLANT

## CHANGELOG :
## - 2021.03.11 - Script creation

#################
#   Variables   #
#################
SSH_PORT=10050
SSH_CONFIG_FILE="/etc/ssh/sshd_config"
## List the users allowed to connect through SSH
SSH_USERS="pi"


#################
#	Function	#
#################
function error {
	if [ `echo $?` -ne 0 ]; then
		echo "Error during $1.";
		exit;
		echo ""
	fi
}


#####################
#   Configuration   #
#####################
echo "##### SSH start #####"
## Define the protocol
## Create the entry before port line
sed -i "/^[#|.]Port .*/i Protocol 2" $SSH_CONFIG_FILE
error "SSH protocol"
## Change port number
sed -i "s/^[#|.]Port .*/Port $SSH_PORT/" $SSH_CONFIG_FILE
error "SSH change port"
## Avoid root remote login
sed -i "s/^[#|.]PermitRootLogin .*/PermitRootLogin no/" $SSH_CONFIG_FILE
error "SSH Root remote login"
## Define number of authentication attempts
sed -i "s/^[#|.]MaxAuthTries .*/MaxAuthTries 4/" $SSH_CONFIG_FILE
error "SSH MaxAuthTries"
## Define allowed users
## Define after MaxSessions
sed -i "/^[#|.]MaxSessions .*/a AllowUsers $SSH_USERS" $SSH_CONFIG_FILE
error "SSH AllowUsers"
## Avoid empty passwords
sed -i "s/^[#|.]PermitEmptyPasswords .*/PermitEmptyPasswords no/" $SSH_CONFIG_FILE
error "SSH Empty passwords"
## Change LoginGraceTime
sed -i "s/^[#|.]LoginGraceTime .*/LoginGraceTime 1m/" $SSH_CONFIG_FILE
error "SSH Login grace time"
## Change MaxStatups value
sed -i "s/^[#|.]MaxStartups .*/MaxStartups 10:30:60/" $SSH_CONFIG_FILE
error "SSH MaxStartups"
## Change Banner value
sed -i "s/^[#|.]Banner .*/Banner \/etc\/issue/" $SSH_CONFIG_FILE
error "SSH Banner"
echo "
WARNING:  Unauthorized access to this system is forbidden and will be
prosecuted by law. By accessing this system, you agree that your actions
may be monitored if unauthorized usage is suspected.
" > /etc/issue
## Change Syslog Facility
sed -i "s/^[#|.]SyslogFacility .*/SyslogFacility AUTH/" $SSH_CONFIG_FILE
error "SSH Syslog Facility"
## Change Log Level
sed -i "s/^[#|.]LogLevel .*/LogLevel INFO/" $SSH_CONFIG_FILE
error "SSH Log Level"
## Change X11Forwarding
sed -i "s/^[#|.]X11Forwarding .*/X11Forwarding no/" $SSH_CONFIG_FILE
error "SSH X11Forwarding"
## Change PrintLastLog
sed -i "s/^[#|.]PrintLastLog .*/PrintLastLog yes/" $SSH_CONFIG_FILE
error "SSH PrintLastLog"
## Change IgnoreRhosts
sed -i "s/^[#|.]IgnoreRhosts .*/IgnoreRhosts yes/" $SSH_CONFIG_FILE
error "SSH IgnoreRhosts"
## Change HostbasedAuthentication
sed -i "s/^[#|.]HostbasedAuthentication .*/HostbasedAuthentication no/" $SSH_CONFIG_FILE
error "SSH HostbasedAuthentication"
## Change UseDNS
sed -i "s/^[#|.]UseDNS .*/UseDNS no/" $SSH_CONFIG_FILE
error "SSH UseDNS"
	
	
## Restart SSH 
systemctl restart ssh.service
error "SSH restart"
echo "----- Open a new shell and connect to the server using SSH to validate that the new configuration did not block the access. DO NOT CLOSE THIS CONNECTION without retesting first. -----"
echo ""
