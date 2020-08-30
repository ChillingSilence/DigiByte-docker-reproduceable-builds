FROM ubuntu:bionic
USER root
WORKDIR /data
ARG ROOTDATADIR=/data
ARG DGBVERSION=7.17.2
# Arch not yet used, will do in-future for cross-compiles etc
ARG ARCH=x86_64

# You can confirm your timezone by setting the TZ database name field from:
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG LOCALTIMEZONE=Etc/UTC

RUN DEBIAN_FRONTEND="noninteractive" apt-get update \
  && apt-get -y install tzdata \
  && ln -fs /usr/share/zoneinfo/${LOCALTIMEZONE} /etc/localtime \
  && dpkg-reconfigure --frontend noninteractive tzdata \
  && apt-get install -y wget git build-essential libtool autotools-dev automake \
  pkg-config curl python
# /data/digibyte/depends/sources/xcb-proto-1.10.tar.bz2 needs Python >= 2.5
# libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev \
#  libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev \
#  libdb-dev libdb++-dev

# Clone the Core wallet source from GitHub and checkout the version.
RUN git clone https://github.com/DigiByte-Core/digibyte/ --branch ${DGBVERSION} --single-branch

# Prepare the build process
# Build for x86_64-pc-linux-gnu as per https://github.com/DigiByte-Core/digibyte/tree/master/depends
RUN cd ${ROOTDATADIR}/digibyte \
	&& cd depends \
	&& make \
	&& cd .. \
	&& ./contrib/install_db4.sh `pwd` \
	&& ./autogen.sh \
	&& ./configureBDB_LIBS="-L${ROOTDATADIR}/digibyte/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${ROOTDATADIR}/digibyte/include" --prefix=$PWD/depends/x86_64-pc-linux-gnu \
	&& make

# Verification time
# wget NEEDGITSUMSURL -o ${ROOTDATADIR}/sums && sha256sum ${ROOTDATADIR}/sums
