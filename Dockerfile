FROM quay.io/podman/stable:latest

# Adding on the docker alias, docker-compose and other useful stuff
RUN dnf install -y podman-docker buildah skopeo docker-compose

# Remove the Emulate Docker CLI using podman messages
RUN touch /etc/containers/nodocker