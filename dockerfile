ARG PYTHON_VERSION="3.12.5"

# Use uv's official Docker image for the build stage
FROM ghcr.io/astral-sh/uv:python${PYTHON_VERSION%.*}-bookworm-slim AS build

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=python${PYTHON_VERSION%.*} \
    DEBIAN_FRONTEND=noninteractive \
    SUPPRESS_WARNINGS=true

# Install dependencies and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    g++ \
    default-jdk \
    pypy3 \
    wget \
    bzip2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/include/x86_64-linux-gnu/c++/12/bits

# Set working directory
WORKDIR /app

# Copy application code
COPY . /app

# Create a virtual environment and sync dependencies using uv with cache
RUN --mount=type=cache,target=/root/.cache \
    uv venv /app/.venv && \
    set -ex && \
    cd /app && \
    uv sync --frozen --no-install-project

# Start the final stage using Python slim image
FROM python:${PYTHON_VERSION}-slim-bookworm

ENV PATH=/app/.venv/bin:$PATH

# Set working directory and copy files from the build stage
WORKDIR /app
COPY --from=build /app /app

# Expose the application port
EXPOSE 8080

# Set the command to run the application
CMD ["/app/.venv/bin/python", "main.py"]
