import SwiftUI

// MARK: - Overview
//
// Attachments are stored in attributed content as a `Textual.Attachment` attribute, but SwiftUI
// `Text` can’t embed arbitrary views. The rendering pipeline converts these runs into placeholder
// `Text` segments and uses an overlay to draw the real views at the resolved layout positions.
//
// `AttachmentAttribute` is attached to the placeholder runs during `Text` construction. It carries:
// - the original attachment value (type-erased as `AnyAttachment`)
// - the run's `PresentationIntent` (used by formatters and higher-level rendering)
// - the run's background color, if any: a placeholder image drops the run's attributes, so the
//   overlay paints it behind the attachment instead (for example, a formula inside a highlight)
//
// `Text.Layout.Run` exposes lightweight accessors so overlay code can discover attachments without
// reaching back into the original attributed string.

struct AttachmentAttribute: TextAttribute {
  var attachment: AnyAttachment
  var presentationIntent: PresentationIntent?
  var backgroundColor: Color?

  init(
    _ attachment: AnyAttachment,
    presentationIntent: PresentationIntent?,
    backgroundColor: Color? = nil
  ) {
    self.attachment = attachment
    self.presentationIntent = presentationIntent
    self.backgroundColor = backgroundColor
  }

  /// The attribute for `attachment` drawn in place of `run`, keeping the run's presentation
  /// intent and background color.
  init(_ attachment: AnyAttachment, run: AttributedString.Runs.Run) {
    self.init(
      attachment,
      presentationIntent: run.presentationIntent,
      backgroundColor: run.backgroundColor
    )
  }
}

extension Text.Layout.Run {
  var attachment: AnyAttachment? {
    self[AttachmentAttribute.self]?.attachment
  }

  var attachmentPresentationIntent: PresentationIntent? {
    self[AttachmentAttribute.self]?.presentationIntent
  }

  var attachmentBackgroundColor: Color? {
    self[AttachmentAttribute.self]?.backgroundColor
  }
}
