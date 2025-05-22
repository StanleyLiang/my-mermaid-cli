FROM minlag/mermaid-cli:latest

# 設置工作目錄
WORKDIR /data

# 添加健康檢查（使用完整路徑）
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD [ "/home/mermaidcli/node_modules/.bin/mmdc", "--help" ]

# 設置默認命令，保持與原始映像相同的配置
ENTRYPOINT ["/home/mermaidcli/node_modules/.bin/mmdc", "-p", "/puppeteer-config.json"]
CMD ["--help"]
