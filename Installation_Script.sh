#!/usr/bin/env bash

#################################################
#	Script Installation Raspberry Pi	#
#################################################

## Author	: Thibault MILLANT

## CHANGELOG :
## - 2018.09.17 : Script Creation, NOT TESTED YET


#################################
#	Configuration		#
#################################
## Set to 1 the set you want to execute
UPGRADE=0
CHPASSWD=0
SSH=0
SUDO=0
NEXTCLOUD=0


#########################
#	Variables	#
#########################
## SSH
SSH_PORT=10050
SSH_CONFIG_FILE="/etc/ssh/sshd_config"

## PHP
PHP_FPM_INI_FILE="/etc/php/7.0/fpm/php.ini"
PHP_FPM_POOL_FILE="/etc/php/7.0/fpm/pool.d/www.conf"

## Nextcloud
NEXTCLOUD_CONFIG_FILE="/srv/http/nextcloud/config/config.php"


#########################
#	Function	#
#########################
function error {
	if [ `echo $?` -ne 0 ]; then
		echo "Error during $1.";
		exit;
		echo ""
	fi
}


#########################################
#	Ugrade and basic tools		#
#########################################
if [ $UPGRADE -eq 1 ]; then
	echo "##### Upgrade start #####"
	## Upgrade the Raspberry Pi
	apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && apt-get autoremove --purge -y
	error "Upgrade"

	## Install additional software
	apt-get install -y vim
	error "Install vim htop"
	echo "##### Upgrade end #####"
	echo ""
fi


#################################
#	Change Password		#
#################################
if [ $CHPASSWD -eq 1 ]; then
	echo "##### Password start #####"
	## Change pi password
	echo "Change pi password"
	passwd pi
	## Change root password
	echo "Change root password"
	passwd root
	echo "##### Password end #####"
	echo ""
fi


#################################
#	Configure SSH		#
#################################
if [ $SSH -eq 1 ]; then
	echo "##### SSH start #####"
	## Change port number
	sed -i "s/^[#|.]Port .*/Port $SSH_PORT/" $SSH_CONFIG_FILE
	error "SSH change port"
	## Avoid root remote login
	sed -i "s/^[#|.]PermitRootLogin .*/PermitRootLogin no/" $SSH_CONFIG_FILE
	error "SSH Root remote login"
	## Avoid empty passwords
	sed -i "s/^[#|.]PermitEmptyPasswords .*/PermitEmptyPasswords no/" $SSH_CONFIG_FILE
	error "SSH Empty passwords"
	## Change LoginGraceTime
	sed -i "s/^[#|.]LoginGraceTime .*/LoginGraceTime 2m/" $SSH_CONFIG_FILE
	error "SSH Login grace time"
	## Change MaxStatups value
	sed -i "s/^[#|.]MaxStartups .*/MaxStartups 10:30:100/" $SSH_CONFIG_FILE
	error "SSH MaxStartups"
	## Change Banner value
	sed -i "s/^[#|.]Banner .*/Banner none/" $SSH_CONFIG_FILE
	error "SSH Banner"
	## Change Syslog Facility
	sed -i "s/^[#|.]SyslogFacility .*/SyslogFacility AUTH/" $SSH_CONFIG_FILE
	error "SSH Syslog Facility"
	## Change Log Level
	sed -i "s/^[#|.]LogLevel .*/LogLevel INFO/" $SSH_CONFIG_FILE
	error "SSH Log Level"
	
	## AllowUsers A FAIRE
	
	## Restart SSH 
	systemctl restart ssh.service
	error "SSH restart"
	echo "----- Open a new shell and connect to the server using SSH to validate that the new configuration did not block the access. DO NOT CLOSE THIS CONNECTION without retesting first. -----"
	echo ""
fi


#################################
#	Remove Sudo		#
#################################
if [ $SUDO -eq 1 ]; then
	echo "##### Remove program start #####"
	## Remove sudo program
	apt-get autoremove --purge -y sudo
	error "Remove program"
	echo "##### Remove program end #####"
	echo ""
fi


