# [Choice] Ruby version (use -bullseye variants on local arm64/Apple Silicon): 3.4, 3.3, 3.2, 3.1, 3.0, 2.7
ARG VARIANT=3.4-bullseye
FROM mcr.microsoft.com/devcontainers/ruby:1-${VARIANT}

# [Choice] Node.js version: none, lts/*, 20, 18
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends gnupg2 \
    && sudo apt-get clean -y && sudo rm -rf /var/lib/apt/lists/*

RUN gem update --system && gem install bundler:2.7.2