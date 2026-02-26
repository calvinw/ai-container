IMAGE = ghcr.io/calvinw/ai-course-devcontainer
TAG = latest

build:
	docker build -t $(IMAGE):$(TAG) .

run:
	docker run --rm -it $(IMAGE):$(TAG) bash

push:
	docker push $(IMAGE):$(TAG)

clean:
	docker rmi $(IMAGE):$(TAG)

.PHONY: build run push clean
