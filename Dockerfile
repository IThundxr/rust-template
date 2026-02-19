# Pull cargo chef
FROM lukemathwalker/cargo-chef:latest-rust-latest AS chef
WORKDIR /app

# Planner Stage
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# Build stage
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release --bin rust-template

# Release Image
FROM gcr.io/distroless/cc:nonroot AS runtime-release
WORKDIR /app
COPY --from=builder /app/target/release/rust-template /app
ENTRYPOINT ["/app/rust-template"]

# Debug Image
FROM gcr.io/distroless/cc:debug-nonroot AS runtime-debug
WORKDIR /app
COPY --from=builder /app/target/release/rust-template /app
ENV RUST_LOG=DEBUG
CMD ["/app/rust-template"]