FROM ubuntu:18.04

RUN apt-get update && apt-get install -y git ca-certificates build-essential curl wget libghc-zlib-dev libgmp-dev python3 verilator
RUN curl -sSL https://get.haskellstack.org/ | sh && stack install --resolver=lts-12.10 clash-ghc-0.99.3
RUN wget https://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.3.tar.gz &&\
    tar xvf systemc-2.3.3.tar.gz && cd systemc-2.3.3 && mkdir build && mkdir /usr/local/systemc-2.3.2 &&\
    cd build && ../configure --prefix=/usr/local/systemc-2.3.2 && make -j && make install
RUN apt install -y python3-pip && python3 -m pip install cheetah3
ENV SYSTEMC_INCLUDE=/usr/local/systemc-2.3.2/include SYSTEMC_LIBDIR=/usr/local/systemc-2.3.2/lib-linux64 SYSTEMC_HOME=/usr/local/systemc-2.3.2
RUN echo $SYSTEMC_LIBDIR >> /etc/ld.so.conf && ldconfig
ENV PATH=/root/.local/bin:$PATH
ADD . /code
RUN cd /code && mkdir build && make build/RTLmodel -j
