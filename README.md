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
docker pull ghcr.io/pjaudiomv/kaniko-ci-toolkit:1.1.7
```

### Docker Hub

```bash
# Pull the latest version
docker pull pjaudiomv/kaniko-ci-toolkit:latest

# Or pull a specific version by tag
docker pull pjaudiomv/kaniko-ci-toolkit:1.1.7
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

### Example Workflow

The repository includes an example GitHub workflow (`.github/workflows/example.yaml`) that demonstrates how to use the kaniko-ci-toolkit image in a real-world CI/CD pipeline:

```yaml
name: Example Multi-Arch Kaniko Build

on:
  push:
    tags: ['v*']

jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      tag: ${{ steps.set-tag.outputs.tag }}
    steps:
      - name: Determine tag
        id: set-tag
        run: |
          if [[ "${GITHUB_REF_TYPE}" == "tag" ]]; then
            echo "tag=${GITHUB_REF_NAME}" >> $GITHUB_OUTPUT
          elif [[ "${GITHUB_REF_NAME}" == "${{ github.event.repository.default_branch }}" ]]; then
            echo "tag=latest" >> $GITHUB_OUTPUT
          else
            echo "tag=${GITHUB_SHA::7}" >> $GITHUB_OUTPUT
          fi

  build:
    needs: prepare
    strategy:
      matrix:
        include:
          - os: ubuntu-24.04
            arch: amd64
          - os: ubuntu-24.04-arm
            arch: arm64
    runs-on: ${{ matrix.os }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup docker auth config
        run: |
          mkdir -p .docker
          echo "{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$(echo -n "${{ secrets.DOCKERHUB_USERNAME }}:${{ secrets.DOCKERHUB_TOKEN }}" | base64)\"}}}" > .docker/config.json

      - name: Build and push ${{ matrix.arch }} image
        run: |
          docker run --rm \
            -v "$PWD:/workspace" \
            -v "$PWD/.docker:/kaniko/.docker" \
            -w /workspace \
            ghcr.io/pjaudiomv/kaniko-ci-toolkit:1.0.0 \
            /kaniko/executor \
              --dockerfile=/workspace/nginx.Dockerfile \
              --context=/workspace \
              --cache=true \
              --destination "docker.io/pjaudiomv/nginx-test:${{ needs.prepare.outputs.tag }}-${{ matrix.arch }}"

  manifest:
    name: Create Multi-Arch Manifest
    runs-on: ubuntu-latest
    needs: [prepare, build]
    steps:
      - name: Setup docker auth config
        run: |
          mkdir -p .docker
          echo "{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$(echo -n "${{ secrets.DOCKERHUB_USERNAME }}:${{ secrets.DOCKERHUB_TOKEN }}" | base64)\"}}}" > .docker/config.json

      - name: Push Multi-Arch Manifest
        run: |
          docker run --rm \
            -v "$PWD:/workspace" \
            -v "$PWD/.docker:/kaniko/.docker" \
            -w /workspace \
            ghcr.io/pjaudiomv/kaniko-ci-toolkit:1.0.0 \
            /busybox/manifest-tool push from-args \
              --platforms linux/amd64,linux/arm64 \
              --template "docker.io/pjaudiomv/nginx-test:${{ needs.prepare.outputs.tag }}-ARCH" \
              --target "docker.io/pjaudiomv/nginx-test:${{ needs.prepare.outputs.tag }}"
```

This workflow demonstrates:

1. **Dynamic Tag Generation**: Automatically determines the appropriate tag based on the Git reference
2. **Multi-Architecture Builds**: Builds images for both amd64 and arm64 architectures
3. **Docker Registry Authentication**: Sets up authentication for Docker Hub
4. **Kaniko Image Building**: Uses the kaniko-ci-toolkit to build and push architecture-specific images
5. **Multi-Architecture Manifest**: Creates and pushes a multi-architecture manifest using manifest-tool

You can use this workflow as a template for your own projects, adjusting the Dockerfile path, destination registry, and other parameters as needed.

### GitLab CI Example

Here's an equivalent example for GitLab CI (`.gitlab-ci.yml`):

```yaml
stages:
  - prepare
  - build
  - manifest

variables:
  DOCKER_REGISTRY: docker.io
  DOCKER_IMAGE: pjaudiomv/nginx-test

prepare:
  stage: prepare
  image: ghcr.io/pjaudiomv/kaniko-ci-toolkit:1.0.0
  script:
    - |
      if [[ -n "$CI_COMMIT_TAG" ]]; then
        echo "TAG=$CI_COMMIT_TAG" >> variables.env
      elif [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then
        echo "TAG=latest" >> variables.env
      else
        echo "TAG=${CI_COMMIT_SHA:0:7}" >> variables.env
      fi
  artifacts:
    reports:
      dotenv: variables.env

.build-template: &build-template
  stage: build
  needs:
    - prepare
  script:
    - mkdir -p .docker
    - echo "{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$(echo -n "${DOCKERHUB_USERNAME}:${DOCKERHUB_TOKEN}" | base64)\"}}}" > .docker/config.json
    - |
      /kaniko/executor \
          --dockerfile=/nginx.Dockerfile \
          --context=/ \
          --cache=true \
          --destination "$DOCKER_REGISTRY/$DOCKER_IMAGE:$TAG-$ARCH"

build-amd64:
  <<: *build-template
  variables:
    ARCH: amd64
  tags:
    - amd64

build-arm64:
  <<: *build-template
  variables:
    ARCH: arm64
  tags:
    - arm64

manifest:
  stage: manifest
  needs:
    - prepare
    - build-amd64
    - build-arm64
  script:
    - mkdir -p .docker
    - echo "{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$(echo -n "${DOCKERHUB_USERNAME}:${DOCKERHUB_TOKEN}" | base64)\"}}}" > .docker/config.json
    - |
      manifest-tool push from-args \
          --platforms linux/amd64,linux/arm64 \
          --template "$DOCKER_REGISTRY/$DOCKER_IMAGE:$TAG-ARCH" \
          --target "$DOCKER_REGISTRY/$DOCKER_IMAGE:$TAG"
  only:
    - tags

# Only run the pipeline for tags starting with 'v'
workflow:
  rules:
    - if: $CI_COMMIT_TAG =~ /^v.*/
```

This GitLab CI configuration achieves the same functionality as the GitHub workflow:

1. **Dynamic Tag Generation**: Uses GitLab CI variables to determine the appropriate tag
2. **Multi-Architecture Builds**: Uses GitLab runners with specific tags for different architectures
3. **Docker Registry Authentication**: Sets up authentication using GitLab CI variables
4. **Kaniko Image Building**: Uses the kaniko-ci-toolkit to build and push architecture-specific images
5. **Multi-Architecture Manifest**: Creates and pushes a multi-architecture manifest

Note that you'll need to:
- Set up GitLab CI variables for `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
- Configure GitLab runners with the appropriate architecture tags (`amd64` and `arm64`)

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is distributed under the MIT License. See the LICENSE file for more information.
