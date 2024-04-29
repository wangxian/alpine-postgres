#!/bin/sh
chown -R postgres "$PGDATA"

if [ -z "$(ls -A "$PGDATA")" ]; then
    su-exec postgres initdb
    sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf

    : ${POSTGRES_USER:="postgres"}

    # 如果环境变量 POSTGRES_DATABASE 没有被设置（即没有值），则将其设置为 POSTGRES_USER 的值。
    # 如果 POSTGRES_USER 也没有被设置，那么 POSTGRES_DATABASE 将被设置为空字符串。
    : ${POSTGRES_DATABASE:=$POSTGRES_USER}

    authMethod=md5
    
    if [ "$POSTGRES_PASSWORD" ]; then
      pass=$POSTGRES_PASSWORD
    fi
    echo

    # default super passwrod
    if [ "$POSTGRES_SUPER_PASSWORD" = "" ]; then
      POSTGRES_SUPER_PASSWORD=s6321..8
      echo "...................... [i] default POSTGRES_SUPER_PASSWORD Password: $POSTGRES_SUPER_PASSWORD"
    fi
    echo

    # normal database
    if [ "$POSTGRES_DATABASE" != 'postgres' ]; then
      createSql="CREATE DATABASE $POSTGRES_DATABASE;"
      echo $createSql | su-exec postgres postgres --single -jE
      echo
    fi

    # normal user
    if [ "$POSTGRES_USER" != 'postgres' ]; then
      userSql="CREATE USER $POSTGRES_USER WITH PASSWORD '$pass';"
      echo $userSql | su-exec postgres postgres --single -jE
      echo

      if [ "$POSTGRES_DATABASE" != 'postgres' ]; then
        createSql="GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DATABASE TO $POSTGRES_USER;"
        echo $createSql | su-exec postgres postgres --single -jE
        echo
      fi
    fi

    # super user pwd
    userSql="ALTER USER postgres WITH SUPERUSER PASSWORD '$POSTGRES_SUPER_PASSWORD';"
    echo $userSql | su-exec postgres postgres --single -jE
    echo

    su-exec postgres pg_ctl -D "$PGDATA" \
        -o "-c listen_addresses=''" \
        -w start

    # echo
    # for f in /docker-entrypoint-initdb.d/*; do
    #     case "$f" in
    #         *.sh)  echo "$0: running $f"; . "$f" ;;
    #         *.sql) echo "$0: running $f"; psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DATABASE" < "$f" && echo ;;
    #         *)     echo "$0: ignoring $f" ;;
    #     esac
    #     echo
    # done

    su-exec postgres pg_ctl -D "$PGDATA" -m fast -w stop

    { echo; echo "host all all 0.0.0.0/0 $authMethod"; } >> "$PGDATA"/pg_hba.conf
fi

exec su-exec postgres "$@"
