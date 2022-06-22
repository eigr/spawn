image=eigr/spawn-proxy:0.1.0
port=8080

.PHONY: all clean

all: build install

build:

	mix deps.clean --all && mix deps.get && docker build -t ${image} .

run: 

	docker run --rm --name=spawn-proxy -e PROXY_DATABASE_TYPE=mysql -e SPAWN_STATESTORE_KEY=3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE= --net=host ${image}

install:

	docker push ${image}
