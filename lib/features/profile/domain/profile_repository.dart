import '../../../core/error/result.dart';
import 'user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> getCurrentProfile();
}
