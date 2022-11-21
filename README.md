# podman-dind-like

A Docker-in-Docker like container using Podman

## Description

This takes the quay.io/podman/stable image and extends it with some enhancements to make it more docker like
and able to use `docker` as a command as well as includes `docker-compose`.

## Notes on Github Actions

This job runs on a self-hosted Github Actions agent and publishes to Github's container registry ghcr.io as a 'public' image and can be downloaded
via a simple docker command or other means as you see fit.

```
docker pull ghcr.io/jamesjonesconsulting/podman-dind-like:latest
```

## Notes on GitLab

This job also runs on a self-hosted gitlab agent with the following in the `/etc/gitlab-runner/config.toml` file so this is also compatible with 
other self-hosted agents for other CI/CD self-hosted agents.

```
  [runners.docker]
    host = "unix:///run/podman/podman.sock"
    tls_verify = false
    image = "quay.io/podman/stable"
    privileged = true
    network_mode = "host"
```

## Setting up Podman socket on build machines for use with muliple flavors of CI/CD agents

First, install podman.socket

```
sudo dnf install -y podman.socket; sudo systemctl enable --now podman.socket
```

Create an systemd overlay to use the docker `group` on the socket file (note: you'll have to create this group yourself separately).


aka: Create a file as `/etc/systemd/system/podman.socket.d/overlay.conf` containing:

```
[Socket]
SocketMode=0660
SocketUser=root
SocketGroup=docker
```

Created a tmpfiles.d entry as `/etc/tmpfiles.d/podman.conf` file containing (ensuring that folder will retain the correct permissions after reboots)

```
d /run/podman 0770 root docker
```

Note: This ensures that the group `docker` has permissions to use this socket.

Finally, add the agent users to the `docker` group (whichever agent you are using).

Run `sudo systemctl reload-daemon` and reboot (quickest way).