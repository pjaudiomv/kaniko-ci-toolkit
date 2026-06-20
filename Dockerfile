# Kaniko Image with
#   - Crane, Cosign, Oras, Make, JQ, Bash, Vault
# renovate: datasource=docker depName=debian
FROM debian:13.5-slim AS debian

# https://ftp.gnu.org/gnu/make/
# renovate: depName=mirror/make
ARG MAKE_VERSION=4.4.1
# https://ftp.gnu.org/gnu/bash/
# renovate: datasource=github-tags depName=mirror/bash extractVersion=^bash-(?<version>.*)$
ARG BASH_VERSION=5.3
# renovate: depName=jqlang/jq
ARG JQ_VERSION=1.8.1
# renovate: depName=hashicorp/vault
ARG VAULT_VERSION=2.0.3
# renovate: depName=oras-project/oras
ARG ORAS_VERSION=1.3.2
# renovate: depName=sigstore/cosign
ARG COSIGN_VERSION=3.1.1
# renovate: depName=google/go-containerregistry
ARG CRANE_VERSION=0.21.6

ARG TARGETARCH

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

RUN wget --progress=dot:giga "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${TARGETARCH}" -O /usr/bin/jq && \
    chmod a+x /usr/bin/jq

RUN wget --progress=dot:giga "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip" -O /tmp/vault.zip && \
    unzip /tmp/vault.zip -d /tmp && \
    rm /tmp/vault.zip && \
    mv /tmp/vault /usr/bin/vault && \
    chmod +x /usr/bin/vault

RUN wget --progress=dot:giga "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_${TARGETARCH}.tar.gz" -O /tmp/oras.tar.gz && \
    tar xzf /tmp/oras.tar.gz -C /tmp && \
    mv /tmp/oras /usr/bin/oras && \
    chmod +x /usr/bin/oras && \
    rm -rf /tmp/*

RUN ARCH=$([ "$TARGETARCH" = "amd64" ] && echo x86_64 || echo "$TARGETARCH") && \
    wget --progress=dot:giga "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_${ARCH}.tar.gz" -O /tmp/crane.tar.gz && \
    tar xzf /tmp/crane.tar.gz -C /tmp && \
    mv /tmp/crane /usr/bin/crane && \
    chmod +x /usr/bin/crane && \
    rm -rf /tmp/*

RUN wget --progress=dot:giga "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${TARGETARCH}" -O /usr/bin/cosign && \
    chmod +x /usr/bin/cosign

# Kaniko
# renovate: datasource=docker depName=martizih/kaniko
FROM docker.io/martizih/kaniko:v1.27.6-debug

COPY --from=debian /usr/bin/crane /busybox/crane
COPY --from=debian /usr/bin/jq /busybox/jq
COPY --from=debian /usr/bin/vault /busybox/vault
COPY --from=debian /usr/bin/cosign /busybox/cosign
COPY --from=debian /usr/bin/oras /busybox/oras
COPY --from=debian /usr/local/bin/make /busybox/make
COPY --from=debian /usr/local/bin/bash /busybox/bash
COPY --from=debian /etc/ssl/certs/ca-certificates.crt /kaniko/ssl/certs/ca-certificates.crt

RUN ["/busybox/ln", "-s", "/busybox/bash", "/bin/bash"]
ENV PATH="/busybox:/bin:${PATH}"
ENTRYPOINT []

LABEL org.opencontainers.image.source="https://github.com/pjaudiomv/kaniko-ci-toolkit" \
      org.opencontainers.image.description="Kaniko with Crane, Cosign, ORAS, Make, jq, Bash, Vault" \
      maintainer="Patrick Joyce <pjaudiomv@gmail.com>"
