* https://github.com/centminmod/http2benchmark/tree/extended-tests

The below tests were done with Litespeed 5.4.0 and Nginx 1.16.0 on CentOS 7.6 64bit KVM VPS using $20/month Upcloud VPS servers.

The original http2benchmark tests only tested standard RSA 2048bit SSL certificates and not the better performing ECC 256bit SSL certificates with ECDSA SSL ciphers. The forked http2benchmarks have optional support for testing ECC 256bit SSL certificates with ECDSA SSL ciphers. Part of the performance comes from smaller SSL certificate and SSL key sizes compared to RSA 2048bit SSL certificate setups. Was expecting Litespeed to have more of an advantage given that it is built with it's own crypto library using Google's BoringSSL which is a forked version of OpenSSL. BoringSSL is known to have better ECDSA performance than OpenSSL. Nginx binaries from nginx.org YUM repo are built against OpenSSL 1.0.2 usually. However, below results were mixed with Nginx beating out Litespeed in some of the below test targets. Especially for `coachblogzip` wordpress simulation tests. Seems Litespeed is more optimised for ECDSA 256bit instead of 128bit.

Below configuration will enable ECDSA SSL certificate support for both Litespeed and Nginx on CentOS 7 servers. Haven't tested on Ubuntu and only test h2load HTTP/2 tests for h2load related profile tools on a select few test targets from below list:

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
echo -e 'SERVER_LIST="lsws nginx"\nTOOL_LIST="h2load h2load-ecc128 h2load-ecc256"\nTARGET_LIST="1kstatic.html 1kgzip-static.html amdepyc2.jpg.webp wordpress coachblog coachbloggzip"\nROUNDNUM=5' > /opt/benchmark.ini
http2benchmark/setup/client/client.sh | tee client.log
/opt/benchmark.sh | tee benchmark.log
```

`/opt/benchmark.ini` will be populated with variables that override `/opt/benchmark.sh`

```
SERVER_LIST="lsws nginx"
TOOL_LIST="h2load h2load-ecc128 h2load-ecc256"
TARGET_LIST="1kstatic.html 1kgzip-static.html amdepyc2.jpg.webp wordpress coachblog coachbloggzip"
ROUNDNUM=5
```

Example results from Upcloud 2 cpu $20/month KVM VPS server + client spun up servers.

```
***Total of 1518 seconds to finish process***
[OK] to archive /opt/Benchmark/081319-125155.tgz
/opt/Benchmark/081319-125155/RESULTS.txt
#############  Benchmark Result  #################

h2load - 1kstatic.html
lsws 5.4        finished in     837.30 seconds,  120084.00 req/s,      14.23 MB/s,          0 failures
nginx 1.16.0    finished in       1.94 seconds,   52198.70 req/s,      11.60 MB/s,          0 failures

h2load-ecc128 - 1kstatic.html
lsws 5.4        finished in       1.18 seconds,   89120.70 req/s,      10.56 MB/s,          0 failures
nginx 1.16.0    finished in       2.65 seconds,   38590.70 req/s,       8.58 MB/s,          0 failures

h2load-ecc256 - 1kstatic.html
lsws 5.4        finished in       0.87 seconds,  114781.00 req/s,      13.60 MB/s,          0 failures
nginx 1.16.0    finished in       3.25 seconds,   30897.30 req/s,       6.87 MB/s,          0 failures

h2load - 1kgzip-static.html
lsws 5.4        finished in     783.82 seconds,  128126.00 req/s,      15.18 MB/s,          0 failures
nginx 1.16.0    finished in       1.78 seconds,   56266.70 req/s,      13.53 MB/s,          0 failures

h2load-ecc128 - 1kgzip-static.html
lsws 5.4        finished in       0.93 seconds,  116531.00 req/s,      13.81 MB/s,          0 failures
nginx 1.16.0    finished in       2.41 seconds,   41938.70 req/s,      10.08 MB/s,          0 failures

h2load-ecc256 - 1kgzip-static.html
lsws 5.4        finished in       0.79 seconds,  127839.00 req/s,      15.14 MB/s,          0 failures
nginx 1.16.0    finished in       2.06 seconds,   49817.30 req/s,      11.97 MB/s,          0 failures

