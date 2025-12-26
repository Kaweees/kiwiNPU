# Like GNU `make`, but `just` rustier.
# https://just.systems/
# run `just` from this directory to see available commands

alias i := install
alias c := clean

# Default command when 'just' is run without arguments
default:
  @just --list -u

TARGET := "asic"
CONTAINER := "hpretl/iic-osic-tools"

# Install the virtual environment and pre-commit hooks
install:
  @echo "Installing..."
  @docker pull {{CONTAINER}}
  @docker build . -t {{TARGET}} --build-arg BASE_IMAGE={{CONTAINER}}
  @xhost local:root
  @docker run -it --rm \
    -v $(pwd):/home/$(whoami)/workspace:rw \
    -v ~/.ssh:/home/$(whoami)/.ssh \
    -v ~/.gitconfig:/home/$(whoami)/.gitconfig \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /mnt/wslg:/mnt/wslg \
    -e DISPLAY \
    -e "TERM=$TERM" \
    --hostname $(whoami) \
    --net=host \
    {{TARGET}} -s bash -c "cd /home/$(whoami)/workspace && bash"

# Remove build artifacts and non-essential files
clean:
  @echo "Cleaning..."
  @docker rm -f {{TARGET}} 2>/dev/null || true
