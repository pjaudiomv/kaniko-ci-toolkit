# Kaniko Image with
#   - Crane, Cosign, Manifest-Tool, Oras, Make, JQ, Bash, Vault

# Debian - Make, JQ, Bash, Vault
FROM debian:12.10 AS debian

ENV MAKE_VERSION=4.4
ENV BASH_VERSION=5.2
ENV JQ_VERSION=1.7.1
ENV VAULT_VERSION=1.19.0
ENV ORAS_VERSION=1.2.2
ENV MANIFEST_TOOL_VERSION=2.1.9

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        wget \
        unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/src

RUN wget https://ftp.gnu.org/gnu/make/make-${MAKE_VERSION}.tar.gz \
    && tar -xzvf make-${MAKE_VERSION}.tar.gz \
    && rm make-${MAKE_VERSION}.tar.gz \
    && cd make-${MAKE_VERSION} \
    && ./configure CFLAGS="-static" \
    && make \
    && make install \
    && cd .. \
    && rm -rf make-${MAKE_VERSION}

RUN wget https://ftp.gnu.org/gnu/bash/bash-${BASH_VERSION}.tar.gz \
    && tar -xzvf bash-${BASH_VERSION}.tar.gz \
    && rm bash-${BASH_VERSION}.tar.gz \
    && cd bash-${BASH_VERSION} \
    && ./configure CFLAGS="-static" \
    && make \
    && make install \
    && cd .. \
    && rm -rf bash-${BASH_VERSION}

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${ARCH}" -O /usr/bin/jq && \
    chmod a+x /usr/bin/jq

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip" -O /tmp/vault.zip && \
    unzip /tmp/vault.zip -d /tmp && \
    rm /tmp/vault.zip && \
    mv /tmp/vault /usr/bin/vault && \
    chmod +x /usr/bin/vault

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/binaries-manifest-tool-${MANIFEST_TOOL_VERSION}.tar.gz" -O /tmp/manifest-tool.tar.gz && \
    tar xzf /tmp/manifest-tool.tar.gz -C /tmp && \
    mv /tmp/manifest-tool-linux-${ARCH} /usr/bin/manifest-tool && \
    chmod +x /usr/bin/manifest-tool && \
    rm -rf /tmp/*

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_${ARCH}.tar.gz" -O /tmp/oras.tar.gz && \
    tar xzf /tmp/oras.tar.gz -C /tmp && \
    mv /tmp/oras /usr/bin/oras && \
    chmod +x /usr/bin/oras && \
    rm -rf /tmp/*

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-${ARCH}" -O /usr/bin/cosign && \
    chmod +x /usr/bin/cosign

# Crane
FROM golang:1.23.7 AS crane
RUN go install github.com/google/go-containerregistry/cmd/crane@latest

# Kaniko
FROM gcr.io/kaniko-project/executor:v1.23.2-debug
COPY --from=crane /go/bin/crane /busybox/crane
COPY --from=debian /usr/bin/jq /busybox/jq
COPY --from=debian /usr/bin/vault /busybox/vault
COPY --from=debian /usr/bin/manifest-tool /busybox/manifest-tool
COPY --from=debian /usr/bin/cosign /busybox/cosign
COPY --from=debian /usr/bin/oras /busybox/oras
COPY --from=debian /usr/local/bin/make /busybox/make
COPY --from=debian /usr/local/bin/bash /busybox/bash

RUN ["/busybox/ln", "-s", "/busybox/bash", "/bin/bash"]
ENV PATH="/bin:${PATH}"
ENTRYPOINT []
