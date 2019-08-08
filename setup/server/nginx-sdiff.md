Inspecting difference between Nginx default /etc/nginx/nginx.conf settings from default installed package versus the custom /etc/nginx/nginx.conf that http2benchmark server.sh setup script uses.

Nginx default nginx.conf_old on left versus custom nginx.conf config used for http2benchmark server.sh setup on right

```
cd /etc/nginx
sdiff -s nginx.conf_old nginx.conf

sdiff -s nginx.conf_old nginx.conf
                                                              | user apache;
user  nginx;                                                  <
                                                              >     multi_accept        on;
                                                              >     use                 epoll;
    access_log  /var/log/nginx/access.log  main;              |     #access_log  /var/log/nginx/access.log  main;
                                                              |     error_log  /dev/null   crit;
    sendfile        on;                                       |     access_log off;
    #tcp_nopush     on;                                       |
                                                              |     client_body_buffer_size 10K;
    keepalive_timeout  65;                                    |     client_header_buffer_size 1k;
                                                              |     client_max_body_size 8m;
    #gzip  on;                                                |     large_client_header_buffers 4 4k;
                                                              >     client_body_timeout 12;
                                                              >     client_header_timeout 12;
                                                              >
                                                              >     sendfile           on;
                                                              >     send_timeout       10;
                                                              >     tcp_nopush         on;
                                                              >     tcp_nodelay        on;
                                                              >     keepalive_timeout  15;
                                                              >
                                                              >     gzip  on;
                                                              >     gzip_vary on;
                                                              >     gzip_comp_level 1;
                                                              >     gzip_min_length 300;
                                                              >     gzip_proxied expired no-cache no-store private auth;
                                                              >     gzip_types text/plain text/css text/xml text/javascript a
                                                              >     gzip_disable "MSIE [1-6]\.";
                                                              >     gzip_buffers 16 8k;
                                                              >
                                                              >     open_file_cache max=200000 inactive=20s;
                                                              >     open_file_cache_valid 30s;
                                                              >     open_file_cache_min_uses 2;
                                                              >     open_file_cache_errors on;
```