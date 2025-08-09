#!/usr/bin/env bash
# Load config file
source config.ini

#############################
#   Configure Root bashrc   #
#############################

## Author   : Thibault MILLANT

## CHANGELOG :
## - 2021.03.10 - Script creation

#################
#   Variables   #
#################
USER="root"
BASH_PATH="/root/.bashrc"
#EMAIL_RCPT="" ## Loaded from config file but can be overwritten
HOSTNAME="`hostname`"


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


#############################
#   Package installation    #
#############################
apt install -y screenfetch
error "Package installation"

#####################
#   Configuration   #
#####################
## Define custom aliases
echo "" >> $BASH_PATH
echo "## Custom aliases" >> $BASH_PATH
echo "alias ll='ls -l'" >> $BASH_PATH
echo "alias la='ls -a'" >> $BASH_PATH
echo "alias lla='ls -l -a'" >> $BASH_PATH
echo "" >> $BASH_PATH
echo "alias vi='vim'" >> $BASH_PATH
echo "" >> $BASH_PATH
echo "alias aptfull='apt update && apt upgrade && apt dist-upgrade'" >> $BASH_PATH
echo "alias aptfullauto='apt update && apt upgrade -y && apt dist-upgrade -y'" >> $BASH_PATH
echo "" >> $BASH_PATH

## Screenfetch
echo "## Screenfetch" >> $BASH_PATH
echo "screenfetch" >> $BASH_PATH

## Email notification
echo "" >> $BASH_PATH
echo 'echo -e "Acces Shell '$USER' le `date` `who` \n\nid\n`id` \n\nw\n`w` \n\nlast\n`last`" | mail -r '$EMAIL_RCPT' -s "['$HOSTNAME'] Connexion serveur to '$USER'" email_alerts' >> $BASH_PATH

echo "Don't forget to install Postfix and configure the alias email_alerts to get the notification email"
