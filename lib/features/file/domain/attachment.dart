import 'package:equatable/equatable.dart';

enum AttachmentKind { image, video, audio, document, other }

enum UploadStatus { none, uploading, uploaded, failed }

/// Where the bytes of an attachment live.
sealed class AttachmentSource extends Equatable {
  const AttachmentSource();
}

/// File on this device (picked or captured, not uploaded yet).
class LocalAttachmentSource extends AttachmentSource {
  const LocalAttachmentSource(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

/// File stored remotely. [storageKey] is the backend-specific object key
/// (S3/MinIO key, Firebase Storage path, custom id...), [url] the
/// downloadable/streamable location (may be a signed URL).
class RemoteAttachmentSource extends AttachmentSource {
  const RemoteAttachmentSource({required this.url, this.storageKey});

  final String url;
  final String? storageKey;

  @override
  List<Object?> get props => [url, storageKey];
}

/// Optional media details.
class MediaInfo extends Equatable {
  const MediaInfo({this.width, this.height, this.duration, this.thumbnailUrl});

  final int? width;
  final int? height;
  final Duration? duration;
  final String? thumbnailUrl;

  @override
  List<Object?> get props => [width, height, duration, thumbnailUrl];
}

/// Vendor-neutral file/media reference used by chat and any other feature.
class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.kind,
    required this.source,
    this.sizeBytes,
    this.media,
    this.uploadStatus = UploadStatus.none,
    this.uploadProgress,
  });

  final String id;
  final String name;
  final String mimeType;
  final AttachmentKind kind;
  final AttachmentSource source;
  final int? sizeBytes;
  final MediaInfo? media;
  final UploadStatus uploadStatus;

  /// 0..1 while uploading, null when unknown.
  final double? uploadProgress;

  bool get isLocal => source is LocalAttachmentSource;
  bool get needsUpload => isLocal && uploadStatus != UploadStatus.uploaded;

  Attachment copyWith({
    AttachmentSource? source,
    UploadStatus? uploadStatus,
    double? uploadProgress,
    MediaInfo? media,
  }) => Attachment(
    id: id,
    name: name,
    mimeType: mimeType,
    kind: kind,
    source: source ?? this.source,
    sizeBytes: sizeBytes,
    media: media ?? this.media,
    uploadStatus: uploadStatus ?? this.uploadStatus,
    uploadProgress: uploadProgress ?? this.uploadProgress,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    mimeType,
    kind,
    source,
    sizeBytes,
    media,
    uploadStatus,
    uploadProgress,
  ];
}
