group "default" {
  targets = [
    "alpine",
    "debian"
  ]
}

variable "VERSION" {
  default = "2.32.2"
}

variable "COMMIT_SHA" {
  default = "unknown"
}

variable "IMAGE" {
  default = "scmmanager/scm-multiarch-test"
}

target "base" {
  context = "."
  args = {
    VERSION = VERSION
    COMMIT_SHA = COMMIT_SHA
  }
  labels = {
    "org.opencontainers.image.vendor" = "Cloudogu GmbH"
    "org.opencontainers.image.title" = "Official SCM-Manager image"
    "org.opencontainers.image.description" = "The easiest way to share and manage your Git, Mercurial and Subversion repositories"
    "org.opencontainers.image.url" = "https://scm-manager.org/"
    "org.opencontainers.image.source" = "https://github.com/scm-manager/docker"
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.version" = VERSION
    "org.opencontainers.image.revision" = COMMIT_SHA
  }
}

target "alpine" {
  inherits = ["base"]
  dockerfile = "Dockerfile.alpine"
  tags = [
    "${IMAGE}:${VERSION}",
    "${IMAGE}:${VERSION}-alpine"
  ]
  platforms = ["linux/amd64", "linux/arm64/v8"]
}

target "debian" {
  inherits = ["base"]
  dockerfile = "Dockerfile.debian"
  tags = [
    "${IMAGE}:${VERSION}-debian"
  ]
  platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7"]
}
