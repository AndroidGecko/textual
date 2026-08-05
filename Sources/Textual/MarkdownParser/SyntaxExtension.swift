import Foundation
import SwiftUI

extension AttributedStringMarkdownParser {
  /// A syntax extension that replaces matched tokens after Markdown parsing.
  public struct SyntaxExtension {
    let patterns: [PatternTokenizer.Pattern]
    let replace:
      (
        _ token: PatternTokenizer.Token,
        _ attributes: AttributeContainer
      ) -> AttributedString?
  }
}

extension AttributedStringMarkdownParser.SyntaxExtension {
  /// Replaces `:shortcode:` sequences using the provided custom emoji definitions.
  public static func emoji(_ emoji: Set<Emoji>) -> Self {
    guard !emoji.isEmpty else {
      return Self(patterns: [], replace: { _, _ in nil })
    }

    let emojiMap = Dictionary(
      uniqueKeysWithValues: emoji.map { emoji in
        (emoji.shortcode, emoji)
      }
    )

    return Self(patterns: [.emoji]) { token, attributes in
      guard let shortcode = token.capturedContent, let emoji = emojiMap[shortcode] else {
        return nil
      }

      return AttributedString(
        shortcode,
        attributes: attributes.emojiURL(emoji.url)
      )
    }
  }

  /// Renders `==text==` (the Obsidian highlight convention) with a
  /// background color, keeping the text and its other attributes intact.
  public static func highlight(color: Color = .yellow.opacity(0.3)) -> Self {
    .init(patterns: [.highlight]) { token, attributes in
      guard let text = token.capturedContent else {
        return nil
      }
      var highlighted = attributes
      highlighted.backgroundColor = color
      return AttributedString(text, attributes: highlighted)
    }
  }

  /// Replaces inline and block math expressions with attachments.
  public static var math: Self {
    .init(patterns: [.mathBlock, .mathInline]) { token, attributes in
      guard let latex = token.capturedContent else {
        return nil
      }

      let attachment = MathAttachment(
        latex: latex,
        style: token.type == .mathBlock ? .block : .inline
      )
      return AttributedString("\u{FFFC}", attributes: attributes.attachment(.init(attachment)))
    }
  }
}
