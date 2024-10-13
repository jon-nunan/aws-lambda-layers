# syntax = docker/dockerfile:1.4

# Declare build arguments
ARG CPU_PREFIX
ARG PHP_VERSION

# Base image with your existing PHP setup
FROM jon-nunan/${CPU_PREFIX}php-${PHP_VERSION}-fpm as base

# Build stage for PHP extensions
FROM base as build_extensions

# Install tools and required libraries for building extensions
RUN dnf install -y gcc make autoconf brotli libpng libwebp

# Install PEAR and PECL
RUN dnf install -y php-pear php-devel

# Install and configure Xdebug
RUN pecl install xdebug \
    && cp $(php -r "echo ini_get('extension_dir');")/xdebug.so /opt/bref/extensions

# Install Blackfire
ARG BLACKFIRE_VERSION=1.87.2
RUN if [ "$PHP_VERSION" != "83" ]; then \
      curl -A "Docker" -o /opt/bref/extensions/blackfire.so -L -s "https://packages.blackfire.io/binaries/blackfire-php/$BLACKFIRE_VERSION/blackfire-php-linux_amd64-php-"$PHP_VERSION".so"; \
    fi

# Final stage
FROM base

# Ensure necessary libraries are available
RUN dnf install -y brotli libpng libwebp \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Copy extensions from build stage
COPY --from=build_extensions /opt /opt

# Copy entrypoint script and make it executable
COPY bref-entrypoint.sh /
RUN chmod +x /bref-entrypoint.sh

# Install Node.js to run the JS app below
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash - \
    && dnf install -y nodejs

# Copy the bref local API Gateway app
COPY --from=bref/local-api-gateway /app /local-api-gateway

# Expose port 8000 for the local API Gateway
EXPOSE 8000

# Add `php/conf.dev.d` to the PHP configuration path
ENV PHP_INI_SCAN_DIR="/opt/bref/etc/php/conf.d:/var/task/php/conf.d:/var/task/php/conf.dev.d"

# Ensure library paths are updated
ENV LD_LIBRARY_PATH="/usr/lib64:$LD_LIBRARY_PATH"

# Set the custom entrypoint script
ENTRYPOINT [ "/bref-entrypoint.sh" ]