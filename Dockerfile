FROM ubuntu:focal

RUN apt update && \
  DEBIAN_FRONTEND=noninteractive apt install -y wget curl jq openssh-server mysql-client \
    git sudo zsh vim unzip zip man-db powerline fonts-powerline zsh-theme-powerlevel9k \
    language-pack-de language-pack-en docker.io rsync ripgrep make dnsutils procps \
    apt-transport-https && \
  ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
  yes | unminimize

RUN useradd -s /usr/bin/bash -r -m -u 666 -G adm,sudo runner && \
    echo "runner    ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner && \
    su - runner -c "mkdir actions-runner && cd actions-runner && curl -O -L https://github.com/actions/runner/releases/download/v2.272.0/actions-runner-linux-x64-2.272.0.tar.gz && tar xzf ./actions-runner-linux-x64-2.272.0.tar.gz && rm actions-runner-linux-x64-2.272.0.tar.gz"


RUN mkdir -p /usr/share/dotnet && cd /usr/share/dotnet && \
    [ $(uname -p) = "x86_64" ] && \
    curl -o dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/8c39349a-23d0-46b0-8206-8b573a404709/b42fd441c1911acc90aaddaa58d7103f/dotnet-sdk-3.1.401-linux-arm64.tar.gz; \
    [ $(uname -p) = "armv7l" ] && \
    curl -o dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/a92a6358-52c3-472b-ad6d-d2d80abdcef4/37a7551a4e2c9e455caed5ef777a8983/dotnet-sdk-3.1.401-linux-arm.tar.gz; \
    [ $(uname -p) = "aarch64" ] && \
    curl -o dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/4f9b8a64-5e09-456c-a087-527cfc8b4cd2/15e14ec06eab947432de139f172f7a98/dotnet-sdk-3.1.401-linux-x64.tar.gz; \
    tar xzf dotnet.tar.gz && \
    rm dotnet.tar.gz && cd /usr/bin && ln -nfs /usr/share/dotnet/dotnet dotnet


RUN [ $(uname -p) = "x86_64" ] && \
    wget https://github.com/cdr/code-server/releases/download/3.4.1/code-server_3.4.1_amd64.deb && \
    dpkg -i code-server_3.4.1_amd64.deb && \
    rm -f code-server_3.4.1_amd64.deb;  \
    [ $(uname -p) = "aarch64" ] && \
    wget https://github.com/cdr/code-server/releases/download/3.4.1/code-server_3.4.1_arm64.deb && \
    dpkg -i code-server_3.4.1_arm64.deb && \
    rm -f code-server_3.4.1_amd64.deb;


RUN mkdir -p /usr/local/bin && \ 
    [ $(uname -p) = "x86_64" ] && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    [ $(uname -p) = "aarch64" ] && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    [ -f awscliv2.zip ] && \
    unzip awscliv2.zip && \
     ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -f awscliv2.zip

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl

#RUN HELMVERSION=3.2.3 && rm -rf /tmp/linux-amd64 && \
#    curl https://get.helm.sh/helm-v$HELMVERSION-linux-amd64.tar.gz | tar xzCf /tmp - && \
#    mv /tmp/linux-amd64/helm /usr/local/bin

RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install helm

RUN HELMDIFFVERSION=3.1.1 && \
    export XDG_DATA_HOME=/usr/local && \
    /usr/local/bin/helm plugin install https://github.com/databus23/helm-diff --version master && \
    echo "export HELM_PLUGIN_DIR=/usr/local/helm/plugins" >> /usr/local/env.sh && \
    echo "::set-env name=HELM_PLUGIN_DIR::/usr/local/helm/plugins" >> /usr/local/env.sh && \
    echo "::set-env name=HELM_PLUGINS::/usr/local/helm/plugins" >> /usr/local/env.sh && \
    echo "export HELM_PLUGINS=/usr/local/helm/plugins" >> /usr/local/env.sh 

ENV HELM_PLUGIN_DIR /usr/local/helm/plugins
ENV HELM_PLUGINS /usr/local/helm/plugins

RUN HELMFILEVERSION=v0.118.7 && \
    curl -L https://github.com/roboll/helmfile/releases/download/$HELMFILEVERSION/helmfile_linux_amd64 -o /usr/local/bin/helmfile && \
    chmod +x /usr/local/bin/helmfile

RUN NECKLESSVERSION=v0.0.4 && \
    curl -L https://github.com/mabels/neckless/releases/download/$NECKLESSVERSION/neckless-linux -o /usr/local/bin/neckless && \
    chmod +x /usr/local/bin/neckless

RUN NVMVERSION=v0.35.3 && export NVM_DIR="/usr/local/nvm" && \
    mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVMVERSION/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install stable && \
    nvm install lts/erbium && \
    nvm install lts/dubnium

#RUN SAML2AWL_VERSION=2.26.1 && \
#    curl -L https://github.com/Versent/saml2aws/releases/download/v${SAML2AWL_VERSION}/saml2aws_${SAML2AWL_VERSION}_linux_amd64.tar.gz | \
#    tar xzvCf /usr/local/bin -

CMD ["/usr/sbin/sshd", "-D" ]
