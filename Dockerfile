FROM minlag/mermaid-cli:latest

# 設置工作目錄
WORKDIR /data

# 安裝依賴
USER root
COPY src/package.json /app/
WORKDIR /app
RUN npm install

# 創建輸出目錄並設置權限
RUN mkdir -p /data/output && \
    chown -R mermaidcli:mermaidcli /data /app

# 複製服務腳本
COPY --chown=mermaidcli:mermaidcli src/server.js /app/

# 切換回 mermaidcli 用戶
USER mermaidcli
WORKDIR /data

# 添加健康檢查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD [ "/home/mermaidcli/node_modules/.bin/mmdc", "--help" ]

# 設置環境變數
ENV NATS_URL=nats://nats:4222 \
    NATS_SUBJECT=mermaid.render \
    OUTPUT_DIR=/data/output

# 設置默認命令為運行 NATS 訂閱服務
ENTRYPOINT ["node", "/app/server.js"]
