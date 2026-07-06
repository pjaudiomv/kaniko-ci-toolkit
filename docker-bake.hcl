# docker-bake.hcl
#
# Build the Kaniko CI Toolkit image with Docker Buildx Bake.
#
#   docker buildx bake                 # build default target
#   docker buildx bake --push          # build and push to registries
#   docker buildx bake --set '*.platform=linux/amd64'  # single-arch
#
# Override variables via environment, e.g.:
#   TAG=1.2.3 docker buildx bake --push

variable "GHCR_IMAGE" {
  default = "ghcr.io/pjaudiomv/kaniko-ci-toolkit"
}

variable "DOCKERHUB_IMAGE" {
  default = "pjaudiomv/kaniko-ci-toolkit"
}

# Image tag (e.g. a semver release or "latest").
variable "TAG" {
  default = "latest"
}

# Short git SHA, surfaced as an image label/annotation.
variable "SHA" {
  default = ""
}

# Space- or comma-separated extra tags to apply in addition to TAG.
variable "EXTRA_TAGS" {
  default = ""
}

function "tags" {
  params = []
  result = flatten([
    for img in [GHCR_IMAGE, DOCKERHUB_IMAGE] : [
      for t in concat([TAG], [for x in split(",", replace(EXTRA_TAGS, " ", ",")) : x if x != ""]) :
      "${img}:${t}"
    ]
  ])
}

group "default" {
  targets = ["toolkit"]
}

# Overridden in CI by the file that docker/metadata-action generates
# (tags, labels, annotations). Locally it supplies the defaults below so
# `docker buildx bake` keeps working standalone.
target "docker-metadata-action" {
  tags = tags()

  labels = {
    "org.opencontainers.image.title"         = "Kaniko CI Toolkit"
    "org.opencontainers.image.description"    = "Kaniko-powered CI build image with essential container tools"
    "org.opencontainers.image.version"       = TAG
    "org.opencontainers.image.revision"      = SHA
    "org.opencontainers.image.authors"       = "pjaudiomv"
    "org.opencontainers.image.licenses"      = "MIT"
    "org.opencontainers.image.source"        = "https://github.com/pjaudiomv/kaniko-ci-toolkit"
    "org.opencontainers.image.documentation" = "https://github.com/pjaudiomv/kaniko-ci-toolkit/README.md"
  }

  annotations = [
    "index,manifest:org.opencontainers.image.title=Kaniko CI Toolkit",
    "index,manifest:org.opencontainers.image.description=Kaniko-powered CI build image with essential container tools",
    "index,manifest:org.opencontainers.image.version=${TAG}",
    "index,manifest:org.opencontainers.image.source=https://github.com/pjaudiomv/kaniko-ci-toolkit",
  ]
}

target "toolkit" {
  inherits   = ["docker-metadata-action"]
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]

  cache-from = ["type=registry,ref=${GHCR_IMAGE}:buildcache"]
  cache-to   = ["type=registry,ref=${GHCR_IMAGE}:buildcache,mode=max"]
}
