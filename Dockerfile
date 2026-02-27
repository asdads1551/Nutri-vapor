# Build stage
FROM swift:6.0-noble AS build

WORKDIR /app

# Copy package manifests first for better layer caching
COPY Package.swift Package.resolved* ./
RUN swift package resolve

# Copy source and build
COPY . .
RUN swift build -c release --static-swift-stdlib

# Run stage — slim image
FROM ubuntu:noble

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built binary
COPY --from=build /app/.build/release/App .

# Create non-root user
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor
USER vapor

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["./App", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
