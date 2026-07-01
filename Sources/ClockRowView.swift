import SwiftUI

/// 横排所有时钟卡片,用 TimelineView 每秒驱动重绘。
/// 背景用一个透明可交互层,让 isMovableByWindowBackground 能接管拖动。
struct ClockRowView: View {
    @ObservedObject var store: ClockStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Group {
                if store.compact {
                    // 简版:横排,紧贴内容。用 fixedSize 让内容撑开真实大小
                    HStack(spacing: 8) {
                        ForEach(store.clocks) { clock in
                            ClockCardView(config: clock, now: context.date, compact: true)
                        }
                    }
                    .padding(12)
                    .fixedSize()   // 按内容真实大小,不被窗口压缩
                } else {
                    // 完整:横排表盘,背景填满窗口便于拖动
                    HStack(spacing: 6) {
                        ForEach(store.clocks) { clock in
                            ClockCardView(config: clock, now: context.date, compact: false)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
            }
        }
    }
}
