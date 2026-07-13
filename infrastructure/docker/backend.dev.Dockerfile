# syntax=docker/dockerfile:1
# Development image for the Rails API and Sidekiq worker.
# Includes the development/test gem groups and build toolchain.
# Build context is the repository root.
ARG RUBY_VERSION=3.3.11
FROM ruby:${RUBY_VERSION}-slim

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    LANG=C.UTF-8 \
    TZ=UTC

WORKDIR /rails

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -y \
        build-essential git libpq-dev libvips pkg-config postgresql-client curl \
    && rm -rf /var/lib/apt/lists/*

# Install gems first so this layer is cached unless the Gemfile changes.
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install

# Application code. In development this is shadowed by a bind mount; it is copied
# so the image can also run standalone (e.g. in CI or one-off tasks).
COPY backend/ ./

EXPOSE 3000
CMD ["bash", "-lc", "bundle exec rails db:prepare && bundle exec rails server -b 0.0.0.0 -p 3000"]
