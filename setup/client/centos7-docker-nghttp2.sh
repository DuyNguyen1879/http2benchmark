#!/bin/bash
####################################################
# install newer version of nghttp2's h2load support
# for TLSv1.3 via docker image
# https://hub.docker.com/r/centminmod/docker-ubuntu-nghttp2-minimal
####################################################
INSTALL_DOCKER='y'

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
  # install nghttp2 docker image
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
  if [[ ! "$(grep -w 'alias h2loadnew' /root/.bashrc)" ]]; then
    echo "alias h2loadnew='docker restart nghttp-min >/dev/null 2>&1; docker exec -ti nghttp-min h2load'" >> /root/.bashrc
  fi
  if [[ ! "$(grep -w 'alias nghttp-min' /root/.bashrc)" ]]; then
    echo "alias nghttpcmd-min='docker exec -ti nghttp-min'" >> /root/.bashrc
  fi
  if [[ ! "$(grep -w 'alias rmnghttp-min' /root/.bashrc)" ]]; then
    echo "alias rmnghttp-min='docker stop nghttp-min; docker rm nghttp-min; docker rmi centminmod/docker-ubuntu-nghttp2-minimal; docker run -ti --net=host --name nghttp-min centminmod/docker-ubuntu-nghttp2-minimal /bin/bash'" >> /root/.bashrc
  fi
  echo
  docker start nghttp-min
  sleep 3
  docker exec -ti nghttp-min h2load --version
  # echo "alias h2loadnew='docker exec -ti nghttp-min'"
  # echo "alias nghttpcmd-min='docker exec -ti nghttp-min'"
  # echo "alias rmnghttp-min='docker stop nghttp-min; docker rm nghttp-min; docker rmi centminmod/docker-ubuntu-nghttp2-minimal; docker run -ti --net=host --name nghttp-min centminmod/docker-ubuntu-nghttp2-minimal /bin/bash'"
  echo "h2loadnew cmd install complete"
}

docker_install
h2load_install