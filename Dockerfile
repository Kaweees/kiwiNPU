FROM hpretl/iic-osic-tools

# Install zsh
USER root

# Install necessary packages
RUN apt-get update && apt-get install -y \
  zsh \
  curl \
  stow \
  fzf \
  tree \
  make \
  just \
  python3 \
  python3-pip \
  libpython3-dev \
  iverilog \
  verilator \
  && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /root/workspace

COPY . .

# Create & sync venv into .venv
RUN uv sync --frozen || uv sync
