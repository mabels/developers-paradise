FROM ubuntu:focal

RUN apt update && \
  DEBIAN_FRONTEND=noninteractive apt install -y wget curl jq openssh-server mysql-client \
    git sudo zsh vim unzip zip man-db powerline fonts-powerline zsh-theme-powerlevel9k \
    language-pack-de language-pack-en docker.io rsync ripgrep make dnsutils procps \
    apt-transport-https gpgv2 gnupg2 apt-utils gcc python3-pip iputils-ping \
    libffi-dev libssl-dev zlib1g-dev supervisor net-tools && \
  ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
  yes | unminimize && \
  apt clean

RUN mv /usr/bin/uname /usr/bin/uname.orig && \
    (echo "#!/bin/sh" ; echo '/usr/bin/uname.orig $@ | sed "s/armv8l/armv7l/g"') > /usr/bin/uname && \
    chmod 755 /usr/bin/uname && \
    uname -a

RUN useradd -s /usr/bin/bash -r -m -u 666 -G adm,sudo,root,docker runner && \
    V=2.272.0 && \
    echo "runner    ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner && \
    if [ $(uname -p) = "x86_64" ]; then \
      su - runner -c "mkdir actions-runner && cd actions-runner && curl -sS -O -L https://github.com/actions/runner/releases/download/v$V/actions-runner-linux-x64-$V.tar.gz && tar xzf ./actions-runner-linux-x64-$V.tar.gz && rm actions-runner-linux-x64-$V.tar.gz"; \
    elif [ $(uname -p) = "armv7l" ]; then \
      su - runner -c "mkdir actions-runner && cd actions-runner && curl -sS -O -L https://github.com/actions/runner/releases/download/v$V/actions-runner-linux-arm-$V.tar.gz && tar xzf ./actions-runner-linux-arm-$V.tar.gz && rm actions-runner-linux-arm-$V.tar.gz"; \
    elif [ $(uname -p) = "aarch64" ]; then \
      su - runner -c "mkdir actions-runner && cd actions-runner && curl -sS -O -L https://github.com/actions/runner/releases/download/v$V/actions-runner-linux-arm64-$V.tar.gz && tar xzf ./actions-runner-linux-arm64-$V.tar.gz && rm actions-runner-linux-arm64-$V.tar.gz"; \
    fi; \
    cd /home/runner/actions-runner && ./bin/installdependencies.sh && \
    apt clean

#RUN find /usr/bin/uname* -ls; uname -a; uname -p

RUN mkdir -p /usr/share/dotnet && cd /usr/share/dotnet && \
    if [ $(uname -p) = "x86_64" ]; then \
      curl -sS -o dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/4f9b8a64-5e09-456c-a087-527cfc8b4cd2/15e14ec06eab947432de139f172f7a98/dotnet-sdk-3.1.401-linux-x64.tar.gz; \
    elif [ $(uname -p) = "armv7l" ]; then \
      curl -sS -o dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/a92a6358-52c3-472b-ad6d-d2d80abdcef4/37a7551a4e2c9e455caed5ef777a8983/dotnet-sdk-3.1.401-linux-arm.tar.gz; \
    elif [ $(uname -p) = "aarch64" ]; then \
      curl -sS -o dotnet.tar.gz	https://download.visualstudio.microsoft.com/download/pr/8c39349a-23d0-46b0-8206-8b573a404709/b42fd441c1911acc90aaddaa58d7103f/dotnet-sdk-3.1.401-linux-arm64.tar.gz; \
    fi; \
    tar xzf dotnet.tar.gz && \
    rm dotnet.tar.gz && cd /usr/bin && ln -nfs /usr/share/dotnet/dotnet dotnet


RUN if [ $(uname -p) = "x86_64" ]; then  \
      wget https://github.com/cdr/code-server/releases/download/3.4.1/code-server_3.4.1_amd64.deb && \
      dpkg -i code-server_3.4.1_amd64.deb && \
      rm -f code-server_3.4.1_amd64.deb; \
    elif [ $(uname -p) = "aarch64" ]; then \
      wget https://github.com/cdr/code-server/releases/download/3.4.1/code-server_3.4.1_arm64.deb && \
      dpkg -i code-server_3.4.1_arm64.deb && \
      rm -f code-server_3.4.1_arm64.deb; \
    fi

