FROM hpretl/iic-osic-tools

# Install zsh
USER root

# Install necessary packages
RUN apt-get update && apt-get install -y \
  zsh \
  stow \
  fzf \
  tree \
  && rm -rf /var/lib/apt/lists/*
