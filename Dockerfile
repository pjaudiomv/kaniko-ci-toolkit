# Kaniko Image with
#   - Crane, Cosign, Manifest-Tool, Oras, Make, JQ, Bash, Vault
FROM debian:12.10 AS debian

# https://ftp.gnu.org/gnu/make/
ENV MAKE_VERSION=4.4
# https://ftp.gnu.org/gnu/bash/
ENV BASH_VERSION=5.2
# https://github.com/jqlang/jq/releases
ENV JQ_VERSION=1.7.1
# https://github.com/hashicorp/vault/releases
ENV VAULT_VERSION=1.19.0
# https://github.com/oras-project/orasgithub.com/oras-project/oras
ENV ORAS_VERSION=1.2.2
# https://github.com/sigstore/cosign/releases
ENV COSIGN_VERSION=2.4.3
# https://github.com/google/go-containerregistry/releases
ENV CRANE_VERSION=0.20.3
# https://github.com/estesp/manifest-tool/releases
ENV MANIFEST_TOOL_VERSION=2.1.9

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/src

RUN wget --progress=dot:giga https://ftp.gnu.org/gnu/make/make-${MAKE_VERSION}.tar.gz \
    && tar -xzvf make-${MAKE_VERSION}.tar.gz \
    && rm make-${MAKE_VERSION}.tar.gz

WORKDIR /usr/local/src/make-${MAKE_VERSION}
RUN ./configure CFLAGS="-static" \
    && make \
    && make install

WORKDIR /usr/local/src
RUN rm -rf make-${MAKE_VERSION}

RUN wget --progress=dot:giga https://ftp.gnu.org/gnu/bash/bash-${BASH_VERSION}.tar.gz \
    && tar -xzvf bash-${BASH_VERSION}.tar.gz \
    && rm bash-${BASH_VERSION}.tar.gz

WORKDIR /usr/local/src/bash-${BASH_VERSION}
RUN ./configure CFLAGS="-static" \
    && make \
    && make install

WORKDIR /usr/local/src
RUN rm -rf bash-${BASH_VERSION}

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget --progress=dot:giga "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${ARCH}" -O /usr/bin/jq && \
    chmod a+x /usr/bin/jq

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget --progress=dot:giga "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip" -O /tmp/vault.zip && \
    unzip /tmp/vault.zip -d /tmp && \
    rm /tmp/vault.zip && \
    mv /tmp/vault /usr/bin/vault && \
    chmod +x /usr/bin/vault

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget --progress=dot:giga "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/binaries-manifest-tool-${MANIFEST_TOOL_VERSION}.tar.gz" -O /tmp/manifest-tool.tar.gz && \
    tar xzf /tmp/manifest-tool.tar.gz -C /tmp && \
    mv "/tmp/manifest-tool-linux-${ARCH}" /usr/bin/manifest-tool && \
    chmod +x /usr/bin/manifest-tool && \
    rm -rf /tmp/*

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget --progress=dot:giga "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_${ARCH}.tar.gz" -O /tmp/oras.tar.gz && \
    tar xzf /tmp/oras.tar.gz -C /tmp && \
    mv /tmp/oras /usr/bin/oras && \
    chmod +x /usr/bin/oras && \
    rm -rf /tmp/*

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget --progress=dot:giga "https://github.com/sigstore/cosign/releases/v${COSIGN_VERSION}/download/cosign-linux-${ARCH}" -O /usr/bin/cosign && \
    chmod +x /usr/bin/cosign

# Crane
FROM golang:1.23.7 AS crane
RUN go install github.com/google/go-containerregistry/cmd/crane@v${CRANE_VERSION}

# Kaniko
FROM gcr.io/kaniko-project/executor:v1.23.2-debug

# Set tool versions
ENV MAKE_VERSION=4.4
ENV BASH_VERSION=5.2
ENV JQ_VERSION=1.7.1
ENV VAULT_VERSION=1.19.0
ENV ORAS_VERSION=1.2.2
ENV MANIFEST_TOOL_VERSION=2.1.9
ENV COSIGN_VERSION=2.4.3
ENV CRANE_VERSION=0.20.3

# Add version labels
LABEL org.opencontainers.image.title="Kaniko CI Toolkit" \
      org.opencontainers.image.description="Kaniko-powered CI build image with essential container tools" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.authors="pjaudiomv" \
      org.opencontainers.image.url="https://github.com/pjaudiomv/kaniko-ci-toolkit" \
      org.opencontainers.image.source="https://github.com/pjaudiomv/kaniko-ci-toolkit" \
      org.opencontainers.image.licenses="MIT"

# Tool version labels
LABEL tools.kaniko.version="1.23.2" \
      tools.crane.version="${CRANE_VERSION}" \
      tools.cosign.version="${COSIGN_VERSION}" \
      tools.manifest-tool.version="${MANIFEST_TOOL_VERSION}" \
      tools.oras.version="${ORAS_VERSION}" \
      tools.make.version="${MAKE_VERSION}" \
      tools.jq.version="${JQ_VERSION}" \
      tools.bash.version="${BASH_VERSION}" \
      tools.vault.version="${VAULT_VERSION}"

COPY --from=crane /go/bin/crane /busybox/crane
COPY --from=debian /usr/bin/jq /busybox/jq
COPY --from=debian /usr/bin/vault /busybox/vault
COPY --from=debian /usr/bin/manifest-tool /busybox/manifest-tool
COPY --from=debian /usr/bin/cosign /busybox/cosign
COPY --from=debian /usr/bin/oras /busybox/oras
COPY --from=debian /usr/local/bin/make /busybox/make
COPY --from=debian /usr/local/bin/bash /busybox/bash

RUN ["/busybox/ln", "-s", "/busybox/bash", "/bin/bash"]
ENV PATH="/busybox:/bin:${PATH}"
ENTRYPOINT []
