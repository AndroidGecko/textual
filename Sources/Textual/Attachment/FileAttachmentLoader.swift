import SwiftUI

/// An attachment loader that reads images synchronously from the local filesystem.
///
/// Use `FileAttachmentLoader` when your markup references images by relative file paths
/// and you need attachments resolved on the first render pass — for example, in widgets.
///
/// ```swift
/// StructuredText(markdown: "![](photo.jpg)")
///   .textual.imageAttachmentLoader(.file(relativeTo: imageDirectoryURL))
/// ```
public struct FileAttachmentLoader: SynchronousAttachmentLoader {
  private let baseURL: URL?

  fileprivate init(baseURL: URL?) {
    self.baseURL = baseURL
  }

  public func attachment(
    for url: URL,
    text: String,
    environment: ColorEnvironmentValues
  ) async throws -> some Attachment {
    guard let attachment = syncAttachment(for: url, text: text, environment: environment)
    else { throw URLError(.cannotDecodeContentData) }
    return attachment
  }

  public func syncAttachment(
    for url: URL,
    text: String,
    environment: ColorEnvironmentValues
  ) -> (any Textual.Attachment)? {
    let imageURL = URL(string: url.absoluteString, relativeTo: baseURL) ?? url
    guard imageURL.isFileURL,
          let data = try? Data(contentsOf: imageURL),
          let image = Image(data: data)
    else { return nil }
    return ImageAttachment(image: image, text: text)
  }
}

extension AttachmentLoader where Self == FileAttachmentLoader {
  /// Loads images synchronously from the local filesystem.
  ///
  /// Use this loader when images are stored as local files and you need first-render
  /// resolution — for example, in widget views.
  ///
  /// - Parameter baseURL: The base URL used to resolve relative file paths.
  public static func file(relativeTo baseURL: URL? = nil) -> Self {
    .init(baseURL: baseURL)
  }
}
