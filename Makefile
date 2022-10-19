version=0.1.0
registry=eigr
proxy-image=${registry}/spawn-proxy:${version}
operator-image=${registry}/spawn-operator:${version}
activator-grpc-image=${registry}/spawn-activator-grpc:${version}
activator-http-image=${registry}/spawn-activator-http:${version}
activator-kafka-image=${registry}/spawn-activator-kafka:${version}
activator-pubsub-image=${registry}/spawn-activator-pubsub:${version}
activator-rabbitmq-image=${registry}/spawn-activator-rabbitmq:${version}
activator-sqs-image=${registry}/spawn-activator-sqs:${version}
spawn-sdk-example-image=${registry}/spawn-sdk-example:${version}

ifeq "$(PROXY_DATABASE_TYPE)" ""
    database:=mysql
else
    database:=$(PROXY_DATABASE_TYPE)
endif

.PHONY: all

all: build test build-all-images

clean:
	mix deps.clean --all

clean-all:
	mix deps.clean --all && kind delete cluster --name default

build:
	mix deps.get && mix compile

build-proxy-image:
	docker build -f Dockerfile-proxy -t ${proxy-image} .

build-operator-image:
	docker build -f Dockerfile-operator -t ${operator-image} .

build-elixir-sdk-image:
	docker build -f Dockerfile-elixir-example -t ${spawn-sdk-example-image} .

build-all-images:
	docker build -f Dockerfile-proxy -t ${proxy-image} .
	docker build -f Dockerfile-operator -t ${operator-image} .
	docker build -f Dockerfile-activator-grpc -t ${activator-grpc-image} .
	docker build -f Dockerfile-activator-http -t ${activator-http-image} .
	docker build -f Dockerfile-activator-kafka -t ${activator-kafka-image} .
	docker build -f Dockerfile-activator-pubsub -t ${activator-pubsub-image} .
	docker build -f Dockerfile-activator-rabbitmq -t ${activator-rabbitmq-image} .
	docker build -f Dockerfile-activator-sqs -t ${activator-sqs-image} .
	docker build -f Dockerfile-elixir-example -t ${spawn-sdk-example-image} .

test:
	MIX_ENV=test mix deps.get
	MIX_ENV=test PROXY_DATABASE_TYPE=mysql PROXY_CLUSTER_STRATEGY=epmd PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

push-all-images:
	docker push ${proxy-image}
	docker push ${operator-image}
	docker push ${activator-grpc-image}
	docker push ${activator-http-image}
	docker push ${activator-kafka-image}
	docker push ${activator-pubsub-image}
	docker push ${activator-rabbitmq-image}
	docker push ${activator-sqs-image}
	docker push ${spawn-sdk-example-image}

create-minikube-cluster:
	minikube start

create-kind-cluster:
	kind create cluster -v 1 --name default --config kind-cluster-config.yaml
	kubectl cluster-info --context kind-default

delete-kind-cluster:
	kind delete cluster --name default

load-kind-images:
	kind load docker-image ${operator-image} --name default
	kind load docker-image ${proxy-image} --name default
	kind load docker-image ${activator-grpc-image} --name default
	kind load docker-image ${activator-http-image} --name default
	kind load docker-image ${activator-kafka-image} --name default
	kind load docker-image ${activator-pubsub-image} --name default
	kind load docker-image ${activator-rabbitmq-image} --name default
	kind load docker-image ${activator-sqs-image} --name default

create-k8s-namespace:
	kubectl create ns eigr-functions

generate-k8s-manifests:
	cd spawn_operator/operator && MIX_ENV=dev mix bonny.gen.manifest --image ${operator-image} --namespace eigr-functions

apply-k8s-manifests:
	kubectl -n eigr-functions apply -f spawn_operator/operator/manifest.yaml

run-proxy-local:
	cd spawn_proxy/proxy && PROXY_DATABASE_TYPE=$(database) SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix

run-sdk-local:
	cd spawn_sdk/spawn_sdk_example && PROXY_CLUSTER_STRATEGY=epmd PROXY_DATABASE_TYPE=$(database) SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_actors_node@127.0.0.1 -S mix

run-sdk-local2:
	cd spawn_sdk/spawn_sdk_example && PROXY_CLUSTER_STRATEGY=epmd PROXY_DATABASE_TYPE=$(database) SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_actors_node1@127.0.0.1 -S mix

run-operator-local:
	cd spawn_operator/operator && MIX_ENV=dev iex --name operator@127.0.0.1 -S mix
	
run-proxy-image:
	docker run --rm --name=spawn-proxy -e PROXY_DATABASE_TYPE=mysql -e SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= --net=host ${proxy-image}

run-operator-image:
	docker run --rm --name=spawn-operator --net=host ${operator-image}