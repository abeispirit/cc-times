import SwiftUI

/// Horizontal row of all clock cards, redrawn every second via TimelineView.
/// The full-mode background fills the window so dragging works anywhere;
/// compact mode uses fixedSize so the window hugs its content.
struct ClockRowView: View {
    @ObservedObject var store: ClockStore
    @ObservedObject var l10n: L10n

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Group {
                if store.settings.compact {
                    HStack(spacing: Const.compactSpacing) {
                        ForEach(store.clocks) { clock in
                            ClockCardView(config: clock, now: context.date,
                                          compact: true, language: l10n.language)
                        }
                    }
                    .padding(Const.compactPadding)
                    .fixedSize()
                } else {
                    HStack(spacing: Const.fullSpacing) {
                        ForEach(store.clocks) { clock in
                            ClockCardView(config: clock, now: context.date,
                                          compact: false, language: l10n.language)
                        }
                    }
                    .padding(Const.fullPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
            }
        }
    }

    private enum Const {
        static let fullPadding: CGFloat = 20
        static let compactPadding: CGFloat = 12
        static let fullSpacing: CGFloat = 6
        static let compactSpacing: CGFloat = 8
    }
}
