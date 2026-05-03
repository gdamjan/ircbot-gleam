ARG GLEAM_VER=v1.16.0-erlang-alpine
ARG ERLANG_VER=28-alpine

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VER} AS gleam
FROM erlang:${ERLANG_VER} AS builder
ARG GLEAM_VER

COPY --from=gleam /bin/gleam /bin/gleam

WORKDIR /src

# Do dependencies first
RUN --mount=type=cache,target=/root/.cache/gleam \
    --mount=type=bind,source=manifest.toml,target=manifest.toml \
    --mount=type=bind,source=gleam.toml,target=gleam.toml \
    gleam deps download

# Build the project
COPY . ./
RUN gleam export erlang-shipment

# Runtime image
FROM erlang:${ERLANG_VER}

COPY --from=builder /src/build/erlang-shipment /app
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