h2load - amdepyc2.jpg.webp
lsws 5.4        finished in      11.21 seconds,    8961.20 req/s,      90.59 MB/s,          0 failures
nginx 1.16.0    finished in      11.36 seconds,    8832.13 req/s,      90.01 MB/s,          0 failures

h2load-ecc128 - amdepyc2.jpg.webp
lsws 5.4        finished in      11.22 seconds,    8932.57 req/s,      90.26 MB/s,          0 failures
nginx 1.16.0    finished in      11.99 seconds,    8383.23 req/s,      85.43 MB/s,          0 failures

h2load-ecc256 - amdepyc2.jpg.webp
lsws 5.4        finished in      12.38 seconds,    8094.10 req/s,      81.75 MB/s,          0 failures
nginx 1.16.0    finished in      12.94 seconds,    7728.23 req/s,      78.76 MB/s,          0 failures

h2load - wordpress
lsws 5.4        finished in       3.99 seconds,   25080.60 req/s,      97.29 MB/s,          0 failures
nginx 1.16.0    finished in      11.46 seconds,    8744.20 req/s,      35.53 MB/s,          0 failures

h2load-ecc128 - wordpress
lsws 5.4        finished in       4.81 seconds,   21888.50 req/s,      84.90 MB/s,          0 failures
nginx 1.16.0    finished in      12.64 seconds,    7914.80 req/s,      32.16 MB/s,          0 failures

h2load-ecc256 - wordpress
lsws 5.4        finished in       4.73 seconds,   21440.40 req/s,      83.17 MB/s,          0 failures
nginx 1.16.0    finished in      12.44 seconds,    8055.70 req/s,      32.73 MB/s,          0 failures

h2load - coachblog
lsws 5.4        finished in       8.00 seconds,   12505.30 req/s,      78.93 MB/s,          0 failures
nginx 1.16.0    finished in      19.58 seconds,    5158.50 req/s,      39.26 MB/s,          0 failures

h2load-ecc128 - coachblog
lsws 5.4        finished in       6.62 seconds,   15127.00 req/s,      95.48 MB/s,          0 failures
nginx 1.16.0    finished in      19.23 seconds,    5207.33 req/s,      39.63 MB/s,          0 failures

h2load-ecc256 - coachblog
lsws 5.4        finished in       7.90 seconds,   12668.50 req/s,      79.96 MB/s,          0 failures
nginx 1.16.0    finished in      21.54 seconds,    4651.40 req/s,      35.39 MB/s,          0 failures

h2load - coachbloggzip
lsws 5.4        finished in       7.29 seconds,   13892.90 req/s,      87.69 MB/s,          0 failures
nginx 1.16.0    finished in       6.76 seconds,   14859.60 req/s,      95.68 MB/s,          0 failures

h2load-ecc128 - coachbloggzip
lsws 5.4        finished in       6.90 seconds,   14533.20 req/s,      91.73 MB/s,          0 failures
nginx 1.16.0    finished in       6.47 seconds,   15468.00 req/s,      99.60 MB/s,          0 failures

