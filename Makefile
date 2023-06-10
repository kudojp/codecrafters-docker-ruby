.PHONY:build
build:
	docker build -t mydocker .

.PHONY: get-docker-explorers
get-docker-explorers:
	sudo curl -Lo /usr/local/bin/docker-explorer https://github.com/codecrafters-io/docker-explorer/releases/download/v17/v17_darwin_amd64
	sudo chmod +x /usr/local/bin/docker-explorer

.PHONY: test
test:
	codecrafters test
