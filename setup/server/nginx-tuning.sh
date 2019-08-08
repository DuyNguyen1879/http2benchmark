#!/bin/bash
dt=$(date +"%d%m%y-%H%M%S")
default_vhost='/etc/nginx/conf.d/default.conf'
nginx_webroot='/var/www/html/wp_nginx'
nginxconf='/etc/nginx/nginx.conf'
phpfpmconf='/etc/php-fpm.d/www.conf'

wptweaks() {
  echo
  cd $nginx_webroot
  echo "install Autoptimize"
  \wp plugin install autoptimize --activate --allow-root
  \wp plugin status autoptimize --allow-root
  echo
  # https://github.com/centminmod/autoptimize-gzip
  echo "install Autoptimize Gzip Companion plugin"
  mkdir -p "wp-content/plugins/autoptimize-gzip"
  wget -4 -cnv -O "wp-content/plugins/autoptimize-gzip/autoptimize-gzip.php" https://github.com/centminmod/autoptimize-gzip/raw/master/autoptimize-gzip.php
  wget -4 -cnv -O "wp-content/plugins/autoptimize-gzip/index.html" https://github.com/centminmod/autoptimize-gzip/raw/master/index.html
  wget -4 -cnv -O "wp-content/plugins/autoptimize-gzip/readme.md" https://github.com/centminmod/autoptimize-gzip/blob/master/readme.md
  wget -4 -cnv -O "wp-content/plugins/autoptimize-gzip/LICENSE" https://github.com/centminmod/autoptimize-gzip/raw/master/LICENSE
  chown -R apache:apache wp-content/plugins
  \wp plugin activate autoptimize-gzip --allow-root
  \wp plugin status autoptimize-gzip --allow-root
  echo
}

nginxtweaks() {
  echo
  echo "backup $nginxconf"
  cp -a "$nginxconf" "${nginxconf}.backup.${dt}"
  echo
  echo "tune $nginxconf"
  if [[ ! "$(grep 'worker_connections  160000' $nginxconf)" ]]; then
    sed -i 's|worker_connections  1024;|worker_connections  160000;|' "$nginxconf"
  fi
  if [[ ! "$(grep 'pcre_jit on;' $nginxconf)" ]]; then
    sed -i 's|worker_processes  1;|worker_processes  1;\npcre_jit on;|' "$nginxconf"
  fi
  if [[ ! "$(grep 'worker_processes  auto' $nginxconf)" ]]; then
    sed -i 's|worker_processes  1;|worker_processes  auto;|' "$nginxconf"
  fi
  if [[ ! "$(grep 'gzip_static on' $nginxconf)" ]]; then
    sed -i 's|gzip  on;|gzip  on;\n    gzip_static on;|' "$nginxconf"
  fi
  if [[ ! "$(grep 'keepalive_requests 160000;' $nginxconf)" ]]; then
    sed -i 's|keepalive_timeout  15;|keepalive_timeout  15;\n    keepalive_requests 160000;|' "$nginxconf"
  fi
  if [[ ! "$(grep 'multi_accept        off;' $nginxconf)" ]]; then
    sed -i 's|multi_accept        on;|multi_accept        off;|' "$nginxconf"
  fi
  if [[ ! "$(grep 'worker_rlimit_nofile 520000;' $nginxconf)" ]]; then
    sed -i 's|user apache;|user apache;\nworker_rlimit_nofile 520000;|' "$nginxconf"
  fi
  if [ ! -f /var/www/html/1kgzip-static.html.gz ]; then
    gzip -9 -c /var/www/html/1kgzip-static.html > /var/www/html/1kgzip-static.html.gz
  fi
  if [ ! -f /var/www/html/10kgzip-static.html.gz ]; then
    gzip -9 -c /var/www/html/10kgzip-static.html > /var/www/html/10kgzip-static.html.gz
  fi
  if [ ! -f /var/www/html/100kgzip-static.html.gz ]; then
    gzip -9 -c /var/www/html/100kgzip-static.html > /var/www/html/100kgzip-static.html.gz
  fi
  chown -R apache:apache /var/www/html/*static.html.gz
  echo
  nginx -t
  echo
  service nginx restart
  echo
  sdiff -s "${nginxconf}.backup.${dt}" "$nginxconf"
  echo
}

phptweaks() {
  echo
  echo "backup $phpfpmconf"
  cp -a "$phpfpmconf" "${phpfpmconf}.backup.${dt}"
  echo
  echo "tune $phpfpmconf"
  sed -i 's|;pm.status_path = /status|pm.status_path = /status|' "$phpfpmconf"
  sed -i 's|;ping.path = /ping|ping.path = /ping|' "$phpfpmconf"
  sed -i 's|;ping.response = pong|ping.response = pong|' "$phpfpmconf"
  echo
}

case "$1" in
  wp )
    wptweaks
    ;;
  nginx )
    nginxtweaks
    ;;
  php )
    phptweaks
    ;;
  all )
    wptweaks
    nginxtweaks
    phptweaks
    ;;
  * )
    echo
    echo "$0 {wp|nginx|php|all}"
    ;;
esac