version=1.3.0
registry=eigr

CLUSTER_NAME=spawn-k8s
K3D_KUBECONFIG_PATH?=./integration.yaml

proxy-initializer=${registry}/spawn-initializer:${version}
proxy-image=${registry}/spawn-proxy:${version}
operator-image=${registry}/spawn-operator:${version}
activator-api-image=${registry}/spawn-activator-grpc:${version}
activator-kafka-image=${registry}/spawn-activator-kafka:${version}
activator-pubsub-image=${registry}/spawn-activator-pubsub:${version}
activator-rabbitmq-image=${registry}/spawn-activator-rabbitmq:${version}
activator-sqs-image=${registry}/spawn-activator-sqs:${version}
activator-simple-image=${registry}/spawn-activator-simple:0.1.3
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
	docker build --no-cache -f Dockerfile-proxy -t ${proxy-image} .

build-operator-image:
	docker build --no-cache -f Dockerfile-operator -t ${operator-image} .

build-elixir-sdk-image:
	docker build --no-cache -f Dockerfile-elixir-example -t ${spawn-sdk-example-image} .

build-activator-simple-image:
	docker build --no-cache -f Dockerfile-activator-simple -t ${activator-simple-image} .

build-all-images:
	docker build --no-cache -f Dockerfile-proxy -t ${proxy-image} .
	docker build --no-cache -f Dockerfile-initializer -t ${proxy-initializer} .
	docker build --no-cache -f Dockerfile-operator -t ${operator-image} .
	#docker build --no-cache -f Dockerfile-activator-api -t ${activator-api-image} .
	#docker build --no-cache -f Dockerfile-activator-kafka -t ${activator-kafka-image} .
	#docker build --no-cache -f Dockerfile-activator-pubsub -t ${activator-pubsub-image} .
	#docker build --no-cache -f Dockerfile-activator-rabbitmq -t ${activator-rabbitmq-image} .
	#docker build --no-cache -f Dockerfile-activator-sqs -t ${activator-sqs-image} .
	#docker build --no-cache -f Dockerfile-elixir-example -t ${spawn-sdk-example-image} .

test-spawn:
	MIX_ENV=test PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_PORT=3307 PROXY_DATABASE_POOL_SIZE=15 PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-statestores_mysql:
	cd spawn_statestores/statestores_mysql && MIX_ENV=test mix deps.get && MIX_ENV=test  PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-statestores_mariadb:
	cd spawn_statestores/statestores_mariadb && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_PORT=3307  PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-statestores_postgres:
	cd spawn_statestores/statestores_postgres && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-statestores_mssql:
	cd spawn_statestores/statestores_mssql && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-statestores_sqlite:
	cd spawn_statestores/statestores_sqlite && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-statestores_native:
	cd spawn_statestores/statestores_native && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-spawn-sdk:
	cd spawn_sdk/spawn_sdk && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_PORT=3307 PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= PROXY_ACTOR_SYSTEM_NAME=spawn-system elixir --name spawn_test@127.0.0.1 -S mix test

test-invoke-backpressure:
	cd spawn_sdk/spawn_sdk && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_POOL_SIZE=50 PROXY_DATABASE_PORT=3307 PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= PROXY_ACTOR_SYSTEM_NAME=spawn-system elixir --name spawn_test@127.0.0.1 -S mix test ./test/actor/actor_test.exs --only parallel:true

test-operator:
	cd spawn_operator/spawn_operator && MIX_ENV=test mix deps.get && MIX_ENV=test PROXY_DATABASE_TYPE=mysql PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

test-proxy:
	cd spawn_proxy/proxy && MIX_ENV=test mix deps.get && MIX_ENV=test SPAWN_PROXY_LOGGER_LEVEL=debug PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_PORT=3307 PROXY_CLUSTER_STRATEGY=gossip PROXY_HTTP_PORT=9005 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test

run-benchmark:
	cd spawn_sdk/spawn_sdk_example &&  mix deps.get && SPAWN_PROXY_LOGGER_LEVEL=info PROXY_CLUSTER_STRATEGY=gossip PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_PORT=3307 PROXY_DATABASE_POOL_SIZE=50 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn@127.0.0.1 -S mix run benchmark.exs

