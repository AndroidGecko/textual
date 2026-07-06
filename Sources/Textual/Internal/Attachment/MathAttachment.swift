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
    MathView(latex: latex, style: displayStyle)
  }

  func baselineOffset(in environment: TextEnvironmentValues) -> CGFloat {
    -typographicBounds(in: environment).descent
  }

  func sizeThatFits(_ proposal: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize {
    // Always measure at natural size (`.unspecified` → maxWidth 0). swiftui-math's
    // interatom line breaking is fragile: a sub-point shortfall below the natural
    // width collapses a short inline expression like `\mathrm{CO}` onto multiple
    // lines, and the leading glyph is then clipped by the single-line run. The
    // shortfall comes from device-scale pixel snapping of the run bounds, which is
    // why it reproduces on iPhone (@3x) but not iPad (@2x).
    let natural = typographicBounds(fitting: .unspecified, in: environment).size

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
    in environment: TextEnvironmentValues
  ) -> Math.TypographicBounds {
    Math.typographicBounds(
      for: latex,
      fitting: proposal,
      font: .init(
        name: .init(environment.mathProperties.fontName),
        size: FontScaled(environment.mathProperties.fontScale).resolve(in: environment)
      ),
      style: .init(displayStyle)
    )
  }
}

private struct MathView: View {
  @Environment(\.textEnvironment) private var environment

  let latex: String
  let style: MathAttachment.DisplayStyle

  var body: some View {
    Math(latex)
      .mathFont(
        .init(
          name: .init(environment.mathProperties.fontName),
          size: FontScaled(environment.mathProperties.fontScale).resolve(in: environment)
        )
      )
      .mathTypesettingStyle(.init(style))
      .mathRenderingMode(.monochrome)
      // Render at natural (unbounded) width so swiftui-math never applies its
      // fragile interatom line breaking, which drops glyphs from short inline
      // expressions. The overlay scales this view into the run's bounds — for block
      // math that's the shrunk-to-fit rect computed in `MathAttachment.sizeThatFits`.
      .fixedSize(horizontal: true, vertical: false)
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
