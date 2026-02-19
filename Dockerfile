ARG BINARY_NAME

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
ARG BINARY_NAME
RUN cargo build --release --bin $BINARY_NAME

# Release Image
FROM gcr.io/distroless/cc:nonroot AS runtime-release
WORKDIR /app
ARG BINARY_NAME
COPY --from=builder /app/target/release/$BINARY_NAME /app
ENTRYPOINT ["/app/$BINARY_NAME"]

# Debug Image
FROM gcr.io/distroless/cc:debug-nonroot AS runtime-debug
WORKDIR /app
ARG BINARY_NAME
COPY --from=builder /app/target/release/$BINARY_NAME /app
ENV RUST_LOG=DEBUG
CMD ["/app/$BINARY_NAME"]