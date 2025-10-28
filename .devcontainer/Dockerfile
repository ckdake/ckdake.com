# Use Ruby 3.4 base image (bullseye for ARM64/Apple Silicon compatibility)
FROM mcr.microsoft.com/devcontainers/ruby:1-3.4-bullseye

# Create rbenv symlink so system Ruby 3.4.4 is recognized by rbenv
RUN su vscode -c "mkdir -p ~/.rbenv/versions && ln -s /usr/local ~/.rbenv/versions/3.4.4"

# Install bundler 2.7.2
RUN su vscode -c "gem update --system && gem install bundler:2.7.2"

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment this line to install additional gems.
# RUN gem install <your-gem-names-here>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1