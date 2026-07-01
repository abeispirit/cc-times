import SwiftUI

/// 横排所有时钟卡片,用 TimelineView 每秒驱动重绘。
/// 背景用一个透明可交互层,让 isMovableByWindowBackground 能接管拖动。
struct ClockRowView: View {
    @ObservedObject var store: ClockStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: store.compact ? 8 : 6) {
                ForEach(store.clocks) { clock in
                    ClockCardView(config: clock, now: context.date, compact: store.compact)
                }
            }
            .padding(20)
            // 透明背景填满整个窗口,确保点击空白处算作窗口背景 → 系统拖动
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
    }
}
