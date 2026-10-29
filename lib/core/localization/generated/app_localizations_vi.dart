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

  @override
  String get offlineBanner =>
      'Bạn đang ngoại tuyến. Một số tính năng có thể không hoạt động.';

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingNext => 'Tiếp';

  @override
  String get onboardingFinish => 'Bắt đầu';

  @override
  String onboardingPageIndicator(int current, int total) {
    return 'Trang $current/$total';
  }

  @override
  String get onboardingPage1Title => 'Nền móng, không phải sản phẩm';

  @override
  String get onboardingPage1Body =>
      'Đăng nhập, mạng, chat, cài đặt và nhiều hơn nữa, sẵn sàng để xây tiếp.';

  @override
  String get onboardingPage2Title => 'Chọn đúng thứ bạn cần';

  @override
  String get onboardingPage2Body =>
      'Quảng cáo, thanh toán, thông báo và telemetry là các package tùy chọn.';

  @override
  String get onboardingPage3Title => 'Chạy không cần server';

  @override
  String get onboardingPage3Body =>
      'Bản giả lập thay cho backend và store cho đến khi bạn có hệ thống thật.';

  @override
  String get premiumTitle => 'Pro';

  @override
  String get premiumHeadline => 'Nâng cấp Pro';

  @override
  String get premiumSubtitle => 'Mua một lần, dùng mãi mãi.';

  @override
  String get premiumBenefitNoAds => 'Không quảng cáo';

  @override
  String get premiumBenefitFeatures => 'Mọi tính năng cao cấp';

  @override
  String get premiumBenefitSupport => 'Ủng hộ phát triển ứng dụng';

  @override
  String get premiumFootnote => 'Thanh toán một lần. Không gia hạn.';

  @override
  String premiumBuy(String price) {
    return 'Mua Pro với giá $price';
  }

  @override
  String get premiumUnavailable => 'Hiện chưa thể mua';

  @override
  String get premiumRestore => 'Khôi phục giao dịch';

  @override
  String get premiumOwned => 'Bạn đã có Pro. Cảm ơn bạn!';

  @override
  String get premiumPending =>
      'Thanh toán đang chờ xử lý. Pro sẽ mở khi hoàn tất.';

  @override
  String get premiumMsgCompleted => 'Chào mừng bạn đến với Pro!';

  @override
  String get premiumMsgPending => 'Thanh toán đang chờ xử lý.';

  @override
  String get premiumMsgAlreadyOwned => 'Bạn đã sở hữu Pro.';

  @override
  String get premiumMsgRestored => 'Đã khôi phục giao dịch.';

  @override
  String get premiumMsgNothingToRestore => 'Không tìm thấy giao dịch trước đó.';

  @override
  String get premiumMsgCouldNotCheck =>
      'Không kết nối được cửa hàng. Vui lòng thử lại.';

  @override
  String get premiumMsgFailed => 'Giao dịch thất bại. Bạn chưa bị trừ tiền.';

  @override
  String get settingsDynamicColor => 'Màu động';

  @override
  String get settingsDynamicColorSubtitle => 'Dùng màu theo hình nền';

  @override
  String get settingsNotifications => 'Thông báo';

  @override
  String get settingsNotificationsSubtitle => 'Nhắc nhở và cập nhật';

  @override
  String get settingsNotificationsDenied =>
      'Thông báo đang bị chặn. Hãy cho phép trong cài đặt hệ thống.';

  @override
  String get settingsPremium => 'Nâng cấp Pro';

  @override
  String get settingsPremiumSubtitle => 'Bỏ quảng cáo và mở khóa mọi tính năng';

  @override
  String get settingsPremiumActive => 'Đã kích hoạt Pro';

  @override
  String get settingsPrivacyOptions => 'Tùy chọn quyền riêng tư';

  @override
  String get settingsRateApp => 'Đánh giá ứng dụng';

  @override
  String get settingsShareApp => 'Chia sẻ ứng dụng';

  @override
  String settingsShareMessage(String appName) {
    return 'Mình đang dùng $appName.';
  }

  @override
  String get settingsPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get settingsReplayOnboarding => 'Xem lại giới thiệu';

  @override
  String get settingsLinkFailed => 'Không mở được liên kết.';

  @override
  String get homeCapabilitiesTitle => 'Tính năng mở rộng';

  @override
  String get homeCapabilitiesSubtitle =>
      'Quảng cáo, thanh toán, thông báo, đánh giá, telemetry';

  @override
  String get notificationChannelReminders => 'Nhắc nhở';

  @override
  String get notificationChannelRemindersDescription =>
      'Các lời nhắc bạn đặt trong ứng dụng';

  @override
  String get notificationDemoTitle => 'Xin chào từ Flutter Base';

  @override
  String get notificationDemoBody => 'Chạm để mở trang tính năng mở rộng.';

  @override
  String get capConnectivity => 'Kết nối mạng';

  @override
  String get capOnline => 'Đang trực tuyến';

  @override
  String get capOffline => 'Ngoại tuyến';

  @override
  String get capTelemetry => 'Telemetry';

  @override
  String capTelemetryBackend(String name) {
    return 'Backend: $name';
  }

  @override
  String get capLogEvent => 'Ghi sự kiện thử';

  @override
  String get capEventLogged => 'Đã ghi sự kiện.';

  @override
  String capPermissionStatus(String status) {
    return 'Quyền: $status';
  }

  @override
  String get capPermissionGranted => 'đã cấp';

  @override
  String get capPermissionNotGranted => 'chưa cấp';

  @override
  String get capRequestPermission => 'Xin quyền';

  @override
  String get capShowNow => 'Hiện ngay';

  @override
  String get capScheduleReminder => 'Nhắc sau 10 giây';

  @override
  String get capReminderScheduled => 'Đã đặt lời nhắc.';

  @override
  String get capReview => 'Đánh giá trong ứng dụng';

  @override
  String get capRequestReview => 'Yêu cầu đánh giá';

  @override
  String get capReviewUnavailable => 'Không thể đánh giá trên thiết bị này.';

  @override
  String get capAds => 'Quảng cáo';

  @override
  String capAdsStatus(String available) {
    return 'Có quảng cáo: $available';
  }

  @override
  String get capShowInterstitial => 'Hiện quảng cáo toàn màn hình';

  @override
  String get capShowRewarded => 'Hiện quảng cáo có thưởng';

  @override
  String get capRecordAction => 'Ghi nhận hành động';

  @override
  String capAdResult(String result) {
    return 'Kết quả: $result';
  }

  @override
  String capPremiumStatus(String status) {
    return 'Trạng thái: $status';
  }

  @override
  String get capOpenPaywall => 'Mở trang Pro';

  @override
  String get capResetPurchase => 'Đặt lại giao dịch demo';

  @override
  String get capOnboarding => 'Giới thiệu';

  @override
  String get commonYes => 'có';

  @override
  String get commonNo => 'không';
}
