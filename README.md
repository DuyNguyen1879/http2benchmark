# HTTP2Benchmark
[<img src="https://img.shields.io/badge/Made%20with-BASH-orange.svg">](https://en.wikipedia.org/wiki/Bash_(Unix_shell)) 

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
