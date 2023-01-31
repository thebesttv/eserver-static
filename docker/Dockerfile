FROM ubuntu:20.04

# docker build -t emacs --build-arg UNAME=$(whoami) --build-arg UID=$(id -u) --build-arg GID=$(id -g) .
# mkdir -p ~/.emacs.d
# docker run -v /home/runner:/home/runner -it --rm emacs /bin/bash -c "cd /home/runner/work/eserver-static/eserver-static/eserver-static && make publish"

# apt update
# apt -y install apt-transport-https ca-certificates

ARG UNAME=runner
ARG UID=1000
ARG GID=1000

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    sed -i 's/^# deb-src/deb-src/' /etc/apt/sources.list && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get -y install build-essential wget git && \
    apt-get -y build-dep emacs

RUN cd /root && \
    wget -qO- https://ftp.gnu.org/gnu/emacs/emacs-28.2.tar.gz | tar xvz && \
    cd emacs-28.2 && mkdir build && cd build && \
    ../configure --with-x-toolkit=no --with-jpeg=no --with-png=no --with-gif=no --with-tiff=no && \
    make && make install && \
    cd /root && rm -rf emacs-28.2*

RUN groupadd -g $GID -o $UNAME && \
    useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME

USER $UNAME
CMD /bin/bash
