FROM ubuntu:22.04

# Set timezone (important for some packages) 
ARG TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV HOME=/home/workspace

RUN yes | unminimize

# Install packages (break this up into checkpoints if you're having build issues)
# Apt caching from: https://stackoverflow.com/a/72851168
# TODO: could probably remove some of these packages
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
  --mount=target=/var/cache/apt,type=cache,sharing=locked \
  rm -f /etc/apt/apt.conf.d/docker-clean \
  &&  apt-get update \
  && apt-get install -y \
  binutils \
  cgdb \
  clang \
  clang-format \
  cmake \
  curl \
  exuberant-ctags \
  g++ \
  gcc \
  gdb \
  gdb-multiarch \
  git \
  libxrandr-dev \
  libncurses5-dev \
  qemu \
  qemu-system-i386 \
  silversearcher-ag \
  tmux \
  vim \
  valgrind \
  autoconf \
  wget \
  python3 \
  python3-pip \
  python-is-python3 \
  libjson-c-dev \
  libfuse-dev \
  sudo \
  fzf \
  openssh-server \
  man \
  file \
  gcc-i686-linux-gnu \
  qemu-user \
  rsync \
  libglib2.0-dev \
  rpcbind \
  nano \
  iputils-ping \
  iproute2 \
  netcat-openbsd \
  dnsutils \
  tcpdump \
  strace \
  lsof \
  expect \
  unzip \
  zip \
  libssl-dev \
  openssl \
  golang-1.24 \
  google-perftools \
  libgoogle-perftools-dev \
  graphviz \
  linux-tools-common \
  linux-tools-generic \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -e && \
    perf_path=$(ls -d /usr/lib/linux-tools-*/perf) && \
    ln -sf "$perf_path" /usr/local/bin/perf

ENV GOPATH=/opt/go
ENV GOBIN=/opt/go/bin
ENV PATH=/usr/lib/go-1.24/bin:$GOBIN:$PATH
# proxy.golang.org is unreachable from the build network on hosts where Google IPs
# are blocked. Fall back to a reachable module proxy first (checksums are still
# verified against the public checksum DB via the proxy). Override with e.g.:
#   docker compose build --build-arg GOPROXY=https://proxy.golang.org,direct
ARG GOPROXY=https://goproxy.cn,proxy.golang.org,direct
ENV GOPROXY=$GOPROXY
RUN go install github.com/google/pprof@latest \
  && command -v go \
  && command -v pprof \
  && command -v dot \
  && printf '%s\n' \
  'export GOPATH=/opt/go' \
  'export GOBIN=/opt/go/bin' \
  'export PATH=/usr/lib/go-1.24/bin:$GOBIN:$PATH' \
  > /etc/profile.d/go-pprof.sh \
  && chmod 0644 /etc/profile.d/go-pprof.sh \
  && ln -sf /usr/lib/go-1.24/bin/go /usr/local/bin/go \
  && ln -sf /opt/go/bin/pprof /usr/local/bin/pprof

RUN useradd --create-home --home-dir /home/workspace --user-group workspace && echo workspace:workspace | chpasswd \
  && chsh -s /bin/bash workspace && echo "workspace ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /home/workspace
COPY ./home/. ./

RUN git config --global init.defaultBranch main

COPY ./install_scripts/. /install_scripts
WORKDIR /install_scripts
RUN ./create_group0.sh && ./create_student0.sh && ./install_bochs.sh && ./install_rust.sh && ./squish/install.sh

WORKDIR /
COPY entrypoint.sh .
COPY ./bin/. ./bin

RUN find /home/workspace/. -not -type d -not -path "./code/*" -not -name ".version" -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum > /home/workspace/.version

RUN chown -R workspace:workspace /home/workspace

RUN mv /home/workspace /workspace

USER workspace

ENTRYPOINT [ "/entrypoint.sh" ]
