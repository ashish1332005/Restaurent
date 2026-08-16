FROM ubuntu:22.04 AS build-env
ARG FLUTTER_VERSION=3.44.1
ARG API_BASE_URL
ARG GOOGLE_CLIENT_ID=
ARG GOOGLE_SERVER_CLIENT_ID=
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils zip libglu1-mesa && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN test -n "${API_BASE_URL}" && flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL} --dart-define=GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID} --dart-define=GOOGLE_SERVER_CLIENT_ID=${GOOGLE_SERVER_CLIENT_ID}
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -qO- http://127.0.0.1/health > /dev/null || exit 1
CMD ["nginx", "-g", "daemon off;"]
