import SwiftUI

extension StructuredText {
  struct MathBlock: View {
    @Environment(\.paragraphStyle) private var paragraphStyle
    @Environment(\.mathProperties) private var mathProperties

    private let content: AttributedSubstring

    init(_ content: AttributedSubstring) {
      self.content = content
    }

    var body: some View {
      let configuration = BlockStyleConfiguration(
        label: .init(label),
        indentationLevel: indentationLevel
      )
      let resolvedStyle = paragraphStyle.resolve(configuration: configuration)

      AnyView(resolvedStyle)
        .layoutValue(key: BlockAlignmentKey.self, value: mathProperties.textAlignment)
    }

    private var label: some View {
      // Wide display equations don't wrap in swiftui-math and would clip off the
      // right edge (worse at larger font sizes). Make them horizontally
      // scrollable instead. `fixedSize(vertical:)` keeps the scroll view's height
      // at the equation's height (a ScrollView would otherwise grow to fill).
      ScrollView(.horizontal, showsIndicators: false) {
        WithInlineStyle(AttributedString(content)) {
          TextFragment($0)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }

    private var indentationLevel: Int {
      content.presentationIntent?.indentationLevel ?? 0
    }
  }
}
