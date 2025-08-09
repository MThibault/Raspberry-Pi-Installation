#!/usr/bin/env bash
# Load config file
source config.ini

#############################
#   Configure User bashrc   #
#############################

## Author   : Thibault MILLANT

## CHANGELOG :
## - 2021.03.10 - Script creation

#################
#   Variables   #
#################
USER=pi
BASH_PATH="/home/$USER/.bashrc"
#EMAIL_RCPT="" ## Loaded from config file but cqn be overwritten
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

## Screenfetch
echo "## Screenfetch" >> $BASH_PATH
echo "screenfetch" >> $BASH_PATH

## Email notification
echo "" >> $BASH_PATH
echo 'echo -e "Acces Shell '$USER' le `date` `who` \n\nid\n`id` \n\nw\n`w` \n\nlast\n`last`" | mail -r '$EMAIL_RCPT' -s "['$HOSTNAME'] Connexion serveur to '$USER'" email_alerts' >> $BASH_PATH

echo "Don't forget to install Postfix and configure the alias email_alerts to get the notification email"
