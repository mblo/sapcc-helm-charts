VERSION=7.16.0

all: build push

build:
	docker build --network=host -t keppel.eu-de-1.cloud.sap/ccloud/auditbeat-oss:${VERSION} --build-arg IMAGE=docker.elastic.co/beats/auditbeat-oss:${VERSION} .

push:
	docker push keppel.eu-de-1.cloud.sap/ccloud/auditbeat-oss:${VERSION}
