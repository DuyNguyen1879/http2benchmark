# HTTP2Benchmark
[<img src="https://img.shields.io/badge/Made%20with-BASH-orange.svg">](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) 

`extended-tests` branch can be searched via [Sourcegraph](https://sourcegraph.com/github.com/centminmod/http2benchmark@extended-tests)

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
