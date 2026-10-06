import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_file_services.dart';
import '../domain/file_services.dart';

/// Override with a real uploader (S3/MinIO/Firebase/custom) in the app.
final fileUploaderProvider = Provider<FileUploader>(
  (ref) => FakeFileUploader(),
);

/// Override with a `file_picker`/`image_picker` implementation in the app.
final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => DemoAttachmentPicker(),
);
