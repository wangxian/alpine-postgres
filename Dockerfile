FROM alpine:3.19
MAINTAINER WangXian <xian366@126.com>

WORKDIR /app
# VOLUME /app

ENV LANG C.UTF-8
ENV PGDATA /app/postgres

RUN apk update \
    && apk add su-exec tzdata postgresql14 \
    && apk add tzdata && cp /usr/share/zoneinfo/PRC /etc/localtime && echo "PRC" > /etc/timezone && apk del tzdata \
    && rm -f /var/cache/apk/*


COPY entrypoint.sh .

RUN chmod -R 755 entrypoint.sh && mkdir -p $PGDATA && chown postgres $PGDATA && mkdir -p /run/postgresql \
    && chown postgres:postgres /run/postgresql

ENTRYPOINT ["/app/entrypoint.sh"]

EXPOSE 5432

CMD ["postgres"]
