IMAGE     = ghcr.io/calvinw/ai-course-devcontainer
TAG       = latest
CONTAINER = ai-container
WORKSPACE = /workspaces/ai-container

# --- Local devcontainer workflow ---

up: pull run setup shell

pull:
	docker pull $(IMAGE):$(TAG)

run:
	docker run -d \
		--name $(CONTAINER) \
		-e CLAUDE_CODE_DISABLE_VSCODE_EXTENSION=1 \
		-e IS_SANDBOX=1 \
		-v "$(PWD)":$(WORKSPACE) \
		-w $(WORKSPACE) \
		$(IMAGE):$(TAG) \
		sleep infinity

setup:
	docker exec $(CONTAINER) bash .devcontainer/post-create.sh

shell:
	docker exec -it $(CONTAINER) bash

stop:
	docker stop $(CONTAINER) && docker rm $(CONTAINER)

up-test: build-test run-test setup shell

run-test:
	docker run -d \
		--name $(CONTAINER) \
		-e CLAUDE_CODE_DISABLE_VSCODE_EXTENSION=1 \
		-e IS_SANDBOX=1 \
		-v "$(PWD)":/workspace \
		-w /workspace \
		ai-container-test \
		sleep infinity

# Simulate an end-user repo: clean workspace with only a conf file, no scripts visible
USER_TEST_DIR = /tmp/test-user-repo

test-user: build-test
	mkdir -p $(USER_TEST_DIR)/configs
	@echo "Add entries to $(USER_TEST_DIR)/configs/mcp-servers.conf then re-run make test-user-shell"

test-user-shell:
	docker run --rm -it \
		-v "$(USER_TEST_DIR)":/workspace \
		ai-container-test bash

# --- Image build/publish workflow ---

build-test:
	docker build -t ai-container-test .

build:
	docker build -t $(IMAGE):$(TAG) .

push:
	docker push $(IMAGE):$(TAG)

clean:
	docker rmi $(IMAGE):$(TAG)

.PHONY: up pull run setup shell stop up-test run-test test-user test-user-shell build-test build push clean
