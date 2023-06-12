[![progress-banner](https://app.codecrafters.io/progress/docker/c4f02c39-77e4-4dd7-938a-f90a14f844af)](https://app.codecrafters.io/users/kudojp)

This is a starting point for Ruby solutions to the
["Build Your Own Docker" Challenge](https://codecrafters.io/challenges/docker).

In this challenge, you'll build a program that can pull an image from
[Docker Hub](https://hub.docker.com/) and execute commands in it. Along the way,
we'll learn about [chroot](https://en.wikipedia.org/wiki/Chroot),
[kernel namespaces](https://en.wikipedia.org/wiki/Linux_namespaces), the
[docker registry API](https://docs.docker.com/registry/spec/api/) and much more.

**Note**: If you're viewing this repo on GitHub, head over to
[codecrafters.io](https://codecrafters.io) to try the challenge.



## How to run your docker engine

You'll use linux-specific syscalls in this challenge. so we'll run your code
_inside_ a Docker container.

Please ensure you have [Docker installed](https://docs.docker.com/get-docker/)
locally.


You can now execute your docker enginea as below.
Note that when the source code is changed, you have to run `make build` before.

```sh
$ make build
$ bin/mydocker run ubuntu:latest /usr/local/bin/docker-explorer echo hey
```
