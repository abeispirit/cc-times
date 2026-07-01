LOGS_DIR = logs
BIN      = mtimes
SRC      = $(wildcard Sources/*.swift)

.PHONY: start stop restart build start-only clean

# ── 构建 ───────────────────────────────────────────────
# 命令行编译(不依赖 Xcode),产出可执行文件 ./mtimes
build:
	@swiftc \
		-target x86_64-apple-macos12 \
		$(SRC) \
		-o $(BIN) \
		-framework AppKit \
		-framework SwiftUI
	@echo "✓ built: ./$(BIN)"

# ── 运行(后台启动 GUI,日志写 logs/app.log)────────────
start: build
	@mkdir -p $(LOGS_DIR)
	@pkill -x $(BIN) 2>/dev/null || true
	@./$(BIN) > $(LOGS_DIR)/app.log 2>&1 &
	@echo "started — desktop clock running (floating layer)"
	@echo "logs: $(LOGS_DIR)/app.log"

# 仅启动,不重新编译
start-only:
	@mkdir -p $(LOGS_DIR)
	@pkill -x $(BIN) 2>/dev/null || true
	@./$(BIN) > $(LOGS_DIR)/app.log 2>&1 &
	@echo "started — desktop clock running"

# ── 停止 ───────────────────────────────────────────────
stop:
	@pkill -x $(BIN) 2>/dev/null || true
	@echo "stopped"

# ── 重启(= stop + start,会重新编译)──────────────────
restart: stop start

# ── 清理 ───────────────────────────────────────────────
clean:
	@rm -rf $(BIN) $(LOGS_DIR) .build
	@echo "cleaned"
