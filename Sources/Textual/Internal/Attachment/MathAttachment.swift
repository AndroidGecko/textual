import SwiftUI
@_spi(Textual) private import SwiftUIMath

struct MathAttachment: Attachment {
  enum DisplayStyle: Sendable {
    case inline
    case block
  }

  var description: String {
    switch displayStyle {
    case .inline:
      return "$\(latex)$"
    case .block:
      return "$$\(latex)$$"
    }
  }

  var selectionStyle: AttachmentSelectionStyle {
    .text
  }

  let latex: String
  let displayStyle: DisplayStyle

  init(latex: String, style: DisplayStyle) {
    self.latex = latex
    self.displayStyle = style
  }

  var body: some View {
    MathView(attachment: self)
  }

  func baselineOffset(in environment: TextEnvironmentValues) -> CGFloat {
    -typographicBounds(in: environment).descent
  }

  /// The width to typeset this run at when it must be promoted from inline to
  /// display, or `nil` when no promotion applies.
  ///
  /// swiftui-math only line-breaks `.display`; inline is deliberately pinned to
  /// `maxWidth: 0`, because a sub-natural proposal collapses short expressions and
  /// clips their leading glyph. The consequence is that a *long* inline expression
  /// can never wrap and simply runs off the edge. Typesetting it as display does
  /// wrap it — measured, a 413pt inline expression becomes 261pt in a 300pt
  /// container.
  ///
  /// `sizeThatFits` and `MathView` both call this, so the reserved rect and the
  /// drawn symbol always agree. If they disagreed, `Canvas.draw(_:in:)` would
  /// scale natural-width math into a wrapped-size rect and distort it.
  func promotedWidth(in environment: TextEnvironmentValues) -> CGFloat? {
    guard displayStyle == .inline,
      let containerWidth = environment.mathProperties.containerWidth,
      containerWidth > 0
    else {
      return nil
    }
    let natural = typographicBounds(fitting: .unspecified, in: environment).width
    return natural > containerWidth ? containerWidth : nil
  }

  func sizeThatFits(_ proposal: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize {
    // Always measure at natural size (`.unspecified` → maxWidth 0). swiftui-math's
    // interatom line breaking is fragile: a sub-point shortfall below the natural
    // width collapses a short inline expression like `\mathrm{CO}` onto multiple
    // lines, and the leading glyph is then clipped by the single-line run. The
    // shortfall comes from device-scale pixel snapping of the run bounds, which is
    // why it reproduces on iPhone (@3x) but not iPad (@2x).
    let natural = typographicBounds(fitting: .unspecified, in: environment).size

    // An inline expression wider than its container is typeset as display, which
    // wraps, rather than overflowing off the edge. Reserve the wrapped size.
    if let width = promotedWidth(in: environment) {
      return typographicBounds(
        fitting: .init(width: width, height: nil),
        style: .display,
        in: environment
      ).size
    }

    // Display equations don't wrap in this swiftui-math version, so a wide one would
    // overflow and clip on a narrow screen. Shrink it to fit the available width
    // instead — the overlay draws the (natural-size) view scaled into this rect.
    if displayStyle == .block, let maxW = proposal.width, maxW.isFinite, maxW > 0,
       natural.width > maxW {
      let scale = maxW / natural.width
      return CGSize(width: maxW, height: natural.height * scale)
    }
    return natural
  }

  private func typographicBounds(
    fitting proposal: ProposedViewSize = .unspecified,
    style: Math.TypesettingStyle? = nil,
    in environment: TextEnvironmentValues
  ) -> Math.TypographicBounds {
    Math.typographicBounds(
      for: latex,
      fitting: proposal,
      font: .init(
        name: .init(environment.mathProperties.fontName),
        size: FontScaled(environment.mathProperties.fontScale).resolve(in: environment)
      ),
      style: style ?? .init(displayStyle)
    )
  }
}

private struct MathView: View {
  @Environment(\.textEnvironment) private var environment

  let attachment: MathAttachment

  var body: some View {
    let promotedWidth = attachment.promotedWidth(in: environment)

    Math(attachment.latex)
      .mathFont(
        .init(
          name: .init(environment.mathProperties.fontName),
          size: FontScaled(environment.mathProperties.fontScale).resolve(in: environment)
        )
      )
      // A promoted run is typeset as display so swiftui-math will wrap it.
      .mathTypesettingStyle(promotedWidth == nil ? .init(attachment.displayStyle) : .display)
      .mathRenderingMode(.monochrome)
      // Promoted math must receive a *bounded* width proposal — that is what makes
      // swiftui-math break it across lines. Everything else keeps the natural
      // (unbounded) width so inline expressions never hit the fragile interatom
      // breaking that drops their leading glyph.
      .frame(maxWidth: promotedWidth)
      .fixedSize(horizontal: promotedWidth == nil, vertical: false)
  }
}

extension Math.Font.Name {
  fileprivate init(_ fontName: MathProperties.FontName) {
    self.init(rawValue: fontName.rawValue)
  }
}

extension Math.TypesettingStyle {
  fileprivate init(_ style: MathAttachment.DisplayStyle) {
    switch style {
    case .inline:
      self = .text
    case .block:
      self = .display
    }
  }
}
