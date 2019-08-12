# Self-signed SSL certificates used for benchmark testing

Prior to runing `server.sh`, in forked version you can choose to use pre-generated self-signed SSL certificates via 3 variables in `server.sh` which are outlined below instead of having to generate the self-signed SSL certificates everytime. HTTP/2 HTTPS benchmarks and performance also depend on the type and size of SSL certificate served by the web server. So having a more common pre-generated self-signed SSL certificate will provide more comparable benchmark results.

* DEFAULT_SSLCERTS='n' - when set to `y`, use default http2benchmark pre-generated RSA 2048bit self-signed SSL certificates. Copied to `/etc/ssl` directory.
* SANS_SSLCERTS='n' - when set to `y`, use pre-generated RSA 2048bit self-signed SSL certificates with proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added. Copied to `/etc/ssl` directory.
* SANSECC_SSLCERTS='n' - when set to `y`, use pre-generated ECDSA 256bit self-signed SSL certificates with proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added. Copied to `/etc/ssl` directory.
*  SANS_SSLCERTS='y' + SANSECC_SSLCERTS='y' - if both variables are set to `y`, then use both sets of pre-generated RSA 2048bit & ECDSA 256bit self-signed SSL certificates. For RSA 2048bit,` http2benchmark.crt` & `http2benchmark.key` named and for ECDSA 256bit, `http2benchmark.ecc.crt` & `http2benchmark.ecc.key` named. Copied to `/etc/ssl` directory.

There are 3 sets available and usually will be saved to `/etc/ssl` directory when you run `setup/server/server.sh` on server:

