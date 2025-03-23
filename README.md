# Kaniko CI Toolkit

A Kaniko-powered CI build image preloaded with essential container tools: Crane, Cosign, Manifest Tool, ORAS, Make, JQ, Bash, and Vault.

## Features

- Based on the official Kaniko executor image with debug shell
- Pre-installed tools for container image management and CI/CD workflows
- Multi-architecture support (amd64 and arm64)
- Statically compiled binaries where possible for maximum portability

## Getting the Image

You can pull the image from either GitHub Container Registry or Docker Hub:

### GitHub Container Registry

```bash
# Pull the latest version
docker pull ghcr.io/pjaudiomv/kaniko-ci-toolkit:latest

# Or pull a specific version by tag
docker pull ghcr.io/pjaudiomv/kaniko-ci-toolkit:1.0.0
```

### Docker Hub

```bash
# Pull the latest version
docker pull pjaudiomv/kaniko-ci-toolkit:latest

# Or pull a specific version by tag
docker pull pjaudiomv/kaniko-ci-toolkit:1.0.0
```

## Usage

### Local Development

```bash
# Run the container with interactive shell (GitHub Container Registry)
docker run --rm -it ghcr.io/pjaudiomv/kaniko-ci-toolkit:latest /busybox/sh
# Or using Docker Hub
docker run --rm -it pjaudiomv/kaniko-ci-toolkit:latest /busybox/sh

# Mount your local directory to build a container
docker run --rm -it \
  -v $(pwd):/workspace \
  -w /workspace \
  ghcr.io/pjaudiomv/kaniko-ci-toolkit:latest \
  /kaniko/executor --dockerfile=Dockerfile --context=dir:///workspace --destination=your-image:latest
```

### GitHub Actions Example

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      # Use either GitHub Container Registry
      image: ghcr.io/pjaudiomv/kaniko-ci-toolkit:latest
      # Or Docker Hub
      # image: pjaudiomv/kaniko-ci-toolkit:latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Build and push with Kaniko
        run: |
          /kaniko/executor \
            --dockerfile=Dockerfile \
            --context=dir://$(pwd) \
            --destination=ghcr.io/username/repo:latest
```

## Included Tools

The image includes the following tools:

- [Kaniko](https://github.com/GoogleContainerTools/kaniko) - Build container images inside a container without privileged mode
- [Crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane) - Tool for interacting with remote container registries
- [Cosign](https://github.com/sigstore/cosign) - Container signing, verification, and storage in an OCI registry
- [Manifest Tool](https://github.com/estesp/manifest-tool) - Tool for creating and pushing manifest lists for multi-architecture images
- [ORAS](https://github.com/oras-project/oras) - OCI Registry As Storage for artifacts
- [Make](https://www.gnu.org/software/make/) - Build automation tool
- [JQ](https://github.com/jqlang/jq) - Lightweight and flexible command-line JSON processor
- [Bash](https://www.gnu.org/software/bash/) - GNU Bourne Again SHell
- [Vault](https://github.com/hashicorp/vault) - Tool for secrets management, encryption as a service, and privileged access management

## Tool Paths

All tools are available in the `/busybox` directory:

```
/busybox/crane
/busybox/cosign
/busybox/manifest-tool
/busybox/oras
/busybox/make
/busybox/jq
/busybox/vault
/busybox/bash
```

Kaniko executor is available at `/kaniko/executor`.

## Development

### CI/CD Workflows

This project uses GitHub Actions for continuous integration and delivery:

1. **Test Build Workflow** - Runs on pull requests to verify that the Dockerfile builds successfully:
   - Performs multi-architecture builds (amd64, arm64)
   - Runs basic tests to verify tool functionality
   - Ensures changes don't break the build process

2. **Build and Push Workflow** - Runs on pushes to main branch and tags:
   - Builds multi-architecture images
   - Pushes to both GitHub Container Registry and Docker Hub
   - Creates proper tags for versioning

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is distributed under the MIT License. See the LICENSE file for more information.
