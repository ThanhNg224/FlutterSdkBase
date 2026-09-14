// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Flutter SDK Base';

  @override
  String get settingsTooltip => 'Cài đặt';

  @override
  String get catalogTitle => 'Danh mục tính năng Core';

  @override
  String get catalogSubtitle =>
      'Khám phá các module kiến trúc, quản lý trạng thái và Clean Architecture trong dự án base.';

  @override
  String get exploreSdkFeaturesTitle => 'Khám phá các tính năng SDK';

  @override
  String get exploreSdkFeaturesSubtitle =>
      'Chọn một module tích hợp bên dưới để cấu hình tham số và kiểm thử trực tiếp SDK.';

  @override
  String get comingSoon => 'Sắp ra mắt';

  @override
  String get postsFeedTitle => 'Danh sách bài viết mẫu';

  @override
  String get refreshTooltip => 'Làm mới';

  @override
  String get noPostsFound => 'Chưa có bài viết nào';

  @override
  String get createFirstPostButton => 'Tạo bài viết đầu tiên';

  @override
  String get newPostButton => 'Tạo bài viết';

  @override
  String get deletePostTitle => 'Xóa bài viết';

  @override
  String deletePostConfirmation(String title) {
    return 'Bạn có chắc chắn muốn xóa \"$title\" không?';
  }

  @override
  String get deleteButton => 'Xóa';

  @override
  String postDetailTitle(int id) {
    return 'Bài viết #$id';
  }

  @override
  String authorIdLabel(int id) {
    return 'Tác giả #$id';
  }

  @override
  String get publishedArticleLabel => 'Bài viết đã xuất bản';

  @override
  String postSubtitle(int id, int userId) {
    return 'Bài viết #$id · Tác giả #$userId';
  }

  @override
  String get createPostTitle => 'Tạo bài viết mới';

  @override
  String get postTitleFieldLabel => 'Tiêu đề';

  @override
  String get postTitleFieldHint => 'Nhập tiêu đề bài viết';

  @override
  String get titleRequiredValidation => 'Vui lòng nhập tiêu đề';

  @override
  String get postBodyFieldLabel => 'Nội dung';

  @override
  String get postBodyFieldHint => 'Nhập nội dung bài viết...';

  @override
  String get contentRequiredValidation => 'Vui lòng nhập nội dung';

  @override
  String get publishPostButton => 'Đăng bài viết';

  @override
  String get postCreatedSuccessMessage => 'Tạo bài viết thành công!';

  @override
  String get developerSdkSettingsTitle => 'Cài đặt & Nhà phát triển';

  @override
  String get sdkEnvironmentTitle => 'Cấu hình môi trường';

  @override
  String get useDevServerLabel => 'Sử dụng máy chủ Dev';

  @override
  String get connectedDevEnvironment => 'Đang kết nối môi trường Dev';

  @override
  String get connectedProdEnvironment => 'Đang kết nối môi trường Production';

  @override
  String get activeBaseUrlLabel => 'Base URL hiện tại:';

  @override
  String get mockSdkModeLabel => 'Chế độ Mock API';

  @override
  String get mockSdkModeDescription => 'Mô phỏng dữ liệu phản hồi không phụ thuộc mạng bên ngoài';

  @override
  String get credentialsTitle => 'Thông tin xác thực & Ghi đè';

  @override
  String get credentialsDescription =>
      'Ghi đè thông tin xác thực cho riêng thiết bị này. Để trống để sử dụng mặc định.';

  @override
  String get appTokenLabel => 'App Token';

  @override
  String get clientKeyLabel => 'Client Key';

  @override
  String credentialsActiveHint(String value) {
    return 'Hiện tại: $value';
  }

  @override
  String get resetCredentialsButton => 'Khôi phục mặc định';

  @override
  String get credentialsResetMessage => 'Đã xóa cấu hình ghi đè';

  @override
  String get saveCredentialsButton => 'Lưu thông tin';

  @override
  String get credentialsSavedMessage => 'Đã cập nhật thông tin xác thực';

  @override
  String get appearanceThemeTitle => 'Giao diện & Chủ đề';

  @override
  String get themeModeLabel => 'Chế độ màu';

  @override
  String get themeModeSystem => 'Hệ thống';

  @override
  String get themeModeLight => 'Sáng';

  @override
  String get themeModeDark => 'Tối';

  @override
  String get languageTitle => 'Ngôn ngữ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get aboutTitle => 'Thông tin';

  @override
  String get sdkVersionLabel => 'Phiên bản Base App:';

  @override
  String get errorNetwork => 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra đường truyền internet và thử lại.';

  @override
  String get errorServer => 'Máy chủ không thể xử lý yêu cầu lúc này. Vui lòng thử lại sau giây lát.';

  @override
  String get errorUnauthorized => 'Thông tin xác thực không hợp lệ. Vui lòng kiểm tra lại cấu hình trong Cài đặt.';

  @override
  String get errorPlatform => 'SDK gốc không thể hoàn thành tác vụ trên thiết bị này.';

  @override
  String get errorStorage => 'Không thể đọc dữ liệu cấu hình cục bộ của ứng dụng.';

  @override
  String get errorUnexpected => 'Đã có lỗi xảy ra. Vui lòng thử lại.';

  @override
  String get validationRequired => 'Trường này là bắt buộc.';

  @override
  String get validationEmail => 'Vui lòng nhập địa chỉ email hợp lệ.';

  @override
  String validationMinLength(int count) {
    return 'Vui lòng nhập ít nhất $count ký tự.';
  }

  @override
  String get offlineBannerMessage => 'Bạn đang ngoại tuyến. Vui lòng kiểm tra kết nối.';

  @override
  String get closeButton => 'Đóng';

  @override
  String get retryButton => 'Thử lại';

  @override
  String get cancelButton => 'Hủy';

  @override
  String get saveButton => 'Lưu';

  @override
  String get confirmButton => 'Xác nhận';

  @override
  String get somethingWentWrongMessage => 'Đã có lỗi xảy ra';

  @override
  String pageNotFoundMessage(String uri) {
    return 'Không tìm thấy trang: $uri';
  }
}
