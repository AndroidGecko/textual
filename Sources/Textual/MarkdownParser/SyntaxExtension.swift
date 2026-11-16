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
  ///
  /// The tokenizer matches one pattern at a time, so maths and `\$` inside a
  /// highlight never reach the `math` extension: the highlight's content is
  /// tokenized with `math`'s own patterns and replaced by its own rules.
  public static func highlight(color: Color = .yellow.opacity(0.3)) -> Self {
    let math = Self.math
    let tokenizer = PatternTokenizer(patterns: math.patterns)

    return .init(patterns: [.highlight]) { token, attributes in
      guard let text = token.capturedContent else {
        return nil
      }
      var highlighted = attributes
      highlighted.backgroundColor = color

      let tokens = (try? tokenizer.tokenize(text)) ?? [.init(type: .text, content: text)]
      return tokens.reduce(into: AttributedString()) { output, token in
        output.append(
          math.replace(token, highlighted)
            ?? AttributedString(token.content, attributes: highlighted)
        )
      }
    }
  }

  /// Replaces inline and block math expressions with attachments, and `\$`
  /// with a literal `$`.
  public static var math: Self {
    .init(patterns: [.escapedDollar, .mathBlock, .mathInline]) { token, attributes in
      if token.type == .escapedDollar {
        return AttributedString("$", attributes: attributes)
      }
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
