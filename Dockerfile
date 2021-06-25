# syntax=docker/dockerfile:1.2

# DOCKER_HOST=ssh://flatbit DOCKER_BUILDKIT=1 docker build --target=hello_world_cpu -o=bin/ .
# GLOG_logtostderr=1 ./hello_world_cpu

# DOCKER_HOST=ssh://flatbit DOCKER_BUILDKIT=1 docker build --target=iris_tracking_cpu -o=bin/ .

# cat Dockerfile | DOCKER_BUILDKIT=1 docker -H ssh://flatbit build --target=libs -o=lib/ -


FROM alpine AS mediapipe-src-builder
WORKDIR /w
RUN set -ux \
 && apk update \
 && apk add git \
 && git init \
 && git remote add origin https://github.com/google/mediapipe \
 && git fetch --depth 1 origin ecb5b5f44ab23ea620ef97a479407c699e424aa7 \
 && git checkout FETCH_HEAD
FROM scratch AS mediapipe-src
COPY --from=mediapipe-src-builder /w /

###FROM ubuntu:20.04 AS base-cpu
FROM ubuntu:18.04 AS base-cpu
WORKDIR /mediapipe
ENV DEBIAN_FRONTEND=noninteractive
RUN set -ux \
 && apt update \
 && apt install -y --no-install-recommends \
        build-essential \
        gcc-8 g++-8 \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        wget \
        unzip \
        python3-dev \
        python3-opencv \
        python3-pip \
        libopencv-core-dev \
        libopencv-highgui-dev \
        libopencv-imgproc-dev \
        libopencv-video-dev \
        libopencv-calib3d-dev \
        libopencv-features2d-dev \
        software-properties-common \
 && add-apt-repository -y ppa:openjdk-r/ppa \
 && apt update \
 && apt install -y openjdk-8-jdk
RUN set -ux \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
 && update-alternatives --install /usr/bin/python python /usr/bin/python3 1
RUN set -ux \
 && pip3 install --upgrade setuptools \
 && pip3 install wheel \
 && pip3 install future \
 && pip3 install six==1.14.0
 # && pip3 install tensorflow==1.14.0 \
 # && pip3 install tf_slim
ARG BAZEL_VERSION=3.7.2
RUN set -ux \
 && mkdir /bazel \
 && wget --no-check-certificate -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" \
 && wget --no-check-certificate -O /bazel/LICENSE.txt "https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE" \
 && chmod +x /bazel/installer.sh \
 && /bazel/installer.sh \
 && rm /bazel/installer.sh
RUN set -ux \
 && echo ' --platform_suffix=-cpu' >/bazelflags
COPY --from=mediapipe-src / /mediapipe/
### RUN set -ux \
###  #    # Fix for OpenCV v4
###  # && sed -i 's%#include <opencv2/optflow.hpp>%#include <opencv2/video/tracking.hpp>%' mediapipe/framework/port/opencv_video_inc.h \
###     # Use OpenCV v4
###  && sed -i 's%# "include/%"include/%g' third_party/opencv_linux.BUILD
RUN \
  --mount=type=cache,target=/root/.cache/bazel \
    set -ux \
 && bazel build $(cat /bazelflags) \
                -c opt \
                --define MEDIAPIPE_DISABLE_GPU=1 \
                mediapipe/examples/desktop/hello_world:hello_world \
 && mkdir /x \
 && cp ./bazel-bin/mediapipe/examples/desktop/hello_world/hello_world /x/hello_world_cpu

FROM scratch AS hello_world_cpu
COPY --from=base-cpu /x/hello_world_cpu /


FROM base-cpu AS base-gpu
RUN set -ux \
 && apt install -y --no-install-recommends \
        mesa-common-dev \
        libegl1-mesa-dev \
        libgles2-mesa-dev \
        mesa-utils
RUN set -ux \
 && echo ' --platform_suffix=-gpu' >/bazelflags
RUN \
  --mount=type=cache,target=/root/.cache/bazel \
    set -ux \
 && bazel build $(cat /bazelflags) \
                -c opt \
                --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11 \
                mediapipe/examples/desktop/hello_world:hello_world \
 && cp ./bazel-bin/mediapipe/examples/desktop/hello_world/hello_world /x/hello_world_gpu

