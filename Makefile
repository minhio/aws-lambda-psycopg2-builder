.DEFAULT_GOAL := .aws-sam

.PHONY: clean

.aws-sam: psycopg2-layer
	sam build

psycopg2-layer: psycopg2-layer/python psycopg2-layer/lib

psycopg2-layer/python: build
	mkdir -p psycopg2-layer/python
	cp -r build/psycopg2/* psycopg2-layer/python

psycopg2-layer/lib: build
	mkdir -p psycopg2-layer/lib
	cp -r build/pgsql/lib/libpq.* psycopg2-layer/lib

build:
	mkdir -p build
	docker build -t localhost/build-psycopg2 -f Dockerfile .
	-docker container rm -f build-psycopg2
	docker container create --name build-psycopg2 localhost/build-psycopg2 /bin/sh -c "true"
	docker cp build-psycopg2:/var/output/. build
	docker container rm build-psycopg2

clean:
	rm -rf .aws-sam psycopg2-layer/lib psycopg2-layer/python build