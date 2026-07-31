
FROM ubuntu:bionic

RUN dpkg --add-architecture i386 && apt-get update

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update --fix-missing && apt-get install -y aria2 curl wget virtualenvwrapper git && \
    apt-get update && apt-get -y upgrade && apt-get update --fix-missing
RUN    apt-get install -y build-essential  \
                        #Libraries
                        libxml2-dev libxslt1-dev libffi-dev cmake libreadline-dev \
                        libtool debootstrap debian-archive-keyring libglib2.0-dev libpixman-1-dev \
                        libssl-dev qtdeclarative5-dev libcapnp-dev libtool-bin \
                        libcurl4-nss-dev libpng-dev libgmp-dev \
                        # x86 Libraries
                        libc6:i386 libgcc1:i386 libstdc++6:i386 libtinfo5:i386 zlib1g:i386 \
                        #python 3
                        python3-pip \
                        #Utils
                        sudo automake  net-tools netcat  \
                        ccache make g++-multilib pkg-config coreutils rsyslog \
                        manpages-dev ninja-build capnproto  software-properties-common zip unzip pwgen \
                        libxss1 bison flex \
			            gawk cvs ncurses-dev \
                        default-jre gradle swig

COPY /httpreqr /httpreqr
RUN cd /httpreqr && make 

COPY wclibs /wclibs
RUN cd /wclibs && \
    gcc -c -Wall -fpic db_fault_escalator.c && \
    gcc -shared -o lib_db_fault_escalator.so db_fault_escalator.o -ldl && \
    rm -f /wclibs/libcgiwrapper.so && \
    ln -s /wclibs/lib_db_fault_escalator.so /wclibs/libcgiwrapper.so && \
    ln -s /wclibs/lib_db_fault_escalator.so /lib/libcgiwrapper.so

COPY /Widash /Widash 
RUN cd /Widash; ./autogen.sh && automake; bash ./x86-build.sh

COPY /php-trace /php-trace

RUN git clone https://github.com/malteskoruppa/phpjoern.git /opt/phpjoern
RUN git clone https://github.com/octopus-platform/joern.git /joern && \
    cd /joern && \
    gradle build -x test -x joernTools
