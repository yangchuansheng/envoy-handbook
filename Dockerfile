FROM klakegg/hugo:0.99.1 AS builder

WORKDIR /app

ADD ../ /app/hugo

RUN git clone https://github.com/yangchuansheng/envoy-handbook /app/envoy-handbook; \
    cd /app/envoy-handbook; \
    hugo

RUN cd /app/hugo; \
    hugo
    
FROM fholzer/nginx-brotli:latest

COPY --from=builder /app/hugo/public /usr/share/nginx/html
COPY --from=builder /app/envoy-handbook/public /usr/share/nginx/html/envoy-handbook