RUN mkdir -p /usr/local && cd /usr/local && \
    if [ $(uname -p) = "x86_64" ]; then \
	curl -sS -L -o golang.tar.gz https://golang.org/dl/go1.15.linux-amd64.tar.gz ; \
    elif [ $(uname -p) = "aarch64" ]; then \
	curl -sS -L -o golang.tar.gz https://golang.org/dl/go1.15.linux-arm64.tar.gz ; \
    elif [ $(uname -p) = "armv7l" ]; then \
	curl -sS -L -o golang.tar.gz https://golang.org/dl/go1.15.linux-armv6l.tar.gz ; \
    fi; \
    tar xzf golang.tar.gz && rm golang.tar.gz && \
    cd bin && ln -s ../go/bin/* .


RUN mkdir -p /usr/local/bin && \ 
    python3 -m pip install awscli && \
    python3 -m pip install awssso
    #if [ $(uname -p) = "x86_64" ]; then \
    #  curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    #elif [ $(uname -p) = "aarch64" ]; then \
    #  curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    #elif [ $(uname -p) = "armv7l" ]; then \
    # DEBIAN_FRONTEND=noninteractive apt install -y python3-pip && \
    # python3 -m pip install awscli
    #fi; \
    #if [ -f awscliv2.zip ]; then  \
    #  unzip awscliv2.zip && \
    # ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    # rm -f awscliv2.zip; \
    #fi

RUN curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl && \
    apt clean

#RUN HELMVERSION=3.2.3 && rm -rf /tmp/linux-amd64 && \
#    curl https://get.helm.sh/helm-v$HELMVERSION-linux-amd64.tar.gz | tar xzCf /tmp - && \
#    mv /tmp/linux-amd64/helm /usr/local/bin

#RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
#    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
#    apt-get update && \
#    apt-get install helm
RUN git clone -b v3.3.0 https://github.com/helm/helm.git && \
    cd helm && make && install bin/helm /usr/local/bin && \
    cd .. && rm -rf helm

#RUN 
#    HELMDIFFVERSION=3.1.1 && \
#    export XDG_DATA_HOME=/usr/local && \
#    helm plugin install https://github.com/databus23/helm-diff --version master && \

ENV HELM_PLUGIN_DIR /usr/local/helm/plugins
ENV HELM_PLUGINS /usr/local/helm/plugins

RUN export HELM_HOME=/usr/local/helm && \
    export GOPATH=$HOME/go && \
    echo "export HELM_PLUGIN_DIR=/usr/local/helm/plugins" >> /usr/local/env.sh && \
    echo "::set-env name=HELM_PLUGIN_DIR::/usr/local/helm/plugins" >> /usr/local/env.sh && \
    echo "::set-env name=HELM_PLUGINS::/usr/local/helm/plugins" >> /usr/local/env.sh && \
    echo "export HELM_PLUGINS=/usr/local/helm/plugins" >> /usr/local/env.sh && \
    export PATH=$HOME/go/bin:$PATH && \
    go get -u golang.org/x/lint/golint && \
    mkdir -p $GOPATH/src/github.com/databus23/ && \
    cd $GOPATH/src/github.com/databus23/ && \
    git clone https://github.com/databus23/helm-diff.git && \
    cd helm-diff && \
    make install && cd .. && \
    rm -rf helm-diff && rm -rf /usr/local/pkg $GOPATH

RUN HELMFILEVERSION=v0.125.7 && \
    export GOPATH=/usr/local && \
    git clone -b $HELMFILEVERSION https://github.com/roboll/helmfile.git && \
    cd helmfile && make install && cd .. && \
    rm -rf helmfile && rm -rf /usr/local/pkg

RUN NECKLESSVERSION=v0.0.4 && \
    curl -sS -L https://github.com/mabels/neckless/releases/download/$NECKLESSVERSION/neckless-linux -o /usr/local/bin/neckless && \
    chmod +x /usr/local/bin/neckless

RUN NVMVERSION=v0.35.3 && export NVM_DIR="/usr/local/nvm" && \
    mkdir -p $NVM_DIR && \
    curl -sS -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVMVERSION/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install stable && nvm use stable && npm install yarn -g && \
    nvm install lts/erbium && nvm use lts/erbium && npm install yarn -g && \
    nvm install lts/dubnium && nvm use lts/dubnium && npm install yarn -g && \
    rm -rf $HOME/.npm

COPY worker.sh /usr/local/bin/worker.sh
COPY entry-worker.sh /home/runner/actions-runner/entry-worker.sh
RUN chmod +x /usr/local/bin/worker.sh /home/runner/actions-runner/entry-worker.sh && \
    ls -l /usr/local/bin

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod 644 /etc/supervisor/conf.d/supervisord.conf


RUN mv /usr/bin/uname.orig /usr/bin/uname

#RUN SAML2AWL_VERSION=2.26.1 && \
#    curl -L https://github.com/Versent/saml2aws/releases/download/v${SAML2AWL_VERSION}/saml2aws_${SAML2AWL_VERSION}_linux_amd64.tar.gz | \
#    tar xzvCf /usr/local/bin -

CMD ["/usr/sbin/sshd", "-D" ]
