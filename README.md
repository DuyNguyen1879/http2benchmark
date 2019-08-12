# HTTP2Benchmark
[<img src="https://img.shields.io/badge/Made%20with-BASH-orange.svg">](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) 

`extended-tests` forked branch can be searched via [Sourcegraph](https://sourcegraph.com/github.com/centminmod/http2benchmark@extended-tests)

# Web servers

This forked version also adds ability to switch from testing Nginx 1.16 stable version to testing Nginx mainline 1.17 version via a new `setup/server/server.sh` variable `NGINX_MAINLINE='n'` which is default disabled to test original Nginx 1.16 stable version. Setting to `NGINX_MAINLINE='y'` prior to running `setup/server/server.sh` will install Nginx mainline 1.17 instead.

# Test Tools

This forked version adds to `/opt/benchmark.sh` some additional test tools and testing profiles to the original mix of h2load, wrk, siege, jmeter of which h2load and wrk are enabled by default. The following test tools are available and defined in variable which defaults to `TOOL_LIST="h2load wrk"`:

* h2load - nghttp2 library's [h2load HTTP/2 HTTPS load testing tool](https://nghttp2.org/documentation/h2load-howto.html).
* h2load-low - h2load test but with reduced request number tested instead of h2load's 100,000 requests test, reduced to 5,000 requests to allow testing on network constrained systems <=1Gbps.
* h2load-m80 - h2load test with one minor change with more realistic HTTP/2 max concurrent streams = 80 given the average web site has approximately 74 assets according to [HTTP Archive](https://httparchive.org/reports/page-weight#reqTotal).
* wrk - original HTTP/1.1 load testing tool from https://github.com/wg/wrk
* wrkcmm - forked version of wrk with additional features outlined at https://github.com/centminmod/wrk/tree/centminmod. By default tests same paramters as original wrk.

So if you were to run additional test tools, you'd edit `/opt/benchmark.sh` like below:

```
TOOL_LIST="h2load h2load-low h2load-m80 wrk wrkcmm"
```

Example benchmark results posted [here](https://gist.github.com/centminmod/6980694c38dc39c5fc9325b581cfd036).

# Test Targets

The following test targets are benchmarked by default

* `1kstatic.html` - 1kb static html file
* `1kgzip-static.html` - 1kb static html file that has been gzip pre-compressed (leverage nginx [gzip_static](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html#gzip_static) directive)
* `1knogzip.jpg` - 1kb jpg image
* `amdepyc2.jpg.webp` - 11kb webP image
* `amdepyc2.jpg` - 26kb jpg image
* `wordpress` - wordpress php/mariadb mysql test where apache uses w3 total cache plugin, litespeed uses litespeed cache plugin and nginx uses php-fpm fastgci_cache caching
* `coachblog` - [wordpress OceanWP Coach theme](https://github.com/centminmod/testpages) test blog static html version simulating wordpress cache plugins which do full page static html caching
* `coachbloggzip` - precompress gzip [wordpress OceanWP Coach theme](https://github.com/centminmod/testpages) test blog static html version simulating wordpress cache plugins which do full page static html caching i.e. [Cache Enabler wordpress plugin](https://wordpress.org/plugins/cache-enabler/) + [Autoptimize wordpress plugin](https://wordpress.org/plugins/autoptimize/) + [Autoptimize Gzip companion plugin](https://github.com/centminmod/autoptimize-gzip). Such combo allows Wordpress site to do full page static html caching with pre-compressed gzipped static assets for html, css and js which can leverage nginx [gzip_static](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html#gzip_static) directive.

# Preparation 
  - Two servers, one is Test Server and the other one is Client Server
  - You need to have root ssh access for both servers
  - There should be no firewall blocking ports 22, 80, 443, or 5001

# Firewalld whitelisted ports

```
firewall-cmd --permanent --zone=public --add-port=22/tcp
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=5001/tcp
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
firewall-cmd --zone=public --list-services
```

# How to benchmark

## Server install

``` bash
git clone -b extended-tests https://github.com/centminmod/http2benchmark.git
```
``` bash
http2benchmark/setup/server/server.sh | tee server.log
```

Prior to running `server.sh`, in forked version you can choose to use pre-generated self-signed SSL certificates via 3 variables in `server.sh` which are outlined below and [here](https://github.com/centminmod/http2benchmark/tree/extended-tests/setup/server/ssl-certificates) instead of having to generate the self-signed SSL certificates everytime. HTTP/2 HTTPS benchmarks and performance also depend on the type and size of SSL certificate served by the web server. So having a more common pre-generated self-signed SSL certificate will provide more comparable benchmark results.

* DEFAULT_SSLCERTS='n' - when set to `y`, use default http2benchmark pre-generated RSA 2048bit self-signed SSL certificates. Copied to `/etc/ssl` directory.
* SANS_SSLCERTS='n' - when set to `y`, use pre-generated RSA 2048bit self-signed SSL certificates with proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added. Copied to `/etc/ssl` directory.
* SANSECC_SSLCERTS='n' - when set to `y`, use pre-generated ECDSA 256bit self-signed SSL certificates with proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added. Copied to `/etc/ssl` directory.
*  SANS_SSLCERTS='y' + SANSECC_SSLCERTS='y' - if both variables are set to `y`, then use both sets of pre-generated RSA 2048bit & ECDSA 256bit self-signed SSL certificates. For RSA 2048bit,` http2benchmark.crt` & `http2benchmark.key` named and for ECDSA 256bit, `http2benchmark.ecc.crt` & `http2benchmark.ecc.key` named. Copied to `/etc/ssl` directory.

## Client install

``` bash
git clone -b extended-tests https://github.com/centminmod/http2benchmark.git
```
``` bash
http2benchmark/setup/client/client.sh | tee client.log
```

You will be required to input [Test Server IP], [copy the public key to the Test server], and then [click any key] to finish the installation, like so:
``` bash
Please input target server IP to continue: [Test Server IP]
```
``` bash
Please add the following key to ~/.ssh/authorized_keys on the Test server
ssh-rsa .................................................................
.........................................................................
.. root@xxx-client
```
``` bash
Once complete, click ANY key to continue: 
```

## How to test
Run the following command in client server:
``` bash
/opt/benchmark.sh | tee benchmark.log
```

You can optionally test against wrk forked version [`wrk-cmm`](https://github.com/centminmod/wrk/tree/centminmod) by editing `/opt/benchmark.sh` adding it to `TOOL_LIST` (note minus the hyphen is correct):

```
TOOL_LIST="h2load wrk wrkcmm"
```

## Log 
After benchmark testing is complete, you will see the result displayed on the console

The log will be stored under `/opt/Benchmark/TIME_STAMP/`:
```
/opt/Benchmark/
   |_TIME_STAMP.tgz
   |_TIME_STAMP 
       |_RESULTS.csv
       |_RESULTS.txt
       |_apache
       |_lsws
       |_nginx
       |_env
```

# Feedback
You may also raise any issues in the http2benchmark repository.
