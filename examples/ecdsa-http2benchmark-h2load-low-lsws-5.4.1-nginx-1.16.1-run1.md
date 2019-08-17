https://github.com/centminmod/http2benchmark/tree/extended-tests

* The below tests were done with Litespeed 5.4.1 and Nginx 1.16.1 on CentOS 7.6 64bit KVM VPS using $20/month Upcloud VPS servers and with latest forked version of http2benchmark which collects additional h2load metrics/info in the resulting RESULTS.txt and RESULTS.csv logs for TLS protocol tested (TLSv1.2 etc). SSL Cipher tested (ECDHE-ECDSA-AES128-GCM-SHA256 etc). and Server Temp Key used i.e. ECDH P-256 256bits. 
* Also included original http2benchmark added h2load's header compression metric to see how much header compresssion space savings were made. Note Litespeed web server implements the full HPACK encoding compression as per RFC7541 specs so you will see higher percentage of header compression savings compared to distro installed Nginx versions. The reason is that distro package builds of Nginx use Nginx's default partial HPACK encoding configuration - Nginx never implemented the full HPACK encoding spec for their HTTP/2 implementation. However, certain Nginx builds can be patched with full HPACK encoding compression as outlined on [Cloudflare's blog](https://blog.cloudflare.com/hpack-the-silent-killer-feature-of-http-2/). Example of Centmin Mod Nginx server with patched full HPACK encoding compression support can be seen [here](https://community.centminmod.com/threads/nginx-1-17-3-dynamtic-tls-hpack-patch-support-in-123-09beta01.18161/).

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

`/opt/benchmark.ini` will be populated with variables that override `/opt/benchmark.sh` - each test is ran 7x times and average taken.

```
SERVER_LIST="lsws nginx"
TOOL_LIST="h2load-low h2load-low-ecc128 h2load-low-ecc256"
TARGET_LIST="1kstatic.html 1kgzip-static.html amdepyc2.jpg.webp wordpress coachblog coachbloggzip"
ROUNDNUM=7
```

Example results from Upcloud 2 cpu $20/month KVM VPS server + client spun up servers.

```
***Total of 309 seconds to finish process***
[OK] to archive /opt/Benchmark/081719-084427.tgz
/opt/Benchmark/081719-084427/RESULTS.txt
#############  Test Environment  #################
Network traffic: 528 Mbits/sec
Network latency: 0.274 ms
Client Server - Memory Size: 3789.44MB
Client Server - CPU number: 2
Client Server - CPU Thread: 1
Test   Server - Memory Size: 3789.44MB
Test   Server - CPU number: 2
Test   Server - CPU Thread: 1
#############  Benchmark Result  #################

h2load-low - 1kstatic.html
lsws 5.4.1      finished in      96.35 seconds,   52060.20 req/s,       6.38 MB/s,          0 failures,    95.2% header compression
nginx 1.16.1    finished in     132.00 seconds,   37957.80 req/s,       8.47 MB/s,          0 failures,    35.5% header compression

h2load-low-ecc128 - 1kstatic.html
lsws 5.4.1      finished in       0.09 seconds,   53189.00 req/s,       6.51 MB/s,          0 failures,    95.2% header compression
nginx 1.16.1    finished in       0.14 seconds,   36773.60 req/s,       8.21 MB/s,          0 failures,    35.5% header compression

h2load-low-ecc256 - 1kstatic.html
lsws 5.4.1      finished in       0.10 seconds,   52583.40 req/s,       6.44 MB/s,          0 failures,    95.2% header compression
nginx 1.16.1    finished in       0.14 seconds,   36081.40 req/s,       8.05 MB/s,          0 failures,    35.5% header compression

h2load-low - 1kgzip-static.html
lsws 5.4.1      finished in      92.20 seconds,   54372.80 req/s,       6.66 MB/s,          0 failures,    95.2% header compression
nginx 1.16.1    finished in     106.62 seconds,   46900.80 req/s,      11.31 MB/s,          0 failures,    38.5% header compression

h2load-low-ecc128 - 1kgzip-static.html
lsws 5.4.1      finished in       0.09 seconds,   52750.80 req/s,       6.46 MB/s,          0 failures,    95.2% header compression
nginx 1.16.1    finished in       0.12 seconds,   43042.80 req/s,      10.39 MB/s,          0 failures,    38.5% header compression

h2load-low-ecc256 - 1kgzip-static.html
lsws 5.4.1      finished in       0.09 seconds,   54913.00 req/s,       6.72 MB/s,          0 failures,    95.2% header compression
nginx 1.16.1    finished in       0.12 seconds,   42082.60 req/s,      10.15 MB/s,          0 failures,    38.5% header compression

h2load-low - amdepyc2.jpg.webp
lsws 5.4.1      finished in     527.81 seconds,    6303.40 req/s,      63.62 MB/s,        0.8 failures,   95.44% header compression
nginx 1.16.1    finished in     608.74 seconds,    8216.74 req/s,      83.75 MB/s,          0 failures,    38.6% header compression

h2load-low-ecc128 - amdepyc2.jpg.webp
lsws 5.4.1      finished in       1.58 seconds,    6906.46 req/s,      69.70 MB/s,        0.2 failures,   95.44% header compression
nginx 1.16.1    finished in       0.62 seconds,    8011.00 req/s,      81.65 MB/s,          0 failures,    38.6% header compression

h2load-low-ecc256 - amdepyc2.jpg.webp
lsws 5.4.1      finished in       4.44 seconds,    2445.34 req/s,      24.68 MB/s,          4 failures,    95.4% header compression
nginx 1.16.1    finished in       0.65 seconds,    7806.56 req/s,      79.57 MB/s,          0 failures,    38.6% header compression

h2load-low - wordpress
lsws 5.4.1      finished in     137.02 seconds,   36525.20 req/s,     141.94 MB/s,          0 failures,   95.36% header compression
nginx 1.16.1    finished in     530.97 seconds,    9501.48 req/s,      38.64 MB/s,          0 failures,    26.5% header compression

h2load-low-ecc128 - wordpress
lsws 5.4.1      finished in       0.14 seconds,   35635.40 req/s,     138.49 MB/s,          0 failures,   95.32% header compression
nginx 1.16.1    finished in       0.50 seconds,   10145.00 req/s,      41.25 MB/s,          0 failures,    26.5% header compression

h2load-low-ecc256 - wordpress
lsws 5.4.1      finished in       0.14 seconds,   35479.20 req/s,     137.87 MB/s,          0 failures,    95.4% header compression
nginx 1.16.1    finished in       0.50 seconds,   10077.20 req/s,      40.98 MB/s,          0 failures,    26.5% header compression

h2load-low - coachblog
lsws 5.4.1      finished in     442.58 seconds,   11732.10 req/s,      74.10 MB/s,          0 failures,    95.1% header compression
nginx 1.16.1    finished in     844.58 seconds,    5924.06 req/s,      45.08 MB/s,          0 failures,    35.3% header compression

h2load-low-ecc128 - coachblog
lsws 5.4.1      finished in       0.48 seconds,   10819.00 req/s,      68.33 MB/s,          0 failures,   95.08% header compression
nginx 1.16.1    finished in       0.86 seconds,    5826.38 req/s,      44.34 MB/s,          0 failures,    35.3% header compression

h2load-low-ecc256 - coachblog
lsws 5.4.1      finished in       0.46 seconds,   11149.60 req/s,      70.42 MB/s,          0 failures,   95.16% header compression
nginx 1.16.1    finished in       0.84 seconds,    5972.90 req/s,      45.46 MB/s,          0 failures,    35.3% header compression

h2load-low - coachbloggzip
lsws 5.4.1      finished in     464.19 seconds,   11263.70 req/s,      71.14 MB/s,          0 failures,   95.16% header compression
nginx 1.16.1    finished in     485.00 seconds,   10572.60 req/s,      68.09 MB/s,          0 failures,    38.5% header compression

h2load-low-ecc128 - coachbloggzip
lsws 5.4.1      finished in       0.48 seconds,   10927.20 req/s,      69.02 MB/s,          0 failures,    95.1% header compression
nginx 1.16.1    finished in       0.44 seconds,   11664.30 req/s,      75.12 MB/s,          0 failures,    38.5% header compression

h2load-low-ecc256 - coachbloggzip
lsws 5.4.1      finished in       0.51 seconds,    9979.26 req/s,      63.03 MB/s,          0 failures,    95.2% header compression
nginx 1.16.1    finished in       0.45 seconds,   11169.40 req/s,      71.93 MB/s,          0 failures,    38.5% header compression
```

```
cat /opt/Benchmark/081719-084427/RESULTS.txt
############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       85.93ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    58186.2
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.13MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               41.67ms
TTFB Avg:               66.90ms
TTFB Max:               54.09ms
TTFB SD:                9.46ms

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       104.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47826.7
Total Bandwidth:        627.05KB
Bandwidth Per Second:   5.86MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               67.82ms
TTFB Avg:               75.42ms
TTFB Max:               72.15ms
TTFB SD:                2.23ms

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       93.03ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53743.7
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.58MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               57.62ms
TTFB Avg:               68.58ms
TTFB Max:               63.05ms
TTFB SD:                3.54ms

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       89.32ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    55980.3
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.86MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               55.16ms
TTFB Avg:               63.93ms
TTFB Max:               61.04ms
TTFB SD:                2.02ms

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       100.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    49729.4
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               57.45ms
TTFB Avg:               67.49ms
TTFB Max:               63.14ms
TTFB SD:                2.13ms

############### lsws-1kstatic.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       176.81ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    28279.5
Total Bandwidth:        627.05KB
Bandwidth Per Second:   3.46MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               133.01ms
TTFB Avg:               145.34ms
TTFB Max:               139.64ms
TTFB SD:                3.54ms

############### lsws-1kstatic.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       94.30ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53022.2
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.49MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               53.02ms
TTFB Avg:               71.94ms
TTFB Max:               63.86ms
TTFB SD:                3.76ms

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       86.45ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    57836.9
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.08MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               54.11ms
TTFB Avg:               62.28ms
TTFB Max:               59.11ms
TTFB SD:                2.29ms

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       86.79ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    57612.3
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.06MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               55.37ms
TTFB Avg:               63.19ms
TTFB Max:               59.89ms
TTFB SD:                2.14ms

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       95.96ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    52106.1
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.38MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               57.68ms
TTFB Avg:               67.25ms
TTFB Max:               63.91ms
TTFB SD:                2.50ms

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       97.75ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    51150.3
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.26MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               62.74ms
TTFB Avg:               69.36ms
TTFB Max:               65.83ms
TTFB SD:                2.22ms

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       94.06ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53159.2
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.51MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               59.87ms
TTFB Avg:               66.47ms
TTFB Max:               63.44ms
TTFB SD:                2.21ms

############### lsws-1kgzip-static.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       104.58ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47812.5
Total Bandwidth:        627.05KB
Bandwidth Per Second:   5.86MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               44.91ms
TTFB Avg:               77.43ms
TTFB Max:               67.54ms
TTFB SD:                8.37ms

############### lsws-1kgzip-static.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       116.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    42903.7
Total Bandwidth:        627.05KB
Bandwidth Per Second:   5.25MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               54.15ms
TTFB Avg:               62.02ms
TTFB Max:               58.67ms
TTFB SD:                2.01ms

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       804.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6214.5
Total Bandwidth:        50.46MB
Bandwidth Per Second:   62.72MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.32%
TTFB Min:               64.45ms
TTFB Avg:               108.21ms
TTFB Max:               83.97ms
TTFB SD:                12.74ms

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       619.76ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8067.6
Total Bandwidth:        50.46MB
Bandwidth Per Second:   81.42MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.32%
TTFB Min:               59.52ms
TTFB Avg:               82.59ms
TTFB Max:               73.71ms
TTFB SD:                6.68ms

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       611.58ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8175.6
Total Bandwidth:        50.46MB
Bandwidth Per Second:   82.51MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.48%
TTFB Min:               56.52ms
TTFB Avg:               75.42ms
TTFB Max:               64.52ms
TTFB SD:                4.37ms

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.64s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    885.4
Total Bandwidth:        50.42MB
Bandwidth Per Second:   8.94MB
Total Failures:         4
Status Code Stats:      4996 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.57%
TTFB Min:               58.49ms
TTFB Avg:               69.97ms
TTFB Max:               65.06ms
TTFB SD:                2.89ms

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       765.97ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6527.7
Total Bandwidth:        50.46MB
Bandwidth Per Second:   65.88MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.58%
TTFB Min:               60.12ms
TTFB Avg:               85.28ms
TTFB Max:               77.53ms
TTFB SD:                5.58ms

############### lsws-amdepyc2.jpg.webp.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       773.28ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6465.9
Total Bandwidth:        50.46MB
Bandwidth Per Second:   65.25MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.58%
TTFB Min:               60.75ms
TTFB Avg:               82.14ms
TTFB Max:               73.83ms
TTFB SD:                5.95ms

############### lsws-amdepyc2.jpg.webp.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       636.08ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7860.7
Total Bandwidth:        50.46MB
Bandwidth Per Second:   79.33MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.58%
TTFB Min:               63.48ms
TTFB Avg:               98.51ms
TTFB Max:               80.23ms
TTFB SD:                12.49ms

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       110.70ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    45167.9
Total Bandwidth:        19.43MB
Bandwidth Per Second:   175.52MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               52.63ms
TTFB Avg:               70.24ms
TTFB Max:               59.58ms
TTFB SD:                4.10ms

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       133.69ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    37401.0
Total Bandwidth:        19.43MB
Bandwidth Per Second:   145.34MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               58.28ms
TTFB Avg:               77.71ms
TTFB Max:               69.36ms
TTFB SD:                5.66ms

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       136.37ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36665.4
Total Bandwidth:        19.43MB
Bandwidth Per Second:   142.48MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               59.00ms
TTFB Avg:               82.21ms
TTFB Max:               70.70ms
TTFB SD:                7.94ms

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       134.29ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    37231.4
Total Bandwidth:        19.43MB
Bandwidth Per Second:   144.68MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               58.16ms
TTFB Avg:               79.58ms
TTFB Max:               70.00ms
TTFB SD:                7.26ms

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       135.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36919.1
Total Bandwidth:        19.43MB
Bandwidth Per Second:   143.49MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.27%
TTFB Min:               59.80ms
TTFB Avg:               79.79ms
TTFB Max:               70.60ms
TTFB SD:                6.52ms

############### lsws-wp_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       145.31ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34409.1
Total Bandwidth:        19.43MB
Bandwidth Per Second:   133.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               55.77ms
TTFB Avg:               84.09ms
TTFB Max:               67.30ms
TTFB SD:                8.89ms

############### lsws-wp_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       135.45ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36915.3
Total Bandwidth:        19.43MB
Bandwidth Per Second:   143.45MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               59.40ms
TTFB Avg:               81.47ms
TTFB Max:               71.35ms
TTFB SD:                7.56ms

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       533.88ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9365.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   59.15MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.23%
TTFB Min:               56.93ms
TTFB Avg:               83.26ms
TTFB Max:               74.80ms
TTFB SD:                6.41ms

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       396.17ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12620.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   79.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               66.24ms
TTFB Avg:               93.59ms
TTFB Max:               80.75ms
TTFB SD:                8.92ms

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       589.97ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8474.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   53.53MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     94.95%
TTFB Min:               59.38ms
TTFB Avg:               85.17ms
TTFB Max:               71.78ms
TTFB SD:                7.25ms

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       393.06ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12720.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   80.34MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.23%
TTFB Min:               61.31ms
TTFB Avg:               94.81ms
TTFB Max:               73.84ms
TTFB SD:                8.88ms

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       547.02ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9140.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   57.73MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               37.30ms
TTFB Avg:               92.68ms
TTFB Max:               73.86ms
TTFB SD:                14.05ms

############### lsws-coachblog_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       357.08ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14002.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   88.45MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     94.96%
TTFB Min:               55.48ms
TTFB Avg:               75.87ms
TTFB Max:               61.52ms
TTFB SD:                5.41ms

############### lsws-coachblog_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       372.21ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13433.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   84.84MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               57.46ms
TTFB Avg:               71.46ms
TTFB Max:               65.19ms
TTFB SD:                3.49ms

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       351.49ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14224.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   89.85MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.01%
TTFB Min:               46.27ms
TTFB Avg:               82.08ms
TTFB Max:               65.53ms
TTFB SD:                10.89ms

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       349.12ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14321.6
Total Bandwidth:        31.58MB
Bandwidth Per Second:   90.45MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               53.90ms
TTFB Avg:               69.80ms
TTFB Max:               60.34ms
TTFB SD:                3.51ms

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       376.13ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13293.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   83.96MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.03%
TTFB Min:               59.73ms
TTFB Avg:               83.84ms
TTFB Max:               72.62ms
TTFB SD:                8.28ms

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       540.18ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9256.1
Total Bandwidth:        31.58MB
Bandwidth Per Second:   58.46MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               59.45ms
TTFB Avg:               87.38ms
TTFB Max:               73.04ms
TTFB SD:                7.84ms

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       538.72ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9281.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   58.62MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.59ms
TTFB Avg:               85.55ms
TTFB Max:               73.61ms
TTFB SD:                8.60ms

############### lsws-coachbloggzip_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       533.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9376.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   59.23MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.00%
TTFB Min:               61.71ms
TTFB Avg:               85.46ms
TTFB Max:               73.42ms
TTFB SD:                7.18ms

############### lsws-coachbloggzip_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       541.44ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9234.6
Total Bandwidth:        31.58MB
Bandwidth Per Second:   58.32MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.61ms
TTFB Avg:               85.26ms
TTFB Max:               73.95ms
TTFB SD:                7.96ms

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       83.12ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    60152.5
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.37MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               52.08ms
TTFB Avg:               60.06ms
TTFB Max:               57.35ms
TTFB SD:                2.12ms

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       99.21ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    50400.6
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.17MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.02ms
TTFB Avg:               66.13ms
TTFB Max:               61.98ms
TTFB SD:                3.28ms

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       85.22ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    58671.6
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.19MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               52.46ms
TTFB Avg:               60.62ms
TTFB Max:               57.79ms
TTFB SD:                2.11ms

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       97.61ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    51222.1
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.27MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               52.96ms
TTFB Avg:               61.07ms
TTFB Max:               58.28ms
TTFB SD:                2.27ms

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       93.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53426.7
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.54MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               55.93ms
TTFB Avg:               65.80ms
TTFB Max:               61.85ms
TTFB SD:                3.27ms

############### lsws-1kstatic.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       95.74ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    52223.6
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.40MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.05ms
TTFB Avg:               66.69ms
TTFB Max:               62.05ms
TTFB SD:                3.56ms

############### lsws-1kstatic.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       104.45ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47871.1
Total Bandwidth:        627.05KB
Bandwidth Per Second:   5.86MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               68.16ms
TTFB Avg:               75.59ms
TTFB Max:               71.80ms
TTFB SD:                2.29ms

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       84.17ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    59407.1
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               51.90ms
TTFB Avg:               61.69ms
TTFB Max:               58.05ms
TTFB SD:                1.98ms

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       93.50ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53476.5
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.55MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.65ms
TTFB Avg:               67.62ms
TTFB Max:               62.75ms
TTFB SD:                3.81ms

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       93.84ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53284.4
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.53MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               51.97ms
TTFB Avg:               69.30ms
TTFB Max:               62.51ms
TTFB SD:                3.34ms

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       98.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    50816.1
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.22MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               54.33ms
TTFB Avg:               75.07ms
TTFB Max:               66.16ms
TTFB SD:                6.14ms

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       100.79ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    49609.0
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.08MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               48.61ms
TTFB Avg:               77.36ms
TTFB Max:               66.81ms
TTFB SD:                9.58ms

############### lsws-1kgzip-static.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       95.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    52331.9
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.41MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               57.88ms
TTFB Avg:               69.14ms
TTFB Max:               63.95ms
TTFB SD:                3.94ms

############### lsws-1kgzip-static.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       92.86ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53845.0
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.59MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               55.76ms
TTFB Avg:               65.90ms
TTFB Max:               61.72ms
TTFB SD:                3.45ms

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.54s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    901.7
Total Bandwidth:        50.45MB
Bandwidth Per Second:   9.10MB
Total Failures:         1
Status Code Stats:      4999 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.57%
TTFB Min:               54.43ms
TTFB Avg:               73.64ms
TTFB Max:               63.38ms
TTFB SD:                5.19ms

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       574.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8704.2
Total Bandwidth:        50.46MB
Bandwidth Per Second:   87.84MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.58%
TTFB Min:               53.04ms
TTFB Avg:               66.06ms
TTFB Max:               60.28ms
TTFB SD:                3.59ms

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       744.90ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6712.3
Total Bandwidth:        50.46MB
Bandwidth Per Second:   67.75MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.31%
TTFB Min:               53.04ms
TTFB Avg:               71.36ms
TTFB Max:               60.31ms
TTFB SD:                3.96ms

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       601.58ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8311.5
Total Bandwidth:        50.46MB
Bandwidth Per Second:   83.88MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.31%
TTFB Min:               63.74ms
TTFB Avg:               96.59ms
TTFB Max:               77.87ms
TTFB SD:                10.50ms

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       591.76ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8449.3
Total Bandwidth:        50.46MB
Bandwidth Per Second:   85.27MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.46%
TTFB Min:               52.53ms
TTFB Avg:               84.68ms
TTFB Max:               61.31ms
TTFB SD:                7.22ms

############### lsws-amdepyc2.jpg.webp.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       612.32ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8165.6
Total Bandwidth:        50.46MB
Bandwidth Per Second:   82.41MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.58%
TTFB Min:               45.42ms
TTFB Avg:               95.79ms
TTFB Max:               73.46ms
TTFB SD:                16.93ms

############### lsws-amdepyc2.jpg.webp.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.53s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    903.2
Total Bandwidth:        50.43MB
Bandwidth Per Second:   9.12MB
Total Failures:         3
Status Code Stats:      4997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.57%
TTFB Min:               53.93ms
TTFB Avg:               69.36ms
TTFB Max:               61.73ms
TTFB SD:                4.50ms

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       147.20ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33966.4
Total Bandwidth:        19.43MB
Bandwidth Per Second:   132.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.32%
TTFB Min:               61.30ms
TTFB Avg:               85.64ms
TTFB Max:               74.41ms
TTFB SD:                8.21ms

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       147.58ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33879.7
Total Bandwidth:        19.43MB
Bandwidth Per Second:   131.66MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               42.59ms
TTFB Avg:               91.22ms
TTFB Max:               65.60ms
TTFB SD:                17.70ms

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       170.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    29295.4
Total Bandwidth:        19.43MB
Bandwidth Per Second:   113.84MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               69.35ms
TTFB Avg:               97.97ms
TTFB Max:               82.94ms
TTFB SD:                10.21ms

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       137.47ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36372.1
Total Bandwidth:        19.43MB
Bandwidth Per Second:   141.38MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.17%
TTFB Min:               59.19ms
TTFB Avg:               79.90ms
TTFB Max:               71.40ms
TTFB SD:                6.64ms

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       133.71ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    37395.2
Total Bandwidth:        19.43MB
Bandwidth Per Second:   145.32MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               59.13ms
TTFB Avg:               83.22ms
TTFB Max:               70.80ms
TTFB SD:                7.77ms

############### lsws-wp_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       121.62ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    41110.6
Total Bandwidth:        19.43MB
Bandwidth Per Second:   159.76MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               43.05ms
TTFB Avg:               69.03ms
TTFB Max:               58.48ms
TTFB SD:                6.09ms

############### lsws-wp_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       136.75ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36563.8
Total Bandwidth:        19.43MB
Bandwidth Per Second:   142.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               58.91ms
TTFB Avg:               83.55ms
TTFB Max:               68.26ms
TTFB SD:                5.10ms

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       530.50ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9425.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   59.53MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               61.33ms
TTFB Avg:               94.62ms
TTFB Max:               74.02ms
TTFB SD:                8.78ms

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       558.27ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8956.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   56.57MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.04%
TTFB Min:               55.06ms
TTFB Avg:               77.04ms
TTFB Max:               65.73ms
TTFB SD:                5.71ms

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       398.92ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12533.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   79.16MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               65.71ms
TTFB Avg:               92.44ms
TTFB Max:               79.89ms
TTFB SD:                8.93ms

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       535.85ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9331.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   58.94MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.00%
TTFB Min:               54.61ms
TTFB Avg:               79.79ms
TTFB Max:               63.60ms
TTFB SD:                5.76ms

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       367.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13603.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   85.91MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               52.50ms
TTFB Avg:               73.47ms
TTFB Max:               60.82ms
TTFB SD:                5.71ms

############### lsws-coachblog_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       388.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12864.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   81.24MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.15ms
TTFB Avg:               89.77ms
TTFB Max:               72.04ms
TTFB SD:                8.47ms

############### lsws-coachblog_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       535.28ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9340.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   59.00MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.06%
TTFB Min:               60.10ms
TTFB Avg:               83.31ms
TTFB Max:               72.13ms
TTFB SD:                7.48ms

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       537.86ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9296.1
Total Bandwidth:        31.58MB
Bandwidth Per Second:   58.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               58.85ms
TTFB Avg:               82.39ms
TTFB Max:               72.69ms
TTFB SD:                5.21ms

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       552.81ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9044.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   57.12MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.33ms
TTFB Avg:               85.81ms
TTFB Max:               73.82ms
TTFB SD:                8.65ms

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       507.77ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9846.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   62.19MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.10%
TTFB Min:               56.03ms
TTFB Avg:               72.91ms
TTFB Max:               63.60ms
TTFB SD:                4.60ms

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       389.51ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12836.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   81.07MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               52.17ms
TTFB Avg:               98.58ms
TTFB Max:               67.55ms
TTFB SD:                12.13ms

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       342.22ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    14610.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   92.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     94.98%
TTFB Min:               53.59ms
TTFB Avg:               76.86ms
TTFB Max:               62.36ms
TTFB SD:                5.35ms

############### lsws-coachbloggzip_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       383.74ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13029.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   82.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               61.82ms
TTFB Avg:               87.08ms
TTFB Max:               74.68ms
TTFB SD:                8.61ms

############### lsws-coachbloggzip_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       577.68ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8655.2
Total Bandwidth:        31.58MB
Bandwidth Per Second:   54.67MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.06%
TTFB Min:               55.28ms
TTFB Avg:               109.59ms
TTFB Max:               82.71ms
TTFB SD:                20.13ms

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       99.50ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    50249.2
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.15MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               58.05ms
TTFB Avg:               71.58ms
TTFB Max:               64.54ms
TTFB SD:                4.56ms

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       99.77ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    50113.7
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.14MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               59.22ms
TTFB Avg:               71.21ms
TTFB Max:               65.75ms
TTFB SD:                4.10ms

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       94.06ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53158.6
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.51MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.62ms
TTFB Avg:               65.76ms
TTFB Max:               62.47ms
TTFB SD:                2.65ms

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       99.18ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    50412.8
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.17MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               58.93ms
TTFB Avg:               71.58ms
TTFB Max:               65.45ms
TTFB SD:                4.39ms

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       91.70ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    54524.4
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.68MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               55.75ms
TTFB Avg:               66.33ms
TTFB Max:               61.62ms
TTFB SD:                3.62ms

############### lsws-1kstatic.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       88.02ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    56807.2
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.96MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               54.75ms
TTFB Avg:               63.80ms
TTFB Max:               60.50ms
TTFB SD:                2.78ms

############### lsws-1kstatic.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       91.62ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    54572.0
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.68MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.77ms
TTFB Avg:               66.79ms
TTFB Max:               62.44ms
TTFB SD:                3.43ms

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       97.57ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    51243.1
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               58.39ms
TTFB Avg:               71.54ms
TTFB Max:               64.85ms
TTFB SD:                4.35ms

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       84.80ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    58962.2
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.22MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               53.15ms
TTFB Avg:               62.21ms
TTFB Max:               58.40ms
TTFB SD:                2.77ms

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       92.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    54000.3
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.61MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.19ms
TTFB Avg:               66.12ms
TTFB Max:               62.17ms
TTFB SD:                3.38ms

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       93.09ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53709.1
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.58MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               55.74ms
TTFB Avg:               66.13ms
TTFB Max:               61.89ms
TTFB SD:                3.07ms

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       92.94ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    53800.4
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.59MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.53ms
TTFB Avg:               66.79ms
TTFB Max:               62.52ms
TTFB SD:                3.54ms

############### lsws-1kgzip-static.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       83.04ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    60212.6
Total Bandwidth:        627.05KB
Bandwidth Per Second:   7.37MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               52.26ms
TTFB Avg:               60.58ms
TTFB Max:               57.32ms
TTFB SD:                2.55ms

############### lsws-1kgzip-static.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       92.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    54093.8
Total Bandwidth:        627.05KB
Bandwidth Per Second:   6.62MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.22%
TTFB Min:               56.18ms
TTFB Avg:               67.23ms
TTFB Max:               62.17ms
TTFB SD:                3.69ms

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       586.45ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8525.9
Total Bandwidth:        50.46MB
Bandwidth Per Second:   86.05MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.31%
TTFB Min:               55.43ms
TTFB Avg:               88.36ms
TTFB Max:               63.22ms
TTFB SD:                7.19ms

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.54s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    900.5
Total Bandwidth:        50.33MB
Bandwidth Per Second:   9.09MB
Total Failures:         13
Status Code Stats:      4987 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.46%
TTFB Min:               52.73ms
TTFB Avg:               74.47ms
TTFB Max:               60.71ms
TTFB SD:                5.23ms

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       775.95ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6443.7
Total Bandwidth:        50.46MB
Bandwidth Per Second:   65.03MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.57%
TTFB Min:               63.07ms
TTFB Avg:               81.02ms
TTFB Max:               72.12ms
TTFB SD:                5.65ms

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.59s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    894.6
Total Bandwidth:        50.45MB
Bandwidth Per Second:   9.03MB
Total Failures:         1
Status Code Stats:      4999 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.57%
TTFB Min:               53.85ms
TTFB Avg:               69.46ms
TTFB Max:               62.00ms
TTFB SD:                3.90ms

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.36s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    931.4
Total Bandwidth:        50.43MB
Bandwidth Per Second:   9.40MB
Total Failures:         3
Status Code Stats:      4997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.57%
TTFB Min:               62.07ms
TTFB Avg:               87.83ms
TTFB Max:               75.18ms
TTFB SD:                8.83ms

############### lsws-amdepyc2.jpg.webp.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.12s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    976.0
Total Bandwidth:        50.43MB
Bandwidth Per Second:   9.85MB
Total Failures:         3
Status Code Stats:      4997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.47%
TTFB Min:               53.78ms
TTFB Avg:               68.67ms
TTFB Max:               60.35ms
TTFB SD:                3.26ms

############### lsws-amdepyc2.jpg.webp.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.13s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    974.3
Total Bandwidth:        50.43MB
Bandwidth Per Second:   9.83MB
Total Failures:         3
Status Code Stats:      4997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.30%
TTFB Min:               54.36ms
TTFB Avg:               75.60ms
TTFB Max:               63.42ms
TTFB SD:                6.41ms

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       144.12ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34693.5
Total Bandwidth:        19.43MB
Bandwidth Per Second:   134.82MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               59.14ms
TTFB Avg:               80.12ms
TTFB Max:               70.53ms
TTFB SD:                6.86ms

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       125.30ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    39905.5
Total Bandwidth:        19.43MB
Bandwidth Per Second:   155.07MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               54.07ms
TTFB Avg:               65.51ms
TTFB Max:               59.15ms
TTFB SD:                2.48ms

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       122.84ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    40702.0
Total Bandwidth:        19.43MB
Bandwidth Per Second:   158.17MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               53.69ms
TTFB Avg:               74.24ms
TTFB Max:               60.75ms
TTFB SD:                4.62ms

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       126.29ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    39592.3
Total Bandwidth:        19.43MB
Bandwidth Per Second:   153.86MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.41%
TTFB Min:               53.07ms
TTFB Avg:               72.83ms
TTFB Max:               60.40ms
TTFB SD:                4.46ms

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       143.51ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34841.2
Total Bandwidth:        19.43MB
Bandwidth Per Second:   135.39MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               55.66ms
TTFB Avg:               99.57ms
TTFB Max:               72.65ms
TTFB SD:                8.21ms

############### lsws-wp_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       176.28ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    28363.6
Total Bandwidth:        19.43MB
Bandwidth Per Second:   110.22MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.42%
TTFB Min:               78.91ms
TTFB Avg:               101.02ms
TTFB Max:               91.12ms
TTFB SD:                6.88ms

############### lsws-wp_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       217.18ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    23022.4
Total Bandwidth:        19.43MB
Bandwidth Per Second:   89.49MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.17%
TTFB Min:               43.09ms
TTFB Avg:               128.63ms
TTFB Max:               76.00ms
TTFB SD:                20.47ms

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       412.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12118.5
Total Bandwidth:        31.58MB
Bandwidth Per Second:   76.54MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               63.23ms
TTFB Avg:               102.91ms
TTFB Max:               77.62ms
TTFB SD:                12.34ms

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       558.90ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8946.0
Total Bandwidth:        31.58MB
Bandwidth Per Second:   56.50MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.09%
TTFB Min:               64.40ms
TTFB Avg:               92.61ms
TTFB Max:               78.00ms
TTFB SD:                9.73ms

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       411.64ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12146.6
Total Bandwidth:        31.58MB
Bandwidth Per Second:   76.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               62.73ms
TTFB Avg:               89.40ms
TTFB Max:               77.03ms
TTFB SD:                8.92ms

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       389.57ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12834.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   81.06MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               58.52ms
TTFB Avg:               94.72ms
TTFB Max:               73.55ms
TTFB SD:                10.84ms

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       533.94ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9364.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   59.14MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               52.87ms
TTFB Avg:               73.72ms
TTFB Max:               62.08ms
TTFB SD:                6.36ms

############### lsws-coachblog_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       561.94ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8897.7
Total Bandwidth:        31.58MB
Bandwidth Per Second:   56.19MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               71.45ms
TTFB Avg:               88.03ms
TTFB Max:               79.63ms
TTFB SD:                4.64ms

############### lsws-coachblog_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       386.91ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12922.9
Total Bandwidth:        31.58MB
Bandwidth Per Second:   81.62MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.80ms
TTFB Avg:               85.85ms
TTFB Max:               74.03ms
TTFB SD:                8.24ms

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       559.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8940.6
Total Bandwidth:        31.58MB
Bandwidth Per Second:   56.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               64.22ms
TTFB Avg:               94.06ms
TTFB Max:               78.22ms
TTFB SD:                10.31ms

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       545.04ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9173.6
Total Bandwidth:        31.58MB
Bandwidth Per Second:   57.94MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               59.42ms
TTFB Avg:               91.84ms
TTFB Max:               72.89ms
TTFB SD:                8.91ms

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       525.77ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9509.8
Total Bandwidth:        31.58MB
Bandwidth Per Second:   60.07MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     94.95%
TTFB Min:               53.32ms
TTFB Avg:               84.82ms
TTFB Max:               62.32ms
TTFB SD:                6.44ms

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       529.92ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9435.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   59.59MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.25%
TTFB Min:               59.49ms
TTFB Avg:               81.38ms
TTFB Max:               74.23ms
TTFB SD:                5.46ms

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       547.38ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9134.4
Total Bandwidth:        31.58MB
Bandwidth Per Second:   57.69MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.29ms
TTFB Avg:               90.15ms
TTFB Max:               72.70ms
TTFB SD:                9.31ms

############### lsws-coachbloggzip_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       411.98ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12136.6
Total Bandwidth:        31.58MB
Bandwidth Per Second:   76.65MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.45ms
TTFB Avg:               87.94ms
TTFB Max:               74.94ms
TTFB SD:                9.04ms

############### lsws-coachbloggzip_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       378.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13212.3
Total Bandwidth:        31.58MB
Bandwidth Per Second:   83.44MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     95.26%
TTFB Min:               60.02ms
TTFB Avg:               85.30ms
TTFB Max:               73.28ms
TTFB SD:                8.34ms

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       138.66ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36059.1
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.05MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               56.25ms
TTFB Avg:               80.42ms
TTFB Max:               71.32ms
TTFB SD:                5.68ms

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       125.84ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    39734.5
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.87MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               54.48ms
TTFB Avg:               78.72ms
TTFB Max:               64.71ms
TTFB SD:                8.34ms

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       109.65ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    45600.8
Total Bandwidth:        1.12MB
Bandwidth Per Second:   10.18MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               40.33ms
TTFB Avg:               72.08ms
TTFB Max:               58.57ms
TTFB SD:                9.61ms

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       139.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    35883.7
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               42.37ms
TTFB Avg:               102.79ms
TTFB Max:               68.72ms
TTFB SD:                18.43ms

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       130.71ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    38252.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.54MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               47.52ms
TTFB Avg:               84.57ms
TTFB Max:               62.55ms
TTFB SD:                12.90ms

############### nginx-1kstatic.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       125.44ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    39860.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.89MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               41.07ms
TTFB Avg:               79.82ms
TTFB Max:               61.75ms
TTFB SD:                12.46ms

############### nginx-1kstatic.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       130.22ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    38395.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.57MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               53.80ms
TTFB Avg:               85.98ms
TTFB Max:               65.57ms
TTFB SD:                8.13ms

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       105.88ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47225.0
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.39MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               54.35ms
TTFB Avg:               67.10ms
TTFB Max:               60.10ms
TTFB SD:                3.02ms

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       107.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    46540.2
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.23MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               52.94ms
TTFB Avg:               66.06ms
TTFB Max:               59.42ms
TTFB SD:                3.55ms

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       105.63ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47333.2
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.42MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               54.02ms
TTFB Avg:               66.49ms
TTFB Max:               59.55ms
TTFB SD:                2.98ms

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       148.61ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33645.3
Total Bandwidth:        1.21MB
Bandwidth Per Second:   8.12MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               65.76ms
TTFB Avg:               88.61ms
TTFB Max:               78.94ms
TTFB SD:                6.66ms

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       108.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    46190.2
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.14MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               53.68ms
TTFB Avg:               68.15ms
TTFB Max:               60.14ms
TTFB SD:                3.57ms

############### nginx-1kgzip-static.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       108.15ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    46232.5
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.15MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               51.98ms
TTFB Avg:               68.58ms
TTFB Max:               60.97ms
TTFB SD:                4.13ms

############### nginx-1kgzip-static.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       105.90ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47215.6
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.39MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               53.99ms
TTFB Avg:               66.96ms
TTFB Max:               59.84ms
TTFB SD:                3.09ms

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       609.88ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8198.3
Total Bandwidth:        50.96MB
Bandwidth Per Second:   83.56MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.87ms
TTFB Avg:               81.65ms
TTFB Max:               63.51ms
TTFB SD:                6.20ms

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       603.30ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8287.8
Total Bandwidth:        50.96MB
Bandwidth Per Second:   84.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.63ms
TTFB Avg:               80.34ms
TTFB Max:               66.74ms
TTFB SD:                7.47ms

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       607.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8232.6
Total Bandwidth:        50.96MB
Bandwidth Per Second:   83.91MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               49.76ms
TTFB Avg:               81.26ms
TTFB Max:               63.34ms
TTFB SD:                9.60ms

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       593.60ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8423.1
Total Bandwidth:        50.96MB
Bandwidth Per Second:   85.85MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.82ms
TTFB Avg:               80.34ms
TTFB Max:               62.94ms
TTFB SD:                6.60ms

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       759.43ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6583.8
Total Bandwidth:        50.96MB
Bandwidth Per Second:   67.10MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.19ms
TTFB Avg:               79.80ms
TTFB Max:               63.24ms
TTFB SD:                6.83ms

############### nginx-amdepyc2.jpg.webp.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       585.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8541.9
Total Bandwidth:        50.96MB
Bandwidth Per Second:   87.06MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.95ms
TTFB Avg:               79.99ms
TTFB Max:               63.78ms
TTFB SD:                6.90ms

############### nginx-amdepyc2.jpg.webp.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       629.57ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7941.9
Total Bandwidth:        50.96MB
Bandwidth Per Second:   80.94MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               40.21ms
TTFB Avg:               98.56ms
TTFB Max:               72.69ms
TTFB SD:                19.91ms

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       608.53ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8216.5
Total Bandwidth:        20.33MB
Bandwidth Per Second:   33.41MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.39ms
TTFB Avg:               210.85ms
TTFB Max:               102.42ms
TTFB SD:                33.59ms

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       570.00ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8771.9
Total Bandwidth:        20.33MB
Bandwidth Per Second:   35.67MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               54.02ms
TTFB Avg:               221.50ms
TTFB Max:               96.45ms
TTFB SD:                40.70ms

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       472.50ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10582.0
Total Bandwidth:        20.33MB
Bandwidth Per Second:   43.03MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               53.49ms
TTFB Avg:               143.87ms
TTFB Max:               88.14ms
TTFB SD:                25.71ms

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       489.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10219.7
Total Bandwidth:        20.33MB
Bandwidth Per Second:   41.56MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               56.65ms
TTFB Avg:               192.86ms
TTFB Max:               103.32ms
TTFB SD:                35.77ms

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       475.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10513.2
Total Bandwidth:        20.33MB
Bandwidth Per Second:   42.75MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.78ms
TTFB Avg:               141.29ms
TTFB Max:               91.31ms
TTFB SD:                25.85ms

############### nginx-wp_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       513.71ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9733.1
Total Bandwidth:        20.33MB
Bandwidth Per Second:   39.58MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               59.79ms
TTFB Avg:               203.30ms
TTFB Max:               100.08ms
TTFB SD:                36.74ms

############### nginx-wp_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       514.55ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9717.3
Total Bandwidth:        20.33MB
Bandwidth Per Second:   39.51MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               57.34ms
TTFB Avg:               150.91ms
TTFB Max:               92.59ms
TTFB SD:                26.63ms

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       878.60ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5690.9
Total Bandwidth:        38.05MB
Bandwidth Per Second:   43.31MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               55.03ms
TTFB Avg:               232.58ms
TTFB Max:               125.63ms
TTFB SD:                47.45ms

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       827.98ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6038.7
Total Bandwidth:        38.05MB
Bandwidth Per Second:   45.96MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               51.19ms
TTFB Avg:               302.54ms
TTFB Max:               134.50ms
TTFB SD:                71.15ms

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       841.86ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5939.2
Total Bandwidth:        38.05MB
Bandwidth Per Second:   45.20MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               62.33ms
TTFB Avg:               300.76ms
TTFB Max:               145.32ms
TTFB SD:                70.40ms

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       828.40ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6035.7
Total Bandwidth:        38.05MB
Bandwidth Per Second:   45.93MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               63.57ms
TTFB Avg:               274.12ms
TTFB Max:               142.96ms
TTFB SD:                68.67ms

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       816.12ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6126.5
Total Bandwidth:        38.05MB
Bandwidth Per Second:   46.62MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               62.05ms
TTFB Avg:               214.41ms
TTFB Max:               133.07ms
TTFB SD:                51.76ms

############### nginx-coachblog_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       985.41ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5074.0
Total Bandwidth:        38.05MB
Bandwidth Per Second:   38.61MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               55.27ms
TTFB Avg:               448.93ms
TTFB Max:               164.50ms
TTFB SD:                105.69ms

############### nginx-coachblog_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       857.92ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5828.0
Total Bandwidth:        38.05MB
Bandwidth Per Second:   44.35MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               54.47ms
TTFB Avg:               228.88ms
TTFB Max:               128.84ms
TTFB SD:                48.99ms

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       394.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12682.2
Total Bandwidth:        32.20MB
Bandwidth Per Second:   81.68MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               61.47ms
TTFB Avg:               84.50ms
TTFB Max:               73.99ms
TTFB SD:                6.45ms

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       404.76ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12353.0
Total Bandwidth:        32.20MB
Bandwidth Per Second:   79.56MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               62.99ms
TTFB Avg:               91.61ms
TTFB Max:               77.92ms
TTFB SD:                7.22ms

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       402.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12421.2
Total Bandwidth:        32.20MB
Bandwidth Per Second:   79.99MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               62.72ms
TTFB Avg:               89.18ms
TTFB Max:               78.86ms
TTFB SD:                7.35ms

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       600.01ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8333.2
Total Bandwidth:        32.20MB
Bandwidth Per Second:   53.67MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               62.96ms
TTFB Avg:               93.84ms
TTFB Max:               81.85ms
TTFB SD:                8.95ms

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       507.31ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9855.9
Total Bandwidth:        32.20MB
Bandwidth Per Second:   63.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               50.12ms
TTFB Avg:               69.58ms
TTFB Max:               62.50ms
TTFB SD:                4.98ms

############### nginx-coachbloggzip_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       509.03ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9822.5
Total Bandwidth:        32.20MB
Bandwidth Per Second:   63.26MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               53.24ms
TTFB Avg:               68.35ms
TTFB Max:               60.40ms
TTFB SD:                3.68ms

############### nginx-coachbloggzip_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       516.94ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9672.2
Total Bandwidth:        32.20MB
Bandwidth Per Second:   62.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               52.81ms
TTFB Avg:               68.03ms
TTFB Max:               62.00ms
TTFB SD:                4.14ms

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       137.51ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36359.9
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.11MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               59.21ms
TTFB Avg:               81.51ms
TTFB Max:               72.41ms
TTFB SD:                5.75ms

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       112.48ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    44453.1
Total Bandwidth:        1.12MB
Bandwidth Per Second:   9.92MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               49.99ms
TTFB Avg:               72.96ms
TTFB Max:               59.99ms
TTFB SD:                3.79ms

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       112.26ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    44541.4
Total Bandwidth:        1.12MB
Bandwidth Per Second:   9.94MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               52.21ms
TTFB Avg:               66.72ms
TTFB Max:               60.14ms
TTFB SD:                3.61ms

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       146.54ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34119.4
Total Bandwidth:        1.12MB
Bandwidth Per Second:   7.61MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               64.67ms
TTFB Avg:               95.56ms
TTFB Max:               77.31ms
TTFB SD:                6.89ms

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       143.86ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34755.7
Total Bandwidth:        1.12MB
Bandwidth Per Second:   7.76MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               63.26ms
TTFB Avg:               85.59ms
TTFB Max:               75.68ms
TTFB SD:                6.37ms

############### nginx-1kstatic.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       146.29ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34179.6
Total Bandwidth:        1.12MB
Bandwidth Per Second:   7.63MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               63.38ms
TTFB Avg:               85.40ms
TTFB Max:               76.23ms
TTFB SD:                6.64ms

############### nginx-1kstatic.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       146.88ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    34040.4
Total Bandwidth:        1.12MB
Bandwidth Per Second:   7.60MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               66.83ms
TTFB Avg:               83.38ms
TTFB Max:               76.00ms
TTFB SD:                3.91ms

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       147.49ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33901.7
Total Bandwidth:        1.21MB
Bandwidth Per Second:   8.18MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               62.30ms
TTFB Avg:               85.98ms
TTFB Max:               76.19ms
TTFB SD:                6.93ms

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       141.65ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    35298.7
Total Bandwidth:        1.21MB
Bandwidth Per Second:   8.52MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               62.19ms
TTFB Avg:               84.47ms
TTFB Max:               74.77ms
TTFB SD:                6.37ms

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       112.31ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    44521.6
Total Bandwidth:        1.21MB
Bandwidth Per Second:   10.74MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               42.93ms
TTFB Avg:               80.15ms
TTFB Max:               61.51ms
TTFB SD:                8.63ms

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       117.47ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    42565.8
Total Bandwidth:        1.21MB
Bandwidth Per Second:   10.27MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               53.06ms
TTFB Avg:               67.52ms
TTFB Max:               60.61ms
TTFB SD:                3.13ms

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       106.11ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47121.3
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.37MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               53.40ms
TTFB Avg:               66.59ms
TTFB Max:               60.69ms
TTFB SD:                3.70ms

############### nginx-1kgzip-static.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       105.13ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    47559.2
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               51.56ms
TTFB Avg:               66.51ms
TTFB Max:               59.61ms
TTFB SD:                3.74ms

############### nginx-1kgzip-static.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       109.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    45707.1
Total Bandwidth:        1.21MB
Bandwidth Per Second:   11.03MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               53.53ms
TTFB Avg:               67.83ms
TTFB Max:               61.61ms
TTFB SD:                3.47ms

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       640.15ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7810.6
Total Bandwidth:        50.96MB
Bandwidth Per Second:   79.61MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               57.55ms
TTFB Avg:               84.46ms
TTFB Max:               76.04ms
TTFB SD:                6.52ms

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       751.03ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6657.5
Total Bandwidth:        50.96MB
Bandwidth Per Second:   67.85MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.31ms
TTFB Avg:               76.93ms
TTFB Max:               61.01ms
TTFB SD:                6.06ms

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       606.58ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8242.9
Total Bandwidth:        50.96MB
Bandwidth Per Second:   84.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.17ms
TTFB Avg:               72.21ms
TTFB Max:               59.39ms
TTFB SD:                4.18ms

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       589.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8480.4
Total Bandwidth:        50.96MB
Bandwidth Per Second:   86.43MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.82ms
TTFB Avg:               71.99ms
TTFB Max:               60.69ms
TTFB SD:                4.09ms

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       621.63ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8043.3
Total Bandwidth:        50.96MB
Bandwidth Per Second:   81.98MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               56.98ms
TTFB Avg:               73.45ms
TTFB Max:               64.03ms
TTFB SD:                4.46ms

############### nginx-amdepyc2.jpg.webp.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       631.25ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7920.7
Total Bandwidth:        50.96MB
Bandwidth Per Second:   80.73MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               54.68ms
TTFB Avg:               97.39ms
TTFB Max:               78.96ms
TTFB SD:                8.95ms

############### nginx-amdepyc2.jpg.webp.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       622.08ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8037.5
Total Bandwidth:        50.96MB
Bandwidth Per Second:   81.92MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               51.95ms
TTFB Avg:               84.63ms
TTFB Max:               62.42ms
TTFB SD:                7.52ms

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       573.16ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8723.5
Total Bandwidth:        20.33MB
Bandwidth Per Second:   35.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               54.46ms
TTFB Avg:               164.45ms
TTFB Max:               94.75ms
TTFB SD:                31.00ms

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       458.02ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10916.6
Total Bandwidth:        20.33MB
Bandwidth Per Second:   44.39MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               52.52ms
TTFB Avg:               148.95ms
TTFB Max:               94.27ms
TTFB SD:                32.33ms

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       517.51ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9661.6
Total Bandwidth:        20.33MB
Bandwidth Per Second:   39.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               50.47ms
TTFB Avg:               148.98ms
TTFB Max:               89.34ms
TTFB SD:                25.26ms

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       464.09ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10773.8
Total Bandwidth:        20.33MB
Bandwidth Per Second:   43.81MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               38.17ms
TTFB Avg:               198.31ms
TTFB Max:               104.10ms
TTFB SD:                56.86ms

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       493.05ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10141.0
Total Bandwidth:        20.33MB
Bandwidth Per Second:   41.24MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               54.29ms
TTFB Avg:               182.60ms
TTFB Max:               90.84ms
TTFB SD:                29.09ms

############### nginx-wp_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       519.61ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9622.6
Total Bandwidth:        20.33MB
Bandwidth Per Second:   39.13MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.32ms
TTFB Avg:               159.36ms
TTFB Max:               93.53ms
TTFB SD:                26.80ms

############### nginx-wp_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       467.79ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10688.5
Total Bandwidth:        20.33MB
Bandwidth Per Second:   43.46MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               44.55ms
TTFB Avg:               207.06ms
TTFB Max:               110.46ms
TTFB SD:                54.57ms

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       929.99ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5376.3
Total Bandwidth:        38.05MB
Bandwidth Per Second:   40.92MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               53.25ms
TTFB Avg:               278.19ms
TTFB Max:               142.28ms
TTFB SD:                56.41ms

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       816.09ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6126.7
Total Bandwidth:        38.05MB
Bandwidth Per Second:   46.63MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               66.55ms
TTFB Avg:               293.80ms
TTFB Max:               143.34ms
TTFB SD:                67.46ms

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       811.49ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6161.4
Total Bandwidth:        38.05MB
Bandwidth Per Second:   46.89MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.99ms
TTFB Avg:               225.62ms
TTFB Max:               130.59ms
TTFB SD:                55.83ms

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       856.52ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5837.5
Total Bandwidth:        38.05MB
Bandwidth Per Second:   44.43MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.22ms
TTFB Avg:               263.82ms
TTFB Max:               133.24ms
TTFB SD:                64.32ms

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       928.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5385.6
Total Bandwidth:        38.05MB
Bandwidth Per Second:   40.99MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               63.98ms
TTFB Avg:               267.29ms
TTFB Max:               143.16ms
TTFB SD:                68.23ms

############### nginx-coachblog_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       859.38ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5818.1
Total Bandwidth:        38.05MB
Bandwidth Per Second:   44.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               55.08ms
TTFB Avg:               252.92ms
TTFB Max:               124.58ms
TTFB SD:                44.93ms

############### nginx-coachblog_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       838.36ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5964.0
Total Bandwidth:        38.05MB
Bandwidth Per Second:   45.39MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               53.15ms
TTFB Avg:               239.06ms
TTFB Max:               120.35ms
TTFB SD:                46.06ms

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       399.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12518.9
Total Bandwidth:        32.20MB
Bandwidth Per Second:   80.62MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               62.14ms
TTFB Avg:               87.54ms
TTFB Max:               77.16ms
TTFB SD:                7.07ms

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       407.32ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12275.2
Total Bandwidth:        32.20MB
Bandwidth Per Second:   79.05MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               61.77ms
TTFB Avg:               87.09ms
TTFB Max:               77.30ms
TTFB SD:                6.99ms

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       357.92ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13969.7
Total Bandwidth:        32.20MB
Bandwidth Per Second:   89.97MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               40.69ms
TTFB Avg:               83.71ms
TTFB Max:               60.15ms
TTFB SD:                14.49ms

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       521.08ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9595.4
Total Bandwidth:        32.20MB
Bandwidth Per Second:   61.80MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               60.04ms
TTFB Avg:               93.77ms
TTFB Max:               67.24ms
TTFB SD:                5.43ms

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       510.36ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9797.0
Total Bandwidth:        32.20MB
Bandwidth Per Second:   63.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               51.73ms
TTFB Avg:               76.65ms
TTFB Max:               61.54ms
TTFB SD:                5.27ms

############### nginx-coachbloggzip_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       374.00ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    13369.0
Total Bandwidth:        32.20MB
Bandwidth Per Second:   86.10MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               51.21ms
TTFB Avg:               79.60ms
TTFB Max:               61.26ms
TTFB SD:                5.24ms

############### nginx-coachbloggzip_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       563.78ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8868.6
Total Bandwidth:        32.20MB
Bandwidth Per Second:   57.12MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               55.12ms
TTFB Avg:               72.16ms
TTFB Max:               65.05ms
TTFB SD:                5.08ms

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       134.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    37158.9
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.29MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               58.52ms
TTFB Avg:               83.01ms
TTFB Max:               72.31ms
TTFB SD:                5.85ms

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       115.82ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    43170.0
Total Bandwidth:        1.12MB
Bandwidth Per Second:   9.63MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               51.99ms
TTFB Avg:               64.76ms
TTFB Max:               59.55ms
TTFB SD:                3.04ms

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       139.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    35882.6
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               59.59ms
TTFB Avg:               81.54ms
TTFB Max:               72.32ms
TTFB SD:                6.28ms

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       136.81ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36547.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.16MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               60.54ms
TTFB Avg:               82.64ms
TTFB Max:               73.08ms
TTFB SD:                6.77ms

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       135.73ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    36837.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   8.22MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               57.85ms
TTFB Avg:               80.89ms
TTFB Max:               71.33ms
TTFB SD:                6.58ms

############### nginx-1kstatic.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       147.14ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33980.7
Total Bandwidth:        1.12MB
Bandwidth Per Second:   7.58MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               64.84ms
TTFB Avg:               88.63ms
TTFB Max:               78.57ms
TTFB SD:                6.83ms

############### nginx-1kstatic.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       149.44ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    33459.3
Total Bandwidth:        1.12MB
Bandwidth Per Second:   7.47MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               69.00ms
TTFB Avg:               88.32ms
TTFB Max:               78.42ms
TTFB SD:                4.84ms

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       120.19ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    41601.4
Total Bandwidth:        1.21MB
Bandwidth Per Second:   10.04MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               53.19ms
TTFB Avg:               72.05ms
TTFB Max:               64.70ms
TTFB SD:                4.48ms

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       121.83ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    41042.4
Total Bandwidth:        1.21MB
Bandwidth Per Second:   9.90MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               55.41ms
TTFB Avg:               72.38ms
TTFB Max:               64.96ms
TTFB SD:                5.07ms

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       120.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    41473.4
Total Bandwidth:        1.21MB
Bandwidth Per Second:   10.01MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               54.90ms
TTFB Avg:               77.61ms
TTFB Max:               63.86ms
TTFB SD:                4.67ms

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       131.85ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    37923.0
Total Bandwidth:        1.21MB
Bandwidth Per Second:   9.15MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               54.78ms
TTFB Avg:               80.49ms
TTFB Max:               64.44ms
TTFB SD:                5.78ms

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       115.55ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    43271.6
Total Bandwidth:        1.21MB
Bandwidth Per Second:   10.44MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               42.47ms
TTFB Avg:               79.92ms
TTFB Max:               62.51ms
TTFB SD:                13.85ms

############### nginx-1kgzip-static.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       116.21ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    43024.4
Total Bandwidth:        1.21MB
Bandwidth Per Second:   10.38MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               51.97ms
TTFB Avg:               70.18ms
TTFB Max:               63.14ms
TTFB SD:                4.40ms

############### nginx-1kgzip-static.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       114.47ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    43681.0
Total Bandwidth:        1.21MB
Bandwidth Per Second:   10.54MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               40.60ms
TTFB Avg:               77.29ms
TTFB Max:               60.77ms
TTFB SD:                12.43ms

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       631.56ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    7916.9
Total Bandwidth:        50.96MB
Bandwidth Per Second:   80.69MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               60.15ms
TTFB Avg:               97.30ms
TTFB Max:               76.29ms
TTFB SD:                8.12ms

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       788.75ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6339.1
Total Bandwidth:        50.96MB
Bandwidth Per Second:   64.61MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               55.02ms
TTFB Avg:               85.23ms
TTFB Max:               63.80ms
TTFB SD:                7.14ms

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       597.58ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8367.1
Total Bandwidth:        50.96MB
Bandwidth Per Second:   85.28MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               57.24ms
TTFB Avg:               80.10ms
TTFB Max:               66.22ms
TTFB SD:                4.87ms

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       587.31ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8513.3
Total Bandwidth:        50.96MB
Bandwidth Per Second:   86.77MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.27ms
TTFB Avg:               80.12ms
TTFB Max:               62.17ms
TTFB SD:                5.91ms

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       798.49ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6261.8
Total Bandwidth:        50.96MB
Bandwidth Per Second:   63.82MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.96ms
TTFB Avg:               81.38ms
TTFB Max:               63.00ms
TTFB SD:                5.04ms

############### nginx-amdepyc2.jpg.webp.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       609.73ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8200.3
Total Bandwidth:        50.96MB
Bandwidth Per Second:   83.58MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               56.95ms
TTFB Avg:               86.24ms
TTFB Max:               64.77ms
TTFB SD:                5.86ms

############### nginx-amdepyc2.jpg.webp.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       609.05ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8209.4
Total Bandwidth:        50.96MB
Bandwidth Per Second:   83.67MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               55.22ms
TTFB Avg:               74.17ms
TTFB Max:               64.70ms
TTFB SD:                4.33ms

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       486.29ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10281.9
Total Bandwidth:        20.33MB
Bandwidth Per Second:   41.81MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               59.10ms
TTFB Avg:               142.97ms
TTFB Max:               94.99ms
TTFB SD:                26.55ms

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       479.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10430.0
Total Bandwidth:        20.33MB
Bandwidth Per Second:   42.41MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.23ms
TTFB Avg:               141.21ms
TTFB Max:               92.74ms
TTFB SD:                27.02ms

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       458.64ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10901.8
Total Bandwidth:        20.33MB
Bandwidth Per Second:   44.33MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               54.19ms
TTFB Avg:               178.39ms
TTFB Max:               90.52ms
TTFB SD:                33.58ms

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       530.22ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9429.9
Total Bandwidth:        20.33MB
Bandwidth Per Second:   38.35MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               51.74ms
TTFB Avg:               149.52ms
TTFB Max:               93.46ms
TTFB SD:                27.55ms

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       520.09ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9613.7
Total Bandwidth:        20.33MB
Bandwidth Per Second:   39.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.19ms
TTFB Avg:               151.42ms
TTFB Max:               94.44ms
TTFB SD:                26.99ms

############### nginx-wp_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       461.16ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    10842.2
Total Bandwidth:        20.33MB
Bandwidth Per Second:   44.09MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               52.05ms
TTFB Avg:               138.32ms
TTFB Max:               95.38ms
TTFB SD:                26.26ms

############### nginx-wp_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       569.32ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    8782.3
Total Bandwidth:        20.33MB
Bandwidth Per Second:   35.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               68.32ms
TTFB Avg:               171.45ms
TTFB Max:               103.11ms
TTFB SD:                31.66ms

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       845.59ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5913.0
Total Bandwidth:        38.05MB
Bandwidth Per Second:   45.00MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               52.78ms
TTFB Avg:               218.57ms
TTFB Max:               121.73ms
TTFB SD:                49.00ms

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       794.78ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6291.0
Total Bandwidth:        38.05MB
Bandwidth Per Second:   47.88MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               52.63ms
TTFB Avg:               239.21ms
TTFB Max:               125.35ms
TTFB SD:                58.37ms

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       928.98ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5382.2
Total Bandwidth:        38.05MB
Bandwidth Per Second:   40.96MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               52.37ms
TTFB Avg:               230.41ms
TTFB Max:               126.32ms
TTFB SD:                51.01ms

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       828.00ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6038.6
Total Bandwidth:        38.05MB
Bandwidth Per Second:   45.96MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.13ms
TTFB Avg:               210.62ms
TTFB Max:               131.23ms
TTFB SD:                43.64ms

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       869.16ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    5752.6
Total Bandwidth:        38.05MB
Bandwidth Per Second:   43.78MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               49.80ms
TTFB Avg:               229.82ms
TTFB Max:               118.54ms
TTFB SD:                51.23ms

############### nginx-coachblog_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       830.14ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6023.1
Total Bandwidth:        38.05MB
Bandwidth Per Second:   45.84MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.71ms
TTFB Avg:               257.26ms
TTFB Max:               133.11ms
TTFB SD:                56.89ms

############### nginx-coachblog_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       814.70ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    6137.2
Total Bandwidth:        38.05MB
Bandwidth Per Second:   46.71MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               54.96ms
TTFB Avg:               210.63ms
TTFB Max:               126.59ms
TTFB SD:                48.45ms

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       412.88ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12110.0
Total Bandwidth:        32.20MB
Bandwidth Per Second:   77.99MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               64.72ms
TTFB Avg:               93.37ms
TTFB Max:               81.29ms
TTFB SD:                8.23ms

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       414.46ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12063.8
Total Bandwidth:        32.20MB
Bandwidth Per Second:   77.69MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               61.53ms
TTFB Avg:               88.39ms
TTFB Max:               77.74ms
TTFB SD:                7.60ms

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       506.40ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9873.7
Total Bandwidth:        32.20MB
Bandwidth Per Second:   63.59MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               55.06ms
TTFB Avg:               70.64ms
TTFB Max:               62.66ms
TTFB SD:                3.84ms

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       508.53ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9832.1
Total Bandwidth:        32.20MB
Bandwidth Per Second:   63.32MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               52.40ms
TTFB Avg:               69.77ms
TTFB Max:               61.74ms
TTFB SD:                4.23ms

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       432.11ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    11571.1
Total Bandwidth:        32.20MB
Bandwidth Per Second:   74.52MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               55.75ms
TTFB Avg:               79.79ms
TTFB Max:               67.93ms
TTFB SD:                7.37ms

############### nginx-coachbloggzip_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       413.65ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    12087.5
Total Bandwidth:        32.20MB
Bandwidth Per Second:   77.85MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               59.35ms
TTFB Avg:               78.61ms
TTFB Max:               70.85ms
TTFB SD:                4.88ms

############### nginx-coachbloggzip_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-low-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       512.62ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         5000
Requests Per Second:    9753.7
Total Bandwidth:        32.20MB
Bandwidth Per Second:   62.82MB
Total Failures:         0
Status Code Stats:      5000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               51.77ms
TTFB Avg:               69.63ms
TTFB Max:               61.47ms
TTFB SD:                4.75ms
```