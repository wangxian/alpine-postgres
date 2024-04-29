# alpine-postgres
a docker image base on alpine with PostgreSQL

## build local image (docker)

```
docker build -t wangxian/alpine-postgres:latest .
```

## Usage (docker)

```
# only super user
docker run -it --name postgres -p 5432:5432 -v ~/appdata/postgres:/app/postgres -e POSTGRES_DATABASE=app -e POSTGRES_SUPER_PASSWORD=s6321..8 wangxian/alpine-postgres

# use normal user
docker run -it --name postgres -p 5432:5432 -v ~/appdata/postgres:/app/postgres -e POSTGRES_DATABASE=app -e POSTGRES_USER=app -e POSTGRES_PASSWORD=app123..8 -e POSTGRES_SUPER_PASSWORD=s6321..8 wangxian/alpine-postgres
```


It will:
- set password for 'postgres'
- create a new db if set POSTGRES_DATABASE
- create an user and set his password
