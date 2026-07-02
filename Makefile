BIN      = cc-times
APP      = $(BIN).app
DMG      = $(BIN).dmg
SRC      = $(wildcard Sources/*.swift)
BUNDLE_ID = com.abesf.cc-times
LOGS_DIR = logs

.PHONY: start stop restart build build-universal start-only clean dmg icon shots

# ── Build (native, for local dev/run) ─────────────────────────────────────
# Command-line compile (no Xcode). No fixed -target so it builds natively on
# the current machine (Intel or Apple Silicon).
build:
	@swiftc \
		$(SRC) \
		-o $(BIN) \
		-framework AppKit \
		-framework SwiftUI
	@echo "✓ built: ./$(BIN)"

# ── Build a Universal binary (arm64 + x86_64) for distribution ───────────
# Compiles each architecture separately, then merges with lipo so one binary
# runs natively on both Apple Silicon and Intel Macs.
build-universal:
	@echo "==> building arm64 (first run may take a few min to build the arm64 stdlib)..."
	@swiftc -target arm64-apple-macos12 $(SRC) -o $(BIN).arm64 -framework AppKit -framework SwiftUI
	@echo "==> building x86_64..."
	@swiftc -target x86_64-apple-macos12 $(SRC) -o $(BIN).x86_64 -framework AppKit -framework SwiftUI
	@echo "==> merging with lipo..."
	@lipo -create -output $(BIN) $(BIN).arm64 $(BIN).x86_64
	@rm -f $(BIN).arm64 $(BIN).x86_64
	@echo "✓ built universal: ./$(BIN)"
	@lipo -info $(BIN)

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

# ── Render promotional screenshots into screenshots/ (offscreen CoreGraphics)
shots:
	@cd scripts && swiftc make_shots.swift -o make_shots \
		-framework AppKit -framework CoreGraphics -framework ImageIO
	@./scripts/make_shots
	@echo "✓ screenshots rendered to screenshots/"

# ── Build a .app bundle (with icon + Info.plist) ──────────────────────────
# Uses the universal binary so the bundle runs on Apple Silicon + Intel.
bundle: build-universal icon
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

# ── Build a Universal .dmg (arm64 + x86_64, unsigned) for release ────────
dmg: bundle
	@rm -f $(DMG)
	@hdiutil create -volname "$(BIN)" -srcfolder $(APP) -ov -format UDZO $(DMG) 2>&1 | tail -1
	@echo "✓ dmg: $(DMG) (universal, unsigned — see README for first-launch)"

# ── Clean ─────────────────────────────────────────────────────────────────
clean:
	@rm -rf $(BIN) $(BIN).arm64 $(BIN).x86_64 $(APP) $(DMG) $(LOGS_DIR) .build \
		scripts/AppIcon.iconset scripts/make_icon scripts/make_shots
	@echo "cleaned"