integration.yaml: ## Create a k3d cluster
	- k3d cluster delete ${CLUSTER_NAME}
	k3d cluster create ${CLUSTER_NAME} --servers 1 --wait
	k3d kubeconfig get ${CLUSTER_NAME} > ${K3D_KUBECONFIG_PATH}
	sleep 5

.PHONY: test.integration

test.integration: integration.yaml

test.integration: ## Run integration tests using k3d `make cluster`
	cd spawn_operator/spawn_operator && PROXY_CLUSTER_STRATEGY=gossip PROXY_DATABASE_TYPE=mysql  PROXY_DATABASE_POOL_SIZE=10 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= TEST_KUBECONFIG=${K3D_KUBECONFIG_PATH} mix test --only integration

push-all-images:
	docker push ${proxy-image}
	docker push ${proxy-initializer}
	docker push ${operator-image}
	#docker push ${activator-api-image}
	#docker push ${activator-http-image}
	#docker push ${activator-kafka-image}
	#docker push ${activator-pubsub-image}
	#docker push ${activator-rabbitmq-image}
	#docker push ${activator-sqs-image}
	#docker push ${spawn-sdk-example-image}

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
	kind load docker-image ${activator-api-image} --name default
	kind load docker-image ${activator-http-image} --name default
	kind load docker-image ${activator-kafka-image} --name default
	kind load docker-image ${activator-pubsub-image} --name default
	kind load docker-image ${activator-rabbitmq-image} --name default
	kind load docker-image ${activator-sqs-image} --name default

create-k8s-namespace:
	kubectl create ns eigr-functions

generate-k8s-manifests:
	cd spawn_operator/spawn_operator && MIX_ENV=prod mix deps.get && MIX_ENV=prod mix bonny.gen.manifest --image ${operator-image} --namespace eigr-functions

apply-k8s-manifests:
	kubectl -n eigr-functions apply -f spawn_operator/spawn_operator/manifest.yaml

run-proxy-local:
	ERL_ZFLAGS='-proto_dist inet_tls -ssl_dist_optfile rel/overlays/local-mtls.ssl.conf' cd spawn_proxy/proxy && mix deps.get && PROXY_DATABASE_TYPE=$(database) PROXY_HTTP_PORT=9002 USER_FUNCTION_PORT=8091 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a1@test.default.svc -S mix

run-proxy-local2:
	ERL_ZFLAGS='-proto_dist inet_tls -ssl_dist_optfile rel/overlays/local-mtls.ssl.conf' cd spawn_proxy/proxy && mix deps.get && PROXY_DATABASE_TYPE=$(database) PROXY_HTTP_PORT=9003 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@test.default.svc -S mix

run-proxy-local-3:
	cd spawn_proxy/proxy && mix deps.get && SPAWN_PROXY_LOGGER_LEVEL=info PROXY_CLUSTER_STRATEGY=epmd SPAWN_USE_INTERNAL_NATS=true SPAWN_PUBSUB_ADAPTER=nats PROXY_DATABASE_PORT=3307 PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_POOL_SIZE=30 PROXY_HTTP_PORT=9003 USER_FUNCTION_PORT=8091 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a3@127.0.0.1 -S mix

run-proxy-local-nodejs-test:
	ERL_ZFLAGS='-proto_dist inet_tls -ssl_dist_optfile rel/overlays/local-mtls.ssl.conf' cd spawn_proxy/proxy && mix deps.get && PROXY_DATABASE_TYPE=$(database) PROXY_HTTP_PORT=9001 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= PROXY_ACTOR_SYSTEM_NAME=SpawnSysTest SPAWN_SUPERVISORS_STATE_HANDOFF_CONTROLLER=crdt iex --name spawn_a1@test.default.svc -S mix

run-proxy-local-dicegame:
	cd spawn_proxy/proxy && mix deps.get && PROXY_DATABASE_TYPE=$(database) PROXY_CLUSTER_STRATEGY=epmd PROXY_HTTP_PORT=9001 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= PROXY_ACTOR_SYSTEM_NAME=game-system SPAWN_SUPERVISORS_STATE_HANDOFF_CONTROLLER=persistent SPAWN_USE_INTERNAL_NATS=true SPAWN_PUBSUB_ADAPTER=nats iex --name spawn_a4@127.0.0.1 -S mix