FROM scratch AS hello_world_gpu
COPY --from=base-gpu /x/hello_world_gpu /


FROM scratch AS libs
COPY --from=base-cpu /usr/lib/x86_64-linux-gnu/libopencv_*.so.*.*.* /


## iris_tracking

FROM base-gpu AS builder-iris_tracking_gpu
# ENV DRI_PRIME=1
RUN \
  --mount=type=cache,target=/root/.cache/bazel \
    set -ux \
 && bazel build $(cat /bazelflags) \
                -c opt \
                --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11 \
                # --copt -DMEDIAPIPE_OMIT_EGL_WINDOW_BIT \
                mediapipe/examples/desktop/iris_tracking:iris_tracking_gpu \
                # -- --calculator_graph_config_file=mediapipe/graphs/iris_tracking/iris_tracking_gpu.pbtxt
 && cp ./bazel-bin/mediapipe/examples/desktop/iris_tracking/iris_tracking_gpu /x/

FROM scratch AS iris_tracking_gpu
COPY --from=builder-iris_tracking_gpu /x/iris_tracking_gpu /


FROM base-cpu AS builder-iris_tracking_cpu
RUN \
  --mount=type=cache,target=/root/.cache/bazel \
    set -ux \
 && bazel build $(cat /bazelflags) \
                -c opt \
                --define MEDIAPIPE_DISABLE_GPU=1 \
                mediapipe/examples/desktop/iris_tracking:iris_tracking_cpu \
 && cp ./bazel-bin/mediapipe/examples/desktop/iris_tracking/iris_tracking_cpu /x/

FROM scratch AS iris_tracking_cpu
COPY --from=builder-iris_tracking_cpu /x/iris_tracking_cpu /
# Graph: mediapipe/graphs/iris_tracking/iris_tracking_cpu.pbtxt
# docker run --rm -it --privileged fenollp/builder-iris_tracking_cpu /x/iris_tracking_cpu --calculator_graph_config_file mediapipe/graphs/iris_tracking/iris_tracking_cpu.pbtxt

# # https://stackoverflow.com/a/25168483/1418165

# XSOCK=/tmp/.X11-unix
# XAUTH=/tmp/.docker.xauth
# xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
# docker run --rm -it -v $XSOCK:$XSOCK -v $XAUTH:$XAUTH -v /dev/input -v "$PWD":/app -e XAUTHORITY=$XAUTH  --privileged fenollp/builder-iris_tracking_cpu /x/iris_tracking_cpu --calculator_graph_config_file mediapipe/graphs/iris_tracking/iris_tracking_cpu.pbtxt

## hand_tracking

FROM base-cpu AS builder-hand_tracking_cpu
RUN \
  --mount=type=cache,target=/root/.cache/bazel \
    set -ux \
 && bazel build $(cat /bazelflags) \
                -c opt \
                --define MEDIAPIPE_DISABLE_GPU=1 \
                mediapipe/examples/desktop/hand_tracking:hand_tracking_cpu \
 && cp ./bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_cpu /x/

FROM scratch AS hand_tracking_cpu
COPY --from=builder-hand_tracking_cpu /x/hand_tracking_cpu /
# Graph: mediapipe/graphs/hand_tracking/hand_tracking_desktop_live.pbtxt

FROM base-gpu AS builder-hand_tracking_gpu
RUN \
  --mount=type=cache,target=/root/.cache/bazel \
    set -ux \
 && bazel build $(cat /bazelflags) \
                -c opt \
                --copt -DMESA_EGL_NO_X11_HEADERS --copt -DEGL_NO_X11 \
                mediapipe/examples/desktop/hand_tracking:hand_tracking_gpu \
 && cp ./bazel-bin/mediapipe/examples/desktop/hand_tracking/hand_tracking_gpu /x/

FROM scratch AS hand_tracking_gpu
COPY --from=builder-hand_tracking_gpu /x/hand_tracking_gpu /
# Graph: mediapipe/graphs/hand_tracking/hand_tracking_desktop_live_gpu.pbtxt