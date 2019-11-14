# rpmMake
Create RPM packages from spec file using Docker container

## Docker
This project relies on Docker to handle dependencies to build and package the software from source. It also provides support for docker-composer:

```
docker-compose build
docker-compose run --rm default
```
## Spec
The spec files(s) needs to be provided in the `rpm` folder from the parent repo.
It is required for the specs files to start with the following header:

```
%define name #RPM_NAME#
%define version #RPM_VERSION#
%define release #RPM_RELEASE#
```
REM: As for now, if required, the URL in the `SourceXXX` field(s) needs to use the tags above.

Have a look in the `rpm` folder of this repo for example.

## Sources
If the source file(s) can not be accessed from the URL defined in `SourceXXX` field(s) in the spec file(s), they need to be placed in the `src` folder of the parent repo.

## Patches
Any patches have to be placed in the `src` folder of the parent repo.

## Make
Create or edit the Makefile in the parent repo as follows:

```
NAME           := [[NAME-OF-YOUR-PACKAGE]] 
PACKAGER       := 'Example Team <team@example.com>'
VENDOR         := 'Example Corp.'
TARGET_DIR     := $(abspath target)
DISTS_DIR      := $(TARGET_DIR)/dists

RPM_NAME        = $(NAME)
RPM_VERSION     = $(VERSION)
RPM_RELEASE     = $(RELEASE)
RPM_PACKAGER    = $(PACKAGER)
RPM_VENDOR      = $(VENDOR)
RPM_TARGET_DIR  = $(TARGET_DIR)
RPM_DISTS_DIR   = $(DISTS_DIR)
RPM_DEBUGINFO   = 0

include rpmMake/Makefile

.PHONY: all check

all: rpm
check: rpm_check
```

REM: It is possible to add any new section as long as they are not prefixed with `rpm_`.

Once in the docker container, call make with at least the version argument:

```
make VERSION=x.x.x RELEASE=y.y
```
