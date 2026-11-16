import Foundation
import SwiftUI
import Testing

@testable import Textual

extension AttributedStringMarkdownParser {
  struct PatternProcessorTests {
    private enum Fixtures {
      static let dogeEmoji = Emoji(
        shortcode: "doge",
        url: URL(string: "https://example.com/doge.png")!
      )
      static let sadDogEmoji = Emoji(
        shortcode: "sad_dog",
        url: URL(string: "https://example.com/sad_dog.png")!
      )
      static let emoji: Set<Emoji> = [dogeEmoji, sadDogEmoji]
      static let highlightColor = Color.yellow
    }

    @Test func expandsEmojiInText() throws {
      // given
      let processor = PatternProcessor(syntaxExtensions: [.emoji(Fixtures.emoji)])
      let input = try AttributedString(markdown: "Hello :doge: and :sad_dog:")

      var expected = try AttributedString(markdown: "Hello doge and sad_dog")

      let doge = try #require(expected.range(of: "doge"))
      let sadDog = try #require(expected.range(of: "sad_dog"))

      expected[doge].textual.emojiURL = Fixtures.dogeEmoji.url
      expected[sadDog].textual.emojiURL = Fixtures.sadDogEmoji.url

      // when
      let output = try processor.expand(input)

      // then
      #expect(output == expected)
    }

    @Test func ignoresEmojiInInlineCode() throws {
      // given
      let processor = PatternProcessor(syntaxExtensions: [.emoji(Fixtures.emoji)])
      let input = try AttributedString(markdown: "Hello `:doge:` and :doge:")

      var expected = try AttributedString(markdown: "Hello `:doge:` and doge")

      let doge = try #require(expected.range(of: "doge", options: .backwards))
      expected[doge].textual.emojiURL = Fixtures.dogeEmoji.url

      // when
      let output = try processor.expand(input)

      // then
      #expect(output == expected)
    }

    @Test func ignoresEmojiInCodeBlock() throws {
      // given
      let processor = PatternProcessor(syntaxExtensions: [.emoji(Fixtures.emoji)])
      let input = try AttributedString(
        markdown: """
          ```
          :doge:
          ```
          :doge:
          """
      )

      var expected = try AttributedString(
        markdown: """
          ```
          :doge:
          ```
          doge
          """
      )

      let doge = try #require(expected.range(of: "doge", options: .backwards))
      expected[doge].textual.emojiURL = Fixtures.dogeEmoji.url

      // when
      let output = try processor.expand(input)

      // then
      #expect(output == expected)
    }

    @Test func ignoresEmojiInNestedCodeBlock() throws {
      // given
      let processor = PatternProcessor(syntaxExtensions: [.emoji(Fixtures.emoji)])
      let input = try AttributedString(
        markdown: """
          > ```
          > :doge:
          > ```
          > :doge:
          """
      )

      var expected = try AttributedString(
        markdown: """
          > ```
          > :doge:
          > ```
          > doge
          """
      )

      let doge = try #require(expected.range(of: "doge", options: .backwards))
      expected[doge].textual.emojiURL = Fixtures.dogeEmoji.url

      // when
      let output = try processor.expand(input)

      // then
      #expect(output == expected)
    }

    @Test func highlightDrawsFormula() throws {
      // given
      let processor = PatternProcessor(
        syntaxExtensions: [.math, .highlight(color: Fixtures.highlightColor)]
      )

      // when
      let output = try processor.expand(AttributedString("==area is $x^2$=="))

      // then
      #expect(output == highlighted("area is ") + highlightedFormula("x^2"))
    }

    @Test func highlightDrawsTwoFormulas() throws {
      // given
      let processor = PatternProcessor(
        syntaxExtensions: [.math, .highlight(color: Fixtures.highlightColor)]
      )

      // when
      let output = try processor.expand(AttributedString("==$a$ and $b$, then=="))

      // then
      #expect(
        output == highlightedFormula("a") + highlighted(" and ") + highlightedFormula("b")
          + highlighted(", then")
      )
    }

    @Test func highlightDrawsBlockFormula() throws {
      // given
      let processor = PatternProcessor(
        syntaxExtensions: [.math, .highlight(color: Fixtures.highlightColor)]
      )

      // when
      let output = try processor.expand(AttributedString("==sum $$x+1$$=="))

      // then
      #expect(output == highlighted("sum ") + highlightedFormula("x+1", style: .block))
    }

    @Test func highlightRendersEscapedDollar() throws {
      // given
      let processor = PatternProcessor(
        syntaxExtensions: [.math, .highlight(color: Fixtures.highlightColor)]
      )

      // when
      let output = try processor.expand(AttributedString("==costs \\$5=="))

      // then
      #expect(output == highlighted("costs $5"))
    }

    @Test func highlightKeepsPricesAsText() throws {
      // given
      let processor = PatternProcessor(
        syntaxExtensions: [.math, .highlight(color: Fixtures.highlightColor)]
      )

      // when
      let output = try processor.expand(AttributedString("==$5 and $10=="))

      // then
      #expect(output == highlighted("$5 and $10"))
    }

    @Test func highlightKeepsPlainContent() throws {
      // given
      let processor = PatternProcessor(
        syntaxExtensions: [.math, .highlight(color: Fixtures.highlightColor)]
      )

      // when
      let output = try processor.expand(AttributedString("Read ==this part== twice"))

      // then
      #expect(
        output == AttributedString("Read ") + highlighted("this part") + AttributedString(" twice")
      )
      #expect(output.runs.count == 3)
    }

    private var highlightAttributes: AttributeContainer {
      var attributes = AttributeContainer()
      attributes.backgroundColor = Fixtures.highlightColor
      return attributes
    }

    private func highlighted(_ text: String) -> AttributedString {
      AttributedString(text, attributes: highlightAttributes)
    }

    private func highlightedFormula(
      _ latex: String,
      style: MathAttachment.DisplayStyle = .inline
    ) -> AttributedString {
      AttributedString(
        "\u{FFFC}",
        attributes: highlightAttributes.attachment(
          .init(MathAttachment(latex: latex, style: style))
        )
      )
    }
  }
}
