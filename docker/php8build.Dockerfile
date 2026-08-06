FROM sieve/basebuild as basebuild
#FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

ARG ARG_PHP_VER=8
ENV PHP_VER=${ARG_PHP_VER}
ENV PHP_INI_DIR="/etc/php/"
ENV LD_LIBRARY_PATH="/wclibs"
ENV PROF_FLAGS="-lcgiwrapper -I/wclibs"
ENV CPATH="/wclibs"

RUN mkdir -p $PHP_INI_DIR/conf.d /phpsrc
COPY repo /phpsrc

COPY witcher-php-install/php-8.4-witcher.patch /phpsrc/witcher.patch
COPY witcher-php-install/zend_witcher_trace.c witcher-php-install/zend_witcher_trace.h /phpsrc/Zend/

RUN apt-get update && apt-get install -y apache2 apache2-dev libsqlite3-dev libonig-dev

RUN cd /tmp && \
    wget https://github.com/skvadrik/re2c/releases/download/2.2/re2c-2.2.tar.xz && \
    tar -xf re2c-2.2.tar.xz && \
    cd re2c-2.2 && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/re2c-2.2

RUN cd /phpsrc && git apply ./witcher.patch && ln -sf ext/xdebug/m4 /phpsrc/m4 && ./buildconf --force

RUN cd /phpsrc &&         \
        ./configure       \
#		--with-config-file-path="$PHP_INI_DIR" \
#		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --with-apxs2=/usr/bin/apxs \
#		\
		--enable-cgi      \
		--enable-ftp      \
		--enable-mbstring \
		--with-gd         \
		\
		--with-openssl      \
		--with-pdo-mysql  \
        --with-mysqli=mysqlnd \
		--with-zlib       \
	&& printf "\033[36m[Sieve] PHP $PHP_VER Configure completed \033[0m\n"

#RUN sed -i 's/CFLAGS_CLEAN = /CFLAGS_CLEAN = -L\/wclibs -lcgiwrapper -I\/wclibs /g' /phpsrc/Makefile \
RUN cd /phpsrc \
	&& make clean &&  EXTRA_CFLAGS="-DWITCHER_DEBUG=1" make -j $(nproc) \
	&& printf "\033[36m[Sieve] PHP $PHP_VER Make completed \033[0m\n"
#
RUN cd /phpsrc && make install \
	&& printf "\033[36m[Sieve] PHP $PHP_VER Install completed \033[0m\n" \
    \


COPY /php-trace /php-trace
RUN cd /php-trace && \
    phpize && \
    ./configure --enable-opcode-tracer && \
    make && \
    make install

# Build php-ast extension
RUN git clone https://github.com/nikic/php-ast /php-ast && \
    cd /php-ast && \
    git checkout 64ea727 && \
    phpize && \
    ./configure && \
    make && \
    make install