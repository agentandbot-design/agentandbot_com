FROM elixir:1.15 AS build

RUN apt-get update -y && apt-get install -y build-essential git npm curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV MIX_ENV=prod
ENV DATABASE_URL=postgresql://p:pass@h:5432/db

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config/
RUN mix deps.get --only prod && mix deps.compile

COPY assets assets/
COPY priv priv/
RUN mix assets.setup && mix assets.build

COPY lib lib/
COPY rel rel/
RUN mix compile

RUN mix phx.digest
RUN mix release

FROM debian:bookworm-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/_build/prod/rel/governance_core ./
RUN chmod +x bin/server bin/governance_core

ENV HOME=/app
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV ELIXIR_ERL_OPTIONS="+fnu"
ENV PORT=4000
ENV PHX_SERVER=true
ENV PHX_HOST=agentandbot.com
ENV SECRET_KEY_BASE=change-me-in-production-32-char-minimum-length
ENV DATABASE_URL=ecto://postgres:postgres@localhost:5432/governance_core_prod

EXPOSE 4000

CMD ["bin/server"]
