
RUN if [ $(uname -p) = "x86_64" ]; then \
      export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
      apt-get -q update && \
      apt-get -q install -y \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4 \
    libedit2 \
    libgcc-9-dev \
    libpython2.7 \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2 \
    libz3-dev \
    pkg-config \
    tzdata \
    zlib1g-dev \
    && rm -r /var/lib/apt/lists/*; apt clean; \
  fi

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little

# pub   4096R/ED3D1561 2019-03-22 [expires: 2021-03-21]
#       Key fingerprint = A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561
# uid                  Swift 5.x Release Signing Key <swift-infrastructure@swift.org
ARG SWIFT_SIGNING_KEY=A62AE125BBBFBB96A6E042EC925CC1CCED3D1561
ARG SWIFT_PLATFORM=ubuntu20.04
ARG SWIFT_BRANCH=swift-5.4.1-release
ARG SWIFT_VERSION=swift-5.4.1-RELEASE
ARG SWIFT_WEBROOT=https://swift.org/builds/

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY \
    SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION \
    SWIFT_WEBROOT=$SWIFT_WEBROOT

RUN if [ $(uname -p) = "x86_64" ]; then \
    set -e; \
    SWIFT_WEBDIR="$SWIFT_WEBROOT/$SWIFT_BRANCH/$(echo $SWIFT_PLATFORM | tr -d .)/" \
    && SWIFT_BIN_URL="$SWIFT_WEBDIR/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz" \
    && SWIFT_SIG_URL="$SWIFT_BIN_URL.sig" \
    # - Grab curl here so we cache better up above
    # - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
    && export GNUPGHOME="$(mktemp -d)" \
    && curl -fsSL "$SWIFT_BIN_URL" -o swift.tar.gz "$SWIFT_SIG_URL" -o swift.tar.gz.sig \
    && curl -f https://swift.org/keys/all-keys.asc | gpg --import - \
    && gpg --batch --verify swift.tar.gz.sig swift.tar.gz \
    # - Unpack the toolchain, set libs permissions, and clean up.
    && tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && chmod -R o+r /usr/lib/swift \
    && rm -rf "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz \
    && swift --version; \
    fi

