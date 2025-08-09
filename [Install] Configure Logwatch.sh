#!/usr/bin/env bash
# Load config file
source config.ini

#####################################
#   Install and Configure Logwatch  #
#####################################

## Author   : Thibault MILLANT

## CHANGELOG :
## - 2021.03.11 - Script creation

#################
#   Variables   #
#################
## Define an email address or an alias
EMAIL_RCPT="email_alerts" # Loaded from config file but cqn be overwritten
#EMAIL_SENDER="" # Loaded from config file but cqn be overwritten
LOG_PATH="/etc/logwatch/conf/logwatch.conf"

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
#   Installation    #
#####################
apt install -y logwatch

#####################
#   Configuration   #
#####################
echo "##### Logwatch start #####"
cp /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/

## Change the output
sed -i "s/^Output .*/Output = mail/" $LOG_PATH
error "Change Output"
## Change the recipient email address
sed -i "s/^MailTo .*/MailTo = $EMAIL_RCPT/" $LOG_PATH
error "Change RCPT"
## Change sender email address
sed -i "s/^MailFrom .*/MailFrom = $EMAIL_SENDER/" $LOG_PATH
error "Change sender"
## Change level of information
sed -i "s/^Detail .*/Detail = High/" $LOG_PATH
error "Change Information level"

## Add Nginx file
touch /etc/logwatch/conf/logfiles/nginx.conf
echo "########################################################
# Define log file group for nginx
########################################################

# What actual file? Defaults to LogPath if not absolute path….
LogFile = nginx/*access.log
LogFile = nginx/*access.log.1
LogFile = nginx/*error.log
LogFile = nginx/*error.log.1

# If the archives are searched, here is one or more line
# (optionally containing wildcards) that tell where they are…
#If you use a “-” in naming add that as well -mgt
Archive = nginx/*access.log*
Archive = nginx/*error.log*

# Expand the repeats (actually just removes them now)
*ExpandRepeats

# Keep only the lines in the proper date range…
*ApplyhttpDate

# vi: shiftwidth=3 tabstop=3" > /etc/logwatch/conf/logfiles/nginx.conf

cp /usr/share/logwatch/default.conf/services/http.conf /etc/logwatch/conf/services/nginx.conf
sed -i "s/^Title .*/Title = \"nginx\"/" /etc/logwatch/conf/services/nginx.conf
error "Change Title"
sed -i "s/^LogFile .*/LogFile = nginx/" /etc/logwatch/conf/services/nginx.conf
error "Change LogFile"

cp /usr/share/logwatch/scripts/services/http /etc/logwatch/scripts/services/nginx
mkdir /var/cache/logwatch
logwatch restart
