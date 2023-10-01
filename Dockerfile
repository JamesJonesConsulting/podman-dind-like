ARG ARTIFACTORY
FROM ${ARTIFACTORY}/podman/stable:latest

# Adding on the docker alias, docker-compose and other useful stuff including the Azure CLI and RPM build tools along with FPM
# docker-compose - broken dependencies in F38 so removing
RUN dnf install -y podman-docker buildah skopeo \
  util-linux ansible-core openssh-clients krb5-devel krb5-libs krb5-workstation git jq wget curl unzip coreutils \
  helm doctl kubernetes-client gnupg2 pinentry expect gh awscli \
  python3-jsonpatch python3-requests-oauthlib python3-kubernetes \
  && rpm --import https://packages.microsoft.com/keys/microsoft.asc \
  && dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm \
  && dnf install -y azure-cli \
  && dnf install -y rpm-build rpm-sign rubygems ruby-devel gcc gcc-c++ make libffi-devel \
  && dnf install -y ansible-collection* \
  && dnf clean all \
  && rm -rf /var/cache/yum \
  && wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq \
  && chmod +x /usr/bin/yq \
  && curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp \
  && mv /tmp/eksctl /usr/bin \
  && touch /etc/containers/nodocker

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