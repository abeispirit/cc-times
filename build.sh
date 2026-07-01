#!/bin/bash
# 一键编译脚本:命令行编译 mtimes(macOS 多时区桌面时钟)
# 用法: ./build.sh   产出可执行文件 ./mtimes
set -e

cd "$(dirname "$0")"

echo "==> 编译 mtimes ..."
# 不依赖 SwiftPM 拉网络,直接 swiftc 单步编译所有源文件
swiftc \
    -target x86_64-apple-macos12 \
    Sources/*.swift \
    -o mtimes \
    -framework AppKit \
    -framework SwiftUI

echo "==> 编译完成: $(pwd)/mtimes"
echo "==> 运行: ./mtimes"
