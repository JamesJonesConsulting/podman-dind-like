FROM quay.io/podman/stable:latest

RUN dnf install -y podman-docker buildah skopeo