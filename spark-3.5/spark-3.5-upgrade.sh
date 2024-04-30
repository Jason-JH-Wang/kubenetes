#apt-get autoremove #清理无用的包
#apt-get install -f #尝试修复损坏的依赖
#apt-get install python3.10-distutils -y
#python3 -m pip install --upgrade pip
##############################################################################################################
# spark 3.5 and upgrade python to 3.10
# docker build -t wangjiahua/spark:3.5.0-v1.0 .
##############################################################################################################

FROM spark:3.5.0
USER root

COPY ./get-pip.py  /opt/spark/work-dir/
COPY ./netty-codec-http2-4.1.109.Final.jar  /opt/spark/jars/
COPY ./mesos-1.7.3-shaded-protobuf.jar  /opt/spark/jars/
COPY ./hadoop-client-runtime-3.3.6.jar  /opt/spark/jars/

RUN pip freeze > requirements.txt \
&& apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y \
&& apt-get install packagekit policykit-1 systemd -y \
&& apt-get install software-properties-common -y \
&& add-apt-repository ppa:deadsnakes/ppa -y \
&& apt-get update \
&& apt-get --purge remove python3.8 -y \
&& apt-get autoremove -y \
&& find / -name '*python3.8*' -exec rm -rf {} \; || true \
&& apt-get install python3.10 -y  \
&& ln -fs /usr/bin/python3.10 /usr/bin/python3 \
&& ln -fs /usr/bin/python3.10 /usr/bin/python \
&& python3 get-pip.py \
&& ln -fs /usr/local/bin/pip /usr/bin/pip \
&& pip install -r requirements.txt \
&& rm -rf /opt/spark/jars/mesos-1.4.3-shaded-protobuf.jar \
&& rm -rf /opt/spark/jars/netty-codec-http2-4.1.96.Final.jar \
&& rm -rf /opt/spark/jars/hadoop-client-runtime-3.3.4.jar 

USER 185

##############################################################################################################
#spark-py 3.5 
#command: ./bin/docker-image-tool.sh -r spark -t 3.5.0 -p ./kubernetes/dockerfiles/spark/bindings/python/Dockerfile build
#Summary：Use  the 3.5 version resource download from apache official website to build the spark py image
##############################################################################################################

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ARG base_img

FROM $base_img
WORKDIR /

# Reset to root to run installation tasks
USER 0

COPY ./netty-codec-http2-4.1.109.Final.jar  /opt/spark/jars/
COPY ./mesos-1.7.3-shaded-protobuf.jar  /opt/spark/jars/
COPY ./hadoop-client-runtime-3.3.6.jar  /opt/spark/jars/

RUN mkdir ${SPARK_HOME}/python
RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get upgrade -y && apt-get dist-upgrade -y && \
    apt install -y python3 python3-pip && \
    pip3 install --upgrade pip setuptools && \
    # Removed the .cache to save space
    rm -rf /root/.cache && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && \
    rm -rf /opt/spark/jars/mesos-1.4.3-shaded-protobuf.jar && \
    rm -rf /opt/spark/jars/netty-codec-http2-4.1.96.Final.jar && \
    rm -rf /opt/spark/jars/hadoop-client-runtime-3.3.4.jar && \
    apt update -y && \
    apt install update-manager-core -y && \
    # apt install linux-libc-dev -y --allow-downgrades && \
    apt-get purge linux-libc-dev -y && \
    dpkg --configure -a && \
    apt install -f && \
    apt autoremove -y

COPY python/pyspark ${SPARK_HOME}/python/pyspark
COPY python/lib ${SPARK_HOME}/python/lib

WORKDIR /opt/spark/work-dir
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
ARG spark_uid=185
USER ${spark_uid}

##############################################################################################################
#Others
##############################################################################################################


./bin/docker-image-tool.sh -r wangjiahua/spark -t 3.5.0-v1.0 -p ./kubernetes/dockerfiles/spark/bindings/python/Dockerfile build

./bin/docker-image-tool.sh -r spark -t 3.5.0 -p ./kubernetes/dockerfiles/spark/bindings/python/Dockerfile build

dpkg -l | grep linux-libc-dev

apt policy linux-libc-dev  # 查看安装的版本和可用版本


/etc/update-manager/release-upgrades #内核升级的配置脚本 lts change to normal


