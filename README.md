CAP
============

CAP (Clipping Amplicon Primer) clips amplicon primers by identifying the most probable amplicon for each reads.
Amplicon primer clipping reduces sequencing noise and variant allele frequency calculation errors.
CAP also generates coverage metrics for each Amplicon.


Getting Started
---------------

The default build of this image presents a container that runs CAP App on CentOS.

### Image Layout

Includes yum modules and other tools dependencies.


Building
--------

The `Dockerfile` provided with this package provides everything that is
needed to build the image. The build system must have Docker installed in
order to build the image.

```
$ cd PROJECT_ROOT
$ docker build -t cap:latest .
```
> Note: PROJECT_ROOT should be replaced with the path to where you have
>       cloned this project on the build system


Running a Container
-------------------

The container host must have Docker installed in order to run the image as a
container. Then the image can be pulled and a container can be started directly.

```
$ docker run cap:latest
```

### Swtiches

Any standard Docker switches may be provided on the command line when running
a container. Some specific switches of interest are documented below.

#### Configuration
```
-v HOST_DATA_FOLDER:/data
```
Content may be copied directly into the running container using a
`docker cp ...` command, alternatively one may choose to simply expose a host
configuration folder to the container.

### Examples

Run CAP as a uniq command.

```
$ docker run --rm cap:latest CAP --bam=sample.bam --output=sample.clipped.bam --manifest=sample.manifest
```

Start CAP container.

```
$ docker run --name cap --entrypoint=bash -ti cap:latest
```


Debugging
---------

You may connect to a running container using the following command
```
$ docker exec -it --user root CONTAINER_NAME /bin/bash
```
> Note: CONTAINER_NAME should be the name provided to Docker when creating the
>       container initially. If not provided explicitly, Docker may have
>       assigned a random name. A container ID may also be used.

You may tail the container logs using the following commands
```
$ docker logs -f CONTAINER_NAME
```
