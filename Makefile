proxy-image=eigr/spawn-proxy:0.1.0
operator-image=eigr/spawn-operator:0.1.0
activator-grpc-image=eigr/spawn-activator-grpc:0.1.0
activator-http-image=eigr/spawn-activator-http:0.1.0
activator-kafka-image=eigr/spawn-activator-kafka:0.1.0
activator-pubsub-image=eigr/spawn-activator-pubsub:0.1.0
activator-rabbitmq-image=eigr/spawn-activator-rabbitmq:0.1.0
activator-sqs-image=eigr/spawn-activator-sqs:0.1.0
port=8080

.PHONY: all clean

all: build test install

build:
	mix deps.clean --all && mix deps.get && docker build -f Dockerfile-proxy -t ${proxy-image} .

build-and-push-all-images:
	docker build -f Dockerfile-proxy -t ${proxy-image} .
	docker push ${proxy-image}
	docker build -f Dockerfile-operator -t ${operator-image} .
	docker push ${operator-image}
	docker build -f Dockerfile-activator-grpc -t ${activator-grpc-image} .
	docker push ${activator-grpc-image}
	docker build -f Dockerfile-activator-http -t ${activator-http-image} .
	docker push ${activator-http-image}
	docker build -f Dockerfile-activator-kafka -t ${activator-kafka-image} .
	docker push ${activator-kafka-image}
	docker build -f Dockerfile-activator-pubsub -t ${activator-pubsub-image} .
	docker push ${activator-pubsub-image}
	docker build -f Dockerfile-activator-rabbitmq -t ${activator-rabbitmq-image} .
	docker push ${activator-rabbitmq-image}
	docker build -f Dockerfile-activator-sqs -t ${activator-sqs-image} .
	docker push ${activator-sqs-image}

run:
	docker run --rm --name=spawn-proxy -e PROXY_DATABASE_TYPE=mysql -e SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= --net=host ${proxy-image}

install:
	docker push ${proxy-image}

test:
	MIX_ENV=test PROXY_DATABASE_TYPE=mysql PROXY_HTTP_PORT=9001 SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= elixir --name spawn@127.0.0.1 -S mix test