#################################
#	Install Nextcloud	#
#################################
if [ $NEXTCLOUD -eq 1 ]; then
	## Version 14.0.0
	echo "##### Nextcloud start #####"
	## Install packets needed
	apt-get install -y nginx-light php7.0-fpm php7.0-zip php7.0-curl php7.0-gd php7.0-xml php7.0-mbstring php7.0-json php7.0-mysql php7.0-bz2 php7.0-intl php7.0-mcrypt php-imagick php-apcu mariadb-server
	error "Install Nextcloud package required"
	rm /etc/nginx/sites-enabled/default
	
	## Get Nextcloud package
	mkdir -p /srv/http
	cd /srv/http
	wget "https://download.nextcloud.com/server/releases/nextcloud-14.0.0.zip"
	error "Get Nextcloud package"
	unzip "nextcloud-14.0.0.zip"
	chown -R www-data:www-data nextcloud
	rm "nextcloud-14.0.0.zip"
	
	touch /etc/nginx/sites-available/nextcloud.conf
	## Download nginx config file for nextcloud
	cp nextcloud.conf /etc/nginx/sites-available/
	ln -s /etc/nginx/sites-available/nextcloud.conf /etc/nginx/sites-enabled/
	
	## Create and install self-sign certificate for Nextcloud
	mkdir -p /etc/ssl/certs/nginx/
	cd /etc/ssl/certs/nginx/
	
	echo "----- You will have to choose and type a passphrase during the process. -----"
	openssl genrsa -des3 -out nextcloud.key 4096
	openssl req -new -key nextcloud.key -out nextcloud.csr
	cp nextcloud.key nextcloud.key.org
	openssl rsa -in nextcloud.key.org  -out nextcloud.key
	openssl x509 -req -days 3650 -in nextcloud.csr -signkey nextcloud.key -out nextcloud.crt
	rm nextcloud.csr nextcloud.key.org
	
	## PHP FPM configuration
	sed -i "s/memory_limit = .*/memory_limit = 512M:" $PHP_FPM_INI_FILE
	sed -i "s/upload_max_filesize = .*/upload_max_filesize = 250M/" $PHP_FPM_INI_FILE
	sed -i "s/post_max_size = .*/post_max_size = 250M/" $PHP_FPM_INI_FILE
	sed -i "s/max_execution_time = .*/max_execution_time = 360/" $PHP_FPM_INI_FILE
	sed -i "s/max_input_time = .*/max_input_time = 360/" $PHP_FPM_INI_FILE

	## PHP getenv support
	## https://docs.nextcloud.com/server/14/admin_manual/installation/source_installation.html#php-fpm-tips-label
	sed -i "s/;env\[HOSTNAME\] = \$HOSTNAME/env\[HOSTNAME\] = \$HOSTNAME/" $PHP_FPM_POOL_FILE
	sed -i "s/;env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin/env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin/" $PHP_FPM_POOL_FILE
	sed -i "s/;env\[TMP\] = \/tmp/env\[TMP\] = \/tmp/" $PHP_FPM_POOL_FILE
	sed -i "s/;env\[TMPDIR\] = \/tmp/env\[TMPDIR\] = \/tmp/" $PHP_FPM_POOL_FILE
	sed -i "s/;env\[TEMP\] = \/tmp/env\[TEMP\] = \/tmp/" $PHP_FPM_POOL_FILE
	sed -i "s/;clear_env = no/clear_env = no/" $PHP_FPM_POOL_FILE

	## PHP Memory Caching to increase performance
	## https://docs.nextcloud.com/server/14/admin_manual/configuration_server/caching_configuration.html
	sed -i "s/^);/  'memcache.local' => '\\\OC\\\Memcache\\\APCu',/" $NEXTCLOUD_CONFIG_FILE
	echo ');' >> $NEXTCLOUD_CONFIG_FILE

	## https://docs.nextcloud.com/server/14/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
	sed -i "s/;opcache.enable=./opcache.enable=1/" $PHP_FPM_INI_FILE
	sed -i "s/;opcache.enable_cli=./opcache.enable_cli=1/" $PHP_FPM_INI_FILE
	sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/" $PHP_FPM_INI_FILE
	sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/" $PHP_FPM_INI_FILE
	sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=128/" $PHP_FPM_INI_FILE
	sed -i "s/;opcache.save_comments=./opcache.save_comments=1/" $PHP_FPM_INI_FILE
	sed -i "s/;opcache.revalidate_freq=./opcache.revalidate_freq=1/" $PHP_FPM_INI_FILE

	## MySQL/MariaDB configuration
	echo "----- You need to configure your database by answering some questions. -----"
	mysql_secure_installation
	echo "----- You need to enter these elements to configure your database for Nextcloud. -----"
	echo "- create database nextcloud;"
	echo "- create user nextcloud@localhost identified by 'choose-a-password';"
	echo "- grant all privileges on nextcloud.* to nextcloud@localhost identified by 'password-chosen';"
	echo "- flush privileges;"
	echo "- exit;"
	mysql -u root -p
	
	systemctl restart nginx.service php7.0-fpm.service mariadb.service
	echo "##### Nextcloud end #####"
	echo ""
fi
