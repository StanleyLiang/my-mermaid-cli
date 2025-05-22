# 映像名稱和版本
IMAGE_NAME := my-mermaid-cli
VERSION := 1.0.0

# 默認目標
.DEFAULT_GOAL := help

# 顯示幫助信息
.PHONY: help
help:
	@echo "使用說明:"
	@echo "  make build              - 構建 Docker 映像"
	@echo "  make test-nats         - 測試 NATS 服務"
	@echo "  make clean             - 清理本地映像"
	@echo "  make run-nats          - 運行 NATS 服務器"
	@echo "  make run-service       - 運行 Mermaid 服務"
	@echo "  make test-send         - 發送測試消息"

# 構建映像
.PHONY: build
build:
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest

# 清理容器和網絡
.PHONY: clean-containers
clean-containers:
	@echo "Stopping containers..."
	-docker stop nats mermaid-service 2>/dev/null || true
	@echo "Removing network..."
	-docker network rm mermaid-test 2>/dev/null || true

# 運行 NATS 服務器
.PHONY: run-nats
run-nats: clean-containers
	docker run --rm --name nats -p 4222:4222 -p 8222:8222 nats:latest

# 運行 Mermaid 服務
.PHONY: run-service
run-service: clean-containers
	docker run --rm --name mermaid-service \
		--network host \
		-v $$(pwd)/output:/data/output \
		-e NATS_URL=nats://localhost:4222 \
		$(IMAGE_NAME):latest

# 發送測試消息
.PHONY: test-send
test-send:
	@echo "發送測試消息到 NATS..."
	cd src && node test-publish.js

# 測試 NATS 服務
.PHONY: test-nats
test-nats: clean build clean-containers
	@echo "啟動測試環境..."
	mkdir -p output
	docker network create mermaid-test || true
	docker run -d --rm --name nats --network mermaid-test nats:latest
	sleep 2
	@echo "啟動 Mermaid 服務..."
	docker run -d --rm --name mermaid-service \
		--network mermaid-test \
		-v $$(pwd)/output:/data/output \
		-e NATS_URL=nats://nats:4222 \
		$(IMAGE_NAME):latest
	@echo "等待服務啟動..."
	sleep 3
	@echo "發送測試消息..."
	cd src && NODE_ENV=test NATS_URL=nats://localhost:4222 node test-publish.js
	@echo "等待處理完成..."
	sleep 3
	@echo "服務日誌..."
	docker logs mermaid-service
	@echo "檢查輸出目錄..."
	ls -l output/
	@echo "測試完成，正在清理環境..."
	make clean-containers

# 清理
.PHONY: clean
clean: clean-containers
	docker rmi $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest 2>/dev/null || true
	rm -rf output/* 2>/dev/null || true
