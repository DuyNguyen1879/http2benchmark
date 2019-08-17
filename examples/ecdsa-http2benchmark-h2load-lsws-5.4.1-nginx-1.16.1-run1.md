https://github.com/centminmod/http2benchmark/tree/extended-tests

* The below tests were done with Litespeed 5.4.1 and Nginx 1.16.1 on CentOS 7.6 64bit KVM VPS using $20/month Upcloud VPS servers and with latest forked version of http2benchmark which collects additional h2load metrics/info in the resulting RESULTS.txt and RESULTS.csv logs for TLS protocol tested (TLSv1.2 etc). SSL Cipher tested (ECDHE-ECDSA-AES128-GCM-SHA256 etc). and Server Temp Key used i.e. ECDH P-256 256bits and TTFB min, avg, max and std dev numbers. 
* Also included original http2benchmark added h2load's header compression metric to see how much header compresssion space savings were made. Note Litespeed web server implements the full HPACK encoding compression as per RFC7541 specs so you will see higher percentage of header compression savings compared to distro installed Nginx versions. The reason is that distro package builds of Nginx use Nginx's default partial HPACK encoding configuration - Nginx never implemented the full HPACK encoding spec for their HTTP/2 implementation. However, certain Nginx builds can be patched with full HPACK encoding compression as outlined on [Cloudflare's blog](https://blog.cloudflare.com/hpack-the-silent-killer-feature-of-http-2/). Example of Centmin Mod Nginx server with patched full HPACK encoding compression support can be seen [here](https://community.centminmod.com/threads/nginx-1-17-3-dynamtic-tls-hpack-patch-support-in-123-09beta01.18161/).

The original http2benchmark tests only tested standard RSA 2048bit SSL certificates and not the better performing ECC 256bit SSL certificates with ECDSA SSL ciphers. The forked http2benchmarks have optional support for testing ECC 256bit SSL certificates with ECDSA SSL ciphers. Part of the performance comes from smaller SSL certificate and SSL key sizes compared to RSA 2048bit SSL certificate setups. Was expecting Litespeed to have more of an advantage given that it is built with it's own crypto library using Google's BoringSSL which is a forked version of OpenSSL. BoringSSL is known to have better ECDSA performance than OpenSSL. Nginx binaries from nginx.org YUM repo are built against OpenSSL 1.0.2 usually. However, below results were mixed with Nginx beating out Litespeed in some of the below test targets. Especially for `amdepyc2.jpg.webp` image tests while the `coachbloggzip` wordpress precompress gzip tests are much closer but with Litespeed leading by ~6%. Seems Litespeed is more optimised for ECDSA 256bit instead of 128bit.

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
echo -e 'SERVER_LIST="lsws nginx"\nTOOL_LIST="h2load h2load-ecc128 h2load-ecc256"\nTARGET_LIST="1kstatic.html 1kgzip-static.html amdepyc2.jpg.webp wordpress coachblog coachbloggzip"\nROUNDNUM=7' > /opt/benchmark.ini
http2benchmark/setup/client/client.sh | tee client.log
/opt/benchmark.sh | tee benchmark.log
```

`/opt/benchmark.ini` will be populated with variables that override `/opt/benchmark.sh` - each test is ran 7x times and average taken.

```
SERVER_LIST="lsws nginx"
TOOL_LIST="h2load h2load-ecc128 h2load-ecc256"
TARGET_LIST="1kstatic.html 1kgzip-static.html amdepyc2.jpg.webp wordpress coachblog coachbloggzip"
ROUNDNUM=7
```

Example results from Upcloud 2 cpu $20/month KVM VPS server + client spun up servers.

```
***Total of 1618 seconds to finish process***
[OK] to archive /opt/Benchmark/081719-095937.tgz
/opt/Benchmark/081719-095937/RESULTS.txt
#############  Test Environment  #################
Network traffic: 526 Mbits/sec
Network latency: 0.258 ms
Client Server - Memory Size: 3789.44MB
Client Server - CPU number: 2
Client Server - CPU Thread: 1
Test   Server - Memory Size: 3789.44MB
Test   Server - CPU number: 2
Test   Server - CPU Thread: 1
#############  Benchmark Result  #################

h2load - 1kstatic.html
lsws 5.4.1      finished in     645.26 seconds,  156815.00 req/s,      18.58 MB/s,          0 failures,   96.24% header compression
nginx 1.16.1    finished in       1.30 seconds,   77284.00 req/s,      17.18 MB/s,          0 failures,    35.5% header compression

h2load-ecc128 - 1kstatic.html
lsws 5.4.1      finished in       0.61 seconds,  163141.00 req/s,      19.32 MB/s,          0 failures,   96.26% header compression
nginx 1.16.1    finished in       1.42 seconds,   70480.20 req/s,      15.66 MB/s,          0 failures,    35.5% header compression

h2load-ecc256 - 1kstatic.html
lsws 5.4.1      finished in       0.60 seconds,  165927.00 req/s,      19.66 MB/s,          0 failures,   96.26% header compression
nginx 1.16.1    finished in       1.33 seconds,   75469.80 req/s,      16.77 MB/s,          0 failures,    35.5% header compression

h2load - 1kgzip-static.html
lsws 5.4.1      finished in     627.18 seconds,  160020.00 req/s,      18.96 MB/s,          0 failures,   96.24% header compression
nginx 1.16.1    finished in       1.32 seconds,   77078.20 req/s,      18.53 MB/s,          0 failures,    38.5% header compression

h2load-ecc128 - 1kgzip-static.html
lsws 5.4.1      finished in       0.59 seconds,  170335.00 req/s,      20.18 MB/s,          0 failures,   96.24% header compression
nginx 1.16.1    finished in       1.15 seconds,   88093.20 req/s,      21.18 MB/s,          0 failures,    38.5% header compression

h2load-ecc256 - 1kgzip-static.html
lsws 5.4.1      finished in       0.63 seconds,  158472.00 req/s,      18.78 MB/s,          0 failures,   96.24% header compression
nginx 1.16.1    finished in       1.22 seconds,   83309.40 req/s,      20.03 MB/s,          0 failures,    38.5% header compression

h2load - amdepyc2.jpg.webp
lsws 5.4.1      finished in       8.73 seconds,   11459.20 req/s,     115.79 MB/s,          0 failures,   91.38% header compression
nginx 1.16.1    finished in       8.83 seconds,   11325.70 req/s,     115.42 MB/s,          0 failures,    38.6% header compression

h2load-ecc128 - amdepyc2.jpg.webp
lsws 5.4.1      finished in      11.35 seconds,    9149.06 req/s,      92.42 MB/s,        1.8 failures,   92.02% header compression
nginx 1.16.1    finished in       8.81 seconds,   11353.70 req/s,     115.71 MB/s,          0 failures,    38.6% header compression

h2load-ecc256 - amdepyc2.jpg.webp
lsws 5.4.1      finished in      12.09 seconds,    8486.50 req/s,      85.74 MB/s,        1.6 failures,   91.82% header compression
nginx 1.16.1    finished in       8.78 seconds,   11394.90 req/s,     116.13 MB/s,          0 failures,    38.6% header compression

h2load - wordpress
lsws 5.4.1      finished in       3.41 seconds,   29339.00 req/s,     113.86 MB/s,          0 failures,    96.6% header compression
nginx 1.16.1    finished in       8.96 seconds,   11163.00 req/s,      45.38 MB/s,          0 failures,    26.5% header compression

h2load-ecc128 - wordpress
lsws 5.4.1      finished in       3.40 seconds,   29387.40 req/s,     114.05 MB/s,          0 failures,    96.6% header compression
nginx 1.16.1    finished in       9.01 seconds,   11103.20 req/s,      45.14 MB/s,          0 failures,    26.5% header compression

h2load-ecc256 - wordpress
lsws 5.4.1      finished in       3.38 seconds,   29638.60 req/s,     115.03 MB/s,          0 failures,    96.6% header compression
nginx 1.16.1    finished in       9.16 seconds,   10921.50 req/s,      44.40 MB/s,          0 failures,    26.5% header compression

h2load - coachblog
lsws 5.4.1      finished in       5.45 seconds,   18357.20 req/s,     115.87 MB/s,          0 failures,    96.2% header compression
nginx 1.16.1    finished in      16.32 seconds,    6146.36 req/s,      46.77 MB/s,          0 failures,    35.3% header compression

h2load-ecc128 - coachblog
lsws 5.4.1      finished in       5.46 seconds,   18318.50 req/s,     115.62 MB/s,          0 failures,    96.2% header compression
nginx 1.16.1    finished in      15.83 seconds,    6324.56 req/s,      48.13 MB/s,          0 failures,    35.3% header compression

h2load-ecc256 - coachblog
lsws 5.4.1      finished in       5.49 seconds,   18235.40 req/s,     115.10 MB/s,          0 failures,    96.2% header compression
nginx 1.16.1    finished in      16.38 seconds,    6112.38 req/s,      46.51 MB/s,          0 failures,    35.3% header compression

h2load - coachbloggzip
lsws 5.4.1      finished in       5.49 seconds,   18201.20 req/s,     114.88 MB/s,          0 failures,    96.2% header compression
nginx 1.16.1    finished in       5.83 seconds,   17166.80 req/s,     110.54 MB/s,          0 failures,    38.5% header compression

h2load-ecc128 - coachbloggzip
lsws 5.4.1      finished in       5.48 seconds,   18249.20 req/s,     115.18 MB/s,          0 failures,    96.2% header compression
nginx 1.16.1    finished in       5.84 seconds,   17135.60 req/s,     110.34 MB/s,          0 failures,    38.5% header compression

h2load-ecc256 - coachbloggzip
lsws 5.4.1      finished in       5.45 seconds,   18359.60 req/s,     115.89 MB/s,          0 failures,    96.2% header compression
nginx 1.16.1    finished in       5.74 seconds,   17424.30 req/s,     112.20 MB/s,          0 failures,    38.5% header compression
```

```
cat /opt/Benchmark/081719-095937/RESULTS.txt
############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       616.84ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    162115.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.21MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               58.61ms
TTFB Avg:               69.91ms
TTFB Max:               65.08ms
TTFB SD:                3.68ms

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       656.54ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    152314.5
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.05MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               55.28ms
TTFB Avg:               64.88ms
TTFB Max:               61.19ms
TTFB SD:                2.78ms

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       530.95ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    188343.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   22.32MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               52.10ms
TTFB Avg:               60.39ms
TTFB Max:               57.26ms
TTFB SD:                1.83ms

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       709.80ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    140884.1
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               57.28ms
TTFB Avg:               68.28ms
TTFB Max:               63.46ms
TTFB SD:                3.83ms

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.26s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    79091.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   9.37MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               92.17ms
TTFB Avg:               101.57ms
TTFB Max:               96.22ms
TTFB SD:                2.65ms

############### lsws-1kstatic.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       892.09ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    112095.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   13.28MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               61.85ms
TTFB Avg:               92.19ms
TTFB Max:               81.10ms
TTFB SD:                5.35ms

############### lsws-1kstatic.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       712.16ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    140418.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               42.82ms
TTFB Avg:               72.15ms
TTFB Max:               64.01ms
TTFB SD:                5.14ms

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       700.61ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    142732.9
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               57.46ms
TTFB Avg:               70.48ms
TTFB Max:               63.49ms
TTFB SD:                2.65ms

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       565.58ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    176809.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   20.95MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               53.78ms
TTFB Avg:               60.80ms
TTFB Max:               57.59ms
TTFB SD:                1.63ms

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       663.72ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    150665.9
Total Bandwidth:        11.85MB
Bandwidth Per Second:   17.85MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               58.69ms
TTFB Avg:               65.41ms
TTFB Max:               61.68ms
TTFB SD:                1.98ms

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       606.30ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    164933.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.54MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               55.49ms
TTFB Avg:               71.99ms
TTFB Max:               61.55ms
TTFB SD:                3.33ms

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       660.04ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    151506.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   17.95MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               59.07ms
TTFB Avg:               70.15ms
TTFB Max:               65.11ms
TTFB SD:                3.60ms

############### lsws-1kgzip-static.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       640.27ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    156183.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.51MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               56.68ms
TTFB Avg:               65.23ms
TTFB Max:               61.62ms
TTFB SD:                2.48ms

############### lsws-1kgzip-static.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       700.22ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    142813.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   16.92MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               57.35ms
TTFB Avg:               65.51ms
TTFB Max:               61.08ms
TTFB SD:                1.86ms

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.78s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11393.2
Total Bandwidth:        1010.64MB
Bandwidth Per Second:   115.14MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     90.76%
TTFB Min:               52.65ms
TTFB Avg:               85.74ms
TTFB Max:               64.35ms
TTFB SD:                10.83ms

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.78s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11395.6
Total Bandwidth:        1010.50MB
Bandwidth Per Second:   115.15MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     91.21%
TTFB Min:               61.25ms
TTFB Avg:               87.76ms
TTFB Max:               74.79ms
TTFB SD:                9.02ms

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.73s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11456.9
Total Bandwidth:        1009.88MB
Bandwidth Per Second:   115.70MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     93.12%
TTFB Min:               73.66ms
TTFB Avg:               116.39ms
TTFB Max:               92.93ms
TTFB SD:                11.21ms

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.65s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11557.0
Total Bandwidth:        1010.67MB
Bandwidth Per Second:   116.80MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     90.67%
TTFB Min:               57.46ms
TTFB Avg:               76.66ms
TTFB Max:               67.11ms
TTFB SD:                4.10ms

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.69s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11501.2
Total Bandwidth:        1010.07MB
Bandwidth Per Second:   116.17MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     92.53%
TTFB Min:               52.66ms
TTFB Avg:               67.62ms
TTFB Max:               60.88ms
TTFB SD:                4.09ms

############### lsws-amdepyc2.jpg.webp.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.72s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11466.7
Total Bandwidth:        1010.78MB
Bandwidth Per Second:   115.90MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     90.34%
TTFB Min:               60.90ms
TTFB Avg:               86.20ms
TTFB Max:               73.92ms
TTFB SD:                7.42ms

############### lsws-amdepyc2.jpg.webp.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.76s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11419.9
Total Bandwidth:        1010.33MB
Bandwidth Per Second:   115.38MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     91.73%
TTFB Min:               58.91ms
TTFB Avg:               89.81ms
TTFB Max:               70.94ms
TTFB SD:                8.54ms

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.41s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    29284.5
Total Bandwidth:        388.09MB
Bandwidth Per Second:   113.65MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               62.55ms
TTFB Avg:               85.34ms
TTFB Max:               73.43ms
TTFB SD:                7.72ms

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.58s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    27933.0
Total Bandwidth:        388.09MB
Bandwidth Per Second:   108.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               59.02ms
TTFB Avg:               78.21ms
TTFB Max:               69.79ms
TTFB SD:                6.67ms

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.38s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    29614.2
Total Bandwidth:        388.09MB
Bandwidth Per Second:   114.93MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               59.25ms
TTFB Avg:               75.32ms
TTFB Max:               69.62ms
TTFB SD:                4.51ms

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.49s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    28651.7
Total Bandwidth:        388.09MB
Bandwidth Per Second:   111.19MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               59.20ms
TTFB Avg:               77.43ms
TTFB Max:               69.82ms
TTFB SD:                5.98ms

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.48s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    28773.9
Total Bandwidth:        388.09MB
Bandwidth Per Second:   111.67MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               60.81ms
TTFB Avg:               81.17ms
TTFB Max:               72.31ms
TTFB SD:                6.88ms

############### lsws-wp_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.41s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    29315.7
Total Bandwidth:        388.09MB
Bandwidth Per Second:   113.77MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               66.23ms
TTFB Avg:               79.12ms
TTFB Max:               72.60ms
TTFB SD:                4.01ms

############### lsws-wp_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.37s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    29706.6
Total Bandwidth:        388.09MB
Bandwidth Per Second:   115.29MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               60.08ms
TTFB Avg:               78.08ms
TTFB Max:               67.08ms
TTFB SD:                4.96ms

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.48s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18247.6
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.18MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               53.23ms
TTFB Avg:               75.89ms
TTFB Max:               62.15ms
TTFB SD:                5.60ms

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.47s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18269.5
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.31MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               52.69ms
TTFB Avg:               75.03ms
TTFB Max:               61.68ms
TTFB SD:                5.86ms

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.41s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18477.7
Total Bandwidth:        631.18MB
Bandwidth Per Second:   116.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.26%
TTFB Min:               64.90ms
TTFB Avg:               88.65ms
TTFB Max:               77.10ms
TTFB SD:                8.03ms

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.45s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18362.5
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.90MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               61.92ms
TTFB Avg:               81.19ms
TTFB Max:               72.22ms
TTFB SD:                4.72ms

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.45s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18348.3
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.81MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               54.37ms
TTFB Avg:               79.28ms
TTFB Max:               63.37ms
TTFB SD:                7.13ms

############### lsws-coachblog_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.46s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18328.2
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.68MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               65.17ms
TTFB Avg:               94.55ms
TTFB Max:               77.45ms
TTFB SD:                9.24ms

############### lsws-coachblog_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.47s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18291.9
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.46MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               52.54ms
TTFB Avg:               66.43ms
TTFB Max:               60.13ms
TTFB SD:                3.59ms

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.47s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18281.8
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.39MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               53.48ms
TTFB Avg:               65.33ms
TTFB Max:               59.66ms
TTFB SD:                3.30ms

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.52s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18106.1
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.28MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               52.75ms
TTFB Avg:               73.18ms
TTFB Max:               60.75ms
TTFB SD:                5.24ms

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.44s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18368.9
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               52.84ms
TTFB Avg:               71.50ms
TTFB Max:               59.35ms
TTFB SD:                3.06ms

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.49s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18205.5
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               55.49ms
TTFB Avg:               71.53ms
TTFB Max:               63.90ms
TTFB SD:                4.95ms

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.47s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18289.3
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.44MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               54.55ms
TTFB Avg:               72.71ms
TTFB Max:               64.28ms
TTFB SD:                6.16ms

############### lsws-coachbloggzip_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.54s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18038.5
Total Bandwidth:        631.18MB
Bandwidth Per Second:   113.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               65.45ms
TTFB Avg:               90.71ms
TTFB Max:               80.53ms
TTFB SD:                7.05ms

############### lsws-coachbloggzip_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.55s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    18027.6
Total Bandwidth:        631.18MB
Bandwidth Per Second:   113.79MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               54.73ms
TTFB Avg:               78.64ms
TTFB Max:               62.95ms
TTFB SD:                5.62ms

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       620.20ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    161238.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.10MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               56.35ms
TTFB Avg:               66.79ms
TTFB Max:               62.28ms
TTFB SD:                3.64ms

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       604.69ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    165375.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.59MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               65.84ms
TTFB Avg:               73.83ms
TTFB Max:               69.20ms
TTFB SD:                2.42ms

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       619.76ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    161352.7
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.11MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               62.08ms
TTFB Avg:               69.82ms
TTFB Max:               66.89ms
TTFB SD:                1.95ms

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       616.66ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    162163.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.21MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               55.74ms
TTFB Avg:               65.39ms
TTFB Max:               61.75ms
TTFB SD:                2.98ms

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       645.04ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    155027.9
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.37MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               62.03ms
TTFB Avg:               69.64ms
TTFB Max:               65.29ms
TTFB SD:                2.32ms

############### lsws-1kstatic.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       601.90ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    166139.7
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               56.07ms
TTFB Avg:               66.93ms
TTFB Max:               62.04ms
TTFB SD:                3.74ms

############### lsws-1kstatic.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       603.96ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    165573.3
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.61MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               57.19ms
TTFB Avg:               71.44ms
TTFB Max:               63.37ms
TTFB SD:                2.81ms

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       658.06ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    151962.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.00MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               58.19ms
TTFB Avg:               71.04ms
TTFB Max:               64.72ms
TTFB SD:                4.48ms

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       612.78ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    163191.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.34MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               55.53ms
TTFB Avg:               65.49ms
TTFB Max:               61.06ms
TTFB SD:                3.34ms

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       597.03ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    167497.1
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.85MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               54.49ms
TTFB Avg:               63.24ms
TTFB Max:               60.04ms
TTFB SD:                2.48ms

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       601.99ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    166115.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.68MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               58.96ms
TTFB Avg:               69.15ms
TTFB Max:               64.91ms
TTFB SD:                3.35ms

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       550.75ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    181570.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   21.51MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               52.41ms
TTFB Avg:               60.29ms
TTFB Max:               57.57ms
TTFB SD:                2.12ms

############### lsws-1kgzip-static.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       577.03ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    173302.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   20.53MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               52.99ms
TTFB Avg:               61.86ms
TTFB Max:               58.38ms
TTFB SD:                2.77ms

############### lsws-1kgzip-static.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       542.83ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    184221.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   21.83MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               52.87ms
TTFB Avg:               60.37ms
TTFB Max:               57.70ms
TTFB SD:                1.89ms

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.87s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10135.7
Total Bandwidth:        1010.48MB
Bandwidth Per Second:   102.42MB
Total Failures:         3
Status Code Stats:      99997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     91.18%
TTFB Min:               60.80ms
TTFB Avg:               89.38ms
TTFB Max:               75.96ms
TTFB SD:                9.79ms

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.89s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11245.9
Total Bandwidth:        1009.98MB
Bandwidth Per Second:   113.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     92.82%
TTFB Min:               62.51ms
TTFB Avg:               87.45ms
TTFB Max:               75.99ms
TTFB SD:                8.32ms

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       13.56s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7375.0
Total Bandwidth:        1010.68MB
Bandwidth Per Second:   74.54MB
Total Failures:         2
Status Code Stats:      99998 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     90.57%
TTFB Min:               54.50ms
TTFB Avg:               78.30ms
TTFB Max:               63.72ms
TTFB SD:                6.48ms

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       13.29s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7526.7
Total Bandwidth:        1010.04MB
Bandwidth Per Second:   76.02MB
Total Failures:         3
Status Code Stats:      99997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     92.54%
TTFB Min:               53.00ms
TTFB Avg:               79.42ms
TTFB Max:               61.75ms
TTFB SD:                6.97ms

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       12.19s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8202.7
Total Bandwidth:        1010.81MB
Bandwidth Per Second:   82.92MB
Total Failures:         2
Status Code Stats:      99998 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     90.18%
TTFB Min:               64.93ms
TTFB Avg:               93.12ms
TTFB Max:               79.50ms
TTFB SD:                8.94ms

############### lsws-amdepyc2.jpg.webp.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       12.26s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    8159.5
Total Bandwidth:        1010.21MB
Bandwidth Per Second:   82.43MB
Total Failures:         4
Status Code Stats:      99996 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     91.99%
TTFB Min:               62.43ms
TTFB Avg:               87.27ms
TTFB Max:               74.07ms
TTFB SD:                7.88ms

############### lsws-amdepyc2.jpg.webp.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.74s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11438.2
Total Bandwidth:        1010.08MB
Bandwidth Per Second:   115.54MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     92.49%
TTFB Min:               61.26ms
TTFB Avg:               90.83ms
TTFB Max:               76.72ms
TTFB SD:                10.18ms

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.38s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    29608.0
Total Bandwidth:        388.09MB
Bandwidth Per Second:   114.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               52.42ms
TTFB Avg:               67.64ms
TTFB Max:               59.69ms
TTFB SD:                4.56ms

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    28970.5
Total Bandwidth:        388.09MB
Bandwidth Per Second:   112.43MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               59.73ms
TTFB Avg:               78.62ms
TTFB Max:               71.08ms
TTFB SD:                5.32ms

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.35s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    29843.3
Total Bandwidth:        388.09MB
Bandwidth Per Second:   115.82MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               58.07ms
TTFB Avg:               74.18ms
TTFB Max:               64.81ms
TTFB SD:                4.05ms

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.28s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    30508.8
Total Bandwidth:        388.09MB
Bandwidth Per Second:   118.40MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               60.65ms
TTFB Avg:               79.34ms
TTFB Max:               69.65ms
TTFB SD:                5.27ms

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.51s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    28517.1
Total Bandwidth:        388.09MB
Bandwidth Per Second:   110.67MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               52.61ms
TTFB Avg:               65.49ms
TTFB Max:               59.76ms
TTFB SD:                3.62ms

############### lsws-wp_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.34s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    29951.2
Total Bandwidth:        388.09MB
Bandwidth Per Second:   116.24MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               61.13ms
TTFB Avg:               87.28ms
TTFB Max:               74.98ms
TTFB SD:                8.57ms

############### lsws-wp_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.50s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    28564.4
Total Bandwidth:        388.09MB
Bandwidth Per Second:   110.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               51.63ms
TTFB Avg:               69.11ms
TTFB Max:               59.65ms
TTFB SD:                4.13ms

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.52s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18117.5
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.35MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               58.50ms
TTFB Avg:               74.49ms
TTFB Max:               66.63ms
TTFB SD:                4.78ms

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.47s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18284.0
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               59.42ms
TTFB Avg:               84.24ms
TTFB Max:               68.87ms
TTFB SD:                5.90ms

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.48s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18264.0
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.28MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               52.94ms
TTFB Avg:               66.75ms
TTFB Max:               59.54ms
TTFB SD:                3.61ms

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18346.9
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.80MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               60.58ms
TTFB Avg:               91.90ms
TTFB Max:               74.03ms
TTFB SD:                9.16ms

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18340.2
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.76MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               41.75ms
TTFB Avg:               91.47ms
TTFB Max:               70.42ms
TTFB SD:                17.10ms

############### lsws-coachblog_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.44s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18373.4
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.97MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               59.97ms
TTFB Avg:               82.28ms
TTFB Max:               72.93ms
TTFB SD:                6.51ms

############### lsws-coachblog_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18357.2
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.87MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               59.74ms
TTFB Avg:               84.34ms
TTFB Max:               73.18ms
TTFB SD:                8.26ms

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.42s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18439.5
Total Bandwidth:        631.18MB
Bandwidth Per Second:   116.39MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.26%
TTFB Min:               54.47ms
TTFB Avg:               78.06ms
TTFB Max:               64.27ms
TTFB SD:                6.01ms

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.48s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18264.1
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.28MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               55.69ms
TTFB Avg:               72.58ms
TTFB Max:               63.70ms
TTFB SD:                4.09ms

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.48s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18253.2
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.21MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               52.38ms
TTFB Avg:               75.77ms
TTFB Max:               61.22ms
TTFB SD:                5.85ms

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.56s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17990.2
Total Bandwidth:        631.18MB
Bandwidth Per Second:   113.55MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               60.23ms
TTFB Avg:               85.86ms
TTFB Max:               72.45ms
TTFB SD:                7.19ms

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.48s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18235.7
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.10MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               54.45ms
TTFB Avg:               80.67ms
TTFB Max:               63.60ms
TTFB SD:                7.16ms

############### lsws-coachbloggzip_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.43s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18427.8
Total Bandwidth:        631.18MB
Bandwidth Per Second:   116.31MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               61.17ms
TTFB Avg:               82.86ms
TTFB Max:               73.96ms
TTFB SD:                6.50ms

############### lsws-coachbloggzip_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.54s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18065.0
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.02MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               62.67ms
TTFB Avg:               85.07ms
TTFB Max:               73.67ms
TTFB SD:                6.27ms

############### lsws-1kstatic.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       628.85ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    159020.9
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.84MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               60.55ms
TTFB Avg:               71.31ms
TTFB Max:               67.59ms
TTFB SD:                2.36ms

############### lsws-1kstatic.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       600.07ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    166648.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.74MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               58.98ms
TTFB Avg:               65.84ms
TTFB Max:               62.58ms
TTFB SD:                2.15ms

############### lsws-1kstatic.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       600.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    166572.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               38.93ms
TTFB Avg:               68.34ms
TTFB Max:               53.51ms
TTFB SD:                11.82ms

############### lsws-1kstatic.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       555.90ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    179889.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   21.31MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               51.39ms
TTFB Avg:               66.57ms
TTFB Max:               60.00ms
TTFB SD:                2.78ms

############### lsws-1kstatic.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       591.17ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    169156.0
Total Bandwidth:        11.85MB
Bandwidth Per Second:   20.04MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               38.78ms
TTFB Avg:               70.71ms
TTFB Max:               59.38ms
TTFB SD:                10.07ms

############### lsws-1kstatic.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       594.41ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    168235.4
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.93MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               52.36ms
TTFB Avg:               67.36ms
TTFB Max:               57.57ms
TTFB SD:                3.29ms

############### lsws-1kstatic.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       640.65ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    156092.2
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.49MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               57.86ms
TTFB Avg:               67.22ms
TTFB Max:               62.89ms
TTFB SD:                2.80ms

############### lsws-1kgzip-static.html.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       581.34ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    172016.6
Total Bandwidth:        11.85MB
Bandwidth Per Second:   20.38MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               56.17ms
TTFB Avg:               65.99ms
TTFB Max:               62.20ms
TTFB SD:                3.32ms

############### lsws-1kgzip-static.html.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       596.40ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    167673.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   19.87MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               58.46ms
TTFB Avg:               64.87ms
TTFB Max:               62.17ms
TTFB SD:                1.74ms

############### lsws-1kgzip-static.html.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       645.97ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    154804.9
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.34MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               60.80ms
TTFB Avg:               72.70ms
TTFB Max:               67.34ms
TTFB SD:                4.06ms

############### lsws-1kgzip-static.html.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       627.39ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    159391.7
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.88MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.30%
TTFB Min:               56.66ms
TTFB Avg:               64.73ms
TTFB Max:               62.11ms
TTFB SD:                1.97ms

############### lsws-1kgzip-static.html.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       646.85ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    154595.1
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.32MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               53.67ms
TTFB Avg:               64.51ms
TTFB Max:               59.23ms
TTFB SD:                3.17ms

############### lsws-1kgzip-static.html.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       641.45ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    155896.5
Total Bandwidth:        11.85MB
Bandwidth Per Second:   18.47MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               55.34ms
TTFB Avg:               65.78ms
TTFB Max:               61.26ms
TTFB SD:                3.47ms

############### lsws-1kgzip-static.html.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       683.38ms
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    146330.8
Total Bandwidth:        11.85MB
Bandwidth Per Second:   17.34MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.29%
TTFB Min:               56.13ms
TTFB Avg:               66.08ms
TTFB Max:               61.80ms
TTFB SD:                3.41ms

############### lsws-amdepyc2.jpg.webp.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.70s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11489.8
Total Bandwidth:        1010.02MB
Bandwidth Per Second:   116.05MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     92.70%
TTFB Min:               53.43ms
TTFB Avg:               64.89ms
TTFB Max:               60.61ms
TTFB SD:                3.41ms

############### lsws-amdepyc2.jpg.webp.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.84s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11314.2
Total Bandwidth:        1009.51MB
Bandwidth Per Second:   114.22MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     94.26%
TTFB Min:               53.40ms
TTFB Avg:               65.47ms
TTFB Max:               61.18ms
TTFB SD:                2.90ms

############### lsws-amdepyc2.jpg.webp.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       12.76s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7835.8
Total Bandwidth:        1010.57MB
Bandwidth Per Second:   79.19MB
Total Failures:         1
Status Code Stats:      99999 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     90.96%
TTFB Min:               53.18ms
TTFB Avg:               73.73ms
TTFB Max:               61.74ms
TTFB SD:                5.38ms

############### lsws-amdepyc2.jpg.webp.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       12.59s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7944.9
Total Bandwidth:        1010.11MB
Bandwidth Per Second:   80.25MB
Total Failures:         2
Status Code Stats:      99998 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     92.34%
TTFB Min:               51.39ms
TTFB Avg:               67.59ms
TTFB Max:               60.03ms
TTFB SD:                3.48ms

############### lsws-amdepyc2.jpg.webp.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       13.35s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7491.5
Total Bandwidth:        1009.81MB
Bandwidth Per Second:   75.65MB
Total Failures:         3
Status Code Stats:      99997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     93.24%
TTFB Min:               60.10ms
TTFB Avg:               71.20ms
TTFB Max:               64.98ms
TTFB SD:                2.87ms

############### lsws-amdepyc2.jpg.webp.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       12.90s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7752.5
Total Bandwidth:        1010.17MB
Bandwidth Per Second:   78.31MB
Total Failures:         1
Status Code Stats:      99999 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     92.21%
TTFB Min:               55.60ms
TTFB Avg:               76.32ms
TTFB Max:               62.96ms
TTFB SD:                6.00ms

############### lsws-amdepyc2.jpg.webp.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       12.72s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    7862.9
Total Bandwidth:        1010.80MB
Bandwidth Per Second:   79.48MB
Total Failures:         3
Status Code Stats:      99997 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     90.18%
TTFB Min:               60.28ms
TTFB Avg:               83.15ms
TTFB Max:               72.41ms
TTFB SD:                7.39ms

############### lsws-wp_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.38s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    29592.5
Total Bandwidth:        388.09MB
Bandwidth Per Second:   114.85MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               53.54ms
TTFB Avg:               69.13ms
TTFB Max:               60.65ms
TTFB SD:                4.29ms

############### lsws-wp_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.33s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    30023.9
Total Bandwidth:        388.09MB
Bandwidth Per Second:   116.52MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               53.28ms
TTFB Avg:               71.95ms
TTFB Max:               60.71ms
TTFB SD:                5.35ms

############### lsws-wp_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.33s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    30039.9
Total Bandwidth:        388.09MB
Bandwidth Per Second:   116.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               53.11ms
TTFB Avg:               71.68ms
TTFB Max:               60.46ms
TTFB SD:                4.46ms

############### lsws-wp_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.48s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    28755.9
Total Bandwidth:        388.09MB
Bandwidth Per Second:   111.60MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               52.37ms
TTFB Avg:               69.16ms
TTFB Max:               60.19ms
TTFB SD:                4.84ms

############### lsws-wp_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.36s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    29780.8
Total Bandwidth:        388.09MB
Bandwidth Per Second:   115.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               55.62ms
TTFB Avg:               68.49ms
TTFB Max:               59.83ms
TTFB SD:                3.15ms

############### lsws-wp_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.31s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    30219.9
Total Bandwidth:        388.09MB
Bandwidth Per Second:   117.28MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.64%
TTFB Min:               59.48ms
TTFB Avg:               78.59ms
TTFB Max:               71.46ms
TTFB SD:                5.93ms

############### lsws-wp_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       3.49s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    28693.6
Total Bandwidth:        388.09MB
Bandwidth Per Second:   111.36MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.63%
TTFB Min:               62.72ms
TTFB Avg:               88.05ms
TTFB Max:               76.08ms
TTFB SD:                8.75ms

############### lsws-coachblog_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.37s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18613.7
Total Bandwidth:        631.18MB
Bandwidth Per Second:   117.49MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               63.90ms
TTFB Avg:               104.14ms
TTFB Max:               79.54ms
TTFB SD:                14.32ms

############### lsws-coachblog_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.45s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18360.9
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.89MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               53.43ms
TTFB Avg:               77.34ms
TTFB Max:               62.37ms
TTFB SD:                5.59ms

############### lsws-coachblog_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.53s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18092.2
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.19MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               52.02ms
TTFB Avg:               85.77ms
TTFB Max:               62.35ms
TTFB SD:                9.40ms

############### lsws-coachblog_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.44s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18368.5
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               60.82ms
TTFB Avg:               87.83ms
TTFB Max:               74.95ms
TTFB SD:                9.16ms

############### lsws-coachblog_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.51s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18162.3
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               61.15ms
TTFB Avg:               89.67ms
TTFB Max:               75.84ms
TTFB SD:                9.74ms

############### lsws-coachblog_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.50s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18193.1
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.83MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               61.03ms
TTFB Avg:               86.37ms
TTFB Max:               74.12ms
TTFB SD:                8.77ms

############### lsws-coachblog_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.53s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18076.8
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.10MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.28%
TTFB Min:               62.39ms
TTFB Avg:               90.38ms
TTFB Max:               77.62ms
TTFB SD:                9.02ms

############### lsws-coachbloggzip_lsws/.1 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.50s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18198.0
Total Bandwidth:        631.18MB
Bandwidth Per Second:   114.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               54.82ms
TTFB Avg:               75.95ms
TTFB Max:               64.08ms
TTFB SD:                6.09ms

############### lsws-coachbloggzip_lsws/.2 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.40s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18507.8
Total Bandwidth:        631.18MB
Bandwidth Per Second:   116.82MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               55.04ms
TTFB Avg:               70.83ms
TTFB Max:               60.33ms
TTFB SD:                3.59ms

############### lsws-coachbloggzip_lsws/.3 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.47s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18284.0
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               54.17ms
TTFB Avg:               86.08ms
TTFB Max:               65.14ms
TTFB SD:                8.63ms

############### lsws-coachbloggzip_lsws/.4 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.44s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18387.2
Total Bandwidth:        631.18MB
Bandwidth Per Second:   116.06MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               54.46ms
TTFB Avg:               78.93ms
TTFB Max:               64.77ms
TTFB SD:                5.24ms

############### lsws-coachbloggzip_lsws/.5 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.46s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18330.0
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.70MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               56.46ms
TTFB Avg:               98.89ms
TTFB Max:               66.31ms
TTFB SD:                9.94ms

############### lsws-coachbloggzip_lsws/.6 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.41s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18493.3
Total Bandwidth:        631.18MB
Bandwidth Per Second:   116.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               46.72ms
TTFB Avg:               99.37ms
TTFB Max:               74.91ms
TTFB SD:                14.81ms

############### lsws-coachbloggzip_lsws/.7 ###############
Server Name:            lsws
Server Version:         5.4.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_lsws/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.46s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18303.6
Total Bandwidth:        631.18MB
Bandwidth Per Second:   115.53MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     96.27%
TTFB Min:               64.20ms
TTFB Avg:               94.45ms
TTFB Max:               78.57ms
TTFB SD:                10.67ms

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.29s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    77409.3
Total Bandwidth:        22.23MB
Bandwidth Per Second:   17.21MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               55.29ms
TTFB Avg:               67.75ms
TTFB Max:               61.22ms
TTFB SD:                3.48ms

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.40s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    71353.7
Total Bandwidth:        22.23MB
Bandwidth Per Second:   15.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               60.29ms
TTFB Avg:               86.31ms
TTFB Max:               73.62ms
TTFB SD:                7.52ms

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.15s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    86859.3
Total Bandwidth:        22.23MB
Bandwidth Per Second:   19.31MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               54.33ms
TTFB Avg:               67.76ms
TTFB Max:               62.50ms
TTFB SD:                3.29ms

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.29s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    77467.0
Total Bandwidth:        22.23MB
Bandwidth Per Second:   17.22MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               52.57ms
TTFB Avg:               68.48ms
TTFB Max:               60.12ms
TTFB SD:                3.80ms

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.41s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    71158.9
Total Bandwidth:        22.23MB
Bandwidth Per Second:   15.82MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               61.16ms
TTFB Avg:               88.61ms
TTFB Max:               78.31ms
TTFB SD:                6.84ms

############### nginx-1kstatic.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.27s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    79011.3
Total Bandwidth:        22.23MB
Bandwidth Per Second:   17.56MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               59.73ms
TTFB Avg:               81.76ms
TTFB Max:               72.60ms
TTFB SD:                6.21ms

############### nginx-1kstatic.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.23s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    81374.3
Total Bandwidth:        22.23MB
Bandwidth Per Second:   18.09MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               62.40ms
TTFB Avg:               72.73ms
TTFB Max:               66.86ms
TTFB SD:                2.79ms

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.07s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    93204.8
Total Bandwidth:        24.04MB
Bandwidth Per Second:   22.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               64.06ms
TTFB Avg:               83.62ms
TTFB Max:               74.11ms
TTFB SD:                5.02ms

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.40s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    71511.3
Total Bandwidth:        24.04MB
Bandwidth Per Second:   17.19MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               58.75ms
TTFB Avg:               82.11ms
TTFB Max:               72.50ms
TTFB SD:                5.82ms

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.44s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    69575.1
Total Bandwidth:        24.04MB
Bandwidth Per Second:   16.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               59.95ms
TTFB Avg:               79.46ms
TTFB Max:               71.04ms
TTFB SD:                5.62ms

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.13s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    88381.1
Total Bandwidth:        24.04MB
Bandwidth Per Second:   21.25MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               56.32ms
TTFB Avg:               72.45ms
TTFB Max:               65.05ms
TTFB SD:                4.02ms

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       994.45ms
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    100558.6
Total Bandwidth:        24.04MB
Bandwidth Per Second:   24.17MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               52.16ms
TTFB Avg:               65.29ms
TTFB Max:               59.19ms
TTFB SD:                3.58ms

############### nginx-1kgzip-static.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.42s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    70324.5
Total Bandwidth:        24.04MB
Bandwidth Per Second:   16.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               60.58ms
TTFB Avg:               82.08ms
TTFB Max:               73.13ms
TTFB SD:                6.04ms

############### nginx-1kgzip-static.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.44s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    69473.3
Total Bandwidth:        24.04MB
Bandwidth Per Second:   16.70MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               60.06ms
TTFB Avg:               80.82ms
TTFB Max:               72.54ms
TTFB SD:                5.93ms

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.81s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11349.5
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               60.84ms
TTFB Avg:               90.55ms
TTFB Max:               72.27ms
TTFB SD:                7.70ms

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.88s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11260.1
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   114.75MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               64.84ms
TTFB Avg:               87.95ms
TTFB Max:               77.69ms
TTFB SD:                6.62ms

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.85s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11302.2
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.18MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               54.83ms
TTFB Avg:               81.36ms
TTFB Max:               63.16ms
TTFB SD:                5.90ms

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.84s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11316.8
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.33MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.31ms
TTFB Avg:               91.81ms
TTFB Max:               66.78ms
TTFB SD:                11.36ms

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.77s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11399.8
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   116.18MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               62.06ms
TTFB Avg:               85.48ms
TTFB Max:               75.37ms
TTFB SD:                6.42ms

############### nginx-amdepyc2.jpg.webp.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.66s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11542.3
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   117.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.07ms
TTFB Avg:               77.96ms
TTFB Max:               62.38ms
TTFB SD:                7.21ms

############### nginx-amdepyc2.jpg.webp.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.05s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11049.2
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   112.60MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               54.57ms
TTFB Avg:               81.41ms
TTFB Max:               61.97ms
TTFB SD:                6.07ms

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.71s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11475.8
Total Bandwidth:        406.56MB
Bandwidth Per Second:   46.66MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.25ms
TTFB Avg:               161.26ms
TTFB Max:               95.03ms
TTFB SD:                25.28ms

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.93s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11202.5
Total Bandwidth:        406.56MB
Bandwidth Per Second:   45.54MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.43ms
TTFB Avg:               143.14ms
TTFB Max:               91.97ms
TTFB SD:                27.12ms

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.16s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    10913.1
Total Bandwidth:        406.56MB
Bandwidth Per Second:   44.37MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               55.68ms
TTFB Avg:               144.72ms
TTFB Max:               92.31ms
TTFB SD:                26.91ms

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.59s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11638.2
Total Bandwidth:        406.56MB
Bandwidth Per Second:   47.32MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               53.55ms
TTFB Avg:               156.91ms
TTFB Max:               96.34ms
TTFB SD:                30.03ms

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.73s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11457.6
Total Bandwidth:        406.56MB
Bandwidth Per Second:   46.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               52.47ms
TTFB Avg:               189.89ms
TTFB Max:               89.66ms
TTFB SD:                29.34ms

############### nginx-wp_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.29s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    10766.1
Total Bandwidth:        406.56MB
Bandwidth Per Second:   43.77MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               60.74ms
TTFB Avg:               155.50ms
TTFB Max:               100.31ms
TTFB SD:                30.53ms

############### nginx-wp_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.88s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    11255.0
Total Bandwidth:        406.56MB
Bandwidth Per Second:   45.76MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               52.59ms
TTFB Avg:               145.71ms
TTFB Max:               91.86ms
TTFB SD:                26.26ms

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       16.88s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    5925.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   45.09MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               53.92ms
TTFB Avg:               254.98ms
TTFB Max:               144.40ms
TTFB SD:                56.22ms

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       17.72s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    5644.5
Total Bandwidth:        760.94MB
Bandwidth Per Second:   42.95MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               55.63ms
TTFB Avg:               248.85ms
TTFB Max:               125.59ms
TTFB SD:                52.11ms

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.05s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    6643.8
Total Bandwidth:        760.94MB
Bandwidth Per Second:   50.56MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               57.88ms
TTFB Avg:               305.09ms
TTFB Max:               140.65ms
TTFB SD:                77.09ms

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.35s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    6514.9
Total Bandwidth:        760.94MB
Bandwidth Per Second:   49.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               60.38ms
TTFB Avg:               224.08ms
TTFB Max:               130.08ms
TTFB SD:                53.65ms

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.42s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    6485.2
Total Bandwidth:        760.94MB
Bandwidth Per Second:   49.35MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               57.99ms
TTFB Avg:               313.39ms
TTFB Max:               132.13ms
TTFB SD:                61.69ms

############### nginx-coachblog_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.64s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    6392.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   48.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.03ms
TTFB Avg:               314.45ms
TTFB Max:               141.24ms
TTFB SD:                64.62ms

############### nginx-coachblog_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       16.23s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    6161.8
Total Bandwidth:        760.94MB
Bandwidth Per Second:   46.89MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.30ms
TTFB Avg:               230.38ms
TTFB Max:               134.30ms
TTFB SD:                53.41ms

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.96s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    16769.3
Total Bandwidth:        643.93MB
Bandwidth Per Second:   107.98MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               62.63ms
TTFB Avg:               88.03ms
TTFB Max:               78.26ms
TTFB SD:                6.90ms

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.94s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    16846.8
Total Bandwidth:        643.93MB
Bandwidth Per Second:   108.48MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               50.81ms
TTFB Avg:               69.14ms
TTFB Max:               61.34ms
TTFB SD:                4.54ms

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.75s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    17377.8
Total Bandwidth:        643.93MB
Bandwidth Per Second:   111.90MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               56.99ms
TTFB Avg:               75.21ms
TTFB Max:               67.27ms
TTFB SD:                4.89ms

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.71s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    17527.0
Total Bandwidth:        643.93MB
Bandwidth Per Second:   112.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               61.95ms
TTFB Avg:               86.68ms
TTFB Max:               77.08ms
TTFB SD:                6.67ms

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.79s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    17256.7
Total Bandwidth:        643.93MB
Bandwidth Per Second:   111.12MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               51.26ms
TTFB Avg:               74.72ms
TTFB Max:               62.67ms
TTFB SD:                6.58ms

############### nginx-coachbloggzip_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.86s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    17060.4
Total Bandwidth:        643.93MB
Bandwidth Per Second:   109.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               54.17ms
TTFB Avg:               71.29ms
TTFB Max:               62.49ms
TTFB SD:                4.18ms

############### nginx-coachbloggzip_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.92s
Concurrent Connections: 100
Concurrent Streams:     10
Total Requests:         100000
Requests Per Second:    16903.1
Total Bandwidth:        643.93MB
Bandwidth Per Second:   108.84MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               54.60ms
TTFB Avg:               73.77ms
TTFB Max:               65.09ms
TTFB SD:                4.45ms

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.18s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    84843.6
Total Bandwidth:        22.23MB
Bandwidth Per Second:   18.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               54.02ms
TTFB Avg:               68.85ms
TTFB Max:               62.33ms
TTFB SD:                4.27ms

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.70s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    58752.5
Total Bandwidth:        22.23MB
Bandwidth Per Second:   13.06MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               55.01ms
TTFB Avg:               69.52ms
TTFB Max:               63.32ms
TTFB SD:                4.19ms

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.39s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    71687.8
Total Bandwidth:        22.23MB
Bandwidth Per Second:   15.93MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               62.52ms
TTFB Avg:               85.27ms
TTFB Max:               75.79ms
TTFB SD:                6.41ms

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.31s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    76260.5
Total Bandwidth:        22.23MB
Bandwidth Per Second:   16.95MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               55.08ms
TTFB Avg:               69.53ms
TTFB Max:               66.10ms
TTFB SD:                2.90ms

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.47s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    67910.9
Total Bandwidth:        22.23MB
Bandwidth Per Second:   15.09MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               53.12ms
TTFB Avg:               80.04ms
TTFB Max:               64.60ms
TTFB SD:                6.40ms

############### nginx-1kstatic.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.41s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    70698.1
Total Bandwidth:        22.23MB
Bandwidth Per Second:   15.71MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               43.65ms
TTFB Avg:               97.40ms
TTFB Max:               69.90ms
TTFB SD:                19.31ms

############### nginx-1kstatic.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.52s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    65843.7
Total Bandwidth:        22.23MB
Bandwidth Per Second:   14.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               58.04ms
TTFB Avg:               77.41ms
TTFB Max:               67.24ms
TTFB SD:                5.09ms

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.39s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    72041.3
Total Bandwidth:        24.04MB
Bandwidth Per Second:   17.32MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               67.37ms
TTFB Avg:               94.33ms
TTFB Max:               80.66ms
TTFB SD:                7.97ms

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.40s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    71187.3
Total Bandwidth:        24.04MB
Bandwidth Per Second:   17.11MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               49.14ms
TTFB Avg:               97.89ms
TTFB Max:               68.66ms
TTFB SD:                18.50ms

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.03s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    97339.8
Total Bandwidth:        24.04MB
Bandwidth Per Second:   23.40MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               52.28ms
TTFB Avg:               66.93ms
TTFB Max:               59.83ms
TTFB SD:                3.32ms

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.04s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    96131.2
Total Bandwidth:        24.04MB
Bandwidth Per Second:   23.11MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               52.47ms
TTFB Avg:               67.09ms
TTFB Max:               60.12ms
TTFB SD:                3.25ms

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.13s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    88443.5
Total Bandwidth:        24.04MB
Bandwidth Per Second:   21.26MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               60.11ms
TTFB Avg:               82.23ms
TTFB Max:               73.22ms
TTFB SD:                6.33ms

############### nginx-1kgzip-static.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.15s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    87128.2
Total Bandwidth:        24.04MB
Bandwidth Per Second:   20.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               52.37ms
TTFB Avg:               66.87ms
TTFB Max:               60.22ms
TTFB SD:                3.67ms

############### nginx-1kgzip-static.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.03s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    96722.0
Total Bandwidth:        24.04MB
Bandwidth Per Second:   23.25MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               54.78ms
TTFB Avg:               68.14ms
TTFB Max:               62.52ms
TTFB SD:                3.79ms

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.72s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11467.3
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   116.86MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               55.88ms
TTFB Avg:               80.50ms
TTFB Max:               65.59ms
TTFB SD:                6.10ms

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.79s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11372.3
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.90MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.44ms
TTFB Avg:               67.44ms
TTFB Max:               60.97ms
TTFB SD:                3.73ms

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.80s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11363.9
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.81MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.64ms
TTFB Avg:               77.92ms
TTFB Max:               62.58ms
TTFB SD:                5.12ms

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.88s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11266.9
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   114.82MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               53.75ms
TTFB Avg:               77.41ms
TTFB Max:               63.32ms
TTFB SD:                4.99ms

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.75s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11430.4
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   116.49MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.69ms
TTFB Avg:               80.11ms
TTFB Max:               64.08ms
TTFB SD:                6.35ms

############### nginx-amdepyc2.jpg.webp.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.89s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11243.4
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   114.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               56.49ms
TTFB Avg:               99.56ms
TTFB Max:               79.20ms
TTFB SD:                11.45ms

############### nginx-amdepyc2.jpg.webp.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.82s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11335.2
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.52MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               61.50ms
TTFB Avg:               90.80ms
TTFB Max:               78.97ms
TTFB SD:                7.20ms

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.63s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11585.5
Total Bandwidth:        406.56MB
Bandwidth Per Second:   47.10MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               59.46ms
TTFB Avg:               141.91ms
TTFB Max:               92.68ms
TTFB SD:                27.73ms

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.97s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11143.4
Total Bandwidth:        406.56MB
Bandwidth Per Second:   45.30MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               63.45ms
TTFB Avg:               153.74ms
TTFB Max:               98.30ms
TTFB SD:                24.69ms

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.16s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10915.6
Total Bandwidth:        406.56MB
Bandwidth Per Second:   44.38MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               57.95ms
TTFB Avg:               151.98ms
TTFB Max:               93.89ms
TTFB SD:                26.60ms

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.66s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10351.5
Total Bandwidth:        406.56MB
Bandwidth Per Second:   42.08MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               59.89ms
TTFB Avg:               152.45ms
TTFB Max:               94.13ms
TTFB SD:                28.04ms

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.32s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10731.4
Total Bandwidth:        406.56MB
Bandwidth Per Second:   43.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               54.05ms
TTFB Avg:               162.75ms
TTFB Max:               96.81ms
TTFB SD:                31.68ms

############### nginx-wp_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.98s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11139.9
Total Bandwidth:        406.56MB
Bandwidth Per Second:   45.29MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               51.40ms
TTFB Avg:               141.77ms
TTFB Max:               88.17ms
TTFB SD:                27.67ms

############### nginx-wp_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.46s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11814.4
Total Bandwidth:        406.56MB
Bandwidth Per Second:   48.03MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.07ms
TTFB Avg:               138.41ms
TTFB Max:               92.03ms
TTFB SD:                26.29ms

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.88s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6295.5
Total Bandwidth:        760.94MB
Bandwidth Per Second:   47.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.37ms
TTFB Avg:               312.72ms
TTFB Max:               133.83ms
TTFB SD:                70.76ms

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.19s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6585.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   50.11MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               52.25ms
TTFB Avg:               282.54ms
TTFB Max:               126.83ms
TTFB SD:                60.35ms

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       16.85s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5934.0
Total Bandwidth:        760.94MB
Bandwidth Per Second:   45.15MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               62.82ms
TTFB Avg:               243.03ms
TTFB Max:               129.93ms
TTFB SD:                56.30ms

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.28s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6542.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   49.78MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.59ms
TTFB Avg:               299.89ms
TTFB Max:               130.64ms
TTFB SD:                59.88ms

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.05s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6643.7
Total Bandwidth:        760.94MB
Bandwidth Per Second:   50.56MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               61.27ms
TTFB Avg:               223.01ms
TTFB Max:               127.43ms
TTFB SD:                52.29ms

############### nginx-coachblog_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       18.61s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5374.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   40.90MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               61.53ms
TTFB Avg:               276.51ms
TTFB Max:               135.50ms
TTFB SD:                64.76ms

############### nginx-coachblog_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.96s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6265.5
Total Bandwidth:        760.94MB
Bandwidth Per Second:   47.68MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               61.35ms
TTFB Avg:               315.57ms
TTFB Max:               139.48ms
TTFB SD:                75.70ms

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.67s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17636.9
Total Bandwidth:        643.93MB
Bandwidth Per Second:   113.57MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               65.44ms
TTFB Avg:               93.67ms
TTFB Max:               82.18ms
TTFB SD:                7.89ms

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.54s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18045.1
Total Bandwidth:        643.93MB
Bandwidth Per Second:   116.20MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               55.14ms
TTFB Avg:               73.10ms
TTFB Max:               65.99ms
TTFB SD:                5.30ms

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       6.00s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16675.7
Total Bandwidth:        643.93MB
Bandwidth Per Second:   107.38MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               63.68ms
TTFB Avg:               88.18ms
TTFB Max:               78.53ms
TTFB SD:                6.87ms

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       6.03s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16580.8
Total Bandwidth:        643.93MB
Bandwidth Per Second:   106.77MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               62.52ms
TTFB Avg:               85.28ms
TTFB Max:               76.25ms
TTFB SD:                6.35ms

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.75s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17400.1
Total Bandwidth:        643.93MB
Bandwidth Per Second:   112.04MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               63.65ms
TTFB Avg:               89.83ms
TTFB Max:               78.44ms
TTFB SD:                7.79ms

############### nginx-coachbloggzip_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       6.04s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16569.5
Total Bandwidth:        643.93MB
Bandwidth Per Second:   106.70MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               67.21ms
TTFB Avg:               94.32ms
TTFB Max:               83.43ms
TTFB SD:                7.69ms

############### nginx-coachbloggzip_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc128
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES128-GCM-SHA256
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.75s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17384.4
Total Bandwidth:        643.93MB
Bandwidth Per Second:   111.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               65.43ms
TTFB Avg:               92.43ms
TTFB Max:               81.30ms
TTFB SD:                6.48ms

############### nginx-1kstatic.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.44s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    69387.5
Total Bandwidth:        22.23MB
Bandwidth Per Second:   15.42MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               60.14ms
TTFB Avg:               82.21ms
TTFB Max:               72.86ms
TTFB SD:                5.69ms

############### nginx-1kstatic.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.25s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    79770.1
Total Bandwidth:        22.23MB
Bandwidth Per Second:   17.73MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               53.26ms
TTFB Avg:               66.85ms
TTFB Max:               61.09ms
TTFB SD:                2.89ms

############### nginx-1kstatic.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.34s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    74849.1
Total Bandwidth:        22.23MB
Bandwidth Per Second:   16.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               53.71ms
TTFB Avg:               68.03ms
TTFB Max:               61.27ms
TTFB SD:                3.23ms

############### nginx-1kstatic.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.42s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    70332.9
Total Bandwidth:        22.23MB
Bandwidth Per Second:   15.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               44.29ms
TTFB Avg:               81.81ms
TTFB Max:               58.52ms
TTFB SD:                13.55ms

############### nginx-1kstatic.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.24s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    80415.5
Total Bandwidth:        22.23MB
Bandwidth Per Second:   17.87MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               54.60ms
TTFB Avg:               75.48ms
TTFB Max:               62.27ms
TTFB SD:                5.77ms

############### nginx-1kstatic.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.38s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    72545.8
Total Bandwidth:        22.23MB
Bandwidth Per Second:   16.12MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               57.54ms
TTFB Avg:               70.86ms
TTFB Max:               65.58ms
TTFB SD:                3.43ms

############### nginx-1kstatic.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kstatic.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.25s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    79850.6
Total Bandwidth:        22.23MB
Bandwidth Per Second:   17.75MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.52%
TTFB Min:               59.32ms
TTFB Avg:               75.68ms
TTFB Max:               67.83ms
TTFB SD:                3.61ms

############### nginx-1kgzip-static.html.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.17s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    85603.9
Total Bandwidth:        24.04MB
Bandwidth Per Second:   20.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               54.93ms
TTFB Avg:               69.59ms
TTFB Max:               63.63ms
TTFB SD:                4.00ms

############### nginx-1kgzip-static.html.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.52s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    65694.0
Total Bandwidth:        24.04MB
Bandwidth Per Second:   15.79MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               63.43ms
TTFB Avg:               87.03ms
TTFB Max:               76.50ms
TTFB SD:                6.99ms

############### nginx-1kgzip-static.html.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.02s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    98142.7
Total Bandwidth:        24.04MB
Bandwidth Per Second:   23.59MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               43.83ms
TTFB Avg:               79.97ms
TTFB Max:               58.28ms
TTFB SD:                13.92ms

############### nginx-1kgzip-static.html.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.41s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    70873.6
Total Bandwidth:        24.04MB
Bandwidth Per Second:   17.04MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               59.24ms
TTFB Avg:               80.47ms
TTFB Max:               71.65ms
TTFB SD:                5.98ms

############### nginx-1kgzip-static.html.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.01s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    99198.7
Total Bandwidth:        24.04MB
Bandwidth Per Second:   23.85MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               51.88ms
TTFB Avg:               66.38ms
TTFB Max:               59.77ms
TTFB SD:                3.41ms

############### nginx-1kgzip-static.html.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.14s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    87713.4
Total Bandwidth:        24.04MB
Bandwidth Per Second:   21.09MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               52.25ms
TTFB Avg:               67.06ms
TTFB Max:               59.98ms
TTFB SD:                3.45ms

############### nginx-1kgzip-static.html.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/1kgzip-static.html
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       1.35s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    74212.9
Total Bandwidth:        24.04MB
Bandwidth Per Second:   17.84MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.58%
TTFB Min:               54.55ms
TTFB Avg:               69.01ms
TTFB Max:               62.91ms
TTFB SD:                4.13ms

############### nginx-amdepyc2.jpg.webp.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.79s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11376.9
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               52.96ms
TTFB Avg:               86.59ms
TTFB Max:               67.03ms
TTFB SD:                10.33ms

############### nginx-amdepyc2.jpg.webp.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.75s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11422.7
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   116.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               51.22ms
TTFB Avg:               75.92ms
TTFB Max:               61.63ms
TTFB SD:                6.13ms

############### nginx-amdepyc2.jpg.webp.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.74s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11442.5
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   116.61MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               41.38ms
TTFB Avg:               75.15ms
TTFB Max:               57.62ms
TTFB SD:                10.16ms

############### nginx-amdepyc2.jpg.webp.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.85s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11305.3
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.21MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               61.05ms
TTFB Avg:               86.44ms
TTFB Max:               76.47ms
TTFB SD:                7.03ms

############### nginx-amdepyc2.jpg.webp.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.85s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11303.8
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   115.20MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               57.02ms
TTFB Avg:               84.97ms
TTFB Max:               68.27ms
TTFB SD:                6.05ms

############### nginx-amdepyc2.jpg.webp.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.75s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11427.3
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   116.46MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               47.94ms
TTFB Avg:               275.95ms
TTFB Max:               65.92ms
TTFB SD:                38.25ms

############### nginx-amdepyc2.jpg.webp.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/amdepyc2.jpg.webp
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.73s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11459.4
Total Bandwidth:        1019.10MB
Bandwidth Per Second:   116.78MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.67%
TTFB Min:               61.15ms
TTFB Avg:               84.43ms
TTFB Max:               75.21ms
TTFB SD:                6.53ms

############### nginx-wp_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.58s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11657.9
Total Bandwidth:        406.56MB
Bandwidth Per Second:   47.40MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               55.05ms
TTFB Avg:               137.64ms
TTFB Max:               88.74ms
TTFB SD:                27.49ms

############### nginx-wp_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.25s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10808.1
Total Bandwidth:        406.56MB
Bandwidth Per Second:   43.94MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               51.58ms
TTFB Avg:               142.97ms
TTFB Max:               88.61ms
TTFB SD:                27.62ms

############### nginx-wp_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       8.63s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    11589.6
Total Bandwidth:        406.56MB
Bandwidth Per Second:   47.12MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.83ms
TTFB Avg:               139.25ms
TTFB Max:               92.15ms
TTFB SD:                26.66ms

############### nginx-wp_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.26s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10799.7
Total Bandwidth:        406.56MB
Bandwidth Per Second:   43.91MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               59.47ms
TTFB Avg:               206.51ms
TTFB Max:               102.35ms
TTFB SD:                44.18ms

############### nginx-wp_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.54s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10487.4
Total Bandwidth:        406.56MB
Bandwidth Per Second:   42.64MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               57.93ms
TTFB Avg:               153.69ms
TTFB Max:               98.61ms
TTFB SD:                29.15ms

############### nginx-wp_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.36s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10678.1
Total Bandwidth:        406.56MB
Bandwidth Per Second:   43.41MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               57.15ms
TTFB Avg:               165.99ms
TTFB Max:               98.35ms
TTFB SD:                29.08ms

############### nginx-wp_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/wp_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       9.32s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    10732.1
Total Bandwidth:        406.56MB
Bandwidth Per Second:   43.63MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     26.54%
TTFB Min:               58.91ms
TTFB Avg:               151.35ms
TTFB Max:               93.66ms
TTFB SD:                28.18ms

############### nginx-coachblog_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.53s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6437.1
Total Bandwidth:        760.94MB
Bandwidth Per Second:   48.98MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               59.54ms
TTFB Avg:               269.88ms
TTFB Max:               133.93ms
TTFB SD:                56.31ms

############### nginx-coachblog_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       16.30s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6136.2
Total Bandwidth:        760.94MB
Bandwidth Per Second:   46.69MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               52.50ms
TTFB Avg:               222.08ms
TTFB Max:               125.37ms
TTFB SD:                54.78ms

############### nginx-coachblog_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       16.82s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5944.6
Total Bandwidth:        760.94MB
Bandwidth Per Second:   45.24MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               56.66ms
TTFB Avg:               258.16ms
TTFB Max:               126.90ms
TTFB SD:                50.80ms

############### nginx-coachblog_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       17.08s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5854.4
Total Bandwidth:        760.94MB
Bandwidth Per Second:   44.55MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               58.59ms
TTFB Avg:               253.89ms
TTFB Max:               138.47ms
TTFB SD:                65.68ms

############### nginx-coachblog_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       17.07s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    5858.2
Total Bandwidth:        760.94MB
Bandwidth Per Second:   44.58MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               44.62ms
TTFB Avg:               361.69ms
TTFB Max:               157.51ms
TTFB SD:                105.58ms

############### nginx-coachblog_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       16.17s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6185.8
Total Bandwidth:        760.94MB
Bandwidth Per Second:   47.07MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               66.23ms
TTFB Avg:               231.62ms
TTFB Max:               132.83ms
TTFB SD:                50.23ms

############### nginx-coachblog_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachblog_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       15.35s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    6514.6
Total Bandwidth:        760.94MB
Bandwidth Per Second:   49.57MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     35.33%
TTFB Min:               56.14ms
TTFB Avg:               218.30ms
TTFB Max:               123.80ms
TTFB SD:                50.28ms

############### nginx-coachbloggzip_nginx/.1 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.60s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17865.0
Total Bandwidth:        643.93MB
Bandwidth Per Second:   115.04MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               54.53ms
TTFB Avg:               73.65ms
TTFB Max:               62.73ms
TTFB SD:                4.43ms

############### nginx-coachbloggzip_nginx/.2 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.93s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    16855.2
Total Bandwidth:        643.93MB
Bandwidth Per Second:   108.54MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               53.16ms
TTFB Avg:               76.85ms
TTFB Max:               63.63ms
TTFB SD:                5.17ms

############### nginx-coachbloggzip_nginx/.3 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.68s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17616.1
Total Bandwidth:        643.93MB
Bandwidth Per Second:   113.44MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               64.99ms
TTFB Avg:               88.47ms
TTFB Max:               76.85ms
TTFB SD:                6.11ms

############### nginx-coachbloggzip_nginx/.4 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.55s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    18023.5
Total Bandwidth:        643.93MB
Bandwidth Per Second:   116.06MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               54.79ms
TTFB Avg:               72.65ms
TTFB Max:               64.93ms
TTFB SD:                5.07ms

############### nginx-coachbloggzip_nginx/.5 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.79s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17281.5
Total Bandwidth:        643.93MB
Bandwidth Per Second:   111.28MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               57.33ms
TTFB Avg:               78.85ms
TTFB Max:               64.61ms
TTFB SD:                4.82ms

############### nginx-coachbloggzip_nginx/.6 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.80s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17246.6
Total Bandwidth:        643.93MB
Bandwidth Per Second:   111.06MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               54.67ms
TTFB Avg:               71.90ms
TTFB Max:               63.18ms
TTFB SD:                4.77ms

############### nginx-coachbloggzip_nginx/.7 ###############
Server Name:            nginx
Server Version:         1.16.1
Benchmark Tool:         h2load-ecc256
URL:                    https://ipaddr/coachbloggzip_nginx/
Application Protocol:   h2
TLS Protocol:           TLSv1.2
Cipher:                 ECDHE-ECDSA-AES256-GCM-SHA384
Server Temp Key:        ECDH-P-256-256-bits
Total Time Spent:       5.84s
Concurrent Connections: 100
Concurrent Streams:     N/A
Total Requests:         100000
Requests Per Second:    17112.3
Total Bandwidth:        643.93MB
Bandwidth Per Second:   110.19MB
Total Failures:         0
Status Code Stats:      100000 2xx, 0 3xx, 0 4xx, 0 5xx
Header Compression:     38.50%
TTFB Min:               55.30ms
TTFB Avg:               88.84ms
TTFB Max:               69.98ms
TTFB SD:                8.75ms
```