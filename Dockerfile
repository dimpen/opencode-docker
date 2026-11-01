FROM ubuntu:22.04

ARG OPENCODE_VERSION=latest

# set working directory
WORKDIR /workspace

# check architecture
RUN uname -m

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    sudo \
    zsh \
    passwd \
    util-linux \
    findutils

# install opencode globally
RUN version="$OPENCODE_VERSION"; \
    if [ "$version" = "latest" ]; then version=""; fi; \
    curl -fsSL https://opencode.ai/v2/install -o /tmp/install-opencode.sh \
    && SHELL=/bin/bash VERSION="$version" bash /tmp/install-opencode.sh --no-modify-path \
    && install -m 0755 /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && rm /tmp/install-opencode.sh \
    && installed_version="$(opencode --version)" \
    && installed_version="${installed_version##* }" \
    && installed_version="${installed_version#v}" \
    && if [ "$version" != "" ] && [ "$installed_version" != "$version" ]; then \
         echo "Expected $version, got $installed_version" >&2; \
         exit 1; \
       fi

# create a non-root opencode user with UID/GID 1000
RUN groupadd -g 1000 opencode && \
  useradd -m -u 1000 -g opencode -s /bin/bash opencode

RUN echo 'opencode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/opencode \
    && chmod 0440 /etc/sudoers.d/opencode \
    && visudo -cf /etc/sudoers.d/opencode

# create necessary directories and set permissions
RUN mkdir -p /home/opencode/.local/share/opencode/ && \
  mkdir -p /home/opencode/.local/state/opencode && \
  mkdir -p /home/opencode/.config/opencode/ && \
  mkdir -p /workspace && \
  chown -R opencode:opencode /home/opencode /workspace
  

# the entrypoint starts as root, remaps opencode to PUID/PGID and drops privileges
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]

# docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/pilinux/opencode:0.0.1 --output type=docker .
