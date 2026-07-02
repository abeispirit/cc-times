BIN      = cc-times
APP      = $(BIN).app
DMG      = $(BIN).dmg
SRC      = $(wildcard Sources/*.swift)
BUNDLE_ID = com.abesf.cc-times
LOGS_DIR = logs

.PHONY: start stop restart build start-only clean dmg icon

# ── Build ─────────────────────────────────────────────────────────────────
# Command-line compile (no Xcode). No fixed -target so it builds natively on
# both Intel and Apple Silicon.
build:
	@swiftc \
		$(SRC) \
		-o $(BIN) \
		-framework AppKit \
		-framework SwiftUI
	@echo "✓ built: ./$(BIN)"

# ── Run (launches GUI in background, logs to logs/app.log) ────────────────
start: build
	@mkdir -p $(LOGS_DIR)
	@pkill -x $(BIN) 2>/dev/null || true
	@./$(BIN) > $(LOGS_DIR)/app.log 2>&1 &
	@echo "started — desktop clock running (floating layer)"
	@echo "logs: $(LOGS_DIR)/app.log"

start-only:
	@mkdir -p $(LOGS_DIR)
	@pkill -x $(BIN) 2>/dev/null || true
	@./$(BIN) > $(LOGS_DIR)/app.log 2>&1 &
	@echo "started — desktop clock running"

# ── Stop ──────────────────────────────────────────────────────────────────
stop:
	@pkill -x $(BIN) 2>/dev/null || true
	@echo "stopped"

# ── Restart (= stop + rebuild + start) ────────────────────────────────────
restart: stop start

# ── Generate app icon (AppIcon.icns) from the CoreGraphics script ─────────
icon:
	@cd scripts && swiftc make_icon.swift -o make_icon \
		-framework AppKit -framework CoreGraphics -framework ImageIO
	@cd scripts && ./make_icon
	@cp scripts/AppIcon.icns .
	@echo "✓ icon: AppIcon.icns"

# ── Build a .app bundle (with icon + Info.plist) ──────────────────────────
bundle: build icon
	@rm -rf $(APP)
	@mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	@cp $(BIN) $(APP)/Contents/MacOS/$(BIN)
	@cp AppIcon.icns $(APP)/Contents/Resources/AppIcon.icns
	@printf '%s\n' \
		'<?xml version="1.0" encoding="UTF-8"?>' \
		'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
		'<plist version="1.0"><dict>' \
		'  <key>CFBundleName</key><string>cc-times</string>' \
		'  <key>CFBundleDisplayName</key><string>cc-times</string>' \
		'  <key>CFBundleIdentifier</key><string>$(BUNDLE_ID)</string>' \
		'  <key>CFBundleVersion</key><string>1</string>' \
		'  <key>CFBundleShortVersionString</key><string>1.0.0</string>' \
		'  <key>CFBundleExecutable</key><string>$(BIN)</string>' \
		'  <key>CFBundleIconFile</key><string>AppIcon</string>' \
		'  <key>CFBundlePackageType</key><string>APPL</string>' \
		'  <key>LSMinimumSystemVersion</key><string>12.0</string>' \
		'  <key>LSUIElement</key><true/>' \
		'</dict></plist>' > $(APP)/Contents/Info.plist
	@echo "✓ bundle: $(APP)/"

# ── Build a .dmg from the .app bundle (unsigned, for self/OSS use) ────────
dmg: bundle
	@rm -f $(DMG)
	@hdiutil create -volname "$(BIN)" -srcfolder $(APP) -ov -format UDZO $(DMG) 2>&1 | tail -1
	@echo "✓ dmg: $(DMG)"
	@echo "  (unsigned — see README for first-launch instructions)"

# ── Clean ─────────────────────────────────────────────────────────────────
clean:
	@rm -rf $(BIN) $(APP) $(DMG) $(LOGS_DIR) .build scripts/AppIcon.iconset scripts/make_icon
	@echo "cleaned"
