FROM quay.io/podman/stable:latest

# Adding on the docker alias, docker-compose and other useful stuff
RUN dnf install -y podman-docker buildah skopeo docker-compose \
  util-linux ansible-core openssh-clients krb5-devel krb5-libs krb5-workstation git jq unzip coreutils \
  helm doctl kubernetes-client expect

# Adding some Ansible Key and Timeout setting
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_TIMEOUT=60
RUN printf "\nStrictHostKeyChecking no\n" >> /etc/ssh/ssh_config

COPY rpm-sign-expect /usr/bin

RUN chmod +x /usr/bin/rpm-sign-expect

# Remove the Emulate Docker CLI using podman messages
RUN touch /etc/containers/nodocker