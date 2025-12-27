# Like GNU `make`, but `just` rustier.
# https://just.systems/
# run `just` from this directory to see available commands

alias i := install
alias u := update
alias p := pre_commit
alias t := test
alias f := format
alias c := clean

TARGET := "asic"
CONTAINER := "hpretl/iic-osic-tools"

# Default command when 'just' is run without arguments
default:
  @just --list -u

update:
  @echo "Updating..."
  @uv sync --upgrade
  @uv run pre-commit autoupdate

# Run pre-commit
pre_commit:
  @echo "Running pre-commit..."
  @uv run pre-commit run -a

# Test the project
test sim="verilator":
  @echo "Testing..."
  @SIM={{sim}} uv run python -m pytest

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

# Format the project
format:
  @echo "Formatting..."

# Remove build artifacts and non-essential files
clean:
  @echo "Cleaning..."
  @docker rm -f {{TARGET}} 2>/dev/null || true
  @find . -type d -name "__pycache__" -exec rm -rf {} +
  @find . -type d -name ".pytest_cache" -exec rm -rf {} +
  @find . -type d -name ".venv" -exec rm -rf {} +
  @find . -type d -name "obj_dir*" -exec rm -rf {} +
  @find . -type d -name "sim_build" -exec rm -rf {} +
  @find . -type f -iname "*.vcd" -exec rm -rf {} +
  @find . -type f -iname "*.log" -exec rm -rf {} +
  @find . -type f -iname "a.out" -exec rm -rf {} +
