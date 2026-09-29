FROM buildpack-deps:bookworm-curl
WORKDIR /tmp

# recisdbのインストール
RUN wget --no-verbose https://github.com/kazuki0824/recisdb-rs/releases/download/1.2.4/recisdb_1.2.4-1_amd64.deb -O recisdb.deb
RUN apt-get install -y \
        recisdb.deb
RUN rm recisdb.deb
# isdb-scannerのインストール
RUN wget --no-verbose https://github.com/tsukumijima/ISDBScanner/releases/download/v1.3.3/isdb-scanner -O /usr/local/bin/isdb-scanner
RUN chmod +x /usr/local/bin/isdb-scanner

# entrypoint.shをコンテナ内にコピー
COPY --chmod=755 ./entrypoint.sh /usr/local/bin/entrypoint.sh

CMD [ "/usr/local/bin/entrypoint.sh" ]
