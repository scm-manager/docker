# SCM-Manager Docker

This project aims to create multi-platform docker images for SCM-Manager.
The goal of the project is it to create the following platforms on our ci infrastructure:

* linux/amd64
* linux/arm64/v8
* linux/arm/v7

This opens the door for running the SCM-Manager docker image on Raspberry PI's, Arm based NAS systems or Apple Silicon.

The created docker images must be considered as experimental.
But if things go well this could be the default for SCM-Manager.

The images are pushed to the docker hub under the [scmmanager/scm-multiarch-test](https://hub.docker.com/r/scmmanager/scm-multiarch-test) tag.
The build uses the normal SCM-Manager CI infrastructure at [oss.cloudogu.com](https://oss.cloudogu.com/jenkins/job/scm-manager-github/job/docker/job/main).

In order to test the images run the following command on your machine, 
regardless if it is an x86 or an arm machine:

```bash
docker run -p 8080:8080 scmmanager/scm-multiarch-test:2.30.1
```

## Changes

In order to archive the goal of an multi-platform images we had to change some things.

* Create separate build with separate repo. The gradle plugin which is used to build the docker images does not support buildx, so it seems easier to separate the build.
* Move from adoptjdk to temurin, because temurin replaces the adoptjdk
* Move from an alpine base to debian bullseye slim, because adoptjdk/temurin does not provide alpine arm images
* Use jlink to create a minimal java edition. The switch from alpine to debian increased the image size. With the usage of jlink we are creating now smaller images as with alpine.

## Resources

Here are some links to learn about building multiplatform images

* https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
* https://github.com/docker/buildx#building-multi-platform-images
* https://docs.docker.com/buildx/working-with-buildx/
* https://hub.docker.com/r/tonistiigi/binfmt
