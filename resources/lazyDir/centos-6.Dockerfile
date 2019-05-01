#
#  This work is protected under copyright law in the Kingdom of
#  The Netherlands. The rules of the Berne Convention for the
#  Protection of Literary and Artistic Works apply.
#  Digital Me B.V. is the copyright owner.
#
#  Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      https://www.gnu.org/licenses/gpl.txt
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

# Pull base image from official repo
FROM centos:centos6.10

# Import required GPG keys
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6 \
	&& rpm --import http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6

# Enable epel repo and Install all current updates
RUN	yum -q -y update \
	&& yum -y install epel-release \
	&& yum -y upgrade \
	&& yum -q clean all

# Install common requirements
RUN yum -q -y update \
	&& yum -y install \
	git \
	wget \
	unzip \
	which \
	&& yum -q clean all

# Install specific requirements
RUN yum -q -y update \
	&& yum -y install \
	make \
	sudo \
	yum-utils \
	rpm-build \
	&& yum -q clean all

# Parameters for default user:group
ARG uid=999
ARG user=pkgmake
ARG gid=999
ARG group=pkgmake

# Create and allow user to install build deps
RUN groupadd -g ${gid} ${group} \
	&& useradd -g ${gid} -u ${uid} -d /var/lib/pkgmake ${user} \
	&& echo -n "Defaults:${user} " > /etc/sudoers.d/pkgmake-yum \
	&& echo '!requiretty' >> /etc/sudoers.d/pkgmake-yum \
	&& echo "${user} ALL=NOPASSWD:/usr/bin/yum-builddep *" >> /etc/sudoers.d/pkgmake-yum \
	&& echo "${user} ALL=NOPASSWD:/usr/bin/yum-config-manager *" >> /etc/sudoers.d/pkgmake-yum \
	&& echo "${user} ALL=NOPASSWD:/usr/bin/yum *" >> /etc/sudoers.d/pkgmake-yum

# Prepare locales
ARG locale="en_US.UTF-8"
ENV LANG "${locale}"
ENV LC_ALL "${locale}"

# Define (unused) arguments (to avoid warning) 
ARG dir=.
