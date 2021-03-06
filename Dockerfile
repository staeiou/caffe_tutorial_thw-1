FROM andrewosh/binder-base

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
	libtiff5-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-setuptools \
        python-scipy && \
    rm -rf /var/lib/apt/lists/*

# per https://groups.google.com/forum/#!msg/caffe-users/wKYe45FKSqE/HcFMlGS-M8gJ
# via https://github.com/BVLC/caffe/issues/4436
RUN ln -s /usr/lib/x86_64-linux-gnu/libhdf5.so.7 /usr/lib/x86_64-linux-gnu/libhdf5.so.9
RUN ln -s /usr/lib/x86_64-linux-gnu/libhdf5_hl.so.7 /usr/lib/x86_64-linux-gnu/libhdf5_hl.so.9
RUN ldconfig

ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

# FIXME: use ARG instead of ENV once DockerHub supports this
ENV CLONE_TAG=rc4

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    pip install --upgrade pip && \
    cd python && for req in $(cat requirements.txt) pydot; do pip install $req; done && cd .. && \
    mkdir build && cd build && \
    cmake -DCPU_ONLY=1 -DBUILD_TIFF=ON .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

WORKDIR /workspace
