Inspecting difference between LiteSpeed default /usr/local/lsws/conf/httpd_config.xml settings from default installed package versus the custom /usr/local/lsws/conf/httpd_config.xml that http2benchmark server.sh setup script uses.

Differences in custom httpd_config.xml settings used for http2benchmark server.sh setup to default Litespeed config for tuning settings as they relate to potential performance capabilities.

* maxConnections raised from 10,000 to 1000,000
* maxSSLConnections raised from 5,000 to 100,000

Litespeed default tuning settings in httpd_config.xml_old

```
    <tuning>
        <maxConnections>10000</maxConnections>
        <maxSSLConnections>5000</maxSSLConnections>
        <connTimeout>300</connTimeout>
        <maxKeepAliveReq>10000</maxKeepAliveReq>
        <keepAliveTimeout>5</keepAliveTimeout>
        <smartKeepAlive>0</smartKeepAlive>
        <sndBufSize>0</sndBufSize>
        <rcvBufSize>0</rcvBufSize>
        <eventDispatcher>best</eventDispatcher>
        <maxCachedFileSize>4096</maxCachedFileSize>
        <totalInMemCacheSize>20M</totalInMemCacheSize>
        <maxMMapFileSize>256K</maxMMapFileSize>
        <totalMMapCacheSize>40M</totalMMapCacheSize>
        <useSendfile>1</useSendfile>
        <useAIO>1</useAIO>
        <AIOBlockSize>4</AIOBlockSize>
        <SSLCryptoDevice>null</SSLCryptoDevice>
        <maxReqURLLen>8192</maxReqURLLen>
        <maxReqHeaderSize>16380</maxReqHeaderSize>
        <maxReqBodySize>500M</maxReqBodySize>
        <maxDynRespHeaderSize>8K</maxDynRespHeaderSize>
        <maxDynRespSize>500M</maxDynRespSize>
        <enableDynGzipCompress>1</enableDynGzipCompress>
        <enableGzipCompress>1</enableGzipCompress>
        <compressibleTypes>text/*,application/x-javascript,application/javascript,application/xml,image/svg+xml,application/rss+xml</compressibleTypes>
        <gzipAutoUpdateStatic>1</gzipAutoUpdateStatic>
    </tuning>
```

Litespeed http2benchmark server.sh setup httpd_config.xml tuning settings

```
  <tuning>
    <eventDispatcher>best</eventDispatcher>
    <maxConnections>100000</maxConnections>
    <maxSSLConnections>100000</maxSSLConnections>
    <connTimeout>300</connTimeout>
    <maxKeepAliveReq>10000</maxKeepAliveReq>
    <smartKeepAlive>0</smartKeepAlive>
    <keepAliveTimeout>5</keepAliveTimeout>
    <sndBufSize>0</sndBufSize>
    <rcvBufSize>0</rcvBufSize>
    <maxReqURLLen>8192</maxReqURLLen>
    <maxReqHeaderSize>16380</maxReqHeaderSize>
    <maxReqBodySize>500M</maxReqBodySize>
    <maxDynRespHeaderSize>8K</maxDynRespHeaderSize>
    <maxDynRespSize>500M</maxDynRespSize>
    <maxCachedFileSize>4096</maxCachedFileSize>
    <totalInMemCacheSize>20M</totalInMemCacheSize>
    <maxMMapFileSize>256K</maxMMapFileSize>
    <totalMMapCacheSize>40M</totalMMapCacheSize>
    <useSendfile>1</useSendfile>
    <useAIO>1</useAIO>
    <AIOBlockSize>4</AIOBlockSize>
    <enableGzipCompress>1</enableGzipCompress>
    <enableDynGzipCompress>1</enableDynGzipCompress>
    <gzipCompressLevel>1</gzipCompressLevel>
    <compressibleTypes>text/*,application/x-javascript,application/javascript,application/xml,image/svg+xml,application/rss+xml</compressibleTypes>
    <gzipAutoUpdateStatic>1</gzipAutoUpdateStatic>
    <gzipStaticCompressLevel>6</gzipStaticCompressLevel>
    <gzipMaxFileSize>1M</gzipMaxFileSize>
    <gzipMinFileSize>300</gzipMinFileSize>
    <SSLCryptoDevice>null</SSLCryptoDevice>
  </tuning>
```

Litespeed default httpd_config.xml_old on left versus custom httpd_config.xml config used for http2benchmark server.sh setup on right

