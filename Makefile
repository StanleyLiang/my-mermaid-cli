# 映像名稱和版本
IMAGE_NAME := my-mermaid-cli
VERSION := 1.0.0

# 默認目標
.DEFAULT_GOAL := help

# 顯示幫助信息
.PHONY: help
help:
	@echo "使用說明:"
	@echo "  make build    - 構建 Docker 映像"
	@echo "  make push     - 推送映像到 Docker Hub"
	@echo "  make test     - 執行所有測試"
	@echo "  make clean    - 清理本地映像"

# 構建映像
.PHONY: build
build:
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest

# 測試映像
.PHONY: test
test: test-svg test-png test-themes

.PHONY: test-svg
test-svg:
	@echo "測試 SVG 輸出..."
	@echo 'graph TD\nA[SVG測試] --> B[成功]' > test-svg.mmd
	docker run --rm -v $$(pwd):/data $(IMAGE_NAME):$(VERSION) -i test-svg.mmd -o test-svg.svg

.PHONY: test-png
test-png:
	@echo "測試 PNG 輸出..."
	@echo 'graph TD\nA[PNG測試] --> B[成功]' > test-png.mmd
	docker run --rm -v $$(pwd):/data $(IMAGE_NAME):$(VERSION) -i test-png.mmd -o test-png.png

.PHONY: test-themes
test-themes:
	@echo "測試不同主題..."
	@echo 'graph TD\nA[主題測試] --> B[預設主題]\nA --> C[深色主題]\nA --> D[森林主題]' > test-themes.mmd
	docker run --rm -v $$(pwd):/data $(IMAGE_NAME):$(VERSION) -i test-themes.mmd -o test-default.png
	docker run --rm -v $$(pwd):/data $(IMAGE_NAME):$(VERSION) -i test-themes.mmd -o test-dark.png -t dark
	docker run --rm -v $$(pwd):/data $(IMAGE_NAME):$(VERSION) -i test-themes.mmd -o test-forest.png -t forest

# 推送映像
.PHONY: push
push:
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest

# 清理
.PHONY: clean
clean:
	docker rmi $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest 2>/dev/null || true
	rm -f test-*.mmd test-*.png test-*.svg 2>/dev/null || true
