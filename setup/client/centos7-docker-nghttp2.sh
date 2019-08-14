#!/bin/bash
####################################################
# install newer version of nghttp2's h2load support
# for TLSv1.3 via docker image
# https://hub.docker.com/r/centminmod/docker-ubuntu-nghttp2-minimal
####################################################
INSTALL_DOCKER='y'
INSTALL_NGHTTPNEW='y'
INSTALL_NGHTTPNEWER='y'

silent() {
  if [[ $debug ]] ; then
    "$@"
  else
    "$@" >/dev/null 2>&1
  fi
}

docker_install() {
if [[ ! -f /usr/bin/docker && "$INSTALL_DOCKER" = [yY] ]]; then
  echo
  echo "---------------------------------------------"
  echo "docker install"
  echo "---------------------------------------------"
  silent yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  silent yum -q -y install yum-utils device-mapper-persistent-data lvm2 jq
  silent yum -q -y install docker-ce
  mkdir -p /etc/systemd/system/docker.service.d
  touch /etc/systemd/system/docker.service.d/docker.conf
  mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
    "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF
  silent systemctl daemon-reload
  silent systemctl start docker
  silent systemctl enable docker
  echo
  echo "docker info"
  docker info
fi
}

h2load_install() {
  # install nghttp2 docker minimal image
  # https://cloud.docker.com/repository/docker/centminmod/docker-ubuntu-nghttp2-minimal
  if [[ "$INSTALL_NGHTTPNEW" = [yY] ]]; then
    echo
    echo "---------------------------------------------"
    echo "h2load docker image install"
    echo "setup h2loadnew cmd alias"
    echo "---------------------------------------------"
    if [[ -f /usr/bin/docker && "$(docker ps --format "{{.Names}}" | grep 'nghttp-min')" = 'nghttp-min' ]]; then
      silent docker stop nghttp-min
      silent docker rm nghttp-min
      silent docker rmi centminmod/docker-ubuntu-nghttp2-minimal
    fi
    docker run -tid --restart=always --net=host --name nghttp-min centminmod/docker-ubuntu-nghttp2-minimal
    # setup docker management cmd aliases
    # if [[ ! "$(grep -w 'alias h2loadnew' /root/.bashrc)" ]]; then
    #   echo "alias h2loadnew='docker restart nghttp-min >/dev/null 2>&1; docker exec -ti nghttp-min h2load'" >> /root/.bashrc
    # fi
    echo 'docker restart nghttp-min >/dev/null 2>&1; sleep 1; docker exec -ti nghttp-min nghttp "$@"' > /usr/bin/nghttpnew
    chmod +x /usr/bin/nghttpnew
    echo 'docker restart nghttp-min >/dev/null 2>&1; sleep 1; docker exec -ti nghttp-min h2load "$@"' > /usr/bin/h2loadnew
    chmod +x /usr/bin/h2loadnew
    if [[ ! "$(grep -w 'alias nghttp-min' /root/.bashrc)" ]]; then
      echo "alias nghttpcmd-min='docker exec -ti nghttp-min'" >> /root/.bashrc
    fi
    if [[ ! "$(grep -w 'alias rmnghttp-min' /root/.bashrc)" ]]; then
      echo "alias rmnghttp-min='docker stop nghttp-min; docker rm nghttp-min; docker rmi centminmod/docker-ubuntu-nghttp2-minimal; docker run -ti --net=host --name nghttp-min centminmod/docker-ubuntu-nghttp2-minimal /bin/bash'" >> /root/.bashrc
    fi
    echo
    docker start nghttp-min
    silent docker exec -ti nghttp-min apt update
    silent docker exec -ti nghttp-min apt -y upgrade
    sleep 3
    docker exec -ti nghttp-min h2load --version
    # echo "alias h2loadnew='docker exec -ti nghttp-min'"
    # echo "alias nghttpcmd-min='docker exec -ti nghttp-min'"
    # echo "alias rmnghttp-min='docker stop nghttp-min; docker rm nghttp-min; docker rmi centminmod/docker-ubuntu-nghttp2-minimal; docker run -ti --net=host --name nghttp-min centminmod/docker-ubuntu-nghttp2-minimal /bin/bash'"
    echo "h2loadnew cmd install complete"
  fi
  # install nghttp2 docker full image
  # https://cloud.docker.com/repository/docker/centminmod/docker-ubuntu-nghttp2
  if [[ "$INSTALL_NGHTTPNEWER" = [yY] ]]; then
    echo
    echo "---------------------------------------------"
    echo "h2load docker image install"
    echo "setup h2loadnewer cmd alias"
    echo "---------------------------------------------"
    if [[ -f /usr/bin/docker && "$(docker ps --format "{{.Names}}" | grep -w 'nghttp$')" = 'nghttp' ]]; then
      silent docker stop nghttp
      silent docker rm nghttp
      silent docker rmi centminmod/docker-ubuntu-nghttp2
    fi
    docker run -tid --restart=always --net=host --name nghttp centminmod/docker-ubuntu-nghttp2
    # setup docker management cmd aliases
    # if [[ ! "$(grep -w 'alias h2loadnewer' /root/.bashrc)" ]]; then
    #   echo "alias h2loadnewer='docker restart nghttp >/dev/null 2>&1; docker exec -ti nghttp h2load'" >> /root/.bashrc
    # fi
    echo 'docker restart nghttp >/dev/null 2>&1; sleep 1; docker exec -ti nghttp nghttp "$@"' > /usr/bin/nghttpnewer
    chmod +x /usr/bin/nghttpnewer
    echo 'docker restart nghttp >/dev/null 2>&1; sleep 1; docker exec -ti nghttp h2load "$@"' > /usr/bin/h2loadnewer
    chmod +x /usr/bin/h2loadnewer
    if [[ ! "$(grep -w 'alias nghttp=' /root/.bashrc)" ]]; then
      echo "alias nghttpcmd='docker exec -ti nghttp'" >> /root/.bashrc
    fi
    if [[ ! "$(grep -w 'alias rmnghttp=' /root/.bashrc)" ]]; then
      echo "alias rmnghttp='docker stop nghttp; docker rm nghttp; docker rmi centminmod/docker-ubuntu-nghttp2; docker run -ti --net=host --name nghttp centminmod/docker-ubuntu-nghttp2 /bin/bash'" >> /root/.bashrc
    fi
    echo
    docker start nghttp
    silent docker exec -ti nghttp apt update
    silent docker exec -ti nghttp apt -y upgrade
    sleep 3
    docker exec -ti nghttp h2load --version
    # echo "alias h2loadnewer='docker exec -ti nghttp'"
    # echo "alias nghttpcmd='docker exec -ti nghttp'"
    # echo "alias rmnghttp='docker stop nghttp; docker rm nghttp; docker rmi centminmod/docker-ubuntu-nghttp2; docker run -ti --net=host --name nghttp centminmod/docker-ubuntu-nghttp2 /bin/bash'"
    echo "h2loadnewer cmd install complete"
  fi
}

docker_install
h2load_install