#!/bin/sh
chown -R postgres "$PGDATA"

# 检查第一个参数是否不是 "postgres" 且 $PGDATA 目录为空或不存在
if [ "$1" == "postgres" ] && [ -z "$(ls -A "$PGDATA")" ]; then
    su-exec postgres initdb
    sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf

    : ${POSTGRES_USER:="postgres"}

    # 如果环境变量 POSTGRES_DATABASE 没有被设置（即没有值），则将其设置为 POSTGRES_USER 的值。
    # 如果 POSTGRES_USER 也没有被设置，那么 POSTGRES_DATABASE 将被设置为空字符串。
    : ${POSTGRES_DATABASE:=$POSTGRES_USER}

    : ${POSTGRES_PASSWORD:=""}

    # default auth method
    authMethod='md5'

    # default super passwrod
    if [ "$POSTGRES_SUPER_PASSWORD" = "" ]; then
      POSTGRES_SUPER_PASSWORD=s6321..8
      echo "...................... [i] set default POSTGRES_SUPER_PASSWORD: '$POSTGRES_SUPER_PASSWORD'"
    fi
    echo
    
    # concat and new user
    userSql=""

    # normal user
    if [ "$POSTGRES_USER" != 'postgres' ]; then
      userSql="CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';"
      # echo $userSql | su-exec postgres postgres --single -jE
      echo "...................... [i] PostgreSQL create user '$POSTGRES_USER' with password '$POSTGRES_PASSWORD' !!!"
      echo
    fi

    # normal database
    if [ "$POSTGRES_DATABASE" != 'postgres' ]; then
      userSql=" $userSql \\nCREATE DATABASE $POSTGRES_DATABASE;"
      echo "...................... [i] PostgreSQL create database '$POSTGRES_DATABASE'"
      echo

      if [ "$POSTGRES_USER" != 'postgres' ]; then
        userSql=" $userSql \\nGRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DATABASE TO $POSTGRES_USER;"
        echo "...................... [i] PostgreSQL grant all privileges ON DATABASE '$POSTGRES_DATABASE' to '$POSTGRES_USER'"
        echo
      fi
    fi
    

    # super user pwd
    echo "ALTER USER postgres WITH SUPERUSER PASSWORD '$POSTGRES_SUPER_PASSWORD';" | su-exec postgres postgres --single -jE
    echo "...................... [i] PostgreSQL set SUPERUSER 'postgres' password '$POSTGRES_SUPER_PASSWORD' !!!"
    echo 
    echo

    # start postgres
    su-exec postgres pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start

    # create new user
    if [ "$userSql" != 'postgres' ]; then
      echo "----------"
      echo -e $userSql
      echo "----------"
      
      echo -e $userSql | su-exec postgres psql -v ON_ERROR_STOP=1 --username postgres
    fi

    # init db and import sql
    echo
    for f in /docker-entrypoint-initdb.d/*; do
        case "$f" in
            *.sh)  echo "$0: running $f"; . "$f" ;;
            *.sql) echo "$0: running $f"; psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DATABASE" < "$f" && echo ;;
            *)     echo "$0: ignoring $f" ;;
        esac
        echo
    done

    su-exec postgres pg_ctl -D "$PGDATA" -m fast -w stop

    { echo; echo "host all all 0.0.0.0/0 $authMethod"; } >> "$PGDATA"/pg_hba.conf
fi

exec su-exec postgres "$@"
