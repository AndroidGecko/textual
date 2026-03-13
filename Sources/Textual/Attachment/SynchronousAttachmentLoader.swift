import SwiftUI

/// An attachment loader that can resolve attachments synchronously.
///
/// Conform to this protocol when your loader can provide attachments without any asynchronous
/// work — for example, when loading images from the local filesystem. Textual will use the
/// synchronous path to resolve attachments on the first render pass, which is required for
/// environments like widgets where `.task` may not trigger a re-render.
///
/// ```swift
/// StructuredText(markdown: "![](photo.jpg)")
///   .textual.imageAttachmentLoader(.file(relativeTo: sharedContainerURL))
/// ```
public protocol SynchronousAttachmentLoader: AttachmentLoader {
  /// Loads an attachment synchronously for the given URL.
  ///
  /// Return `nil` if the attachment cannot be resolved synchronously.
  ///
  /// - Parameters:
  ///   - url: The URL found in the markup.
  ///   - text: The original text associated with the URL (for example, image alt text).
  ///   - environment: The current color environment.
  func syncAttachment(
    for url: URL,
    text: String,
    environment: ColorEnvironmentValues
  ) -> (any Textual.Attachment)?
}
