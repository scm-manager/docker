#
# MIT License
#
# Copyright (c) 2020-present Cloudogu GmbH and Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Create minimal java version
FROM eclipse-temurin:11.0.14_9-jdk-focal as jre-build

RUN jlink \
 --add-modules ALL-MODULE-PATH \
 --strip-debug \
 --no-man-pages \
 --no-header-files \
 --compress=2 \
 --output /javaruntime

# Download and verify scm-manager package
FROM debian:bullseye-20220125-slim as scm-downloader

ARG VERSION

# ensure version is set
RUN test -n "${VERSION}"

# install required tools
RUN set -x \
 && apt-get update \
 && apt-get install -y gpg curl gnupg2

# download
RUN GPG_KEY="https://packages.scm-manager.org/repository/keys/gpg/oss-cloudogu-com.pub" \
    ARCHIVE="https://packages.scm-manager.org/repository/releases/sonia/scm/packaging/unix/${VERSION}/unix-${VERSION}.tar.gz" \
    set -x \
 && curl --fail --silent --location --show-error --output "/tmp/gpg.key" "${GPG_KEY}" \
 && curl --fail --silent --location --show-error --output "/tmp/scm-server.tar.gz" "${ARCHIVE}" \
 && curl --fail --silent --location --show-error --output "/tmp/scm-server.tar.gz.asc" "${ARCHIVE}.asc" 

# verify
RUN gpg --no-tty --import /tmp/gpg.key \
 && gpg --no-tty --verify /tmp/scm-server.tar.gz.asc /tmp/scm-server.tar.gz

# extract
RUN tar xvfz /tmp/scm-server.tar.gz

# ---

# SCM-Manager runtime
FROM debian:bullseye-20220125-slim as runtime

ENV SCM_HOME /var/lib/scm
ENV CACHE_DIR /var/cache/scm/work
ENV JAVA_HOME /opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"

ARG COMMIT_SHA=unknown

COPY etc /etc
COPY opt /opt
COPY --from=jre-build /javaruntime "${JAVA_HOME}"
COPY --from=scm-downloader /scm-server/lib /opt/scm-server/lib
COPY --from=scm-downloader /scm-server/var /opt/scm-server/var

RUN set -x \
 && mkdir -p ${SCM_HOME} ${CACHE_DIR} \
 && chmod +x /opt/scm-server/bin/scm-server \
 && apt-get update \
 # libfreetype6 libfontconfig1 graphviz
 && apt-get install -y --no-install-recommends libfreetype6 libfontconfig1 graphviz mercurial bash ca-certificates \
 # use gid 0 for openshift compatibility
 && useradd -d "${SCM_HOME}" -u 1000 -g 0 -m -s /bin/bash scm \
 # set permissions to group 0 for openshift compatibility
 && chown 1000:0 ${SCM_HOME} ${CACHE_DIR} \
 && chmod -R g=u ${SCM_HOME} ${CACHE_DIR} \
 # cleanup apt cache
 && rm -rf /var/lib/apt/lists/*

# we us a high relative high start period,
# because the start time depends on the number of installed plugins
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/scm/api/v2 || exit 1

# set opencontainer labels
LABEL \
  org.opencontainers.image.vendor="Cloudogu GmbH" \
  org.opencontainers.image.title="Official SCM-Manager image" \
  org.opencontainers.image.description="The easiest way to share and manage your Git, Mercurial and Subversion repositories" \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.url="https://scm-manager.org/" \
  org.opencontainers.image.source="https://github.com/scm-manager/docker" \
  org.opencontainers.image.revision="${COMMIT_SHA}" \
  org.opencontainers.image.licenses="MIT"

ENTRYPOINT [ "/opt/scm-server/bin/scm-server" ]
