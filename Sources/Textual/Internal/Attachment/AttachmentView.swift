import SwiftUI

// MARK: - Overview
//
// `AttachmentView` draws attachment bodies at the positions reported by SwiftUI's `Text.Layout`.
//
// The `Text` pipeline reserves space for attachments using placeholders; the overlay draws the
// real SwiftUI views on top of those placeholders. Drawing uses a `Canvas` so attachment views can
// be resolved once as symbols and efficiently drawn into each run's `typographicBounds`.
//
// An attachment run with a background color (for example, a formula inside a highlight) gets that
// color painted behind it: its placeholder drops the run's attributes, so `Text` paints none.
//
// Selection integration:
// On macOS, when text selection is enabled, object-style attachments are dimmed when they fall
// inside the selected range. Inline-style attachments (for example, emoji) are not dimmed.

struct AttachmentView: View {
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
  #endif
  private let attachments: Set<AnyAttachment>
  private let origin: CGPoint
  private let layout: Text.Layout

  init(
    attachments: Set<AnyAttachment>,
    origin: CGPoint,
    layout: Text.Layout
  ) {
    self.attachments = attachments
    self.origin = origin
    self.layout = layout
  }

  var body: some View {
    Canvas { context, _ in
      context.translateBy(x: origin.x, y: origin.y)
      for (lineIndex, line) in zip(layout.indices, layout) {
        for (runIndex, run) in zip(line.indices, line) {
          guard
            let attachment = run.attachment,
            let symbol = context.resolveSymbol(id: attachment)
          else {
            continue
          }

          context.opacity = opacity(
            for: attachment,
            lineIndex: lineIndex,
            runIndex: runIndex
          )

          if let backgroundColor = run.attachmentBackgroundColor {
            context.fill(
              Path(backgroundRect(for: run, in: line, scale: context.environment.displayScale)),
              with: .color(backgroundColor)
            )
          }

          context.draw(symbol, in: run.typographicBounds.rect)
        }
      }
    } symbols: {
      ForEach(Array(attachments), id: \.self) { attachment in
        attachment.body
          .tag(attachment)
      }
    }
  }

  /// The attachment's width, from its line's top to its lowest run's bottom: where `Text` paints
  /// a text run's background color (the line's own descent reaches lower), so the fill joins the
  /// text's around it. `Text` pins a run's background edges to the device pixel at or before them,
  /// so the band's edges are pinned the same way: no hairline gap or overlap where they meet.
  private func backgroundRect(
    for run: Text.Layout.Run,
    in line: Text.Layout.Line,
    scale: CGFloat
  ) -> CGRect {
    let runRect = run.typographicBounds.rect
    let top = line.typographicBounds.rect.minY
    let bottom = line.map(\.typographicBounds.rect.maxY).max() ?? runRect.maxY
    let minX = floorToPixel(runRect.minX, scale: scale)
    let maxX = floorToPixel(runRect.maxX, scale: scale)
    return CGRect(x: minX, y: top, width: maxX - minX, height: bottom - top)
  }

  /// `x`, in the canvas's layout coordinates, floored to a device pixel of the window.
  private func floorToPixel(_ x: CGFloat, scale: CGFloat) -> CGFloat {
    guard scale > 0 else { return x }
    return ((origin.x + x) * scale).rounded(.down) / scale - origin.x
  }

  private func opacity(
    for attachment: AnyAttachment,
    lineIndex: Int,
    runIndex: Int
  ) -> CGFloat {
    #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
      guard
        attachment.selectionStyle == .object,
        let textSelectionModel,
        let selectedRange = textSelectionModel.selectedRange,
        let layoutIndex = textSelectionModel.layoutIndex(of: layout)
      else {
        return 1
      }

      let position = TextPosition(
        indexPath: .init(run: runIndex, line: lineIndex, layout: layoutIndex),
        affinity: .downstream
      )

      return selectedRange.contains(position) ? 0.5 : 1
    #else
      1
    #endif
  }
}
