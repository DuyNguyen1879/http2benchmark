* https://github.com/centminmod/http2benchmark/tree/extended-tests

The below tests were done with Litespeed 5.4.0 and Nginx 1.16.0 on CentOS 7.6 64bit KVM VPS using $20/month Upcloud VPS servers. Updated tests with [Litespeed 5.4.1 vs Nginx 1.16.1](https://github.com/centminmod/http2benchmark/blob/extended-tests/examples/ecdsa-http2benchmark-h2load-low-lsws-5.4.1-nginx-1.16.1-run1.md) are [here](https://github.com/centminmod/http2benchmark/blob/extended-tests/examples/ecdsa-http2benchmark-h2load-low-lsws-5.4.1-nginx-1.16.1-run1.md).

The original http2benchmark tests only tested standard RSA 2048bit SSL certificates and not the better performing ECC 256bit SSL certificates with ECDSA SSL ciphers. The forked http2benchmarks have optional support for testing ECC 256bit SSL certificates with ECDSA SSL ciphers. Part of the performance comes from smaller SSL certificate and SSL key sizes compared to RSA 2048bit SSL certificate setups. Was expecting Litespeed to have more of an advantage given that it is built with it's own crypto library using Google's BoringSSL which is a forked version of OpenSSL. BoringSSL is known to have better ECDSA performance than OpenSSL. Nginx binaries from nginx.org YUM repo are built against OpenSSL 1.0.2 usually. However, below results were mixed with Nginx beating out Litespeed in some of the below test targets. Especially for `coachblogzip` wordpress simulation tests. Seems Litespeed is more optimised for ECDSA 256bit instead of 128bit.

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

Example results from Upcloud 2 cpu $20/month KVM VPS server + client spun up servers.

```
***Total of 271 seconds to finish process***
[OK] to archive /opt/Benchmark/081319-121410.tgz
/opt/Benchmark/081319-121410/RESULTS.txt
#############  Benchmark Result  #################

h2load-low - 1kstatic.html
lsws 5.4        finished in     152.31 seconds,   33357.00 req/s,       4.08 MB/s,          0 failures
nginx 1.16.0    finished in     241.15 seconds,   21643.90 req/s,       4.83 MB/s,          0 failures

h2load-low-ecc128 - 1kstatic.html
lsws 5.4        finished in       0.25 seconds,   21561.80 req/s,       2.64 MB/s,          0 failures
nginx 1.16.0    finished in       0.20 seconds,   26179.40 req/s,       5.84 MB/s,          0 failures

h2load-low-ecc256 - 1kstatic.html
lsws 5.4        finished in       0.12 seconds,   43456.00 req/s,       5.32 MB/s,          0 failures
nginx 1.16.0    finished in       0.50 seconds,   18773.40 req/s,       4.19 MB/s,          0 failures

h2load-low - 1kgzip-static.html
lsws 5.4        finished in     207.86 seconds,   25846.60 req/s,       3.16 MB/s,          0 failures
nginx 1.16.0    finished in     173.90 seconds,   28812.20 req/s,       6.95 MB/s,          0 failures

h2load-low-ecc128 - 1kgzip-static.html
lsws 5.4        finished in       0.31 seconds,   16384.10 req/s,       2.01 MB/s,          0 failures
nginx 1.16.0    finished in       0.18 seconds,   27285.50 req/s,       6.58 MB/s,          0 failures

h2load-low-ecc256 - 1kgzip-static.html
lsws 5.4        finished in       0.10 seconds,   49933.70 req/s,       6.11 MB/s,          0 failures
nginx 1.16.0    finished in       0.32 seconds,   16402.90 req/s,       3.96 MB/s,          0 failures

h2load-low - amdepyc2.jpg.webp
lsws 5.4        finished in     815.63 seconds,    6209.17 req/s,      62.66 MB/s,          0 failures
nginx 1.16.0    finished in     721.13 seconds,    7112.75 req/s,      72.49 MB/s,          0 failures

h2load-low-ecc128 - amdepyc2.jpg.webp
lsws 5.4        finished in       0.90 seconds,    5833.90 req/s,      58.88 MB/s,          0 failures
nginx 1.16.0    finished in       0.53 seconds,    9508.53 req/s,      96.91 MB/s,          0 failures

h2load-low-ecc256 - amdepyc2.jpg.webp
lsws 5.4        finished in       0.77 seconds,    6538.10 req/s,      65.99 MB/s,          0 failures
nginx 1.16.0    finished in       0.67 seconds,    7621.13 req/s,      77.67 MB/s,          0 failures

h2load-low - wordpress
lsws 5.4        finished in     309.89 seconds,   16523.70 req/s,      64.18 MB/s,          0 failures
nginx 1.16.0    finished in     591.46 seconds,    5177.60 req/s,      21.04 MB/s,          0 failures

h2load-low-ecc128 - wordpress
lsws 5.4        finished in       0.26 seconds,   19317.20 req/s,      75.03 MB/s,          0 failures
nginx 1.16.0    finished in       0.70 seconds,    7161.13 req/s,      29.10 MB/s,          0 failures

h2load-low-ecc256 - wordpress
lsws 5.4        finished in       0.26 seconds,   19572.40 req/s,      76.02 MB/s,          0 failures
nginx 1.16.0    finished in       0.65 seconds,    7753.53 req/s,      31.51 MB/s,          0 failures

h2load-low - coachblog
lsws 5.4        finished in     577.89 seconds,    9229.20 req/s,      58.29 MB/s,          0 failures
nginx 1.16.0    finished in     241.68 seconds,    4972.90 req/s,      37.85 MB/s,          0 failures

h2load-low-ecc128 - coachblog
lsws 5.4        finished in       0.48 seconds,   11247.90 req/s,      71.04 MB/s,          0 failures
nginx 1.16.0    finished in       0.96 seconds,    5200.80 req/s,      39.58 MB/s,          0 failures

h2load-low-ecc256 - coachblog
lsws 5.4        finished in       0.37 seconds,   13656.60 req/s,      86.25 MB/s,          0 failures
nginx 1.16.0    finished in       1.04 seconds,    4822.20 req/s,      36.70 MB/s,          0 failures

h2load-low - coachbloggzip
lsws 5.4        finished in     481.31 seconds,    6060.63 req/s,      38.28 MB/s,          0 failures
nginx 1.16.0    finished in     408.68 seconds,   12266.70 req/s,      79.00 MB/s,          0 failures

h2load-low-ecc128 - coachbloggzip
lsws 5.4        finished in       0.40 seconds,   12571.80 req/s,      79.40 MB/s,          0 failures
nginx 1.16.0    finished in       0.49 seconds,   10292.20 req/s,      66.29 MB/s,          0 failures

h2load-low-ecc256 - coachbloggzip
lsws 5.4        finished in       0.39 seconds,   12891.80 req/s,      81.42 MB/s,          0 failures
nginx 1.16.0    finished in       0.38 seconds,   13162.70 req/s,      84.77 MB/s,          0 failures
```

```
cat /opt/Benchmark/081319-121410/RESULTS.txt
############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       104.96ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47639.0
Total Bandwidth:        627.69KB
Bandwidth Per Second:   5.84MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       176.46ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    28335.6
Total Bandwidth:        626.95KB
Bandwidth Per Second:   3.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       129.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    38641.9
Total Bandwidth:        626.95KB
Bandwidth Per Second:   4.73MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       151.09ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33093.9
Total Bandwidth:        626.95KB
Bandwidth Per Second:   4.05MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       168.04ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    29755.0
Total Bandwidth:        626.95KB
Bandwidth Per Second:   3.64MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       128.75ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    38834.0
Total Bandwidth:        626.95KB
Bandwidth Per Second:   4.76MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       283.18ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    17656.9
Total Bandwidth:        626.95KB
Bandwidth Per Second:   2.16MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       193.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    25834.0
Total Bandwidth:        626.95KB
Bandwidth Per Second:   3.16MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       146.85ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34048.8
Total Bandwidth:        626.95KB
Bandwidth Per Second:   4.17MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       103.33ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    48387.7
Total Bandwidth:        626.95KB
Bandwidth Per Second:   5.93MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       894.73ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5588.2
Total Bandwidth:        50.46MB
Bandwidth Per Second:   56.40MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       650.36ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7688.0
Total Bandwidth:        50.46MB
Bandwidth Per Second:   77.59MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       691.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7228.7
Total Bandwidth:        50.46MB
Bandwidth Per Second:   72.95MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       860.49ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5810.6
Total Bandwidth:        50.46MB
Bandwidth Per Second:   58.64MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       514.04ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9726.9
Total Bandwidth:        50.46MB
Bandwidth Per Second:   98.17MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       249.95ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    20004.0
Total Bandwidth:        19.42MB
Bandwidth Per Second:   77.70MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       316.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    15810.3
Total Bandwidth:        19.42MB
Bandwidth Per Second:   61.41MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       363.46ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13756.8
Total Bandwidth:        19.42MB
Bandwidth Per Second:   53.43MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       355.42ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14067.9
Total Bandwidth:        19.42MB
Bandwidth Per Second:   54.64MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       345.00ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14492.8
Total Bandwidth:        19.42MB
Bandwidth Per Second:   56.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       395.14ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12653.8
Total Bandwidth:        31.58MB
Bandwidth Per Second:   79.92MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       495.02ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10100.5
Total Bandwidth:        31.58MB
Bandwidth Per Second:   63.79MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       459.93ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10871.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   68.66MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       616.86ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8105.5
Total Bandwidth:        31.58MB
Bandwidth Per Second:   51.19MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       721.67ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6928.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   43.76MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       1.25s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4002.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   25.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       564.13ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8863.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   55.98MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       829.15ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6030.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   38.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       613.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8149.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   51.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       1.39s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    3608.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   22.79MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       146.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34145.0
Total Bandwidth:        626.95KB
Bandwidth Per Second:   4.18MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       247.81ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    20176.9
Total Bandwidth:        626.95KB
Bandwidth Per Second:   2.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       172.46ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    28992.9
Total Bandwidth:        626.95KB
Bandwidth Per Second:   3.55MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       322.26ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    15515.6
Total Bandwidth:        626.95KB
Bandwidth Per Second:   1.90MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       326.70ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    15304.7
Total Bandwidth:        626.95KB
Bandwidth Per Second:   1.87MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       200.99ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    24876.8
Total Bandwidth:        626.95KB
Bandwidth Per Second:   3.05MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       271.61ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    18408.6
Total Bandwidth:        626.95KB
Bandwidth Per Second:   2.25MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       300.49ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    16639.4
Total Bandwidth:        627.00KB
Bandwidth Per Second:   2.04MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       354.50ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14104.3
Total Bandwidth:        626.95KB
Bandwidth Per Second:   1.73MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       380.97ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13124.3
Total Bandwidth:        626.95KB
Bandwidth Per Second:   1.61MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       1.09s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4604.0
Total Bandwidth:        50.46MB
Bandwidth Per Second:   46.46MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       1.24s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4025.2
Total Bandwidth:        50.46MB
Bandwidth Per Second:   40.63MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       656.01ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7621.8
Total Bandwidth:        50.46MB
Bandwidth Per Second:   76.92MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       931.62ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5366.9
Total Bandwidth:        50.46MB
Bandwidth Per Second:   54.17MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       663.93ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7530.8
Total Bandwidth:        50.46MB
Bandwidth Per Second:   76.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       221.00ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    22624.1
Total Bandwidth:        19.42MB
Bandwidth Per Second:   87.87MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       258.28ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    19358.9
Total Bandwidth:        19.42MB
Bandwidth Per Second:   75.19MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       313.11ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    15968.7
Total Bandwidth:        19.42MB
Bandwidth Per Second:   62.02MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       564.87ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8851.5
Total Bandwidth:        19.42MB
Bandwidth Per Second:   34.38MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       430.14ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    11624.0
Total Bandwidth:        19.42MB
Bandwidth Per Second:   45.15MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       436.86ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    11445.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   72.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       338.41ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14774.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   93.31MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       664.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7523.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   47.52MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       567.08ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8817.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   55.69MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       457.05ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10939.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   69.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       350.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14258.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   90.05MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       342.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14590.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   92.16MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       475.47ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10516.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   66.42MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       386.35ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12941.5
Total Bandwidth:        31.58MB
Bandwidth Per Second:   81.74MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       499.15ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10017.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   63.26MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       117.60ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    42518.4
Total Bandwidth:        626.95KB
Bandwidth Per Second:   5.21MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       149.89ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33358.0
Total Bandwidth:        626.95KB
Bandwidth Per Second:   4.08MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       113.19ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    44172.3
Total Bandwidth:        626.95KB
Bandwidth Per Second:   5.41MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       107.80ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    46381.3
Total Bandwidth:        626.95KB
Bandwidth Per Second:   5.68MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       114.48ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    43677.2
Total Bandwidth:        626.95KB
Bandwidth Per Second:   5.35MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       95.41ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    52404.8
Total Bandwidth:        626.95KB
Bandwidth Per Second:   6.42MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       104.05ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    48051.9
Total Bandwidth:        626.95KB
Bandwidth Per Second:   5.88MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       113.30ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    44129.4
Total Bandwidth:        629.20KB
Bandwidth Per Second:   5.42MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       96.78ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    51665.7
Total Bandwidth:        626.95KB
Bandwidth Per Second:   6.33MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       99.83ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    50083.6
Total Bandwidth:        626.95KB
Bandwidth Per Second:   6.13MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       727.35ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6874.2
Total Bandwidth:        50.46MB
Bandwidth Per Second:   69.38MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       972.17ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5143.1
Total Bandwidth:        50.46MB
Bandwidth Per Second:   51.91MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       765.81ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6529.0
Total Bandwidth:        50.46MB
Bandwidth Per Second:   65.89MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       805.01ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6211.1
Total Bandwidth:        50.46MB
Bandwidth Per Second:   62.69MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       643.63ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7768.3
Total Bandwidth:        50.46MB
Bandwidth Per Second:   78.40MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       250.75ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    19940.4
Total Bandwidth:        19.42MB
Bandwidth Per Second:   77.45MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       252.69ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    19787.4
Total Bandwidth:        19.42MB
Bandwidth Per Second:   76.86MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       233.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    21408.0
Total Bandwidth:        19.42MB
Bandwidth Per Second:   83.15MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       299.66ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    16685.8
Total Bandwidth:        19.42MB
Bandwidth Per Second:   64.81MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
Total Time Spent:       263.30ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    18989.4
Total Bandwidth:        19.42MB
Bandwidth Per Second:   73.76MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       477.33ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10474.8
Total Bandwidth:        31.58MB
Bandwidth Per Second:   66.16MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       357.73ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13977.1
Total Bandwidth:        31.58MB
Bandwidth Per Second:   88.27MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       541.93ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9226.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   58.27MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       363.17ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13767.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   86.95MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
Total Time Spent:       378.07ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13225.1
Total Bandwidth:        31.58MB
Bandwidth Per Second:   83.54MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       455.88ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10967.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   69.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       395.16ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12653.1
Total Bandwidth:        31.58MB
Bandwidth Per Second:   79.91MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       376.58ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13277.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   83.85MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       392.31ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12745.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   80.49MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
Total Time Spent:       343.83ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14542.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   91.84MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       170.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    29368.5
Total Bandwidth:        1.12MB
Bandwidth Per Second:   6.55MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       303.49ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    16474.9
Total Bandwidth:        1.12MB
Bandwidth Per Second:   3.68MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       311.11ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    16071.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   3.59MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       188.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    26516.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   5.92MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       223.77ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    22344.1
Total Bandwidth:        1.12MB
Bandwidth Per Second:   4.99MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       168.16ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    29733.2
Total Bandwidth:        1.21MB
Bandwidth Per Second:   7.17MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       165.69ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    30176.8
Total Bandwidth:        1.21MB
Bandwidth Per Second:   7.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       171.23ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    29200.6
Total Bandwidth:        1.21MB
Bandwidth Per Second:   7.04MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       184.78ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    27059.3
Total Bandwidth:        1.21MB
Bandwidth Per Second:   6.53MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       178.50ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    28011.9
Total Bandwidth:        1.21MB
Bandwidth Per Second:   6.76MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       933.46ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5356.4
Total Bandwidth:        50.96MB
Bandwidth Per Second:   54.59MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       679.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7360.1
Total Bandwidth:        50.96MB
Bandwidth Per Second:   75.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       621.79ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8041.3
Total Bandwidth:        50.96MB
Bandwidth Per Second:   81.96MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       649.92ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7693.2
Total Bandwidth:        50.96MB
Bandwidth Per Second:   78.41MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       569.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8781.3
Total Bandwidth:        50.96MB
Bandwidth Per Second:   89.50MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       542.11ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9223.2
Total Bandwidth:        20.32MB
Bandwidth Per Second:   37.48MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       775.14ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6450.4
Total Bandwidth:        20.32MB
Bandwidth Per Second:   26.21MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       1.23s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4072.5
Total Bandwidth:        20.32MB
Bandwidth Per Second:   16.55MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       998.02ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5009.9
Total Bandwidth:        20.32MB
Bandwidth Per Second:   20.36MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       1.37s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    3637.9
Total Bandwidth:        20.32MB
Bandwidth Per Second:   14.78MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.03s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4844.0
Total Bandwidth:        38.05MB
Bandwidth Per Second:   36.86MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       963.67ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5188.4
Total Bandwidth:        38.05MB
Bandwidth Per Second:   39.49MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.02s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4904.7
Total Bandwidth:        38.05MB
Bandwidth Per Second:   37.33MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.01s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4954.5
Total Bandwidth:        38.05MB
Bandwidth Per Second:   37.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.15s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4352.9
Total Bandwidth:        38.05MB
Bandwidth Per Second:   33.13MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       438.60ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    11399.9
Total Bandwidth:        32.20MB
Bandwidth Per Second:   73.42MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       379.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13177.7
Total Bandwidth:        32.20MB
Bandwidth Per Second:   84.87MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       336.03ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14879.7
Total Bandwidth:        32.20MB
Bandwidth Per Second:   95.83MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       397.06ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12592.5
Total Bandwidth:        32.20MB
Bandwidth Per Second:   81.10MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       390.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12807.7
Total Bandwidth:        32.20MB
Bandwidth Per Second:   82.48MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       174.63ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    28632.6
Total Bandwidth:        1.12MB
Bandwidth Per Second:   6.39MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       295.60ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    16914.6
Total Bandwidth:        1.12MB
Bandwidth Per Second:   3.77MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       169.53ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    29493.4
Total Bandwidth:        1.12MB
Bandwidth Per Second:   6.58MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       244.95ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    20412.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   4.55MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       152.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    32775.0
Total Bandwidth:        1.12MB
Bandwidth Per Second:   7.31MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       147.18ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33972.7
Total Bandwidth:        1.21MB
Bandwidth Per Second:   8.20MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       172.32ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    29015.9
Total Bandwidth:        1.21MB
Bandwidth Per Second:   7.00MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       194.66ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    25686.0
Total Bandwidth:        1.21MB
Bandwidth Per Second:   6.20MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       199.13ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    25109.6
Total Bandwidth:        1.21MB
Bandwidth Per Second:   6.06MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       184.13ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    27154.7
Total Bandwidth:        1.21MB
Bandwidth Per Second:   6.55MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       552.84ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9044.2
Total Bandwidth:        50.96MB
Bandwidth Per Second:   92.18MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       547.66ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9129.8
Total Bandwidth:        50.96MB
Bandwidth Per Second:   93.05MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       508.66ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9829.7
Total Bandwidth:        50.96MB
Bandwidth Per Second:   100.18MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       522.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9566.1
Total Bandwidth:        50.96MB
Bandwidth Per Second:   97.50MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       507.78ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9846.7
Total Bandwidth:        50.96MB
Bandwidth Per Second:   100.36MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       1.00s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4975.9
Total Bandwidth:        20.32MB
Bandwidth Per Second:   20.22MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       607.73ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8227.3
Total Bandwidth:        20.32MB
Bandwidth Per Second:   33.43MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       679.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7359.0
Total Bandwidth:        20.32MB
Bandwidth Per Second:   29.90MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       650.92ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7681.4
Total Bandwidth:        20.32MB
Bandwidth Per Second:   31.21MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       776.03ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6443.0
Total Bandwidth:        20.32MB
Bandwidth Per Second:   26.18MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       963.05ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5191.8
Total Bandwidth:        38.05MB
Bandwidth Per Second:   39.51MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.01s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4932.1
Total Bandwidth:        38.05MB
Bandwidth Per Second:   37.54MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.09s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4589.5
Total Bandwidth:        38.05MB
Bandwidth Per Second:   34.93MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       912.65ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5478.5
Total Bandwidth:        38.05MB
Bandwidth Per Second:   41.69MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       870.48ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5743.9
Total Bandwidth:        38.05MB
Bandwidth Per Second:   43.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       560.04ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8927.9
Total Bandwidth:        32.20MB
Bandwidth Per Second:   57.50MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       464.95ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10753.9
Total Bandwidth:        32.20MB
Bandwidth Per Second:   69.26MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       514.62ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9715.8
Total Bandwidth:        32.20MB
Bandwidth Per Second:   62.57MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       447.45ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    11174.5
Total Bandwidth:        32.20MB
Bandwidth Per Second:   71.97MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       464.07ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10774.2
Total Bandwidth:        32.20MB
Bandwidth Per Second:   69.39MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       311.50ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    16051.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   3.58MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       619.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8069.8
Total Bandwidth:        1.12MB
Bandwidth Per Second:   1.80MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       195.45ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    25581.7
Total Bandwidth:        1.12MB
Bandwidth Per Second:   5.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       190.76ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    26210.9
Total Bandwidth:        1.12MB
Bandwidth Per Second:   5.85MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
Total Time Spent:       1.10s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4527.7
Total Bandwidth:        1.12MB
Bandwidth Per Second:   1.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       228.21ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    21910.0
Total Bandwidth:        1.21MB
Bandwidth Per Second:   5.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       240.36ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    20802.5
Total Bandwidth:        1.21MB
Bandwidth Per Second:   5.02MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       337.93ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14796.1
Total Bandwidth:        1.21MB
Bandwidth Per Second:   3.57MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       367.37ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13610.1
Total Bandwidth:        1.21MB
Bandwidth Per Second:   3.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
Total Time Spent:       457.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10924.6
Total Bandwidth:        1.21MB
Bandwidth Per Second:   2.64MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       671.65ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7444.3
Total Bandwidth:        50.96MB
Bandwidth Per Second:   75.87MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       532.61ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9387.7
Total Bandwidth:        50.96MB
Bandwidth Per Second:   95.68MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       555.92ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8994.1
Total Bandwidth:        50.96MB
Bandwidth Per Second:   91.67MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       778.20ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6425.0
Total Bandwidth:        50.96MB
Bandwidth Per Second:   65.48MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
Total Time Spent:       1.01s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4939.1
Total Bandwidth:        50.96MB
Bandwidth Per Second:   50.34MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       503.98ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9920.9
Total Bandwidth:        20.32MB
Bandwidth Per Second:   40.31MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       585.35ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8541.8
Total Bandwidth:        20.32MB
Bandwidth Per Second:   34.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       1.11s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4500.4
Total Bandwidth:        20.32MB
Bandwidth Per Second:   18.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       698.44ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7158.8
Total Bandwidth:        20.32MB
Bandwidth Per Second:   29.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
Total Time Spent:       661.38ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7560.0
Total Bandwidth:        20.32MB
Bandwidth Per Second:   30.72MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.02s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4900.5
Total Bandwidth:        38.05MB
Bandwidth Per Second:   37.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       913.70ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5472.2
Total Bandwidth:        38.05MB
Bandwidth Per Second:   41.65MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.04s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4821.0
Total Bandwidth:        38.05MB
Bandwidth Per Second:   36.69MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.05s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    4745.1
Total Bandwidth:        38.05MB
Bandwidth Per Second:   36.11MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
Total Time Spent:       1.27s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    3931.3
Total Bandwidth:        38.05MB
Bandwidth Per Second:   29.92MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       364.61ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13713.1
Total Bandwidth:        32.20MB
Bandwidth Per Second:   88.31MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       403.80ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12382.3
Total Bandwidth:        32.20MB
Bandwidth Per Second:   79.74MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       373.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13392.7
Total Bandwidth:        32.20MB
Bandwidth Per Second:   86.25MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       413.69ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12086.2
Total Bandwidth:        32.20MB
Bandwidth Per Second:   77.84MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.0
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
Total Time Spent:       353.98ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14124.9
Total Bandwidth:        32.20MB
Bandwidth Per Second:   90.97MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
```