ARG NGINX_VERSION=1.21.4

FROM nginx:$NGINX_VERSION-alpine

RUN apk --update --no-cache add \
        gcc \
        make \
        libc-dev \
        g++ \
        openssl-dev \
        linux-headers \
        pcre-dev \
        zlib-dev \
        libtool \
        automake \
        autoconf \
        libmaxminddb-dev \
        git

RUN cd /opt \
    && git clone --depth 1 --single-branch https://github.com/leev/ngx_http_geoip2_module.git \
    && wget -O - http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar zxfv - \
    && mv /opt/nginx-$NGINX_VERSION /opt/nginx \
    && cd /opt/nginx \
    && ./configure --with-compat --add-dynamic-module=/opt/ngx_http_geoip2_module \
    && make modules

FROM nginx:$NGINX_VERSION-alpine

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/resolvers.conf /etc/nginx/conf.d/resolvers.conf
COPY ./nginx/ip_ranges.conf /etc/nginx/conf.d/ip_ranges.conf

RUN mkdir -p /tmp/nginx
RUN mkdir -p /var/lib/nginx/cache
RUN mkdir -p /data/logs
RUN mkdir -p /data/custom
RUN mkdir -p /data/proxy_host
RUN mkdir -p /data/dead_host
RUN mkdir -p /data/default_host
RUN mkdir -p /data/temp
RUN mkdir -p /data/redirection_host
RUN touch /data/logs/access.log
RUN touch /data/logs/error.log

COPY --from=0 /opt/nginx/objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules

RUN apk --update --no-cache add libmaxminddb \
    && chmod -R 644 /usr/lib/nginx/modules/ngx_http_geoip2_module.so \