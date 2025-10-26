# Use Debian 12 (bookworm)
FROM debian:12

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Ensure i386 support and initial update
RUN dpkg --add-architecture i386 && \
    apt-get update

# Install prerequisites for adding the Wine repo and for the healthcheck
RUN apt-get install -y --no-install-recommends \
      wget \
      gnupg2 \
      software-properties-common \
      lsb-release \
      ca-certificates \
      tar \
      python3 \
      apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# Add WineHQ apt key and repository using the sequence you provided,
# then install winehq-stable (no strict pin to 9.0)
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key -O /tmp/winehq.key && \
    apt-key add /tmp/winehq.key && \
    rm /tmp/winehq.key && \
    apt-add-repository https://dl.winehq.org/wine-builds/debian/ && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for running the server
RUN useradd -m plutainer
USER plutainer
WORKDIR /home/plutainer/.plutainer

# Download and extract the updaters
RUN wget https://github.com/mxve/plutonium-updater.rs/releases/latest/download/plutonium-updater-x86_64-unknown-linux-gnu.tar.gz -O plutonium-updater.tar.gz && \
    tar -xzvf plutonium-updater.tar.gz && \
    rm plutonium-updater.tar.gz

RUN wget https://github.com/iw4x/launcher/releases/latest/download/iw4x-launcher-x86_64-unknown-linux-gnu.tar.gz -O iw4x-updater.tar.gz && \
    tar -xzvf iw4x-updater.tar.gz && \
    rm iw4x-updater.tar.gz && \
    chmod +x iw4x-launcher

# Copy all necessary scripts and the python module into the image
COPY --chown=plutainer:plutainer entrypoint.sh plutoentry.sh iw4xentry.sh healthcheck.sh pyquake3.py .
RUN chmod +x entrypoint.sh healthcheck.sh plutoentry.sh iw4xentry.sh

# Force termination on stop
STOPSIGNAL SIGKILL

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --start-period=1m --retries=3 \
  CMD ./healthcheck.sh

# Entrypoint
ENTRYPOINT ["./entrypoint.sh"]
