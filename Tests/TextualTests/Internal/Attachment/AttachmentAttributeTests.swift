import SwiftUI
import Testing

@testable import Textual

struct AttachmentAttributeTests {
  private let processor = AttributedStringMarkdownParser.PatternProcessor(
    syntaxExtensions: [.math, .highlight(color: .yellow)]
  )

  @Test func carriesTheRunsBackgroundColor() throws {
    // given
    let output = try processor.expand(AttributedString("==area is $x^2$=="))
    let run = try #require(output.runs.first { $0.textual.attachment != nil })
    let attachment = try #require(run.textual.attachment)

    // when
    let attribute = AttachmentAttribute(attachment, run: run)

    // then
    #expect(attribute.backgroundColor == .yellow)
  }

  @Test func carriesNoBackgroundColorWithoutOne() throws {
    // given
    let output = try processor.expand(AttributedString("area is $x^2$"))
    let run = try #require(output.runs.first { $0.textual.attachment != nil })
    let attachment = try #require(run.textual.attachment)

    // when
    let attribute = AttachmentAttribute(attachment, run: run)

    // then
    #expect(attribute.backgroundColor == nil)
    #expect(attribute == AttachmentAttribute(attachment, presentationIntent: nil))
  }

  @Test func keepsTheRunsPresentationIntent() throws {
    // given
    let input = try AttributedString(markdown: "area is $x^2$")
    let output = try processor.expand(input)
    let run = try #require(output.runs.first { $0.textual.attachment != nil })
    let attachment = try #require(run.textual.attachment)

    // when
    let attribute = AttachmentAttribute(attachment, run: run)

    // then
    #expect(attribute.presentationIntent != nil)
    #expect(attribute.presentationIntent == input.runs.first?.presentationIntent)
  }
}
