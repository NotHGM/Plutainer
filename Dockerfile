# Use Debian 12 (bookworm)
FROM debian:12

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Add i386 architecture and update package lists
RUN dpkg --add-architecture i386 && \
    apt-get update

# Install basic dependencies required to set up the WineHQ repository and for the healthcheck
RUN apt-get install -y --no-install-recommends \
    wget \
    gpg \
    ca-certificates \
    tar \
    python3 \
    apt-transport-https \
    gnupg && \
    rm -rf /var/lib/apt/lists/*

# Add WineHQ repository key
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key

# Add WineHQ repository for Debian 12 (bookworm)
RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources

# Update package lists, install Wine pinned to 9.0 and fail the build if wine-9.0 is not available.
# We also hold the package to avoid upgrades inside the image later.
RUN apt-get update && \
    apt-get install -y --install-recommends winehq-stable=9.0* || (echo "wine-9.0 is not available from configured repos; aborting build" >&2; exit 1) && \
    apt-mark hold winehq-stable && \
    # Verify installed version is exactly wine-9.0 (fail if not)
    (wine --version | grep -q '^wine-9\.0' || (echo "installed wine is not 9.0; aborting" >&2; exit 1)) && \
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