```
cd /usr/local/lsws/conf
sdiff -s httpd_config.xml_old httpd_config.xml

<?xml version="1.0" encoding="UTF-8"?>                        | <?xml version="1.0" encoding="UTF-8"?>
<httpServerConfig>                                            | <httpServerConfig>
    <serverName>$HOSTNAME</serverName>                        |   <serverName>$HOSTNAME</serverName>
    <adminEmails>root@localhost</adminEmails>                 |   <user>apache</user>
    <priority>0</priority>                                    |   <group>apache</group>
    <autoRestart>1</autoRestart>                              |   <priority>0</priority>
    <user>apache</user>                                       |   <chrootPath>/</chrootPath>
    <group>apache</group>                                     |   <enableChroot>0</enableChroot>
    <enableChroot>0</enableChroot>                            |   <inMemBufSize>120M</inMemBufSize>
    <chrootPath>/</chrootPath>                                |   <swappingDir>/tmp/lshttpd/swap</swappingDir>
    <inMemBufSize>120M</inMemBufSize>                         |   <autoFix503>1</autoFix503>
    <autoFix503>1</autoFix503>                                |   <loadApacheConf>0</loadApacheConf>
    <loadApacheConf>0</loadApacheConf>                        |   <mime>$SERVER_ROOT/conf/mime.properties</mime>
    <mime>$SERVER_ROOT/conf/mime.properties</mime>            |   <showVersionNumber>0</showVersionNumber>
    <showVersionNumber>0</showVersionNumber>                  |   <autoUpdateInterval>86400</autoUpdateInterval>
    <autoUpdateInterval>86400</autoUpdateInterval>            |   <autoUpdateDownloadPkg>1</autoUpdateDownloadPkg>
    <autoUpdateDownloadPkg>1</autoUpdateDownloadPkg>          |   <adminEmails>root@localhost</adminEmails>
                                                              |   <adminRoot>$SERVER_ROOT/admin/</adminRoot>
    <adminRoot>$SERVER_ROOT/admin/</adminRoot>                |   <logging>
    <swappingDir>/tmp/lshttpd/swap</swappingDir>              |     <log>
    <listenerList>                                            |       <fileName>$SERVER_ROOT/logs/error.log</fileName>
        <listener>                                            |       <logLevel>ERROR</logLevel>
            <name>Default</name>                              |       <debugLevel>0</debugLevel>
            <address>*:443</address>                          |       <rollingSize>10M</rollingSize>
            <secure>0</secure>                                |       <enableStderrLog>1</enableStderrLog>
            <vhostMapList>                                    |       <enableAioLog>1</enableAioLog>
                <vhostMap>                                    |     </log>
                    <vhost>Example</vhost>                    |     <accessLog>
                    <domain>*</domain>                        |       <fileName>$SERVER_ROOT/logs/access.log</fileName>
                </vhostMap>                                   |       <rollingSize>10M</rollingSize>
            </vhostMapList>                                   |       <keepDays>30</keepDays>
        </listener>                                           |       <compressArchive>0</compressArchive>
    </listenerList>                                           |     </accessLog>
    <virtualHostList>                                         |   </logging>
        <virtualHost>                                         |   <indexFiles>index.html, index.php</indexFiles>
            <name>Example</name>                              |   <htAccess>
            <vhRoot>$SERVER_ROOT/DEFAULT/</vhRoot>            |     <allowOverride>31</allowOverride>
            <configFile>$VH_ROOT/conf/vhconf.xml</config      |     <accessFileName>.htaccess</accessFileName>
            <allowSymbolLink>1</allowSymbolLink>              |   </htAccess>
            <enableScript>1</enableScript>                    |   <expires>
            <restrained>1</restrained>                        |     <enableExpires>1</enableExpires>
            <setUIDMode>0</setUIDMode>                        |     <expiresByType>image/*=A604800, text/css=A604800, applica
            <chrootMode>0</chrootMode>                        |   </expires>
        </virtualHost>                                        |   <tuning>
    </virtualHostList>                                        |     <eventDispatcher>best</eventDispatcher>
    <vhTemplateList>                                          |     <maxConnections>100000</maxConnections>
        <vhTemplate>                                          |     <maxSSLConnections>100000</maxSSLConnections>
            <name>centralConfigLog</name>                     |     <connTimeout>300</connTimeout>
            <templateFile>$SERVER_ROOT/conf/templates/cc      |     <maxKeepAliveReq>10000</maxKeepAliveReq>
            <listeners>Default</listeners>                    |     <smartKeepAlive>0</smartKeepAlive>
        </vhTemplate>                                         |     <keepAliveTimeout>5</keepAliveTimeout>
        <vhTemplate>                                          |     <sndBufSize>0</sndBufSize>
            <name>PHP_SuEXEC</name>                           |     <rcvBufSize>0</rcvBufSize>
            <templateFile>$SERVER_ROOT/conf/templates/ph      |     <maxReqURLLen>8192</maxReqURLLen>
            <listeners>Default</listeners>                    |     <maxReqHeaderSize>16380</maxReqHeaderSize>
        </vhTemplate>                                         |     <maxReqBodySize>500M</maxReqBodySize>
        <vhTemplate>                                          |     <maxDynRespHeaderSize>8K</maxDynRespHeaderSize>
            <name>EasyRailsWithSuEXEC</name>                  |     <maxDynRespSize>500M</maxDynRespSize>
            <templateFile>$SERVER_ROOT/conf/templates/ra      |     <maxCachedFileSize>4096</maxCachedFileSize>
            <listeners>Default</listeners>                    |     <totalInMemCacheSize>20M</totalInMemCacheSize>
        </vhTemplate>                                         |     <maxMMapFileSize>256K</maxMMapFileSize>
    </vhTemplateList>                                         |     <totalMMapCacheSize>40M</totalMMapCacheSize>
                                                              |     <useSendfile>1</useSendfile>
                                                              |     <useAIO>1</useAIO>
  <extProcessorList>                                          |     <AIOBlockSize>4</AIOBlockSize>
    <extProcessor>                                            |     <enableGzipCompress>1</enableGzipCompress>
      <type>lsapi</type>                                      |     <enableDynGzipCompress>1</enableDynGzipCompress>
      <name>lsphp5</name>                                     |     <gzipCompressLevel>1</gzipCompressLevel>
      <address>uds://tmp/lshttpd/lsphp5.sock</address>        |     <compressibleTypes>text/*,application/x-javascript,applic
      <note></note>                                           |     <gzipAutoUpdateStatic>1</gzipAutoUpdateStatic>
      <maxConns>35</maxConns>                                 |     <gzipStaticCompressLevel>6</gzipStaticCompressLevel>
      <env>PHP_LSAPI_CHILDREN=35</env>                        |     <gzipMaxFileSize>1M</gzipMaxFileSize>
      <initTimeout>60</initTimeout>                           |     <gzipMinFileSize>300</gzipMinFileSize>
      <retryTimeout>0</retryTimeout>                          |     <SSLCryptoDevice>null</SSLCryptoDevice>
      <persistConn>1</persistConn>                            |   </tuning>
      <pcKeepAliveTimeout></pcKeepAliveTimeout>               |   <security>
      <respBuffer>0</respBuffer>                              |     <fileAccessControl>
      <autoStart>3</autoStart>                                |       <followSymbolLink>1</followSymbolLink>
      <path>$SERVER_ROOT/fcgi-bin/lsphp5</path>               |       <checkSymbolLink>0</checkSymbolLink>
      <backlog>100</backlog>                                  |       <requiredPermissionMask>000</requiredPermissionMask>
      <instances>1</instances>                                |       <restrictedPermissionMask>000</restrictedPermissionMask
      <runOnStartUp></runOnStartUp>                           |     </fileAccessControl>
      <extMaxIdleTime></extMaxIdleTime>                       |     <perClientConnLimit>
      <priority>0</priority>                                  |       <staticReqPerSec>0</staticReqPerSec>
      <memSoftLimit>2047M</memSoftLimit>                      |       <dynReqPerSec>0</dynReqPerSec>
      <memHardLimit>2047M</memHardLimit>                      |       <outBandwidth>0</outBandwidth>
      <procSoftLimit>400</procSoftLimit>                      |       <inBandwidth>0</inBandwidth>
      <procHardLimit>500</procHardLimit>                      |       <softLimit>10000</softLimit>
    </extProcessor>                                           |       <hardLimit>10000</hardLimit>
  </extProcessorList>                                         |       <gracePeriod>15</gracePeriod>
  <scriptHandlerList>                                         |       <banPeriod>300</banPeriod>
    <scriptHandler>                                           |     </perClientConnLimit>
      <suffix>php</suffix>                                    |     <CGIRLimit>
      <type>lsapi</type>                                      |       <maxCGIInstances>200</maxCGIInstances>
      <handler>lsphp5</handler>                               |       <minUID>11</minUID>
    </scriptHandler>                                          |       <minGID>10</minGID>
    <scriptHandler>                                           |       <priority>0</priority>
      <suffix>php5</suffix>                                   |       <CPUSoftLimit>300</CPUSoftLimit>
      <type>lsapi</type>                                      |       <CPUHardLimit>600</CPUHardLimit>
      <handler>lsphp5</handler>                               |       <memSoftLimit>1450M</memSoftLimit>
      <note></note>                                           |       <memHardLimit>1500M</memHardLimit>
    </scriptHandler>                                          |       <procSoftLimit>1400</procSoftLimit>
  </scriptHandlerList>                                        |       <procHardLimit>1450</procHardLimit>
                                                              |     </CGIRLimit>
  <phpConfig>                                                 |     <censorshipControl>
    <maxConns>35</maxConns>                                   |       <enableCensorship>0</enableCensorship>
    <env>PHP_LSAPI_CHILDREN=35</env>                          |       <logLevel>0</logLevel>
    <initTimeout>60</initTimeout>                             |       <defaultAction>deny,log,status:403</defaultAction>
    <retryTimeout>0</retryTimeout>                            |       <scanPOST>1</scanPOST>
    <pcKeepAliveTimeout>1</pcKeepAliveTimeout>                |     </censorshipControl>
    <respBuffer>0</respBuffer>                                |     <accessDenyDir>
    <extMaxIdleTime>60</extMaxIdleTime>                       |       <dir>/</dir>
    <memSoftLimit>2047M</memSoftLimit>                        |       <dir>/etc/*</dir>
    <memHardLimit>2047M</memHardLimit>                        |       <dir>/dev/*</dir>
    <procSoftLimit>400</procSoftLimit>                        |       <dir>$SERVER_ROOT/conf/*</dir>
    <procHardLimit>500</procHardLimit>                        |       <dir>$SERVER_ROOT/admin/conf/*</dir>
  </phpConfig>                                                |     </accessDenyDir>
  <railsDefaults>                                             |     <accessControl>
    <rubyBin></rubyBin>                                       |       <allow>ALL</allow>
    <railsEnv>1</railsEnv>                                    |     </accessControl>
    <maxConns>5</maxConns>                                    |   </security>
    <env>LSAPI_MAX_IDLE=60</env>                              |   <extProcessorList>
    <initTimeout>180</initTimeout>                            |     <extProcessor>
    <retryTimeout>0</retryTimeout>                            |       <type>lsapi</type>
    <pcKeepAliveTimeout>60</pcKeepAliveTimeout>               |       <name>lsphp72</name>
    <respBuffer>0</respBuffer>                                |       <address>uds://tmp/lshttpd/lsphp72.sock</address>
    <backlog>50</backlog>                                     |       <maxConns>2000</maxConns>
    <runOnStartUp>1</runOnStartUp>                            |       <env>PHP_LSAPI_CHILDREN=2000</env>
    <extMaxIdleTime></extMaxIdleTime>                         |       <initTimeout>60</initTimeout>
    <priority>3</priority>                                    |       <retryTimeout>0</retryTimeout>
    <memSoftLimit>2047M</memSoftLimit>                        |       <persistConn>1</persistConn>
    <memHardLimit>2047M</memHardLimit>                        |       <respBuffer>0</respBuffer>
    <procSoftLimit>400</procSoftLimit>                        |       <autoStart>3</autoStart>
    <procHardLimit>500</procHardLimit>                        |       <path>/usr/bin/lsphp</path>
  </railsDefaults>                                            |       <backlog>100</backlog>
                                                              |       <instances>1</instances>
    <tuning>                                                  |       <priority>0</priority>
        <maxConnections>10000</maxConnections>                |       <memSoftLimit>2047M</memSoftLimit>
        <maxSSLConnections>5000</maxSSLConnections>           |       <memHardLimit>2047M</memHardLimit>
        <connTimeout>300</connTimeout>                        |       <procSoftLimit>1000</procSoftLimit>
        <maxKeepAliveReq>10000</maxKeepAliveReq>              |       <procHardLimit>1000</procHardLimit>
        <keepAliveTimeout>5</keepAliveTimeout>                |     </extProcessor>
        <smartKeepAlive>0</smartKeepAlive>                    |   </extProcessorList>
        <sndBufSize>0</sndBufSize>                            |   <scriptHandlerList>
        <rcvBufSize>0</rcvBufSize>                            |     <scriptHandler>
        <eventDispatcher>best</eventDispatcher>               |       <suffix>php</suffix>
        <maxCachedFileSize>4096</maxCachedFileSize>           |       <type>lsapi</type>
        <totalInMemCacheSize>20M</totalInMemCacheSize>        |       <handler>lsphp72</handler>
        <maxMMapFileSize>256K</maxMMapFileSize>               |     </scriptHandler>
        <totalMMapCacheSize>40M</totalMMapCacheSize>          |     <scriptHandler>
        <useSendfile>1</useSendfile>                          |       <suffix>php5</suffix>
        <useAIO>1</useAIO>                                    |       <type>lsapi</type>
        <AIOBlockSize>4</AIOBlockSize>                        |       <handler>lsphp72</handler>
        <SSLCryptoDevice>null</SSLCryptoDevice>               |     </scriptHandler>
        <maxReqURLLen>8192</maxReqURLLen>                     |   </scriptHandlerList>
        <maxReqHeaderSize>16380</maxReqHeaderSize>            |   <cache>
        <maxReqBodySize>500M</maxReqBodySize>                 |     <storage>
        <maxDynRespHeaderSize>8K</maxDynRespHeaderSize>       |       <cacheStorePath>/home/lscache/</cacheStorePath>
        <maxDynRespSize>500M</maxDynRespSize>                 |     </storage>
        <enableDynGzipCompress>1</enableDynGzipCompress>      |   </cache>
        <enableGzipCompress>1</enableGzipCompress>            |   <phpConfig>
        <compressibleTypes>text/*,application/x-javascri      |     <maxConns>35</maxConns>
        <gzipAutoUpdateStatic>1</gzipAutoUpdateStatic>        |     <env>PHP_LSAPI_CHILDREN=35</env>
    </tuning>                                                 |     <initTimeout>60</initTimeout>
    <logging>                                                 |     <retryTimeout>0</retryTimeout>
        <log>                                                 |     <pcKeepAliveTimeout>1</pcKeepAliveTimeout>
            <fileName>$SERVER_ROOT/logs/error.log</fileN      |     <respBuffer>0</respBuffer>
            <logLevel>DEBUG</logLevel>                        |     <extMaxIdleTime>60</extMaxIdleTime>
            <debugLevel>0</debugLevel>                        |     <memSoftLimit>2047M</memSoftLimit>
            <rollingSize>10M</rollingSize>                    |     <memHardLimit>2047M</memHardLimit>
            <enableStderrLog>1</enableStderrLog>              |     <procSoftLimit>400</procSoftLimit>
            <enableAioLog>1</enableAioLog>                    |     <procHardLimit>500</procHardLimit>
        </log>                                                |   </phpConfig>
        <accessLog>                                           |   <railsDefaults>
            <fileName>$SERVER_ROOT/logs/access.log</file      |     <railsEnv>1</railsEnv>
            <keepDays>30</keepDays>                           |     <maxConns>5</maxConns>
            <rollingSize>10M</rollingSize>                    |     <env>LSAPI_MAX_IDLE=60</env>
            <logReferer>1</logReferer>                        |     <initTimeout>180</initTimeout>
            <logUserAgent>1</logUserAgent>                    |     <retryTimeout>0</retryTimeout>
            <compressArchive>0</compressArchive>              |     <pcKeepAliveTimeout>60</pcKeepAliveTimeout>
        </accessLog>                                          |     <respBuffer>0</respBuffer>
    </logging>                                                |     <backlog>50</backlog>
    <indexFiles>index.html, index.php</indexFiles>            |     <runOnStartUp>1</runOnStartUp>
    <htAccess>                                                |     <priority>3</priority>
        <allowOverride>0</allowOverride>                      |     <memSoftLimit>2047M</memSoftLimit>
        <accessFileName>.htaccess</accessFileName>            |     <memHardLimit>2047M</memHardLimit>
    </htAccess>                                               |     <procSoftLimit>400</procSoftLimit>
    <expires>                                                 |     <procHardLimit>500</procHardLimit>
        <enableExpires>1</enableExpires>                      |   </railsDefaults>
        <expiresByType>image/*=A604800, text/css=A604800      |   <virtualHostList>
   </expires>                                                 |     <virtualHost>
   <security>                                                 |       <name>Example</name>
        <accessDenyDir>                                       |       <vhRoot>$SERVER_ROOT/DEFAULT/</vhRoot>
            <dir>/</dir>                                      |       <configFile>$VH_ROOT/conf/vhconf.xml</configFile>
            <dir>/etc/*</dir>                                 |       <allowSymbolLink>1</allowSymbolLink>
            <dir>/dev/*</dir>                                 |       <enableScript>1</enableScript>
            <dir>$SERVER_ROOT/conf/*</dir>                    |       <restrained>0</restrained>
            <dir>$SERVER_ROOT/admin/conf/*</dir>              |       <setUIDMode>0</setUIDMode>
        </accessDenyDir>                                      |       <chrootMode>0</chrootMode>
        <CGIRLimit>                                           |     </virtualHost>
            <maxCGIInstances>200</maxCGIInstances>            |   </virtualHostList>
            <minUID>11</minUID>                               |   <listenerList>
            <minGID>10</minGID>                               |     <listener>
            <priority>0</priority>                            |       <name>HTTPS</name>
            <CPUSoftLimit>300</CPUSoftLimit>                  |       <address>*:443</address>
            <CPUHardLimit>600</CPUHardLimit>                  |       <reusePort>0</reusePort>
            <memSoftLimit>1450M</memSoftLimit>                |       <binding>1</binding>
            <memHardLimit>1500M</memHardLimit>                |       <secure>1</secure>
            <procSoftLimit>1400</procSoftLimit>               |       <vhostMapList>
            <procHardLimit>1450</procHardLimit>               |         <vhostMap>
        </CGIRLimit>                                          |           <vhost>Example</vhost>
        <perClientConnLimit>                                  |           <domain>*</domain>
                                                              |         </vhostMap>
                                                              |       </vhostMapList>
            <staticReqPerSec>0</staticReqPerSec>              |       <keyFile>/etc/ssl/http2benchmark.key</keyFile>
            <dynReqPerSec>0</dynReqPerSec>                    |       <certFile>/etc/ssl/http2benchmark.crt</certFile>
            <outBandwidth>0</outBandwidth>                    |     </listener>
            <inBandwidth>0</inBandwidth>                      |     <listener>
            <softLimit>10000</softLimit>                      |       <name>HTTP</name>
            <hardLimit>10000</hardLimit>                      |       <address>*:80</address>
            <gracePeriod>15</gracePeriod>                     |       <secure>0</secure>
            <banPeriod>300</banPeriod>                        |       <vhostMapList>
        </perClientConnLimit>                                 |         <vhostMap>
        <fileAccessControl>                                   |           <vhost>Example</vhost>
            <followSymbolLink>1</followSymbolLink>            |           <domain>*</domain>
            <checkSymbolLink>0</checkSymbolLink>              |         </vhostMap>
            <requiredPermissionMask>000</requiredPermiss      |       </vhostMapList>
            <restrictedPermissionMask>000</restrictedPer      |     </listener>
        </fileAccessControl>                                  |   </listenerList>
    <censorshipControl>                                       |   <vhTemplateList>
      <enableCensorship>0</enableCensorship>                  |     <vhTemplate>
      <logLevel>0</logLevel>                                  |       <name>centralConfigLog</name>
      <defaultAction>deny,log,status:403</defaultAction>      |       <templateFile>$SERVER_ROOT/conf/templates/ccl.xml</temp
      <scanPOST>1</scanPOST>                                  |       <listeners>HTTPS</listeners>
    </censorshipControl>                                      |     </vhTemplate>
    <censorshipRuleSet>                                       |     <vhTemplate>
    </censorshipRuleSet>                                      |       <name>PHP_SuEXEC</name>
                                                              |       <templateFile>$SERVER_ROOT/conf/templates/phpsuexec.xml
        <accessControl>                                       |       <listeners>HTTPS</listeners>
            <allow>ALL</allow>                                |     </vhTemplate>
            <deny></deny>                                     |     <vhTemplate>
        </accessControl>                                      |       <name>EasyRailsWithSuEXEC</name>
    </security>                                               |       <templateFile>$SERVER_ROOT/conf/templates/rails.xml</te
</httpServerConfig>                                           |       <listeners>HTTPS</listeners>
                                                              |     </vhTemplate>
                                                              >   </vhTemplateList>
                                                              > </httpServerConfig>
```