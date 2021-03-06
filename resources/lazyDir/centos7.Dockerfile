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

##############################
# General level requirements #
##############################

# Pull base image from official repo
FROM centos:centos7.9.2009

# Import local GPG keys and enable epel repo
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum -q clean all && \
    yum -q makecache && \
    yum -y install --setopt=tsflags=nodocs \
      epel-release \
    && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 && \
    yum -q -y clean all --enablerepo='*'

# Install common requirements
RUN INSTALL_PKGS="git unzip wget which" && \
    yum -q clean expire-cache && \
    yum -q makecache && \
    yum -y install --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -q -y clean all --enablerepo='*'

# Prepare locales
ARG locale=en_US.UTF-8
ENV LANG "${locale}"
ENV LC_ALL "${locale}"

# Configure desired timezone
ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

###############################
# Enable Software Collections #
###############################

# Add repos, keys and tools
RUN yum -q clean expire-cache && \
    yum -q makecache && \
    yum -y install --setopt=tsflags=nodocs \
      centos-release-scl \
      scl-utils \
    && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo && \
    yum -q -y clean all --enablerepo='*'

# Enable SCLs for any later bash session
COPY scl_enable.sh /usr/local/bin/scl_enable
ENV BASH_ENV="/usr/local/bin/scl_enable" \
    ENV="/usr/local/bin/scl_enable" \
    PROMPT_COMMAND=". /usr/local/bin/scl_enable"

##################################
# Application level requirements #
##################################

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

###########################
# User level requirements #
###########################

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

# Switch to non-root user
USER ${user}
WORKDIR /home/${user}

# Prepare user variables
ENV USER ${user}
ENV HOME=/home/${user}

# Define (unused) arguments (to avoid warning) 
ARG dir=.
