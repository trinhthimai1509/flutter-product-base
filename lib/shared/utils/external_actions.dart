import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Leaving the app: share sheet and external links.
///
/// Behind an interface so widgets stay testable (override
/// `externalActionsProvider` with a fake).
abstract interface class ExternalActions {
  /// Opens the system share sheet. Returns false if it could not open.
  Future<bool> shareText(String text, {String? subject});

  /// Opens an http/https URL in the browser. Any other scheme is refused
  /// (prevents `intent:`/`file:` tricks from untrusted strings).
  Future<bool> openUrl(String url);
}

class PlatformExternalActions implements ExternalActions {
  const PlatformExternalActions();

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
      return result.status != ShareResultStatus.unavailable;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !isWebUrl(uri)) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }

  static bool isWebUrl(Uri uri) =>
      (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
}
