ARG ARTIFACTORY
FROM ${ARTIFACTORY}/podman/stable:latest

ENV SONAR_SCANNER_VERSION=5.0.1.3006
ENV SONAR_SCANNER_HOME=/opt/sonar-scanner

RUN echo ipv4 >> ~/.curlrc && \
  echo "inet4_only = on" >> ~/.wgetrc

RUN dnf install -y --nogpgcheck \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
  dnf config-manager setopt fedora-cisco-openh264.enabled=1 -y

# Adding on the docker alias, docker-compose and other useful stuff including the Azure CLI and RPM build tools along with FPM
# docker-compose - broken dependencies in F38 so removing
RUN dnf install -y podman-docker buildah skopeo \
  util-linux ansible-core openssh-clients krb5-devel krb5-libs krb5-workstation git jq wget curl unzip coreutils \
  nss-tools samba-client samba-common cifs-utils helm doctl gnupg2 pinentry expect gh awscli glab yq \
  python3-jsonpatch python3-requests-oauthlib python3-kubernetes python3-pyyaml python3-pip \
  && curl -k -s -o - \
    https://nexus.jamesjonesconsulting.com/repository/package-config/dist/proxy/rpmfusion/rpmfusion-setup-proxy-repos.sh |\
    bash \
  && rpm --import https://packages.microsoft.com/keys/microsoft.asc \
  && dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm \
  && curl -k -s -o - \
    https://nexus.jamesjonesconsulting.com/repository/package-config/dist/proxy/microsoft/microsoft-setup-yum-proxy-repos.sh |\
    bash \
  && dnf install -y azure-cli \
  && dnf install -y rpm-build rpm-sign rubygems ruby-devel gcc gcc-c++ make libffi-devel \
  && dnf install -y ansible-collection* \
  && dnf install -y cpanminus perl-Mojolicious perl-Test-Mojo perl-Test-Harness perl-Perl-Critic perl-Carton \
  && dnf install -y \
    $(curl -k -sS -X 'GET' 'https://nexus.jamesjonesconsulting.com/service/rest/v1/search/assets?sort=version&direction=desc&repository=yum-hosted-arch&yum.architecture=noarch&yum.name=jamesjonesconsulting-repos' |\
    jq '.items[] | .downloadUrl' -r | head -n1) \
  && dnf install -y okd-client okd-client-helm-plugin operator-sdk \
  && dnf install -y sonar-scanner-cli-${SONAR_SCANNER_VERSION} \
  && dnf clean all \
  && rm -rf /var/cache/yum \
  && curl --silent \
    --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | \
    tar xz -C /tmp \
  && mv /tmp/eksctl /usr/bin \
  && touch /etc/containers/nodocker

ENV PATH=$SONAR_SCANNER_HOME/bin:$PATH

# Adding some Ansible Key and Timeout setting as well as accepting ssh-rsa
ENV ANSIBLE_HOST_KEY_CHECKING=False \
  ANSIBLE_TIMEOUT=120 \
  GPG_TTY=/dev/console
COPY ssh_ansible.conf /etc/ssh/ssh_config.d/99-ansible.conf
RUN chown root:root /etc/ssh/ssh_config.d/99-ansible.conf && chmod 644 /etc/ssh/ssh_config.d/99-ansible.conf

# Ensuring the fpm tool is installed to build distro packages such as RPM and DEB
COPY rpm-sign-expect /usr/bin
RUN curl -k -s -o - \
  https://nexus.jamesjonesconsulting.com/repository/package-config/rubygems/rubygems-repos.sh |\
  bash
RUN gem install ffi \
  && gem install fpm \
  && chmod +x /usr/bin/rpm-sign-expect

# Setting up Pypi to use proxy
RUN curl -k -s -o - \
  https://nexus.jamesjonesconsulting.com/repository/package-config/pypi/python3-pypi-repos.sh |\
  bash \
  && mv ~/.config/pip/pip.conf /etc/pip.conf \
  && chmod 644 /etc/pip.conf \
  && rm -Rf ~/.config/pip

ENV PIP_CONFIG_FILE=/etc/pip.conf

# Adding on the CPAN mirror settings for Carton and cpanminus
ENV PERL_CPANM_OPT="--mirror https://nexus.jamesjonesconsulting.com/repository/cpan-proxy/" \
    PERL_CARTON_MIRROR=https://nexus.jamesjonesconsulting.com/repository/cpan-proxy/