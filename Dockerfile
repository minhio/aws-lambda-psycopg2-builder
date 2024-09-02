# this Dockerfile build psycopg2 and postgres binaries for use in AWS Lambda
# the output is stored in /var/output/

ARG PYTHON_VER=3.12

FROM public.ecr.aws/lambda/python:${PYTHON_VER}

ARG PYTHON_VER
ARG POSTGRES_VER=16.4
ARG PSYCOPG_VER=2.9.9

RUN dnf update -y \
    && dnf upgrade -y \
    && dnf install -y \
        tar \
        gcc \
        openssl-devel \
        python3-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# setuptools isn't installed by default in the 3.12 image for some reason ¯\_(ツ)_/¯
# https://github.com/aws/aws-sam-cli/issues/7176
RUN pip install --upgrade pip \
    && pip install setuptools

# download postgres
WORKDIR /tmp
ADD https://ftp.postgresql.org/pub/source/v${POSTGRES_VER}/postgresql-${POSTGRES_VER}.tar.gz postgresql-${POSTGRES_VER}.tar.gz
RUN tar -zxf postgresql-${POSTGRES_VER}.tar.gz

# build postgres
WORKDIR /tmp/postgresql-${POSTGRES_VER}
RUN ./configure --without-readline --without-icu --without-zlib --with-ssl=openssl \
    && make -C src/bin install \
    && make -C src/include install \
    && make -C src/interfaces install

# copy postgres libs to output dir
RUN mkdir -p /var/output/pgsql/lib \
    && cp -r /usr/local/pgsql/lib/libpq.* /var/output/pgsql/lib

# setting PATH and LD_LIBRARY_PATH so psycopg2 can find the postgres binaries
ENV PATH="/usr/local/pgsql/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/pgsql/lib:${LD_LIBRARY_PATH}"

# build/install psycopg2 into output dir
RUN mkdir -p /var/output/psycopg2 \
    && pip install --no-compile psycopg2==${PSYCOPG_VER} -t /var/output/psycopg2

WORKDIR /var/output

ENTRYPOINT [""]