ARG ARTIFACTORY
FROM ${ARTIFACTORY}/podman/stable:latest

# Adding on the docker alias, docker-compose and other useful stuff
RUN dnf install -y podman-docker buildah skopeo docker-compose \
  util-linux ansible-core openssh-clients krb5-devel krb5-libs krb5-workstation git jq wget curl unzip coreutils \
  helm doctl kubernetes-client gnupg2 pinentry expect gh awscli

# Adding the Azure CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
  && dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm \
  && dnf install -y azure-cli

# Adding some Ansible Key and Timeout setting
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_TIMEOUT=60
RUN printf "\nStrictHostKeyChecking no\n" >> /etc/ssh/ssh_config
ENV GPG_TTY /dev/console

# Adding RPM build tools along with FPM
RUN dnf install -y rpm-build rpm-sign rubygems ruby-devel gcc gcc-c++ make libffi-devel

RUN gem install ffi \
    && gem install fpm
COPY rpm-sign-expect /usr/bin

RUN chmod +x /usr/bin/rpm-sign-expect

# Get the latest version of the unpackage yq utility
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq \
  && chmod +x /usr/bin/yq

# Remove the Emulate Docker CLI using podman messages
RUN touch /etc/containers/nodocker