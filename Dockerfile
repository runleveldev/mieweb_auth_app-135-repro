# =====================================================
# Setup a Node.js environment for building a Meteor app
# =====================================================
FROM debian:12 AS base
ENV NODE_VERSION=v20.18.0
ENV NODE_DIST=node-${NODE_VERSION}-linux-x64
ENV PATH="/opt/${NODE_DIST}/bin:${PATH}"

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl xz-utils ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://nodejs.org/dist/${NODE_VERSION}/${NODE_DIST}.tar.xz | tar -xJf - -C /opt

# Create a non-root user
RUN useradd -m -d /home/mieweb -s /usr/sbin/nologin mieweb

# ===========
# Build stage
# ===========
FROM base AS builder
WORKDIR /home/mieweb
ENV ANDROID_HOME="/home/mieweb/.android"
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
ENV PATH="/home/mieweb/.meteor:${PATH}"

# Install build dependencies
RUN apt-get update && \
    apt-get install -y git openjdk-17-jdk unzip gradle && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Drop privileges to the mieweb user
USER mieweb:mieweb

# Install Meteor
RUN curl https://install.meteor.com/ | /bin/sh

# Install Android SDK and other dependencies
RUN curl https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -o /tmp/commandlinetools.zip && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    unzip /tmp/commandlinetools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm /tmp/commandlinetools.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "build-tools;34.0.0" "platform-tools" "platforms;android-34"

# Clone the repo
ARG BRANCH
RUN git clone --depth 1 -b ${BRANCH} https://github.com/mieweb/mieweb_auth_app.git /home/mieweb/app
WORKDIR /home/mieweb/app

# Build the Meteor app
COPY google-services.json public/android/dev/google-services.json
COPY GoogleService-Info.plist public/ios/dev/GoogleService-Info.plist

# Install dependencies
RUN meteor npm install --omit=dev --no-audit --no-fund

# Build the Meteor app
ARG ROOT_URL
RUN meteor build \
      --architecture os.linux.x86_64 \
      --directory /home/mieweb/build \
      --server ${ROOT_URL} \
      --packageType=apk

# Sign the APK
RUN keytool -genkey -v \
        -keystore /home/mieweb/app.keystore \
        -alias mieweb \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass password \
        -keypass password \
        -dname "CN=Test,OU=Test,O=Test,L=Test,S=Test,C=Test" && \
    ${ANDROID_HOME}/build-tools/34.0.0/apksigner sign \
        --ks /home/mieweb/app.keystore \
        --ks-pass pass:password \
     --key-pass pass:password \
        --out /home/mieweb/build/android/app-release-signed.apk \
        /home/mieweb/build/android/app-release-unsigned.apk && \
    rm /home/mieweb/build/android/app-release-unsigned.apk

# =======================
# Make a production image
# =======================
FROM base
ENV NODE_ENV=production
ENV PORT=3000
USER mieweb:mieweb
COPY --from=builder /home/mieweb/build /opt/mieweb_auth_app
WORKDIR /opt/mieweb_auth_app/bundle
RUN cd /opt/mieweb_auth_app/bundle/programs/server && \
    npm install && \
    npm cache clean --force
EXPOSE 3000
ENTRYPOINT ["node", "main.js"]
