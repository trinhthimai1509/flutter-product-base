// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get commonEmpty => 'Chưa có nội dung';

  @override
  String get commonErrorTitle => 'Đã xảy ra lỗi';

  @override
  String get errorNetwork =>
      'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';

  @override
  String get errorTimeout =>
      'Yêu cầu mất quá nhiều thời gian. Vui lòng thử lại.';

  @override
  String get errorUnauthorized =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get errorForbidden => 'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get errorNotFound => 'Không tìm thấy dữ liệu yêu cầu.';

  @override
  String get errorValidation =>
      'Một số thông tin không hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get errorServer => 'Máy chủ gặp sự cố. Vui lòng thử lại sau.';

  @override
  String get errorStorage => 'Không thể truy cập bộ nhớ thiết bị.';

  @override
  String get errorUnknown => 'Đã xảy ra lỗi không mong muốn.';

  @override
  String get authSignInTitle => 'Chào mừng';

  @override
  String get authSignInSubtitle => 'Đăng nhập để tiếp tục';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Mật khẩu';

  @override
  String get authSignInButton => 'Đăng nhập';

  @override
  String get authContinueAsGuest => 'Tiếp tục với tư cách khách';

  @override
  String get authEmailInvalid => 'Vui lòng nhập email hợp lệ';

  @override
  String authPasswordTooShort(int min) {
    return 'Mật khẩu phải có ít nhất $min ký tự';
  }

  @override
  String get authDemoHint =>
      'Chế độ demo: dùng email bất kỳ và mật khẩu từ 6 ký tự.';

  @override
  String get authSignOut => 'Đăng xuất';

  @override
  String get authSignOutConfirmTitle => 'Đăng xuất?';

  @override
  String get authSignOutConfirmMessage =>
      'Bạn sẽ cần đăng nhập lại để tiếp tục.';

  @override
  String get authGuestName => 'Khách';

  @override
  String get homeTitle => 'Trang chủ';

  @override
  String homeGreeting(String name) {
    return 'Xin chào, $name';
  }

  @override
  String get homeSubtitle =>
      'Ứng dụng nền tảng này minh họa các module có thể tái sử dụng.';

  @override
  String get homeChatTitle => 'Demo Chat';

  @override
  String get homeChatSubtitle => 'Chat engine tổng quát với provider giả lập';

  @override
  String get homeSettingsTitle => 'Cài đặt';

  @override
  String get homeSettingsSubtitle =>
      'Giao diện, ngôn ngữ và thông tin ứng dụng';

  @override
  String get homeShowcaseTitle => 'Trình diễn nền tảng';

  @override
  String get homeShowcaseSubtitle =>
      'Các thành phần và trạng thái của design system';

  @override
  String get homeProfileTitle => 'Hồ sơ';

  @override
  String get homeProfileSubtitle => 'Người dùng và phiên hiện tại';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String get settingsAbout => 'Thông tin';

  @override
  String get settingsAppName => 'Tên ứng dụng';

  @override
  String get settingsVersion => 'Phiên bản';

  @override
  String get settingsEnvironment => 'Môi trường';

  @override
  String get settingsAccount => 'Tài khoản';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profileUserId => 'Mã người dùng';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileNoEmail => 'Chưa cung cấp';

  @override
  String get profileGuestBadge => 'Phiên khách';

  @override
  String get chatTitle => 'Cuộc trò chuyện';

  @override
  String get chatEmptyConversations => 'Chưa có cuộc trò chuyện nào';

  @override
  String get chatEmptyMessages => 'Chưa có tin nhắn. Hãy gửi lời chào!';

  @override
  String get chatComposerHint => 'Nhập tin nhắn';

  @override
  String get chatSend => 'Gửi';

  @override
  String get chatAttach => 'Đính kèm tệp';

  @override
  String get chatStop => 'Dừng tạo phản hồi';

  @override
  String get chatRegenerate => 'Tạo lại';

  @override
  String get chatFailed => 'Chưa gửi được. Chạm để thử lại.';

  @override
  String chatReplyingTo(String name) {
    return 'Đang trả lời $name';
  }

  @override
  String get chatReply => 'Trả lời';

  @override
  String get chatCancelReply => 'Hủy trả lời';

  @override
  String chatTyping(String name) {
    return '$name đang nhập…';
  }

  @override
  String get chatSources => 'Nguồn tham khảo';

  @override
  String get chatYou => 'Bạn';

  @override
  String get chatDemoHint =>
      'Mẹo: thêm \"/fail\" vào tin nhắn để giả lập gửi thất bại.';

  @override
  String get chatUploading => 'Đang tải lên…';

  @override
  String get notFoundTitle => 'Không tìm thấy trang';

  @override
  String get notFoundMessage => 'Trang bạn tìm kiếm không tồn tại.';

  @override
  String get notFoundGoHome => 'Về trang chủ';

  @override
  String get showcaseTitle => 'Trình diễn nền tảng';

  @override
  String get showcaseButtons => 'Nút bấm';

  @override
  String get showcasePrimary => 'Chính';

  @override
  String get showcaseSecondary => 'Phụ';

  @override
  String get showcaseTextButton => 'Văn bản';

  @override
  String get showcaseInputs => 'Ô nhập liệu';

  @override
  String get showcaseSampleInput => 'Ô nhập mẫu';

  @override
  String get showcaseStates => 'Trạng thái';

  @override
  String get showcaseFeedback => 'Phản hồi';

  @override
  String get showcaseShowDialog => 'Hiện hộp thoại';

  @override
  String get showcaseDialogMessage =>
      'Đây là hộp thoại xác nhận có thể tái sử dụng.';

  @override
  String get showcaseShowSnackbar => 'Hiện snackbar';

  @override
  String get showcaseSnackbarMessage => 'Đây là snackbar có thể tái sử dụng.';

  @override
  String get showcaseSendNotification => 'Gửi thông báo trong ứng dụng';

  @override
  String get showcaseNotificationTitle => 'Xin chào từ trung tâm thông báo';

  @override
  String get showcaseNotificationBody =>
      'Thông báo trong ứng dụng được gửi qua một service có thể thay thế.';

  @override
  String get showcaseAttachments => 'Tệp đính kèm';
}