1. [Default http2benchmark original](https://github.com/http2benchmark/http2benchmark) RSA 2048bit self-signed SSL certifcate and key. Just with extended expiry date from 365 days to 36500 days.

* http2benchmark.crt
* http2benchmark.key

2. RSA 2048bit self-signed SSL certificate with 36500 days expiry which has proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added to SSL certificate

* http2benchmarksans.crt
* http2benchmarksans.key

3. ECDSA 256bit self-signed SSL certificate with 36500 days expiry which has proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added to SSL certificate

* http2benchmarksans.ecc.crt
* http2benchmarksans.ecc.key

Comparison of sizes

```
drwxr-xr-x  2 root root 4096 Aug 12 11:14 .
drwxr-xr-x 37 root root 4096 Aug 12 10:52 ..
-rw-r--r--  1 root root 1330 Aug 12 11:20 http2benchmark.crt
-rw-r--r--  1 root root 1704 Aug 12 11:20 http2benchmark.key
-rw-r--r--  1 root root 1489 Aug 12 11:05 http2benchmarksans.crt
-rw-r--r--  1 root root  956 Aug 12 11:14 http2benchmarksans.ecc.crt
-rw-r--r--  1 root root  302 Aug 12 11:14 http2benchmarksans.ecc.key
-rw-r--r--  1 root root 1704 Aug 12 11:05 http2benchmarksans.key
```

# Inspecting the self-signed SSL certificates

1. default RSA 2048bit self-signed without [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName)

```
openssl x509 -noout -text < http2benchmark.crt                                                    
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            9b:db:88:76:b6:2b:c6:6e
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, ST=NJ, L=Virtual, O=HTTP2benchmark, OU=Testing, CN=webadmin
        Validity
            Not Before: Aug 12 11:20:41 2019 GMT
            Not After : Jul 19 11:20:41 2119 GMT
        Subject: C=US, ST=NJ, L=Virtual, O=HTTP2benchmark, OU=Testing, CN=webadmin
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:bf:db:01:01:70:8e:ce:98:18:e1:83:39:1a:da:
                    17:d8:0c:ba:f9:ff:23:7e:3b:9f:37:53:20:af:bf:
                    89:d9:70:03:07:e1:50:48:12:2d:48:81:f3:f5:fd:
                    de:b8:09:c8:e1:29:78:53:89:b2:c4:79:e4:2c:73:
                    c0:39:93:a9:02:83:77:34:35:c9:bf:35:75:78:c0:
                    4f:fd:bd:0a:3f:8a:c2:df:83:6f:de:82:0e:64:59:
                    96:0e:ba:20:52:a5:2c:b8:a8:1f:0b:2d:83:c2:21:
                    ba:01:37:28:6a:ce:27:84:9e:23:2b:24:1b:72:8b:
                    b3:ae:f0:69:c4:8c:25:a8:c2:1d:4d:f8:4d:39:21:
                    b4:90:d4:b7:07:2c:b9:d2:22:da:c7:6c:37:47:61:
                    1b:41:c4:dd:e9:5d:a3:8b:48:fb:39:06:15:61:61:
                    00:94:35:25:2d:e2:7c:84:64:48:ab:52:39:c1:42:
                    63:23:70:ee:09:e5:ca:0c:84:ff:67:73:2f:07:c6:
                    42:87:16:85:54:63:ea:80:c9:2f:82:95:fa:d0:f6:
                    af:95:d9:77:05:cd:8a:af:d1:16:86:a0:11:d1:02:
                    6d:6b:e1:e8:f4:bd:58:16:da:28:32:6b:c0:7e:9d:
                    9f:e7:b6:14:18:89:5c:2a:58:28:e1:6e:c9:2f:4e:
                    da:33
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                2C:E3:E9:73:F0:7C:86:00:16:64:CE:29:61:34:60:2F:83:98:05:E1
            X509v3 Authority Key Identifier: 
                keyid:2C:E3:E9:73:F0:7C:86:00:16:64:CE:29:61:34:60:2F:83:98:05:E1

            X509v3 Basic Constraints: 
                CA:TRUE
    Signature Algorithm: sha256WithRSAEncryption
         06:d3:86:ca:0e:ed:f0:1d:af:f2:3c:f3:a9:3a:be:d4:48:66:
         f1:50:53:c4:00:8d:19:46:38:2d:8d:4c:22:27:c5:a0:eb:31:
         b2:17:6e:36:92:c1:33:fa:22:ea:3d:fc:e7:bc:3b:85:da:de:
         0d:4f:d6:0a:0b:92:49:c9:21:6f:b7:4c:85:8b:83:11:fe:13:
         f7:0f:5d:20:02:90:6a:5a:67:78:c1:ec:50:b7:06:dd:3e:81:
         86:59:41:59:e6:cc:82:bb:d4:9a:33:af:67:13:bf:1f:a1:5e:
         bd:b5:1a:db:2f:8c:b7:ae:64:af:cd:35:d1:71:40:48:f4:35:
         24:4f:01:28:90:10:7c:94:bb:de:b2:5a:95:c6:22:6b:60:e3:
         40:ba:c5:82:30:a4:84:ae:cd:a6:26:91:ff:1d:f0:34:48:0b:
         c8:0f:6d:95:c9:47:4f:08:01:6c:46:e5:52:6c:4c:23:22:f3:
         7d:dd:d2:8b:2f:ec:09:59:c6:44:81:ba:a0:4e:c5:04:cd:c2:
         61:13:b4:af:df:eb:78:cb:ff:9d:32:96:4f:52:40:f8:cf:83:
         a5:f6:bd:49:50:43:aa:b4:d7:9a:ad:f3:de:6c:50:24:85:71:
         ff:54:62:c5:ec:13:52:e9:07:c0:87:af:62:b8:1b:a7:5d:9e:
         f2:44:0a:39
```

2. RSA 2048bit self-signed SSL certificate with 36500 days expiry which has proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added to SSL certificate

```
openssl x509 -noout -text < http2benchmarksans.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            a4:38:d6:e0:48:e5:6d:05
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, ST=NJ, L=Virtual, O=HTTP2benchmark, OU=Testing, CN=webadmin
        Validity
            Not Before: Aug 12 11:05:52 2019 GMT
            Not After : Jul 19 11:05:52 2119 GMT
        Subject: C=US, ST=NJ, L=Virtual, O=HTTP2benchmark, OU=Testing, CN=webadmin
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:d8:e6:09:5f:26:a8:85:dd:1b:76:0c:1b:1c:59:
                    97:70:0e:4b:3c:06:ff:00:f0:ad:0b:73:71:9f:32:
                    43:32:95:6c:60:4b:2e:98:ba:be:6d:5b:92:f7:e0:
                    a0:9a:59:ce:ac:13:70:80:27:0f:2a:ea:3e:7f:db:
                    c3:fe:48:01:21:3d:f6:c1:d9:3a:43:5a:28:a0:67:
                    26:11:f1:71:35:01:0f:11:0c:55:c7:bd:3d:5d:13:
                    6d:5d:0b:37:5d:d2:21:21:17:b3:ed:fb:11:57:10:
                    84:f0:84:96:2f:0b:77:6f:a1:06:33:fc:d9:d3:67:
                    f7:e9:ee:5a:78:cd:09:cd:81:18:6f:c3:60:fc:b3:
                    4b:a8:65:4c:8d:e8:c6:fa:ae:ec:48:f0:65:61:34:
                    fc:a3:80:ef:fc:bb:9b:3f:24:f5:83:5c:a7:6f:b6:
                    f6:02:53:6b:aa:a6:c2:74:7b:67:42:35:11:d2:3f:
                    17:5b:28:30:8b:59:4f:df:fd:d5:ee:19:f9:43:cc:
                    6a:80:82:fc:c4:c9:1b:c9:9f:69:e7:55:eb:29:bf:
                    ed:a0:97:70:65:e7:47:00:9b:dc:17:90:16:0b:42:
                    80:c4:b5:fa:97:2d:35:8f:29:09:85:07:c9:c6:60:
                    1c:77:18:3d:c2:8b:88:f8:7e:67:9b:05:57:22:77:
                    9e:a5
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Authority Key Identifier: 
                DirName:/C=US/ST=NJ/L=Virtual/O=HTTP2benchmark/OU=Testing/CN=webadmin
                serial:A4:38:D6:E0:48:E5:6D:05

            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Key Usage: 
                Digital Signature, Non Repudiation, Key Encipherment, Data Encipherment
            X509v3 Subject Alternative Name: 
                DNS:webadmin, DNS:www.webadmin
    Signature Algorithm: sha256WithRSAEncryption
         1b:07:1d:e5:58:a1:10:a5:cb:a1:6c:58:12:eb:03:6e:ad:2d:
         e4:e7:8e:eb:8b:f7:32:3c:94:a7:b2:b8:b4:f7:d3:f9:57:53:
         d2:d2:62:f4:8f:51:66:3c:8e:e7:4d:69:be:b4:79:41:73:24:
         89:a8:19:b8:08:34:4c:19:93:49:2a:e5:f8:53:bb:2b:8d:e1:
         49:1f:b7:69:cc:12:c4:eb:b7:4b:6b:ce:73:7a:2b:3a:c2:43:
         b5:a9:77:43:6b:05:c7:34:9d:58:34:3b:37:b1:ee:da:09:1b:
         df:09:ff:da:f1:80:f8:30:80:dd:41:62:a6:67:41:c3:c6:05:
         26:84:86:8a:a4:b9:87:d8:39:5f:67:78:9f:99:d1:3f:f8:f6:
         f6:76:1a:3b:ca:3c:61:ac:39:9c:76:68:2c:26:8b:e1:4d:b6:
         9d:0a:fb:50:1a:66:29:a1:e2:12:0c:1e:d0:2f:84:2f:c4:e7:
         f4:92:dd:d3:3e:8a:e5:90:6b:7e:05:30:59:e8:59:d8:6c:79:
         55:42:c2:f1:fc:55:86:76:7b:fc:7b:e9:9b:7a:87:0a:d2:73:
         9e:5b:66:ef:80:67:cd:f2:9c:b9:66:c2:0f:f0:56:c0:31:07:
         16:b2:ce:f1:96:03:d1:37:66:72:02:35:d9:00:ee:28:72:96:
         09:9f:73:ae
```

3. ECDSA 256bit self-signed SSL certificate with 36500 days expiry which has proper [V3 compatible subjectAltName field](http://wiki.cacert.org/FAQ/subjectAltName) added to SSL certificate

```
openssl x509 -noout -text < http2benchmarksans.ecc.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            ab:70:7a:bd:60:4f:5f:18
    Signature Algorithm: ecdsa-with-SHA256
        Issuer: C=US, ST=NJ, L=Virtual, O=HTTP2benchmark, OU=Testing, CN=webadmin
        Validity
            Not Before: Aug 12 11:14:33 2019 GMT
            Not After : Jul 19 11:14:33 2119 GMT
        Subject: C=US, ST=NJ, L=Virtual, O=HTTP2benchmark, OU=Testing, CN=webadmin
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub: 
                    04:f8:4c:ca:5c:6f:49:40:a8:b5:89:e0:72:3a:d6:
                    7b:fb:7d:bc:c4:86:58:4a:0d:cd:ac:20:54:21:a4:
                    04:dd:2b:95:f4:d3:07:a5:af:2d:e9:d6:3f:ff:63:
                    64:f5:ff:db:84:ae:00:07:22:d8:60:ac:59:ed:ee:
                    94:fe:d7:4e:63
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Authority Key Identifier: 
                DirName:/C=US/ST=NJ/L=Virtual/O=HTTP2benchmark/OU=Testing/CN=webadmin
                serial:AB:70:7A:BD:60:4F:5F:18

            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Key Usage: 
                Digital Signature, Non Repudiation, Key Encipherment, Data Encipherment
            X509v3 Subject Alternative Name: 
                DNS:webadmin, DNS:www.webadmin
    Signature Algorithm: ecdsa-with-SHA256
         30:46:02:21:00:d1:45:13:cb:83:c6:3f:84:6c:f1:d6:93:35:
         94:b2:5b:0f:98:9a:81:f7:0e:4b:73:5f:0c:c6:04:47:fc:7c:
         c7:02:21:00:c0:14:67:81:4d:53:e9:71:7a:b1:e5:8b:f4:05:
         4b:67:01:13:3d:ae:5f:48:7c:74:74:a9:cf:67:0d:31:19:b6
```