h2load-ecc256 - coachbloggzip
lsws 5.4        finished in       6.62 seconds,   15146.00 req/s,      95.60 MB/s,          0 failures
nginx 1.16.0    finished in       7.01 seconds,   14276.80 req/s,      91.93 MB/s,          0 failures
```
```
cat /opt/Benchmark/081319-125155/RESULTS.txt
############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       709.76ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    140892.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       864.23ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    115709.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   13.71MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       894.06ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    111849.3
Total Bandwidth:        11.85MB
Bandwidth Per Second:   13.25MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       798.15ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    125289.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   14.84MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       753.62ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    132692.3
Total Bandwidth:        11.85MB
Bandwidth Per Second:   15.72MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       928.10ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    107747.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   12.77MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       754.98ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    132453.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   15.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       976.14ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    102444.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   12.14MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       857.11ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    116671.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   13.82MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       739.36ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    135252.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.03MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       12.06s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8293.9
Total Bandwidth:        1011.46MB
Bandwidth Per Second:   83.89MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       11.46s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8728.1
Total Bandwidth:        1009.94MB
Bandwidth Per Second:   88.15MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       11.82s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8457.7
Total Bandwidth:        1010.82MB
Bandwidth Per Second:   85.49MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.77s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    9284.1
Total Bandwidth:        1010.64MB
Bandwidth Per Second:   93.83MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.19s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    9809.1
Total Bandwidth:        1010.64MB
Bandwidth Per Second:   99.14MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       4.70s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    21269.0
Total Bandwidth:        387.90MB
Bandwidth Per Second:   82.50MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       3.95s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    25332.1
Total Bandwidth:        387.90MB
Bandwidth Per Second:   98.26MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       3.84s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    26030.5
Total Bandwidth:        387.90MB
Bandwidth Per Second:   100.97MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       4.24s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    23583.4
Total Bandwidth:        387.90MB
Bandwidth Per Second:   91.48MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       4.19s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    23879.1
Total Bandwidth:        387.90MB
Bandwidth Per Second:   92.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       7.74s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    12924.5
Total Bandwidth:        631.20MB
Bandwidth Per Second:   81.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       8.24s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    12128.8
Total Bandwidth:        631.20MB
Bandwidth Per Second:   76.56MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       8.02s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    12462.5
Total Bandwidth:        631.20MB
Bandwidth Per Second:   78.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       6.74s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    14838.8
Total Bandwidth:        631.19MB
Bandwidth Per Second:   93.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       9.80s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    10207.8
Total Bandwidth:        631.20MB
Bandwidth Per Second:   64.43MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       8.95s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11168.1
Total Bandwidth:        631.20MB
Bandwidth Per Second:   70.49MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.61s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    15133.3
Total Bandwidth:        631.19MB
Bandwidth Per Second:   95.52MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       11.22s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8913.9
Total Bandwidth:        631.21MB
Bandwidth Per Second:   56.27MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.78s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    14744.7
Total Bandwidth:        631.19MB
Bandwidth Per Second:   93.07MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       8.47s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11800.8
Total Bandwidth:        631.20MB
Bandwidth Per Second:   74.49MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       881.02ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    113504.9
Total Bandwidth:        11.85MB
Bandwidth Per Second:   13.45MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       861.42ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    116088.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   13.75MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.49s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    67207.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   7.96MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.03s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    96908.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   11.48MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.19s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    84067.5
Total Bandwidth:        11.85MB
Bandwidth Per Second:   9.96MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       935.97ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    106840.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   12.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.12s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    89133.1
Total Bandwidth:        11.85MB
Bandwidth Per Second:   10.56MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       713.65ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    140124.9
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.60MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       743.22ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    134550.3
Total Bandwidth:        11.85MB
Bandwidth Per Second:   15.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.33s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    74918.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   8.88MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.80s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    9256.8
Total Bandwidth:        1009.89MB
Bandwidth Per Second:   93.48MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.69s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7306.6
Total Bandwidth:        1011.64MB
Bandwidth Per Second:   73.92MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       11.93s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8383.7
Total Bandwidth:        1010.79MB
Bandwidth Per Second:   84.74MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.80s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    9258.4
Total Bandwidth:        1011.42MB
Bandwidth Per Second:   93.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.92s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    9157.2
Total Bandwidth:        1010.72MB
Bandwidth Per Second:   92.55MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       3.70s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    27018.5
Total Bandwidth:        387.90MB
Bandwidth Per Second:   104.80MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       4.21s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    23764.4
Total Bandwidth:        387.90MB
Bandwidth Per Second:   92.18MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       6.43s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15550.9
Total Bandwidth:        387.91MB
Bandwidth Per Second:   60.32MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       7.18s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    13926.8
Total Bandwidth:        387.92MB
Bandwidth Per Second:   54.02MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       3.80s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    26350.3
Total Bandwidth:        387.90MB
Bandwidth Per Second:   102.21MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       6.63s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15079.5
Total Bandwidth:        631.19MB
Bandwidth Per Second:   95.18MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       6.80s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14716.6
Total Bandwidth:        631.19MB
Bandwidth Per Second:   92.89MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       8.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11834.6
Total Bandwidth:        631.20MB
Bandwidth Per Second:   74.70MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       6.11s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16364.4
Total Bandwidth:        631.19MB
Bandwidth Per Second:   103.29MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       6.42s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15584.8
Total Bandwidth:        631.19MB
Bandwidth Per Second:   98.37MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       7.71s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    12969.6
Total Bandwidth:        631.19MB
Bandwidth Per Second:   81.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       7.19s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    13898.8
Total Bandwidth:        631.19MB
Bandwidth Per Second:   87.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15510.1
Total Bandwidth:        631.19MB
Bandwidth Per Second:   97.90MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       7.05s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14190.6
Total Bandwidth:        631.19MB
Bandwidth Per Second:   89.57MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.39s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15654.4
Total Bandwidth:        631.19MB
Bandwidth Per Second:   98.81MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       981.86ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    101847.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   12.07MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       935.26ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    106922.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   12.67MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       861.74ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    116044.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   13.75MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       823.89ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    121375.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   14.38MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       684.28ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    146139.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   17.31MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.12s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    89528.5
Total Bandwidth:        11.85MB
Bandwidth Per Second:   10.61MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       806.31ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    124021.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   14.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       918.37ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    108888.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   12.90MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       714.91ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    139877.1
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.57MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       835.99ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    119618.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   14.17MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       12.19s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8206.0
Total Bandwidth:        1009.91MB
Bandwidth Per Second:   82.87MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.11s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    9888.3
Total Bandwidth:        1010.55MB
Bandwidth Per Second:   99.93MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       11.84s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8448.1
Total Bandwidth:        1009.62MB
Bandwidth Per Second:   85.29MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.11s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7628.2
Total Bandwidth:        1010.47MB
Bandwidth Per Second:   77.08MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.36s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7486.0
Total Bandwidth:        1010.69MB
Bandwidth Per Second:   75.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       15.17s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6593.7
Total Bandwidth:        387.95MB
Bandwidth Per Second:   25.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       7.11s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14063.8
Total Bandwidth:        387.92MB
Bandwidth Per Second:   54.56MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       5.39s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18538.8
Total Bandwidth:        387.91MB
Bandwidth Per Second:   71.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       4.04s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    24739.3
Total Bandwidth:        387.90MB
Bandwidth Per Second:   95.97MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       4.75s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    21043.1
Total Bandwidth:        387.91MB
Bandwidth Per Second:   81.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       8.01s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    12479.1
Total Bandwidth:        631.19MB
Bandwidth Per Second:   78.77MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       7.56s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    13235.4
Total Bandwidth:        631.19MB
Bandwidth Per Second:   83.54MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       6.84s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14626.6
Total Bandwidth:        631.19MB
Bandwidth Per Second:   92.32MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       8.14s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    12290.9
Total Bandwidth:        631.20MB
Bandwidth Per Second:   77.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       8.60s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11627.2
Total Bandwidth:        631.20MB
Bandwidth Per Second:   73.39MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.21s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16115.7
Total Bandwidth:        631.19MB
Bandwidth Per Second:   101.72MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.81s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14684.3
Total Bandwidth:        631.19MB
Bandwidth Per Second:   92.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       7.06s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14155.8
Total Bandwidth:        631.19MB
Bandwidth Per Second:   89.35MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.83s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14638.0
Total Bandwidth:        631.19MB
Bandwidth Per Second:   92.39MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       6.18s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16170.2
Total Bandwidth:        631.19MB
Bandwidth Per Second:   102.06MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.66s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    60360.4
Total Bandwidth:        22.23MB
Bandwidth Per Second:   13.42MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       2.08s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    48074.4
Total Bandwidth:        22.23MB
Bandwidth Per Second:   10.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       2.08s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    48161.0
Total Bandwidth:        22.23MB
Bandwidth Per Second:   10.70MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.95s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    51160.0
Total Bandwidth:        22.23MB
Bandwidth Per Second:   11.37MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.63s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    61254.1
Total Bandwidth:        22.23MB
Bandwidth Per Second:   13.61MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.86s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    53892.5
Total Bandwidth:        24.04MB
Bandwidth Per Second:   12.96MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.72s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    58189.0
Total Bandwidth:        24.04MB
Bandwidth Per Second:   13.99MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       2.85s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    35090.9
Total Bandwidth:        24.04MB
Bandwidth Per Second:   8.44MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.76s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    56718.4
Total Bandwidth:        24.04MB
Bandwidth Per Second:   13.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.81s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    55231.3
Total Bandwidth:        24.04MB
Bandwidth Per Second:   13.28MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.51s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    9514.0
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   96.96MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       11.71s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8541.0
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   87.04MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.68s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    7308.6
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   74.48MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       12.54s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    7972.7
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   81.25MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       11.85s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8441.4
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   86.03MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       11.30s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8849.8
Total Bandwidth:        406.27MB
Bandwidth Per Second:   35.95MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       10.98s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    9108.6
Total Bandwidth:        406.27MB
Bandwidth Per Second:   37.01MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       10.10s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    9896.8
Total Bandwidth:        406.27MB
Bandwidth Per Second:   40.21MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       12.09s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    8274.2
Total Bandwidth:        406.27MB
Bandwidth Per Second:   33.62MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       9.35s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    10696.5
Total Bandwidth:        406.27MB
Bandwidth Per Second:   43.46MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       21.72s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    4604.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   35.04MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       21.76s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    4594.9
Total Bandwidth:        760.94MB
Bandwidth Per Second:   34.97MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       17.41s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    5744.1
Total Bandwidth:        760.94MB
Bandwidth Per Second:   43.71MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       17.06s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    5860.5
Total Bandwidth:        760.94MB
Bandwidth Per Second:   44.60MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       19.96s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    5010.6
Total Bandwidth:        760.94MB
Bandwidth Per Second:   38.13MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.56s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    15254.4
Total Bandwidth:        643.93MB
Bandwidth Per Second:   98.23MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.18s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    16192.5
Total Bandwidth:        643.93MB
Bandwidth Per Second:   104.27MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       7.26s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    13766.3
Total Bandwidth:        643.93MB
Bandwidth Per Second:   88.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.80s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    14711.8
Total Bandwidth:        643.93MB
Bandwidth Per Second:   94.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.84s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    14620.1
Total Bandwidth:        643.93MB
Bandwidth Per Second:   94.14MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       2.42s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    41344.9
Total Bandwidth:        22.23MB
Bandwidth Per Second:   9.19MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       2.31s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    43357.9
Total Bandwidth:        22.23MB
Bandwidth Per Second:   9.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       3.44s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    29078.7
Total Bandwidth:        22.23MB
Bandwidth Per Second:   6.46MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.72s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    58003.8
Total Bandwidth:        22.23MB
Bandwidth Per Second:   12.89MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       3.22s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    31068.9
Total Bandwidth:        22.23MB
Bandwidth Per Second:   6.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       2.26s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    44329.9
Total Bandwidth:        24.04MB
Bandwidth Per Second:   10.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       2.21s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    45215.3
Total Bandwidth:        24.04MB
Bandwidth Per Second:   10.87MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       3.23s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    30964.4
Total Bandwidth:        24.04MB
Bandwidth Per Second:   7.44MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       2.76s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    36270.4
Total Bandwidth:        24.04MB
Bandwidth Per Second:   8.72MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.66s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    60249.4
Total Bandwidth:        24.04MB
Bandwidth Per Second:   14.48MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.99s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    9102.5
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   92.76MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.11s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7627.7
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   77.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       14.41s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6938.4
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   70.71MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       10.36s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    9649.1
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   98.33MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       11.88s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8419.5
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   85.80MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       10.93s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    9150.8
Total Bandwidth:        406.27MB
Bandwidth Per Second:   37.18MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       12.34s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8101.1
Total Bandwidth:        406.27MB
Bandwidth Per Second:   32.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       12.89s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7759.8
Total Bandwidth:        406.27MB
Bandwidth Per Second:   31.53MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       12.68s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7883.5
Total Bandwidth:        406.27MB
Bandwidth Per Second:   32.03MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       9.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10580.3
Total Bandwidth:        406.27MB
Bandwidth Per Second:   42.98MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       20.21s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    4947.1
Total Bandwidth:        760.94MB
Bandwidth Per Second:   37.65MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       20.77s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    4814.9
Total Bandwidth:        760.94MB
Bandwidth Per Second:   36.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       16.40s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6096.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   46.39MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       18.28s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5470.6
Total Bandwidth:        760.94MB
Bandwidth Per Second:   41.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       19.21s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5204.3
Total Bandwidth:        760.94MB
Bandwidth Per Second:   39.60MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       7.16s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    13962.0
Total Bandwidth:        643.93MB
Bandwidth Per Second:   89.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.46s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15469.3
Total Bandwidth:        643.93MB
Bandwidth Per Second:   99.61MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.27s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15937.8
Total Bandwidth:        643.93MB
Bandwidth Per Second:   102.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.04s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16552.9
Total Bandwidth:        643.93MB
Bandwidth Per Second:   106.59MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.67s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14996.8
Total Bandwidth:        643.93MB
Bandwidth Per Second:   96.57MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       3.25s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    30814.6
Total Bandwidth:        22.23MB
Bandwidth Per Second:   6.85MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       2.98s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    33538.6
Total Bandwidth:        22.23MB
Bandwidth Per Second:   7.45MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       3.53s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    28338.8
Total Bandwidth:        22.23MB
Bandwidth Per Second:   6.30MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       4.41s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    22698.7
Total Bandwidth:        22.23MB
Bandwidth Per Second:   5.05MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       2.21s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    45245.4
Total Bandwidth:        22.23MB
Bandwidth Per Second:   10.06MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       2.86s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    34969.6
Total Bandwidth:        24.04MB
Bandwidth Per Second:   8.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       2.55s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    39286.6
Total Bandwidth:        24.04MB
Bandwidth Per Second:   9.44MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.76s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    56714.0
Total Bandwidth:        24.04MB
Bandwidth Per Second:   13.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.87s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    53451.6
Total Bandwidth:        24.04MB
Bandwidth Per Second:   12.85MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       1.75s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    57179.4
Total Bandwidth:        24.04MB
Bandwidth Per Second:   13.75MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.14s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7607.6
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   77.53MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.84s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7227.8
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   73.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       13.00s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7693.8
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   78.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       12.68s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7883.3
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   80.34MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       12.01s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8328.6
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   84.88MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       11.99s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8338.4
Total Bandwidth:        406.27MB
Bandwidth Per Second:   33.88MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       12.04s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8303.2
Total Bandwidth:        406.27MB
Bandwidth Per Second:   33.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       13.29s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7525.5
Total Bandwidth:        406.27MB
Bandwidth Per Second:   30.57MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       9.05s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11046.5
Total Bandwidth:        406.27MB
Bandwidth Per Second:   44.88MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       11.86s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8428.3
Total Bandwidth:        406.27MB
Bandwidth Per Second:   34.24MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       21.62s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    4625.0
Total Bandwidth:        760.94MB
Bandwidth Per Second:   35.19MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       23.40s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    4272.6
Total Bandwidth:        760.94MB
Bandwidth Per Second:   32.51MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       18.72s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5343.1
Total Bandwidth:        760.94MB
Bandwidth Per Second:   40.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       20.32s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    4922.1
Total Bandwidth:        760.94MB
Bandwidth Per Second:   37.45MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       22.69s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    4407.1
Total Bandwidth:        760.94MB
Bandwidth Per Second:   33.54MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       7.56s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    13235.6
Total Bandwidth:        643.93MB
Bandwidth Per Second:   85.23MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       7.08s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14123.2
Total Bandwidth:        643.93MB
Bandwidth Per Second:   90.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       7.23s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    13835.3
Total Bandwidth:        643.93MB
Bandwidth Per Second:   89.09MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.72s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    14871.8
Total Bandwidth:        643.93MB
Bandwidth Per Second:   95.76MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       6.63s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    15093.9
Total Bandwidth:        643.93MB
Bandwidth Per Second:   97.19MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
```