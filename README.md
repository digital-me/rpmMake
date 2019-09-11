# rpmMake
Create RPM packages from spec file using Docker container

## Docker
This project relies on Docker to handle dependencies to build and package the software 
from source:
```
docker build --build-arg uid=$(id -u) --build-arg gid=$(id -g) -t rpmmake-centos-7 -f resources/lazyDir/centos-7.Dockerfile resources/lazyDir
docker run -it --rm -w /var/tmp/rpmmake -v $(pwd):/var/tmp/rpmmake --hostname build.local --name build.local rpmmake-centos-7:latest bash
```
