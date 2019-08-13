* https://github.com/centminmod/http2benchmark/tree/extended-tests

Below configuration will enable ECDSA SSL certificate support for both Litespeed and Nginx on CentOS 7 servers. Haven't tested on Ubuntu and only test h2load HTTP/2 tests for h2load-low related profile tools on a select few test targets from below list:

* `1kstatic.html` - 1kb static html file
* `1kgzip-static.html` - 1kb static html file that has been gzip pre-compressed (leverage nginx [gzip_static](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html#gzip_static) directive)
* `1knogzip.jpg` - 1kb jpg image
* `amdepyc2.jpg.webp` - 11kb webP image
* `amdepyc2.jpg` - 26kb jpg image
* `wordpress` - wordpress php/mariadb mysql test where apache uses w3 total cache plugin, litespeed uses litespeed cache plugin and nginx uses php-fpm fastgci_cache caching
* `coachblog` - [wordpress OceanWP Coach theme](https://github.com/centminmod/testpages) test blog static html version simulating wordpress cache plugins which do full page static html caching
* `coachbloggzip` - precompress gzip [wordpress OceanWP Coach theme](https://github.com/centminmod/testpages) test blog static html version simulating wordpress cache plugins which do full page static html caching i.e. [Cache Enabler wordpress plugin](https://wordpress.org/plugins/cache-enabler/) + [Autoptimize wordpress plugin](https://wordpress.org/plugins/autoptimize/) + [Autoptimize Gzip companion plugin](https://github.com/centminmod/autoptimize-gzip). Such combo allows Wordpress site to do full page static html caching with pre-compressed gzipped static assets for html, css and js which can leverage nginx [gzip_static](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html#gzip_static) directive.

# on both server and client

```
yum -y install git
firewall-cmd --permanent --zone=public --add-port=22/tcp
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=5001/tcp
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
firewall-cmd --zone=public --list-services
```

# on server

```
git clone -b extended-tests https://github.com/centminmod/http2benchmark.git
echo -e "SANS_SSLCERTS='y'\nSANSECC_SSLCERTS='y'" > /opt/server.ini
http2benchmark/setup/server/server.sh | tee server.log
```

`/opt/server.ini` will be populated with variables that override `http2benchmark/setup/server/server.sh`

```
SANS_SSLCERTS='y'
SANSECC_SSLCERTS='y'
```

# on client

```
git clone -b extended-tests https://github.com/centminmod/http2benchmark.git
echo -e 'SERVER_LIST="lsws nginx"\nTOOL_LIST="h2load-low h2load-low-ecc128 h2load-low-ecc256"\nTARGET_LIST="1kstatic.html 1kgzip-static.html amdepyc2.jpg.webp wordpress coachblog coachbloggzip"\nROUNDNUM=5' > /opt/benchmark.ini
http2benchmark/setup/client/client.sh | tee client.log
/opt/benchmark.sh | tee benchmark.log
```

`/opt/benchmark.ini` will be populated with variables that override `/opt/benchmark.sh`

```
SERVER_LIST="lsws nginx"
TOOL_LIST="h2load-low h2load-low-ecc128 h2load-low-ecc256"
TARGET_LIST="1kstatic.html 1kgzip-static.html amdepyc2.jpg.webp wordpress coachblog coachbloggzip"
ROUNDNUM=5
```