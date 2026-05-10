FROM rust:bookworm AS builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src
COPY data ./data

RUN cargo build --release

FROM debian:bookworm-slim AS runner

WORKDIR /app

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/wallpaper_backend /app/wallpaper_backend
COPY --from=builder /app/data ./data

ENV PORT=7860
EXPOSE 7860

CMD ["/app/wallpaper_backend"]