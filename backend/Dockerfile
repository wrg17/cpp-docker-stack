FROM ubuntu:24.04 AS builder
LABEL authors="willgeorge"

LABEL stage=builder
ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends \
  build-essential \
  clang \
  cmake \
  ninja-build \
  gdb \
  vim \
  git \
  pkg-config \
  ca-certificates \
  libboost-system-dev \
  libpqxx-dev \
  libpq-dev
rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /app

COPY .. .

WORKDIR /app/backend
ARG CMAKE_PRESET=release
RUN cmake --preset ${CMAKE_PRESET}
RUN cmake --build --preset ${CMAKE_PRESET} --target cpp_server --parallel

FROM ubuntu:24.04 AS final

ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends \
  libboost-system1.83.0 \
  libpq5 \
  libpqxx-7.8 \
  libstdc++6 \
  ca-certificates
rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /app
ARG CMAKE_PRESET=release
COPY --from=builder /app/backend/build/${CMAKE_PRESET}/cpp_server ./cpp_server

CMD ["./cpp_server"]


