import '../models/break_identity.dart';

abstract class BreakIdentityRepository {
  Future<BreakIdentity> getOrCreateIdentity();

  Future<BreakIdentity> saveNickname(String nickname);
}
