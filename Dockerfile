FROM ubuntu:focal

RUN apt update && \
  DEBIAN_FRONTEND=noninteractive apt install -y wget curl jq openssh-server mysql-client \
    git sudo zsh vim unzip zip man-db powerline fonts-powerline zsh-theme-powerlevel9k \
    language-pack-de language-pack-en docker.io rsync ripgrep make dnsutils procps && \
  ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
  yes | unminimize

RUN useradd -s /usr/bin/bash -r -m -u 666 -G adm,sudo runner && \
    echo "runner    ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner && \
    su - runner -c "mkdir actions-runner && cd actions-runner && curl -O -L https://github.com/actions/runner/releases/download/v2.272.0/actions-runner-linux-x64-2.272.0.tar.gz && tar xzf ./actions-runner-linux-x64-2.272.0.tar.gz && rm actions-runner-linux-x64-2.272.0.tar.gz"

RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt update && apt-get install -y aspnetcore-runtime-3.1

RUN wget https://github.com/cdr/code-server/releases/download/3.4.1/code-server_3.4.1_amd64.deb && \
    dpkg -i code-server_3.4.1_amd64.deb && \
    rm -f code-server_3.4.1_amd64.deb

RUN mkdir -p /usr/local/bin

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -f awscliv2.zip

RUN KUBECTLVERSION=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt` && \
    echo $KUBECTLVERSION && \
    curl https://storage.googleapis.com/kubernetes-release/release/$KUBECTLVERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

RUN curl -L https://github.com/ahmetb/kubectx/releases/download/v0.9.0/kubectx_v0.9.0_linux_x86_64.tar.gz | \
    tar xvzCf /usr/local/bin -

RUN HELMVERSION=3.2.3 && rm -rf /tmp/linux-amd64 && \
    curl https://get.helm.sh/helm-v$HELMVERSION-linux-amd64.tar.gz | tar xzCf /tmp - && \
    mv /tmp/linux-amd64/helm /usr/local/bin

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