cat> /etc/update-manager/release-upgrades
[DEFAULT]
# Default prompting and upgrade behavior, valid options:
#
#  never  - Never check for, or allow upgrading to, a new release.
#  normal - Check to see if a new release is available.  If more than one new
#           release is found, the release upgrader will attempt to upgrade to
#           the supported release that immediately succeeds the
#           currently-running release.
#  lts    - Check to see if a new LTS release is available.  The upgrader
#           will attempt to upgrade to the first LTS release available after
#           the currently-running one.  Note that if this option is used and
#           the currently-running release is not itself an LTS release the
#           upgrader will assume prompt was meant to be normal.
Prompt=normal

apt update
apt upgrade
/usr/bin/do-release-upgrade -f DistUpgradeViewNonInteractive
apt update
apt upgrade

root@1eaa9df12c8d:/opt/spark/work-dir# cat /etc/*release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=23.10
DISTRIB_CODENAME=mantic
DISTRIB_DESCRIPTION="Ubuntu 23.10"
PRETTY_NAME="Ubuntu 23.10"
NAME="Ubuntu"
VERSION_ID="23.10"
VERSION="23.10 (Mantic Minotaur)"
VERSION_CODENAME=mantic
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=mantic
LOGO=ubuntu-logo


docker run -it --user root --name spark-3.5.0  bash

##############################################################################################################
#Others options for ubuntu core upgrade
##############################################################################################################

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ARG base_img

FROM $base_img
WORKDIR /

# Reset to root to run installation tasks
USER 0

COPY ./netty-codec-http2-4.1.109.Final.jar  /opt/spark/jars/
COPY ./mesos-1.7.3-shaded-protobuf.jar  /opt/spark/jars/
COPY ./hadoop-client-runtime-3.3.6.jar  /opt/spark/jars/
COPY ./release-upgrades /etc/update-manager/release-upgrades

RUN mkdir ${SPARK_HOME}/python
RUN apt-get -o Acquire::Check-Valid-Until=false update && apt-get upgrade -y && apt-get dist-upgrade -y && \
    apt install -y python3 python3-pip && \
    pip3 install --upgrade pip setuptools && \
    # Removed the .cache to save space
    rm -rf /root/.cache && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && \
    rm -rf /opt/spark/jars/mesos-1.4.3-shaded-protobuf.jar && \
    rm -rf /opt/spark/jars/netty-codec-http2-4.1.96.Final.jar && \
    rm -rf /opt/spark/jars/hadoop-client-runtime-3.3.4.jar && \
    apt update -y && \
    apt install update-manager-core -y && \
    apt-mark hold python3 && \
    apt update && apt upgrade -y && \
    touch /sbin/reboot && apt-get install --reinstall ubuntu-release-upgrader-core \
# RUN DEBIAN_FRONTEND=noninteractive yes | /usr/bin/do-release-upgrade -f DistUpgradeViewNonInteractive && echo $?
RUN 'echo "y\n\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\n" | DEBIAN_FRONTEND=noninteractive /usr/bin/do-release-upgrade  -f DistUpgradeViewNonInteractive'
# RUN DPkg::options { "--force-confdef"; "--force-confnew"; } && DEBIAN_FRONTEND=noninteractive /usr/bin/do-release-upgrade -f DistUpgradeViewNonInteractive && echo $?
RUN dpkg --configure -a && \
    apt install -f && \
    apt autoremove -y

COPY python/pyspark ${SPARK_HOME}/python/pyspark
COPY python/lib ${SPARK_HOME}/python/lib

WORKDIR /opt/spark/work-dir
ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
ARG spark_uid=185
USER ${spark_uid}





# Try to downgrade linux-libc-dev
/bin/sh -c apt-get -o Acquire::Check-Valid-Until=false update && apt-get upgrade -y && apt-get dist-upgrade -y &&     apt install -y python3 python3-pip &&     pip3 install --upgrade pip setuptools &&     rm -rf /root/.cache && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* &&     rm -rf /opt/spark/jars/mesos-1.4.3-shaded-protobuf.jar &&     rm -rf /opt/spark/jars/netty-codec-http2-4.1.96.Final.jar &&     rm -rf /opt/spark/jars/hadoop-client-runtime-3.3.4.jar &&     apt update -y &&     apt install update-manager-core -y &&     apt install linux-libc-dev=5.15.0-25.25 -y --allow-downgrades &&     dpkg --configure -a &&     apt install -f &&     apt autoremove -y