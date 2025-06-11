ARG ubuntu=22.04
FROM ubuntu:$ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install \
    wget lsb-release build-essential devscripts libgtk-3-dev libgnutls28-dev \
    libgif-dev librsvg2-dev texinfo libncurses-dev libgccjit-11-dev libm17n-dev \
    libxpm-dev \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -d /home/builder -m builder
USER builder
WORKDIR /home/builder

COPY Makefile .
RUN mkdir debian
COPY debian/* debian/
RUN make tree-sitter

USER root
RUN dpkg -i /home/builder/target/libtree-sitter*.deb
USER builder

VOLUME /home/builder

CMD ["all"]
ENTRYPOINT ["/usr/bin/make"]
