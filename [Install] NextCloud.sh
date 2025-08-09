#!/usr/bin/env bash
# Load config file
source config.ini

#########################
#   Install NextCloud   #
#########################

## Author   : Thibault MILLANT

## CHANGELOG :
## - 2021.03.11 - Script creation

#################
#   Variables   #
#################
#PHP_VERSION="7.3" # Loaded from config file but can be overwritten
FPM_INI="/etc/php/$PHP_VERSION/fpm/php.ini"
FPM_POOL="/etc/php/$PHP_VERSION/fpm/pool.d/www.conf"

#NEXTCLOUD_VERSION="nextcloud-21.0.0.zip" # Loaded from config file but can be overwritten

#DOMAIN="" # Loaded from config file but can be overwritten

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
apt install -y nginx-light php$PHP_VERSION-fpm php$PHP_VERSION-curl php$PHP_VERSION-gd php$PHP_VERSION-json php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip php$PHP_VERSION-mysql php$PHP_VERSION-bz2 php$PHP_VERSION-intl php-apcu php-imagick ffmpeg mariadb-server php$PHP_VERSION-bcmath php$PHP_VERSION-gmp imagemagick
error "APT"

## NextCloud
mkdir -p /srv/http
cd /srv/http
wget "https://download.nextcloud.com/server/releases/$NEXTCLOUD_VERSION"
error "Get NextCloud package"
unzip $NEXTCLOUD_VERSION
error "Extract Nextcloud"
rm $NEXTCLOUD_VERSION
error "Delete archive"
chown -R www-data:www-data nextcloud
error "Chown"

## PHP-FPM Configuration
#sed -i "s/memory_limit = .*/memory_limit = 512M/" $FPM_INI
#sed -i "s/max_execution_time = .*/max_execution_time = 360/" $FPM_INI
#sed -i "s/max_input_time = .*/max_input_time = 360/" $FPM_INI

## https://docs.nextcloud.com/server/21/admin_manual/installation/source_installation.html#php-ini-configuration-notes
sed -i "s/^;date.timezone =.*/date.timezone = \"Europe\/Paris\"/" $FPM_INI
error "timezone"

## https://docs.nextcloud.com/server/21/admin_manual/installation/source_installation.html#php-fpm-configuration-notes
sed -i "s/;clear_env = no/clear_env = no/" $FPM_POOL
sed -i "s/;env\[HOSTNAME\] = \$HOSTNAME/env\[HOSTNAME\] = \$HOSTNAME/" $FPM_POOL
sed -i "s/;env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin/env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin/"  $FPM_POOL
sed -i "s/;env\[TMP\] = \/tmp/env\[TMP\] = \/tmp/" $FPM_POOL
sed -i "s/;env\[TMPDIR\] = \/tmp/env\[TMPDIR\] = \/tmp/" $FPM_POOL
sed -i "s/;env\[TEMP\] = \/tmp/env\[TEMP\] = \/tmp/" $FPM_POOL

sed -i "s/upload_max_filesize = .*/upload_max_filesize = 500M/" $FPM_INI
sed -i "s/post_max_size = .*/post_max_size = 500M/" $FPM_INI

## https://docs.nextcloud.com/server/21/admin_manual/installation/server_tuning.html#enable-php-opcache
sed -i "s/;opcache.enable=./opcache.enable=1/" $FPM_INI
sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/" $FPM_INI
sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/" $FPM_INI
sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=128/" $FPM_INI
sed -i "s/;opcache.save_comments=./opcache.save_comments=1/" $FPM_INI
sed -i "s/;opcache.revalidate_freq=./opcache.revalidate_freq=1/" $FPM_INI
sed -i "s/;opcache.enable_cli=./opcache.enable_cli=1/" $FPM_INI

sed -i '/^extension=pdo_mysql.so/a \
\
[mysql]\
mysql.allow_local_infile=On\
mysql.allow_persistent=On\
mysql.cache_size=2000\
mysql.max_persistent=-1\
mysql.max_links=-1\
mysql.default_port=\
mysql.default_socket=/var/run/mysqld/mysqld.sock\
mysql.default_host=\
mysql.default_user=\
mysql.default_password=\
mysql.connect_timeout=60\
mysql.trace_mode=Off\
' /etc/php/$PHP_VERSION/fpm/conf.d/20-pdo_mysql.ini
error "PDO MySQL"

