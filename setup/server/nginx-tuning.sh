#!/bin/bash
dt=$(date +"%d%m%y-%H%M%S")
default_vhost='/etc/nginx/conf.d/default.conf'
nginx_webroot='/var/www/html/wp_nginx'
nginxconf='/etc/nginx/nginx.conf'
phpfpmconf='/etc/php-fpm.d/www.conf'
wpclilink='https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar'

wpcli_install() {
  if [ ! -f /usr/bin/wp ]; then
    wget -q -4 --no-check-certificate $wpclilink -O /usr/bin/wp --tries=3
    chmod 0700 /usr/bin/wp
    /usr/bin/wp --info --allow-root
  fi
  wpaliascheck=$(grep 'allow-root' /root/.bashrc)
  if [[ -z "$wpaliascheck" ]]; then
    echo "alias wp='wp --allow-root'" >> /root/.bashrc
  fi
}

wptweaks() {
  wpcli_install
  echo
  cd $nginx_webroot
  echo "install Autoptimize"
  \wp plugin install autoptimize --activate --allow-root
  echo
  \wp plugin status autoptimize --allow-root
  echo
  wp option update autoptimize_cache_clean 0 --activate --allow-root 
  wp option update autoptimize_cache_nogzip on --activate --allow-root 
  wp option update autoptimize_cdn_url "" --activate --allow-root 
  wp option update autoptimize_css on --activate --allow-root 
  wp option update autoptimize_css_aggregate "" --activate --allow-root 
  wp option update autoptimize_css_datauris "" --activate --allow-root 
  wp option update autoptimize_css_defer "" --activate --allow-root 
  wp option update autoptimize_css_defer_inline "" --activate --allow-root 
  wp option update autoptimize_css_exclude 'wp-content/cache/, wp-content/uploads/, admin-bar.min.css, dashicons.min.css' --activate --allow-root 
  wp option update autoptimize_css_include_inline "" --activate --allow-root 
  wp option update autoptimize_css_inline "" --activate --allow-root 
  wp option update autoptimize_css_justhead "" --activate --allow-root 
  wp option update autoptimize_html "" --activate --allow-root 
  wp option update autoptimize_html_keepcomments "" --activate --allow-root 
  wp option update autoptimize_imgopt_launched on --activate --allow-root 
  wp option update autoptimize_js on --activate --allow-root 
  wp option update autoptimize_js_aggregate "" --activate --allow-root 
  wp option update autoptimize_js_exclude 'wp-includes/js/dist/, wp-includes/js/tinymce/, js/jquery/jquery.js' --activate --allow-root 
  wp option update autoptimize_js_forcehead "" --activate --allow-root 
  wp option update autoptimize_js_include_inline "" --activate --allow-root 
  wp option update autoptimize_js_justhead "" --activate --allow-root 
  wp option update autoptimize_js_trycatch "" --activate --allow-root 
  wp option update autoptimize_minify_excluded on --activate --allow-root 
  wp option update autoptimize_optimize_checkout "" --activate --allow-root 
  wp option update autoptimize_optimize_logged on --activate --allow-root 
  wp option update autoptimize_show_adv 1 --activate --allow-root 
  wp option list --search=autoptimize* --activate --allow-root
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