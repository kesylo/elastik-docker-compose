#!/bin/bash

# check if root
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

# create log file
touch output.log

exec 3>&1 1>>output.log 2>&1

# update pckg
apt-get update -y
apt-get dist-upgrade -y

# install docker
printf 'Installing docker...\n\n' 1>&3

sudo apt-get remove --yes docker docker-engine docker.io containerd runc \
    && sudo apt-get update \
    && sudo apt-get --yes --no-install-recommends install \
        apt-transport-https \
        ca-certificates \
    && wget --quiet --output-document=- https://download.docker.com/linux/ubuntu/gpg \
        | sudo apt-key add - \
    && sudo add-apt-repository \
        "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu \
        $(lsb_release --codename --short) \
        stable" \
    && sudo apt-get update \
    && sudo apt-get --yes --no-install-recommends install docker-ce docker-ce-cli containerd.io \
    && sudo usermod --append --groups docker "$USER" \
    && sudo systemctl enable docker \
    && printf '\nDocker installed successfully\n\n'

printf 'Waiting for Docker to start...\n\n' 1>&3
sleep 3
printf 'Docker running.\n\n' 1>&3

# install docker compose
printf 'Installing Docker Compose...\n' 1>&3
sudo wget \
        --output-document=/usr/bin/docker-compose \
        https://github.com/docker/compose/releases/download/1.25.4/run.sh \
    && sudo chmod +x /usr/bin/docker-compose \
    && sudo wget \
        --output-document=/etc/bash_completion.d/docker-compose \
        "https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose" \
    && printf '\nDocker Compose installed successfully.\n\n' 1>&3

# install elk
printf 'Installing ElasticSearch...\n\n' 1>&3
# get docker compose from github
curl https://raw.githubusercontent.com/kesylo/elastik-docker-compose/master/docker-compose.yml --output docker-compose.yml

# run docker compose file
docker-compose up -d

# print elasticsearch health from API
printf 'Get health check.\n\n' 1>&3
curl localhost:9200/_cat/health 1>&3

# cleanup
sudo rm docker-compose.yml