## MariaDB
## MySQL/MariaDB configuration
sed -i '/^\[client-server\]/i [server]\
skip_name_resolve = 1\
innodb_buffer_pool_size = 128M\
innodb_buffer_pool_instances = 1\
innodb_flush_log_at_trx_commit = 2\
innodb_log_buffer_size = 32M\
innodb_max_dirty_pages_pct = 90\
query_cache_type = 1\
query_cache_limit = 2M\
query_cache_min_res_unit = 2k\
query_cache_size = 64M\
tmp_table_size= 64M\
max_heap_table_size= 64M\
slow_query_log = 1\
slow_query_log_file = /var/log/mysql/slow.log\
long_query_time = 1\
' /etc/mysql/my.cnf
error "My.cnf 1"

sed -i '/^\!includedir \/etc\/mysql\/mariadb.conf.d/a \
[client]\
default-character-set = utf8mb4\
\
[mysqld]\
character_set_server = utf8mb4\
collation_server = utf8mb4_general_ci\
transaction_isolation = READ-COMMITTED\
binlog_format = ROW\
innodb_large_prefix=on\
innodb_file_format=barracuda\
innodb_file_per_table=1\
' /etc/mysql/my.cnf
error "My.cnf 2"

echo "----- You need to configure your database by answering some questions. -----"
mysql_secure_installation
echo "----- You need to enter these elements to configure your database for Nextcloud. -----"
echo "- CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'choose-a-password';"
echo "- CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
echo "- GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';"
echo "- flush privileges;"
echo "- quit;"
mysql -u root -p

## Let's Encrypt
apt install -y certbot python3-certbot-nginx

certbot certonly --nginx -d $DOMAIN -d mycloud.$DOMAIN


## Nginx configuration
rm /etc/nginx/sites-enabled/default
openssl dhparam 4096 -out /etc/ssl/dhparam4096.pem
touch /etc/nginx/sites-available/nextcloud.conf
ln -s /etc/nginx/sites-available/nextcloud.conf /etc/nginx/sites-enabled/
echo "upstream php-handler {
    #server 127.0.0.1:9000;
    server unix:/var/run/php/php7.3-fpm.sock;
}

#server {
#    listen 80;
#    listen [::]:80;
#    server_name mycloud.$DOMAIN;

    # Enforce HTTPS
#    return 301 https://\$server_name\$request_uri;
#}

