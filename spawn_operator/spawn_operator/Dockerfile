#########################
###### Build Image ######
#########################

FROM elixir:1.14 as builder

ENV MIX_ENV=prod \
  MIX_HOME=/opt/mix \
  HEX_HOME=/opt/hex

RUN mix local.hex --force && \
  mix local.rebar --force

WORKDIR /app

COPY mix.exs ./
COPY config config

RUN mix deps.get --only-prod && mix deps.compile

COPY priv priv
COPY lib lib

RUN mix release

#########################
##### Release Image #####
#########################

FROM erlang:25.1-alpine

# elixir expects utf8.
ENV LANG=C.UTF-8

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/spawn_operator ./
RUN chown -R nobody: /app

ENTRYPOINT ["/app/bin/spawn_operator"]
CMD ["start"]
