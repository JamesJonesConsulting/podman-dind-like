# podman-dind-like

A Docker-in-Docker like container using Podman

## Description

This takes the quay.io/podman/stable image and extends it with some enhancements to make it more docker like
and able to use `docker` as a command as well as includes `docker-compose`.

## Notes

This job runs on a self-hosted gitlab agent with the following in the config.toml so this is also compatible with 
other self-hosted agents for other CI/CD self-hosted agents 

```
  [runners.docker]
    host = "unix:///run/podman/podman.sock"
    tls_verify = false
    image = "quay.io/podman/stable"
    privileged = true
    network_mode = "host"
```