
DEBIAN_FRONTEND=noninteractive \
apt update && \
apt upgrade -y && \
apt install -y wget curl jq openssh-server mysql-client \
    git sudo zsh vim unzip zip man-db \
    rsync make dnsutils procps \
    apt-transport-https gpgv2 gnupg2 apt-utils gcc python3-pip 

snap install docker --classic

ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime

mv /usr/bin/uname /usr/bin/uname.orig && \
   (echo "#!/bin/sh" ; echo '/usr/bin/uname.orig $@ | sed "s/armv8l/armv7l/g"') > /usr/bin/uname && \
    chmod 755 /usr/bin/uname

useradd -s /usr/bin/bash -r -m -u 666 -G adm,sudo,root runner && \
    V=2.272.0 && \
    echo "runner    ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner && \
    if [ $(uname -p) = "x86_64" ]; then \
      su - runner -c "mkdir actions-runner && cd actions-runner && curl -sS -O -L https://github.com/actions/runner/releases/download/v$V/actions-runner-linux-x64-$V.tar.gz && tar xzf ./actions-runner-linux-x64-$V.tar.gz && rm actions-runner-linux-x64-$V.tar.gz"; \
    elif [ $(uname -p) = "armv7l" ]; then \
      su - runner -c "mkdir actions-runner && cd actions-runner && curl -sS -O -L https://github.com/actions/runner/releases/download/v$V/actions-runner-linux-arm-$V.tar.gz && tar xzf ./actions-runner-linux-arm-$V.tar.gz && rm actions-runner-linux-arm-$V.tar.gz"; \
    elif [ $(uname -p) = "aarch64" ]; then \
      su - runner -c "mkdir actions-runner && cd actions-runner && curl -sS -O -L https://github.com/actions/runner/releases/download/v$V/actions-runner-linux-arm64-$V.tar.gz && tar xzf ./actions-runner-linux-arm64-$V.tar.gz && rm actions-runner-linux-arm64-$V.tar.gz"; \
    fi


mkdir -p /usr/share/dotnet && cd /usr/share/dotnet && \
    if [ $(uname -p) = "x86_64" ]; then \
      curl -sS -o dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/4f9b8a64-5e09-456c-a087-527cfc8b4cd2/15e14ec06eab947432de139f172f7a98/dotnet-sdk-3.1.401-linux-x64.tar.gz; \
    elif [ $(uname -p) = "armv7l" ]; then \
      curl -sS -o dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/a92a6358-52c3-472b-ad6d-d2d80abdcef4/37a7551a4e2c9e455caed5ef777a8983/dotnet-sdk-3.1.401-linux-arm.tar.gz; \
    elif [ $(uname -p) = "aarch64" ]; then \
      curl -sS -o dotnet.tar.gz	https://download.visualstudio.microsoft.com/download/pr/8c39349a-23d0-46b0-8206-8b573a404709/b42fd441c1911acc90aaddaa58d7103f/dotnet-sdk-3.1.401-linux-arm64.tar.gz; \
    fi; \
    tar xzf dotnet.tar.gz && \
    rm dotnet.tar.gz && \
    cd /usr/bin && ln -nfs /usr/share/dotnet/dotnet dotnet


