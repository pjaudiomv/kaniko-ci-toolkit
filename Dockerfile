# Kaniko Image with
#   - Crane, Cosign, Manifest-Tool, Oras, Make, JQ, Bash, Vault
# renovate: datasource=docker depName=debian
FROM debian:13.1 AS debian

# https://ftp.gnu.org/gnu/make/
ARG MAKE_VERSION=4.4
# https://ftp.gnu.org/gnu/bash/
ARG BASH_VERSION=5.3
# renovate: datasource=github-releases depName=jqlang/jq
ARG JQ_VERSION=1.8.1
# renovate: datasource=github-releases depName=hashicorp/vault
ARG VAULT_VERSION=1.20.4
# renovate: datasource=github-releases depName=oras-project/oras
ARG ORAS_VERSION=1.3.0
# renovate: datasource=github-releases depName=sigstore/cosign
ARG COSIGN_VERSION=2.6.0
# renovate: datasource=github-releases depName=estesp/manifest-tool
ARG MANIFEST_TOOL_VERSION=2.2.1
# renovate: datasource=github-releases depName=google/go-containerregistry
ARG CRANE_VERSION=0.20.6

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        unzip \
        ca-certificates \
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

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "x86_64"; fi) && \
    wget --progress=dot:giga "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_${ARCH}.tar.gz" -O /tmp/crane.tar.gz && \
    tar xzf /tmp/crane.tar.gz -C /tmp && \
    mv /tmp/crane /usr/bin/crane && \
    chmod +x /usr/bin/crane && \
    rm -rf /tmp/*

RUN ARCH=$(if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    wget --progress=dot:giga "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${ARCH}" -O /usr/bin/cosign && \
    chmod +x /usr/bin/cosign

# Kaniko
# renovate: datasource=docker depName=martizih/kaniko
FROM docker.io/martizih/kaniko:v1.25.5-debug

COPY --from=debian /usr/bin/crane /busybox/crane
COPY --from=debian /usr/bin/jq /busybox/jq
COPY --from=debian /usr/bin/vault /busybox/vault
COPY --from=debian /usr/bin/manifest-tool /busybox/manifest-tool
COPY --from=debian /usr/bin/cosign /busybox/cosign
COPY --from=debian /usr/bin/oras /busybox/oras
COPY --from=debian /usr/local/bin/make /busybox/make
COPY --from=debian /usr/local/bin/bash /busybox/bash
COPY --from=debian /etc/ssl/certs/ca-certificates.crt /kaniko/ssl/certs/ca-certificates.crt

RUN ["/busybox/ln", "-s", "/busybox/bash", "/bin/bash"]
ARG PATH="/busybox:/bin:${PATH}"
ENTRYPOINT []

LABEL repository="https://github.com/pjaudiomv/kaniko-ci-toolkit" \
      maintainer="Patrick Joyce <pjaudiomv@gmail.com>"
