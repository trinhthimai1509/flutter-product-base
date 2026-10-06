import '../../../shared/utils/id_generator.dart';
import '../domain/attachment.dart';
import '../domain/file_services.dart';
import '../domain/mime_types.dart';

/// Simulates an upload with progress; returns a fake remote URL.
/// For demos/tests only.
class FakeFileUploader implements FileUploader {
  FakeFileUploader({
    this.stepDelay = const Duration(milliseconds: 150),
    this.steps = 4,
  });

  final Duration stepDelay;
  final int steps;

  @override
  Future<RemoteAttachmentSource> upload(
    Attachment attachment, {
    void Function(double progress)? onProgress,
  }) async {
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(stepDelay);
      onProgress?.call(i / steps);
    }
    final key = 'uploads/${attachment.id}/${attachment.name}';
    return RemoteAttachmentSource(
      url: 'https://files.example.com/$key',
      storageKey: key,
    );
  }
}

/// Returns a sample document without touching the file system, so the chat
/// demo can exercise the attachment pipeline without native plugins.
class DemoAttachmentPicker implements AttachmentPicker {
  DemoAttachmentPicker([IdGenerator? ids]) : _ids = ids ?? RandomIdGenerator();

  final IdGenerator _ids;

  @override
  Future<List<Attachment>> pick({Set<AttachmentKind>? kinds}) async {
    const name = 'sample-report.pdf';
    final mime = MimeTypes.fromFileName(name);
    return [
      Attachment(
        id: _ids.next(),
        name: name,
        mimeType: mime,
        kind: MimeTypes.kindOf(mime),
        sizeBytes: 248 * 1024,
        source: const LocalAttachmentSource('/demo/sample-report.pdf'),
      ),
    ];
  }
}
