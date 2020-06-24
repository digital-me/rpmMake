#
#  This work is protected under copyright law in the Kingdom of
#  The Netherlands. The rules of the Berne Convention for the
#  Protection of Literary and Artistic Works apply.
#  Digital Me B.V. is the copyright owner.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

# Pull base image from official repo
FROM centos:centos7.8.2003

# Import local GPG keys and enable epel repo
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum -q clean expire-cache && \
    yum -q makecache && \
    yum -y install --setopt=tsflags=nodocs \
      epel-release \
    && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && \
    yum -q -y clean all --enablerepo='*'

# Install common requirements
RUN yum -q clean expire-cache && \
    yum -q makecache && \
    yum -y install --setopt=tsflags=nodocs \
      git \
      unzip \
      wget \
      which \
    && \
    yum -q -y clean all --enablerepo='*'

# Enable Software Collections
RUN yum -q clean expire-cache && \
    yum -q makecache && \
    yum -y install --setopt=tsflags=nodocs \
      centos-release-scl \
      scl-utils-build \
    && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo && \
    yum -q -y clean all --enablerepo='*'

# Install specific requirements
RUN yum -q clean expire-cache && \
    yum -q makecache && \
    yum -y install --setopt=tsflags=nodocs \
      make \
      rpm-build \
      sudo \
      yum-utils \
    && \
    yum -q -y clean all --enablerepo='*'

# Parameters for default user:group
ARG uid=999
ARG user=pkgmake
ARG gid=999
ARG group=pkgmake

# Add or modify user and group for build and runtime (convenient)
RUN id ${user} > /dev/null 2>&1 && \
    { groupmod -g "${gid}" "${group}" && usermod -md /home/${user} -s /bin/bash -g "${group}" -u "${uid}" "${user}"; } || \
    { groupadd -g "${gid}" "${group}" && useradd -md /home/${user} -s /bin/bash -g "${group}" -u "${uid}" "${user}"; }

# Allow user to install build deps
RUN echo -n "Defaults:${user} " > /etc/sudoers.d/pkgmake-yum && \
    echo '!requiretty' >> /etc/sudoers.d/pkgmake-yum && \
    echo "${user} ALL=NOPASSWD:/usr/bin/yum-builddep *" >> /etc/sudoers.d/pkgmake-yum && \
    echo "${user} ALL=NOPASSWD:/usr/bin/yum-config-manager *" >> /etc/sudoers.d/pkgmake-yum && \
    echo "${user} ALL=NOPASSWD:/usr/bin/yum *" >> /etc/sudoers.d/pkgmake-yum

# Prepare locales
ARG locale="en_US.UTF-8"
ENV LANG "${locale}"
ENV LC_ALL "${locale}"

# Define (unused) arguments (to avoid warning) 
ARG dir=.

# Switch to non-root user
USER ${user}
