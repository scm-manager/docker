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

target "alpine" {
  dockerfile = "Dockerfile.alpine"
  context = "."
  args = {
    VERSION = VERSION
    COMMIT_SHA = COMMIT_SHA
  }
  tags = [
    "${IMAGE}:${VERSION}",
    "${IMAGE}:${VERSION}-alpine"
  ]
  platforms = ["linux/amd64", "linux/arm64/v8"]
}

target "debian" {
  dockerfile = "Dockerfile.debian"
  context = "."
  args = {
    VERSION = VERSION,
    COMMIT_SHA = COMMIT_SHA
  }
  tags = [
    "${IMAGE}-debian:${VERSION}-debian"
  ]
  platforms = ["linux/amd64", "linux/arm64/v8", "linux/arm/v7"]
}
