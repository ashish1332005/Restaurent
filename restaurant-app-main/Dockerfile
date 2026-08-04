# Stage 1: Build the Flutter web app
FROM ubuntu:20.04 AS build-env

# Setup timezone and install dependencies
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter channel stable && flutter upgrade

WORKDIR /app
COPY . .

# Build Web App
RUN flutter pub get
RUN flutter build web

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
