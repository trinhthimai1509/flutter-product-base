import 'attachment.dart';

/// Uploads a local attachment to remote storage.
///
/// Implement per backend: presigned S3/MinIO PUT, Firebase Storage, or a
/// custom multipart endpoint. Throws `AppFailure` on error.
abstract interface class FileUploader {
  Future<RemoteAttachmentSource> upload(
    Attachment attachment, {
    void Function(double progress)? onProgress,
  });
}

/// Lets the user choose files. Implement with `file_picker` / `image_picker`
/// in the consuming app; the base ships only a demo implementation to avoid
/// native plugin setup that not every app needs.
abstract interface class AttachmentPicker {
  Future<List<Attachment>> pick({Set<AttachmentKind>? kinds});
}