server {
    listen 443      ssl http2;
    listen [::]:443 ssl http2;
    server_name mycloud.$DOMAIN;

    ## Logs
    access_log /var/log/nginx/nextcloud-access.log combined;
    error_log /var/log/nginx/nextcloud-error.log error;

    ## SSL Config
    ## Specifies that server ciphers should be prefered over client ciphers
    ssl_prefer_server_ciphers on;
    ## Do not authorize Weak protocols
    ssl_protocols TLSv1.2 TLSv1.3;
    ## Specifies the enabled ciphers
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256';

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/$DOMAIN/chain.pem;
    resolver 8.8.8.8 8.8.4.4;

    ssl_dhparam /etc/ssl/dhparam4096.pem;

    ## Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # HSTS settings
    # WARNING: Only add the preload option once you read about
    # the consequences in https://hstspreload.org/. This option
    # will add the domain to a hardcoded list that is shipped
    # in all major browsers and getting removed from this list
    # could take several months.
    #add_header Strict-Transport-Security \"max-age=15768000; includeSubDomains; preload;\" always;
    add_header Strict-Transport-Security \"max-age=15768000; includeSubDomains;\" always;

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Pagespeed is not supported by Nextcloud, so if your server is built
    # with the \`ngx_pagespeed\` module, uncomment this line to disable it.
    #pagespeed off;

    # HTTP response headers borrowed from Nextcloud \`.htaccess\`
    add_header X-Frame-Options                      \"SAMEORIGIN\"              always;
    add_header X-XSS-Protection                     \"1; mode=block\"           always;
    add_header X-Content-Type-Options               \"nosniff\"                 always;
    add_header Referrer-Policy                      \"no-referrer\"             always;
    add_header X-Download-Options                   \"noopen\"                  always;
    add_header X-Permitted-Cross-Domain-Policies    \"none\"                    always;
    add_header X-Robots-Tag                         \"none\"                    always;
    add_header Expect-CT                            \"enforce; max-age=86400\"  always;
    add_header Permissions-Policy \"geolocation=(self);midi=();notifications=(self);push=();sync-xhr=();microphone=(self);camera=(self);magnetometer=();gyroscope=();speaker=(self);vibrate=();fullscreen=(self);payment=();\" always;
    ## CSP Policy is already included in the source code of Nextcloud

    # Remove X-Powered-By, which is an information leak
    fastcgi_hide_header X-Powered-By;

    # Path to the root of your installation
    root /srv/http/nextcloud;

    # Specify how to handle directories -- specifying \`/index.php\$request_uri\`
    # here as the fallback means that Nginx always exhibits the desired behaviour
    # when a client requests a path that corresponds to a directory that exists
    # on the server. In particular, if that directory contains an index.php file,
    # that file is correctly served; if it doesn't, then the request is passed to
    # the front-end controller. This consistent behaviour means that we don't need
    # to specify custom rules for certain paths (e.g. images and other assets,
    # \`/updater\`, \`/ocm-provider\`, \`/ocs-provider\`), and thus
    # \`try_files \$uri \$uri/ /index.php\$request_uri\`
    # always provides the desired behaviour.
    index index.php index.html /index.php\$request_uri;

    # Rule borrowed from \`.htaccess\` to handle Microsoft DAV clients
    location = / {
        if ( \$http_user_agent ~ ^DavClnt ) {
            return 302 /remote.php/webdav/\$is_args\$args;
        }
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Make a regex exception for \`/.well-known\` so that clients can still
    # access it despite the existence of the regex rule
    # \`location ~ /(\.|autotest|...)\` which would otherwise handle requests
    # for \`/.well-known\`.
    location ^~ /.well-known {
        # The following 6 rules are borrowed from \`.htaccess\`

        location = /.well-known/carddav     { return 301 /remote.php/dav/; }
        location = /.well-known/caldav      { return 301 /remote.php/dav/; }
        # Anything else is dynamically handled by Nextcloud
        location ^~ /.well-known            { return 301 /index.php\$uri; }

        try_files \$uri \$uri/ =404;
    }

    # Rules borrowed from \`.htaccess\` to hide certain paths from clients
    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)              { return 404; }

    # Ensure this block, which passes PHP files to the PHP process, is above the blocks
    # which handle static assets (as seen below). If this block is not declared first,
    # then Nginx will encounter an infinite rewriting loop when it prepends \`/index.php\`
    # to the URI, resulting in a HTTP 500 error response.
    location ~ \.php(?:$|/) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        set \$path_info \$fastcgi_path_info;

        try_files \$fastcgi_script_name =404;

        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$path_info;
        fastcgi_param HTTPS on;

        fastcgi_param modHeadersAvailable true;         # Avoid sending the security headers twice
        fastcgi_param front_controller_active true;     # Enable pretty urls
        fastcgi_pass php-handler;

        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ \.(?:css|js|svg|gif)$ {
        try_files \$uri /index.php\$request_uri;
        expires 6M;         # Cache-Control policy borrowed from \`.htaccess\`
        access_log off;     # Optional: Don't log access to assets
    }

    location ~ \.woff2?$ {
        try_files \$uri /index.php\$request_uri;
        expires 7d;         # Cache-Control policy borrowed from \`.htaccess\`
        access_log off;     # Optional: Don't log access to assets
    }

    location / {
        try_files \$uri \$uri/ /index.php\$request_uri;
    }
}
" > /etc/nginx/sites-available/nextcloud.conf

systemctl restart nginx.service php$PHP_VERSION-fpm.service mariadb.service
