import Foundation
import Testing

@testable import Textual

struct PatternTokenizerTests {
  @Test func text() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.emoji])

    // when
    let tokens = try tokenizer.tokenize("Hello world")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Hello world")
      ]
    )
  }

  @Test func emoji() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.emoji])

    // when
    let tokens = try tokenizer.tokenize("Hello :smile: and :heart: world")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Hello "),
        .init(type: .emoji, content: ":smile:", capturedContent: "smile"),
        .init(type: .text, content: " and "),
        .init(type: .emoji, content: ":heart:", capturedContent: "heart"),
        .init(type: .text, content: " world"),
      ]
    )
  }

  @Test func adjacentEmoji() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.emoji])

    // when
    let tokens = try tokenizer.tokenize("Hello :smile::heart: world")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Hello "),
        .init(type: .emoji, content: ":smile:", capturedContent: "smile"),
        .init(type: .emoji, content: ":heart:", capturedContent: "heart"),
        .init(type: .text, content: " world"),
      ]
    )
  }

  @Test func incompleteEmoji() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.emoji])

    // when
    let tokens = try tokenizer.tokenize("Hello :smile")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Hello :smile")
      ]
    )
  }

  @Test func emptyEmoji() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.emoji])

    // when
    let tokens = try tokenizer.tokenize("Hello :: world")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Hello :: world")
      ]
    )
  }

  @Test func invalidEmoji() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.emoji])

    // when
    let tokens = try tokenizer.tokenize("Hello :not emoji: :notemoji!: world")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Hello :not emoji: :notemoji!: world")
      ]
    )
  }

  @Test func preservesNewlines() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.emoji])

    // when
    let tokens = try tokenizer.tokenize(
      """
      Some line
      Hello :smile: and :heart: world
      Another line
      """
    )

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Some line\nHello "),
        .init(type: .emoji, content: ":smile:", capturedContent: "smile"),
        .init(type: .text, content: " and "),
        .init(type: .emoji, content: ":heart:", capturedContent: "heart"),
        .init(type: .text, content: " world\nAnother line"),
      ]
    )
  }

  @Test func inlineMath() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.mathBlock, .mathInline])

    // when
    let tokens = try tokenizer.tokenize("Euler: $e^{i\\pi}+1=0$.")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Euler: "),
        .init(type: .mathInline, content: "$e^{i\\pi}+1=0$", capturedContent: "e^{i\\pi}+1=0"),
        .init(type: .text, content: "."),
      ]
    )
  }

  @Test func inlineMathEscapedDollar() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.mathBlock, .mathInline])

    // when
    let tokens = try tokenizer.tokenize("Cost: $a\\$b$")

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Cost: "),
        .init(type: .mathInline, content: "$a\\$b$", capturedContent: "a\\$b"),
      ]
    )
  }

  @Test func pricesAreNotMath() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.escapedDollar, .mathBlock, .mathInline])

    // when
    let prices = try tokenizer.tokenize("It costs $5 and $10.")
    let thousands = try tokenizer.tokenize("$20,000 and $30,000")

    // then
    #expect(prices == [.init(type: .text, content: "It costs $5 and $10.")])
    #expect(thousands == [.init(type: .text, content: "$20,000 and $30,000")])
  }

  @Test func inlineMathFollowsPandocRule() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.escapedDollar, .mathBlock, .mathInline])

    // then: a space just inside either dollar, or a digit right after
    // the closing one, means no math
    #expect(try tokenizer.tokenize("$ x$") == [.init(type: .text, content: "$ x$")])
    #expect(try tokenizer.tokenize("$x $") == [.init(type: .text, content: "$x $")])
    #expect(try tokenizer.tokenize("$x$5") == [.init(type: .text, content: "$x$5")])
    #expect(
      try tokenizer.tokenize("$x^2$, $5 and $y$") == [
        .init(type: .mathInline, content: "$x^2$", capturedContent: "x^2"),
        .init(type: .text, content: ", $5 and "),
        .init(type: .mathInline, content: "$y$", capturedContent: "y"),
      ]
    )
  }

  @Test func escapedDollarIsLiteral() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.escapedDollar, .mathBlock, .mathInline])

    // when
    let tokens = try tokenizer.tokenize("\\$5 and \\$10")

    // then
    #expect(
      tokens == [
        .init(type: .escapedDollar, content: "\\$", capturedContent: "$"),
        .init(type: .text, content: "5 and "),
        .init(type: .escapedDollar, content: "\\$", capturedContent: "$"),
        .init(type: .text, content: "10"),
      ]
    )
  }

  @Test func escapedDollarInsideMathStaysMath() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.escapedDollar, .mathBlock, .mathInline])

    // when
    let tokens = try tokenizer.tokenize("$a \\$ b$ and $x\\\\$")

    // then
    #expect(
      tokens == [
        .init(type: .mathInline, content: "$a \\$ b$", capturedContent: "a \\$ b"),
        .init(type: .text, content: " and "),
        .init(type: .mathInline, content: "$x\\\\$", capturedContent: "x\\\\"),
      ]
    )
  }

  @Test func mathExtensionRendersEscapedDollar() throws {
    // given
    let processor = AttributedStringMarkdownParser.PatternProcessor(syntaxExtensions: [.math])

    // when
    let output = try processor.expand(AttributedString("\\$5 and \\$10, $x$"))

    // then
    #expect(String(output.characters) == "$5 and $10, \u{FFFC}")
  }

  @Test func blockMath() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.mathBlock, .mathInline])

    // when
    let tokens = try tokenizer.tokenize(
      """
      Before
      $$E = mc^2$$
      After
      """
    )

    // then
    #expect(
      tokens == [
        .init(type: .text, content: "Before\n"),
        .init(type: .mathBlock, content: "$$E = mc^2$$", capturedContent: "E = mc^2"),
        .init(type: .text, content: "\nAfter"),
      ]
    )
  }

  @Test func blockMathPreferredOverInline() throws {
    // given
    let tokenizer = PatternTokenizer(patterns: [.mathBlock, .mathInline])

    // when
    let tokens = try tokenizer.tokenize("$$x+1$$")

    // then
    #expect(
      tokens == [
        .init(type: .mathBlock, content: "$$x+1$$", capturedContent: "x+1")
      ]
    )
  }
}
