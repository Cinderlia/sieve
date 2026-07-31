
FROM sieve/basebuild


# Use the fastest APT repo
#COPY ./files/sources.list.with_mirrors /etc/apt/sources.list
RUN apt-get update --fix-missing

ENV DEBIAN_FRONTEND noninteractive

# Install all APT packages

RUN apt-get install -y software-properties-common python3-pip \
                        # other stuff
                        mysql-server \
                        # editors
                        vim  \
                        # analysis
                        afl \
                        # web
                        apache2 apache2-dev

RUN rm -rf /var/lib/mysql
RUN  /usr/sbin/mysqld --initialize-insecure

RUN pip3 install supervisor

# Create sv user
RUN useradd -s /bin/bash -m sv
# Add sv to sudo group
RUN usermod -aG sudo sv
RUN echo "sv ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN su - sv -c "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && mkvirtualenv -p `which python3` sieve"

######### Install phuzzer stuff
RUN apt-get install -y libxss1 bison

RUN su - sv -c "source /home/sv/.virtualenvs/sieve/bin/activate && pip install protobuf termcolor "

RUN su - sv -c "source /home/sv/.virtualenvs/sieve/bin/activate && pip install git+https://github.com/Cinderlia/phuzzer.git"

######### last installs, b/c don't want to wait for phuzzer stuff again.
RUN apt-get install -y jq
RUN wget https://github.com/sharkdp/bat/releases/download/v0.15.0/bat_0.15.0_amd64.deb -O /root/bat15.deb && sudo dpkg -i /root/bat15.deb


######### sv's environment setup
USER sv
WORKDIR /home/sv
RUN mkdir -p /home/sv/tmp/emacs-saves
RUN git clone -q https://github.com/etrickel/docker_env.git && chown sv:sv -R . && cp -r /home/sv/docker_env/. . && sudo cp -r /home/sv/docker_env/. /root/
COPY config/.bash_prompt /home/sv/.bash_prompt

RUN echo 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh' >> /home/sv/.bashrc
RUN echo 'workon sieve' >> /home/sv/.bashrc


######### NodeJS and NPM Setup
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
RUN echo 'export NVM_DIR=$HOME/.nvm; . $NVM_DIR/nvm.sh; . $NVM_DIR/bash_completion' >> /home/sv/.bashrc
ENV NVM_DIR /home/sv/.nvm
RUN . $NVM_DIR/nvm.sh && nvm install 16
#RUN sudo mkdir /node_modules && sudo chown sv:sv /node_modules && sudo apt-get install -y npm
RUN sudo apt-get install -y npm libgbm-dev
RUN . $NVM_DIR/nvm.sh && npm install puppeteer cheerio

USER root
RUN mkdir /app && chown www-data:sv /app
COPY --chown=sv:sv /helpers/gremlins.min.js /app


COPY config/supervisord.conf /etc/supervisord.conf
RUN if [ ! -d /run/sshd ]; then mkdir /run/sshd; chmod 0755 /run/sshd; fi
RUN mkdir /var/run/mysqld ; chown mysql:mysql /var/run/mysqld
# mysql configuration for disk access, used when running 25+ containers on single system
RUN printf "[mysqld]\ninnodb_use_native_aio = 0\n" >> /etc/mysql/my.cnf

RUN ln -s /p /projects

COPY config/network_config.sh /netconf.sh
RUN chmod +x /netconf.sh

ENV TZ=America/Phoenix
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo "export TZ=$TZ" >> /home/sv/.bashrc

RUN usermod -a -G www-data sv

#"Installing" the Witcher's Dash that abends on a parsing error when STRICT=1 is set.
#

#COPY --from=hacrs/build-httpreqr /Witcher/base/httpreqr/httpreqr /httpreqr
COPY --from=sieve/basebuild /httpreqr/httpreqr.64 /httpreqr

COPY afl /afl
ENV AFL_PATH=/afl

COPY --chown=sv:sv helpers/ /helpers/
COPY --chown=sv:sv phuzzer /helpers/phuzzer
COPY --chown=sv:sv witcher /witcher/

RUN . $NVM_DIR/nvm.sh && cd /helpers/request_crawler && npm install
RUN su - sv -c "source /home/sv/.virtualenvs/sieve/bin/activate &&  pip install archr ipdb ply &&  cd /helpers/phuzzer && pip install -e . &&  cd /witcher && pip install -e ."

COPY --from=sieve/basebuild /wclibs/lib_db_fault_escalator.so /lib/
RUN mkdir -p /wclibs && ln -sf /lib/lib_db_fault_escalator.so /wclibs/ && ln -sf /lib/lib_db_fault_escalator.so /wclibs/libcgiwrapper.so && ln -sf /lib/lib_db_fault_escalator.so /lib/libcgiwrapper.so

# copy x86_64 version of dash
COPY --from=sieve/basebuild /Widash/archbuilds/dash /crashing_dash

#COPY --chown=sv:sv bins /bins

ENV CONTAINER_NAME="sieve"
ENV WC_TEST_VER="EXWICHR"
ENV WC_FIRST=""
ENV WC_CORES="10"
ENV WC_TIMEOUT="1200"
ENV WC_SET_AFFINITY="0"
# single script takes "--target scriptname"
ENV WC_SINGLE_SCRIPT=""

RUN mkdir -p /test && chown sv:sv /test

RUN ln -s /usr/local/bin/supervisord /usr/bin/supervisord && ln -s /usr/local/bin/pidproxy /usr/bin/pidproxy

CMD /netconf.sh && /usr/bin/supervisord -c /etc/supervisord.conf