run-sdk-local:
	cd spawn_sdk/spawn_sdk_example && mix deps.get && PROXY_CLUSTER_STRATEGY=gossip PROXY_DATABASE_TYPE=$(database) SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_actors_node@127.0.0.1 -S mix

run-sdk-local2:
	cd spawn_sdk/spawn_sdk_example && mix deps.get && PROXY_CLUSTER_STRATEGY=epmd PROXY_DATABASE_POOL_SIZE=5 SPAWN_USE_INTERNAL_NATS=true SPAWN_PUBSUB_ADAPTER=nats PROXY_DATABASE_TYPE=$(database) SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a2@127.0.0.1 -S mix

run-sdk-local3:
	cd spawn_sdk/spawn_sdk_example && mix deps.get && PROXY_CLUSTER_STRATEGY=epmd SPAWN_USE_INTERNAL_NATS=true SPAWN_PUBSUB_ADAPTER=nats PROXY_DATABASE_TYPE=mariadb PROXY_DATABASE_PORT=3307 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a3@127.0.0.1 -S mix

run-sdk-local-with-mariadb:
	cd spawn_sdk/spawn_sdk_example && mix deps.get && PROXY_CLUSTER_STRATEGY=epmd SPAWN_USE_INTERNAL_NATS=true SPAWN_PUBSUB_ADAPTER=nats PROXY_DATABASE_PORT=3307 PROXY_DATABASE_TYPE=mariadb SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a3@127.0.0.1 -S mix

run-sdk-local-nats:
	cd spawn_sdk/spawn_sdk_example && mix deps.get && PROXY_CLUSTER_STRATEGY=epmd PROXY_DATABASE_TYPE=$(database) SPAWN_USE_INTERNAL_NATS=true SPAWN_PUBSUB_ADAPTER=nats SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= iex --name spawn_a3@127.0.0.1 -S mix

run-operator-local:
	cd spawn_operator/spawn_operator && mix deps.get && MIX_ENV=dev BONNY_POD_NAME=spawn-operator iex --name operator@127.0.0.1 -S mix
	
run-activator-local:
	cd spawn_activators/activator && mix deps.get && MIX_ENV=dev iex --name activator@127.0.0.1 -S mix

run-activator-grpc-local:
	cd spawn_activators/activator_api && mix deps.get && MIX_ENV=dev iex --name activator_api@127.0.0.1 -S mix

run-activator-kafka-local:
	cd spawn_activators/activator_kafka && mix deps.get && MIX_ENV=dev iex --name activator_kafka@127.0.0.1 -S mix

run-activator-pubsub-local:
	cd spawn_activators/activator_pubsub && mix deps.get && MIX_ENV=dev iex --name activator_pubsub@127.0.0.1 -S mix

run-activator-rabbitmq-local:
	cd spawn_activators/activator_rabbitmq && mix deps.get && MIX_ENV=dev iex --name activator_rabbitmq@127.0.0.1 -S mix

run-activator-sqs-local:
	cd spawn_activators/activator_sqs && mix deps.get && MIX_ENV=dev iex --name activator_sqs@127.0.0.1 -S mix

run-deps-get-all:
	cd spawn_operator/spawn_operator && mix deps.get
	cd spawn_sdk/spawn_sdk && mix deps.get
	cd spawn_proxy/proxy && mix deps.get
	cd spawn_activators/activator && mix deps.get
	cd spawn_activators/activator_api && mix deps.get
	cd spawn_activators/activator_pubsub && mix deps.get
	cd spawn_activators/activator_kafka && mix deps.get
	cd spawn_activators/activator_sqs && mix deps.get
	cd spawn_activators/activator_rabbitmq && mix deps.get

run-proxy-image:
	docker run --rm --name=spawn-proxy -e PROXY_DATABASE_TYPE=mysql -e SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= --net=host ${proxy-image}

run-operator-image:
	docker run --rm --name=spawn-operator --net=host ${operator-image}
