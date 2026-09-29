FROM buildpack-deps:bookworm-curl
WORKDIR /tmp

# recisdbのインストール
RUN wget --no-verbose https://github.com/kazuki0824/recisdb-rs/releases/download/1.3.0/recisdb_1.3.0-1_amd64.deb -O recisdb.deb \
    && apt-get update && apt-get install -y /tmp/recisdb.deb \
    && rm recisdb.deb \
# isdb-scannerのインストール
    && wget --no-verbose https://github.com/tsukumijima/ISDBScanner/releases/download/v1.3.3/isdb-scanner -O /usr/local/bin/isdb-scanner \
    && chmod +x /usr/local/bin/isdb-scanner

# entrypoint.shをコンテナ内にコピー
COPY --chmod=755 ./entrypoint.sh /usr/local/bin/entrypoint.sh

CMD [ "/usr/local/bin/entrypoint.sh" ]