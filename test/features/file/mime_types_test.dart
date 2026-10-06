import 'package:flutter_project_base/features/file/domain/attachment.dart';
import 'package:flutter_project_base/features/file/domain/mime_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects MIME type from file name', () {
    expect(MimeTypes.fromFileName('a.JPG'), 'image/jpeg');
    expect(MimeTypes.fromFileName('b.pdf'), 'application/pdf');
    expect(MimeTypes.fromFileName('noext'), MimeTypes.octetStream);
    expect(MimeTypes.fromFileName('weird.'), MimeTypes.octetStream);
  });

  test('classifies kinds', () {
    expect(MimeTypes.kindOf('image/png'), AttachmentKind.image);
    expect(MimeTypes.kindOf('video/mp4'), AttachmentKind.video);
    expect(MimeTypes.kindOf('audio/mpeg'), AttachmentKind.audio);
    expect(MimeTypes.kindOf('application/pdf'), AttachmentKind.document);
    expect(MimeTypes.kindOf('text/plain'), AttachmentKind.document);
    expect(
      MimeTypes.kindOf(MimeTypes.fromFileName('x.docx')),
      AttachmentKind.document,
    );
    expect(MimeTypes.kindOf('application/zip'), AttachmentKind.other);
  });

  test('formats byte sizes', () {
    expect(MimeTypes.formatBytes(512), '512 B');
    expect(MimeTypes.formatBytes(1536), '1.5 KB');
    expect(MimeTypes.formatBytes(25 * 1024 * 1024), '25 MB');
  });

  test('local attachments need upload until uploaded', () {
    const a = Attachment(
      id: '1',
      name: 'x.png',
      mimeType: 'image/png',
      kind: AttachmentKind.image,
      source: LocalAttachmentSource('/tmp/x.png'),
    );
    expect(a.needsUpload, isTrue);
    expect(
      a.copyWith(uploadStatus: UploadStatus.uploaded).needsUpload,
      isFalse,
    );
    expect(
      a
          .copyWith(source: const RemoteAttachmentSource(url: 'https://x'))
          .needsUpload,
      isFalse,
    );
  });
}
